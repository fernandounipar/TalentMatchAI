# RF8 - HISTÓRICO DE ENTREVISTAS (INTERVIEW HISTORY)

## Visão Geral

**Status:** ✅ Implementado (Backend completo)  
**Data de Conclusão:** 22/11/2025  
**Migrations:** 022-023  
**Endpoints:** 7 main + 5 dashboard = 12 total  
**Testes:** 70+ requests na coleção RF8_INTERVIEWS_API_COLLECTION.http

O RF8 aprimora o sistema de entrevistas existente com capacidades completas de histórico e métricas, permitindo rastreamento detalhado do ciclo de vida das entrevistas, atribuição de entrevistadores, registro de resultados, e análise de performance.

---

## Arquitetura

### Stack Tecnológica
- **Backend:** Node.js + Express.js
- **Banco de Dados:** PostgreSQL 14+
- **Autenticação:** JWT (middleware exigirAutenticacao)
- **Multitenant:** Isolamento por company_id

### Componentes
1. **Tabela interviews** (enhanced): 18 colunas (7 originais + 11 novas RF8)
2. **7 Views de Métricas**: Agregações para dashboard e relatórios
3. **1 Função SQL**: get_interview_metrics() retorna 14 KPIs
4. **CRUD API**: 7 endpoints principais
5. **Dashboard API**: 5 endpoints de métricas
6. **Triggers**: Auto-update de timestamps e auto-fill de completed_at/cancelled_at

---

## Database Schema

### Tabela: `interviews`

**Colunas Originais (7):**
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | PK, identificador único |
| company_id | UUID | FK → companies, multitenant |
| application_id | UUID | FK → applications, candidatura associada |
| scheduled_at | TIMESTAMP | Data/hora agendada |
| mode | TEXT | Modo: online/presencial/phone |
| status | TEXT | Ver seção "Status Lifecycle" |
| created_at | TIMESTAMP | Data de criação |

**Colunas RF8 (11 novas):**
| Coluna | Tipo | Constraint | Descrição |
|--------|------|------------|-----------|
| notes | TEXT | NULL | Observações do entrevistador |
| duration_minutes | INTEGER | NULL | Duração real em minutos |
| completed_at | TIMESTAMP | NULL | Auto-preenchido ao concluir |
| cancelled_at | TIMESTAMP | NULL | Auto-preenchido ao cancelar |
| cancellation_reason | TEXT | NULL | Motivo do cancelamento |
| interviewer_id | UUID | FK → users | Entrevistador responsável |
| result | TEXT | CHECK: approved/rejected/pending/on_hold | Decisão final |
| overall_score | NUMERIC(4,2) | CHECK: 0-10 | Score geral da entrevista |
| metadata | JSONB | DEFAULT '{}' | Dados adicionais (meet link, etc) |
| updated_at | TIMESTAMP | NULL | Última atualização |
| deleted_at | TIMESTAMP | NULL | Soft delete |

**Índices (12 total):**
- idx_interviews_company (company_id WHERE deleted_at IS NULL)
- idx_interviews_application (application_id WHERE deleted_at IS NULL)
- idx_interviews_status (status WHERE deleted_at IS NULL)
- idx_interviews_scheduled_at (scheduled_at WHERE deleted_at IS NULL)
- idx_interviews_created_at (created_at DESC WHERE deleted_at IS NULL)
- idx_interviews_result (result WHERE deleted_at IS NULL AND result IS NOT NULL)
- idx_interviews_interviewer (interviewer_id WHERE deleted_at IS NULL)
- idx_interviews_completed_at (completed_at DESC WHERE deleted_at IS NULL AND completed_at IS NOT NULL)
- idx_interviews_metadata_gin (metadata USING GIN)
- idx_interviews_company_status (company_id, status WHERE deleted_at IS NULL)
- idx_interviews_company_result (company_id, result WHERE deleted_at IS NULL AND result IS NOT NULL)
- idx_interviews_scheduled_date (DATE(scheduled_at) WHERE deleted_at IS NULL AND scheduled_at IS NOT NULL)

**Foreign Keys:**
- company_id → companies(id) ON DELETE CASCADE
- application_id → applications(id) ON DELETE CASCADE
- interviewer_id → users(id) ON DELETE SET NULL

**Triggers:**
- **trigger_update_interviews (BEFORE UPDATE):** Executa `update_interviews_timestamps()`
  - Atualiza `updated_at = now()` em qualquer UPDATE
  - Auto-preenche `completed_at = now()` quando status muda para 'completed'
  - Auto-preenche `cancelled_at = now()` quando status muda para 'cancelled'

---

## Status Lifecycle

```
        CREATE
          ↓
    [scheduled]
          ↓
    (start interview)
          ↓
   [in_progress] ←─────── (resume se pausada)
          ↓
    (complete/cancel/no-show)
          ↓
     ┌────┴────┬──────────┐
     ↓         ↓          ↓
[completed] [cancelled] [no_show]
```

**Valores permitidos:**
- `scheduled`: Agendada (estado inicial)
- `in_progress`: Em andamento
- `completed`: Concluída (trigger auto-preenche completed_at)
- `cancelled`: Cancelada (trigger auto-preenche cancelled_at)
- `no_show`: Candidato não compareceu

**Migração PT → EN:**
A migration 022 converte valores antigos em português:
- PENDENTE → scheduled
- EM_ANDAMENTO → in_progress
- CONCLUIDA/CONCLUÍDA → completed
- CANCELADA → cancelled
- NAO_COMPARECEU/NÃO_COMPARECEU → no_show

---

## Result Values

**Valores permitidos:**
- `approved`: Candidato aprovado
- `rejected`: Candidato reprovado
- `pending`: Decisão pendente (default após completed)
- `on_hold`: Em espera/segunda rodada

**Nota:** `result` é diferente de `status`. Status rastreia o ciclo de vida da entrevista, result rastreia a decisão final sobre o candidato.

---

## API Endpoints

### 1. CRUD Principal

#### 1.1 GET /api/interviews
Lista todas as entrevistas com filtros.

**Query Parameters:**
- `status` (string): scheduled/in_progress/completed/cancelled/no_show
- `result` (string): approved/rejected/pending/on_hold
- `mode` (string): online/presencial/phone
- `job_id` (UUID): Filtrar por vaga
- `candidate_id` (UUID): Filtrar por candidato
- `interviewer_id` (UUID): Filtrar por entrevistador
- `from` (ISO 8601): Data inicial (scheduled_at >=)
- `to` (ISO 8601): Data final (scheduled_at <=)
- `page` (int): Página (default: 1)
- `limit` (int): Itens por página (default: 50, max: 50)

**Resposta:**
```json
[
  {
    "id": "uuid",
    "company_id": "uuid",
    "application_id": "uuid",
    "job_id": "uuid",
    "candidate_id": "uuid",
    "job_title": "Desenvolvedor Sênior",
    "candidate_name": "João Silva",
    "interviewer_id": "uuid",
    "interviewer_name": "Maria Santos",
    "scheduled_at": "2025-11-25T14:00:00Z",
    "mode": "online",
    "status": "completed",
    "result": "approved",
    "overall_score": 8.5,
    "duration_minutes": 45,
    "notes": "Candidato demonstrou excelente conhecimento técnico",
    "completed_at": "2025-11-25T14:45:00Z",
    "metadata": {
      "meet_link": "https://meet.google.com/xxx-yyyy-zzz"
    },
    "created_at": "2025-11-20T10:00:00Z",
    "updated_at": "2025-11-25T14:45:00Z"
  }
]
```

**Exemplo:**
```http
GET /api/interviews?status=completed&result=approved&from=2025-11-01&to=2025-11-30&page=1&limit=20
Authorization: Bearer <token>
```

---

#### 1.2 GET /api/interviews/:id
Busca detalhes de uma entrevista específica.

**Path Parameters:**
- `id` (UUID): ID da entrevista

**Resposta:** Objeto interview completo (mesmo formato do GET /)

**Erros:**
- 404: Entrevista não encontrada

---

#### 1.3 POST /api/interviews
Cria uma nova entrevista (agenda).

**Request Body:**
```json
{
  "job_id": "uuid",              // obrigatório
  "candidate_id": "uuid",        // obrigatório
  "scheduled_at": "ISO 8601",    // obrigatório
  "ends_at": "ISO 8601",         // opcional (default: +1h de scheduled_at)
  "mode": "online",              // opcional (default: "online")
  "interviewer_id": "uuid",      // opcional
  "notes": "Texto livre",        // opcional
  "metadata": {}                 // opcional (JSONB)
}
```

**Resposta:** Objeto interview criado + calendar_event vinculado

**Efeitos colaterais:**
1. Se application não existir, cria automaticamente (status='open')
2. Cria calendar_event vinculado
3. Status inicial: 'scheduled'
4. Gera log de auditoria

**Validações:**
- job_id, candidate_id, scheduled_at são obrigatórios
- scheduled_at deve ser data futura (recomendado no client)
- mode é normalizado para lowercase

---

#### 1.4 PUT /api/interviews/:id
Atualiza uma entrevista existente.

**Path Parameters:**
- `id` (UUID): ID da entrevista

**Request Body (todos opcionais):**
```json
{
  "scheduled_at": "ISO 8601",
  "ends_at": "ISO 8601",
  "mode": "presencial",
  "status": "completed",
  "result": "approved",
  "overall_score": 8.5,
  "notes": "Texto livre",
  "duration_minutes": 45,
  "cancellation_reason": "Motivo",
  "interviewer_id": "uuid",
  "metadata": {}
}
```

**Comportamento:**
- Usa COALESCE: só atualiza campos enviados (não sobrescreve com NULL)
- `updated_at` é automaticamente atualizado (trigger)
- Se `status` muda para 'completed', `completed_at` é auto-preenchido
- Se `status` muda para 'cancelled', `cancelled_at` é auto-preenchido
- Se `scheduled_at` ou `ends_at` mudam, atualiza calendar_event vinculado

**Resposta:** Objeto interview atualizado

**Erros:**
- 404: Entrevista não encontrada

---

#### 1.5 DELETE /api/interviews/:id
Soft delete de uma entrevista (não remove do banco, marca deleted_at).

**Path Parameters:**
- `id` (UUID): ID da entrevista

**Resposta:**
```json
{
  "mensagem": "Entrevista removida com sucesso"
}
```

**Efeitos:**
- Define `deleted_at = now()`
- Entrevista não aparece mais em listagens (WHERE deleted_at IS NULL)
- Preserva histórico para auditoria
- Não remove calendar_event (pode ser ajustado se necessário)

**Erros:**
- 404: Entrevista não encontrada

---

### 2. Dashboard - Métricas RF8

#### 2.1 GET /api/dashboard/interviews/metrics
Retorna métricas consolidadas de histórico de entrevistas.

**Resposta:**
```json
{
  "success": true,
  "data": {
    "total_interviews": 150,
    "scheduled_count": 30,
    "in_progress_count": 5,
    "completed_count": 100,
    "cancelled_count": 12,
    "no_show_count": 3,
    "approval_rate": 65.5,         // % aprovados sobre completados
    "rejection_rate": 20.0,        // % rejeitados sobre completados
    "avg_overall_score": 7.8,
    "avg_duration_minutes": 48,
    "interviews_last_7_days": 15,
    "interviews_last_30_days": 60,
    "completed_last_7_days": 10,
    "completed_last_30_days": 40,
    "by_status": [
      {
        "status": "completed",
        "interview_count": 100,
        "avg_score": 7.8,
        "avg_duration": 48,
        "earliest_scheduled": "2025-01-05T10:00:00Z",
        "latest_scheduled": "2025-11-25T14:00:00Z"
      },
      // ... outros status
    ],
    "by_result": [
      {
        "result": "approved",
        "interview_count": 65,
        "avg_score": 8.5,
        "completed_count": 65
      },
      // ... outros results
    ]
  }
}
```

**Fonte de dados:**
- Função: `get_interview_metrics(company_id)`
- Views: `interview_stats_overview`, `interviews_by_status`, `interviews_by_result`

---

#### 2.2 GET /api/dashboard/interviews/timeline
Timeline de criação/conclusão/cancelamento de entrevistas.

**Query Parameters:**
- `days` (int): Número de dias para trás (default: 30)

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "interview_date": "2025-11-25",
      "interviews_created": 5,
      "scheduled": 3,
      "completed": 4,
      "cancelled": 1,
      "approved": 3,
      "rejected": 1,
      "avg_score": 8.2,
      "avg_duration": 50
    },
    // ... dias anteriores
  ]
}
```

**Fonte:** View `interview_timeline`

**Uso:** Gráficos de linha/área mostrando volume ao longo do tempo

---

#### 2.3 GET /api/dashboard/interviews/by-job
Entrevistas agrupadas por vaga (funil de conversão por vaga).

**Query Parameters:**
- `limit` (int): Número de vagas a retornar (default: 20)

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "job_id": "uuid",
      "job_title": "Desenvolvedor Sênior",
      "total_interviews": 25,
      "completed_interviews": 20,
      "approved_count": 12,
      "rejected_count": 5,
      "avg_score": 7.9,
      "last_interview_date": "2025-11-25T14:00:00Z"
    },
    // ... outras vagas
  ]
}
```

**Fonte:** View `interviews_by_job`

**Uso:** Comparar performance de recrutamento por vaga

---

#### 2.4 GET /api/dashboard/interviews/by-interviewer
Entrevistas agrupadas por entrevistador (workload e performance).

**Query Parameters:**
- `limit` (int): Número de entrevistadores a retornar (default: 20)

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "interviewer_id": "uuid",
      "interviewer_name": "Maria Santos",
      "total_interviews": 35,
      "completed_count": 30,
      "approved_count": 20,
      "avg_score": 8.2,
      "avg_duration": 52
    },
    // ... outros entrevistadores
  ]
}
```

**Fonte:** View `interviews_by_interviewer`

**Uso:** Distribuição de carga de trabalho, comparação de rigor/padrões

---

#### 2.5 GET /api/dashboard/interviews/completion-rate
Taxa de conclusão de entrevistas ao longo do tempo.

**Query Parameters:**
- `days` (int): Número de dias para trás (default: 30)

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "scheduled_date": "2025-11-25",
      "total_scheduled": 10,
      "completed": 8,
      "cancelled": 1,
      "no_show": 1,
      "completion_rate": 80.0,    // % completed
      "no_show_rate": 10.0        // % no_show
    },
    // ... dias anteriores
  ]
}
```

**Fonte:** View `interview_completion_rate`

**Uso:** Identificar problemas de no-show, otimizar agendamento

---

## Views de Métricas

### 1. interview_stats_overview
Estatísticas gerais por empresa.

**Campos:** total_interviews, scheduled_count, in_progress_count, completed_count, cancelled_count, no_show_count, approved_count, rejected_count, pending_count, avg_overall_score, avg_duration_minutes, interviews_last_7_days, interviews_last_30_days, completed_last_7_days, completed_last_30_days

**Uso:** Dashboard principal

---

### 2. interviews_by_status
Agrupamento por status.

**Campos:** company_id, status, interview_count, avg_score, avg_duration, earliest_scheduled, latest_scheduled

**Uso:** Distribuição de entrevistas por etapa

---

### 3. interviews_by_result
Agrupamento por resultado.

**Campos:** company_id, result, interview_count, avg_score, completed_count

**Uso:** Taxa de aprovação/rejeição

---

### 4. interview_timeline
Timeline diária de atividades.

**Campos:** company_id, interview_date, interviews_created, scheduled, completed, cancelled, approved, rejected, avg_score, avg_duration

**Uso:** Gráficos de tendência temporal

---

### 5. interviews_by_job
Agrupamento por vaga.

**Campos:** company_id, job_id, job_title, total_interviews, completed_interviews, approved_count, rejected_count, avg_score, last_interview_date

**Uso:** Performance de recrutamento por vaga

---

### 6. interviews_by_interviewer
Agrupamento por entrevistador.

**Campos:** company_id, interviewer_id, interviewer_name, total_interviews, completed_count, approved_count, avg_score, avg_duration

**Uso:** Workload e performance de entrevistadores

---

### 7. interview_completion_rate
Taxa de conclusão por data.

**Campos:** company_id, scheduled_date, total_scheduled, completed, cancelled, no_show, completion_rate, no_show_rate

**Uso:** Qualidade do processo de agendamento

---

## Segurança

### Autenticação
- **Middleware:** exigirAutenticacao (JWT Bearer token)
- **Header:** `Authorization: Bearer <access_token>`
- Todos os endpoints exigem autenticação

### Multitenant
- **Isolamento:** Todas as queries filtram por `req.usuario.company_id`
- **Validação:** Endpoints verificam que recursos pertencem à company do usuário
- **Views:** Filtram automaticamente por company_id

### Auditoria
- **Middleware:** audit(req, action, resource, resource_id, changes)
- **Ações registradas:** create, update, delete
- **Dados:** user_id, company_id, timestamp, IP, changes

### LGPD/GDPR
- **Soft Delete:** Preserva histórico para compliance
- **Anonimização:** (futura) Função para anonimizar dados de candidatos
- **Logs:** Não gravam dados sensíveis (senhas, tokens)

---

## Performance

### Índices
12 índices otimizam queries comuns:
- Listagem por company + status
- Listagem por company + result
- Ordenação por data (scheduled_at, completed_at)
- Filtro por entrevistador
- Busca em metadata (GIN index)

### Paginação
- **Default:** 50 itens por página
- **Máximo:** 50 (enforced no backend)
- **Offset-based:** LIMIT + OFFSET

### Views Materializadas
- **Atual:** Views normais (recalculam em cada query)
- **Futura:** Considerar materialização para grandes volumes (> 100k entrevistas)

### Caching
- **Recomendado:** Cache Redis para `/dashboard/interviews/metrics` (TTL: 5 min)
- **Invalidação:** Ao criar/atualizar/deletar entrevista

---

## Testes

### Coleção: RF8_INTERVIEWS_API_COLLECTION.http
- **Total:** 70+ requests
- **Cobertura:**
  - CRUD básico (10 requests)
  - Filtros avançados (12 requests)
  - Dashboard metrics (10 requests)
  - Validações/erros (10 requests)
  - Segurança/multitenant (5 requests)
  - Performance/limites (5 requests)
  - Casos E2E (7 flows)

### Como Testar
1. Abrir RF8_INTERVIEWS_API_COLLECTION.http no VS Code (REST Client extension)
2. Ajustar @baseUrl se necessário
3. Executar request 0.1 (Login) para obter token
4. Token é automaticamente propagado via variável {{token}}
5. Executar requests sequencialmente ou individualmente

---

## Integração com Outros RFs

### RF2 - Jobs (Vagas)
- **Relação:** `interviews.application_id → applications.job_id → jobs.id`
- **Join:** View `interviews_by_job` agrega entrevistas por vaga
- **Dashboard:** Métricas de recrutamento por vaga

### RF3 - Interview Questions
- **Relação:** `interviews.id ← interview_questions.interview_id`
- **Uso:** Perguntas geradas para entrevista específica
- **Endpoint existente:** POST /interviews/:id/questions

### RF6 - Live Assessments
- **Relação:** `interviews.id ← live_assessments.interview_id`
- **Uso:** Avaliações em tempo real durante entrevista
- **Score:** overall_score da entrevista pode ser média dos live_assessments

### RF7 - Interview Reports
- **Relação:** `interviews.id ← interview_reports.interview_id`
- **Uso:** Relatório final gerado ao concluir entrevista
- **Endpoint existente:** POST /interviews/:id/report

---

## Casos de Uso Típicos

### 1. Agendar Entrevista
```
Recrutador:
1. Seleciona vaga e candidato no UI
2. POST /interviews com job_id, candidate_id, scheduled_at, interviewer_id
3. Sistema cria application (se não existir) + interview + calendar_event
4. Recrutador vê confirmação no UI
```

### 2. Conduzir Entrevista
```
Entrevistador:
1. Acessa lista de entrevistas do dia (GET /interviews?interviewer_id=<me>&scheduled_at=today)
2. Inicia entrevista (PUT /:id com status=in_progress)
3. Durante entrevista:
   - Faz perguntas (GET /:id/questions)
   - Registra respostas (POST /:id/answers)
   - Sistema gera avaliações (RF6 live_assessments)
4. Conclui entrevista (PUT /:id com status=completed, result, overall_score, duration_minutes, notes)
```

### 3. Analisar Performance de Recrutamento
```
Gestor de RH:
1. Acessa dashboard (GET /dashboard/interviews/metrics)
2. Visualiza KPIs:
   - Total de entrevistas realizadas
   - Taxa de aprovação/rejeição
   - Score médio
   - No-show rate
3. Analisa timeline (GET /dashboard/interviews/timeline?days=90)
4. Compara vagas (GET /dashboard/interviews/by-job)
5. Avalia entrevistadores (GET /dashboard/interviews/by-interviewer)
6. Identifica gargalos e ajusta processo
```

### 4. Cancelar Entrevista
```
Recrutador/Candidato:
1. Identifica necessidade de cancelamento
2. PUT /:id com status=cancelled, cancellation_reason
3. Sistema marca cancelled_at automaticamente (trigger)
4. Opcional: Notificação por email/SMS (integração externa)
```

---

## Troubleshooting

### Problema: Entrevista não aparece na listagem
**Causa:** deleted_at IS NOT NULL (soft delete)  
**Solução:** Verificar se foi deletada acidentalmente, restaurar se necessário (UPDATE interviews SET deleted_at=NULL WHERE id=...)

### Problema: completed_at não é preenchido ao atualizar status
**Causa:** Trigger não está ativo ou UPDATE não mudou status de/para completed  
**Solução:** 
1. Verificar trigger: `SELECT * FROM pg_trigger WHERE tgname = 'trigger_update_interviews'`
2. Re-aplicar migration 022 se necessário

### Problema: Métricas retornam 0 para tudo
**Causa:** Sem dados na tabela interviews ou views não foram criadas  
**Solução:** 
1. Verificar views: `SELECT * FROM pg_views WHERE viewname LIKE 'interview%'`
2. Re-aplicar migration 023 se necessário
3. Popular dados de teste

### Problema: Erro "column u.name does not exist"
**Causa:** Migration 023 usava u.name mas a tabela users tem u.full_name  
**Solução:** Corrigido na migration 023 (usar u.full_name)

### Problema: Erro "constraint interviews_status_check violated"
**Causa:** Status em português (PENDENTE) mas constraint espera inglês (scheduled)  
**Solução:** Corrigido na migration 022 (converte PT→EN antes de alterar constraint)

---

## Roadmap (Futuras Melhorias)

### Curto Prazo
- [ ] Frontend Flutter Web (telas RF8)
- [ ] Notificações de email/SMS ao agendar/cancelar
- [ ] Integração com calendário externo (Google Calendar, Outlook)
- [ ] Export de relatórios (CSV, PDF)

### Médio Prazo
- [ ] Videoconferência integrada (Jitsi, Whereby)
- [ ] Gravação de entrevistas (áudio/vídeo)
- [ ] Transcrição automática (Whisper API)
- [ ] Feedback 360° (múltiplos entrevistadores)

### Longo Prazo
- [ ] Machine Learning para sugerir perguntas baseadas em performance histórica
- [ ] Análise de sentimento em respostas (NLP)
- [ ] Predição de no-show (modelo preditivo)
- [ ] Benchmark de mercado (comparação com outras empresas)

---

## Referências

- **Migrations:** backend/scripts/sql/022_interviews_improvements.sql, 023_interview_metrics_views.sql
- **Routes:** backend/src/api/rotas/interviews.js, dashboard.js
- **Tests:** backend/RF8_INTERVIEWS_API_COLLECTION.http
- **Planning:** AGENTS.md (seção RF8)

---

**Última Atualização:** 22/11/2025  
**Versão:** 1.0.0  
**Autor:** TalentMatchIA Team
