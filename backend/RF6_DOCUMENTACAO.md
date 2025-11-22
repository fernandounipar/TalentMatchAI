# RF6 - Avaliação em Tempo Real das Respostas (Live Assessments)

## 📋 Visão Geral

O RF6 implementa o sistema de **avaliação automática e manual de respostas de entrevista** do TalentMatchIA. Permite que o sistema avalie automaticamente via IA as respostas dos candidatos e que recrutadores ajustem os scores manualmente, garantindo um processo de avaliação híbrido (IA + humano) mais preciso.

### Principais Funcionalidades

- ✅ **Avaliação automática via IA** (OpenRouter/Grok) de respostas
- ✅ **Ajuste manual** de scores e feedback pelo entrevistador
- ✅ **Concordância IA vs Humano** (métricas de discrepância)
- ✅ **CRUD completo** de avaliações
- ✅ **Métricas e KPIs** (taxa de ajuste, scores médios, concordância)
- ✅ **Categorização** por tipo (behavioral, technical, situational, cultural, general)
- ✅ **Tracking de tempo de resposta** para análise de performance
- ✅ **Soft delete** para preservar histórico de auditoria

---

## 🗄️ Banco de Dados

### Migration 018: Tabela `live_assessments`

```sql
CREATE TABLE live_assessments (
  id UUID PRIMARY KEY,
  company_id UUID NOT NULL,
  interview_id UUID NOT NULL,
  question_id UUID,                     -- Link para pergunta (opcional)
  answer_id UUID,                       -- Link para resposta (opcional)
  
  -- Scores
  score_auto NUMERIC(4,2),              -- Score IA (0-10)
  score_manual NUMERIC(4,2),            -- Score ajustado (0-10)
  score_final NUMERIC(4,2),             -- Calculado automaticamente
  
  -- Feedback
  feedback_auto JSONB,                  -- { nota, feedback, pontosFortesResposta, pontosMelhoria }
  feedback_manual TEXT,                 -- Comentário do avaliador
  
  -- Metadados
  assessment_type TEXT CHECK (type IN ('behavioral', 'technical', 'situational', 'cultural', 'general')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'auto_evaluated', 'manually_adjusted', 'validated', 'invalidated')),
  response_time_seconds INTEGER,        -- Tempo de resposta do candidato
  
  -- Auditoria
  evaluated_by UUID,
  evaluated_at TIMESTAMP,
  created_by UUID,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  deleted_at TIMESTAMP
);
```

**Índices:** 8 índices (company, interview, question, status, type, created_at, scores, date)

**Triggers:** `trigger_update_live_assessments` - Auto-atualiza `updated_at`, `score_final` e `status`

---

### Migration 019: Views de Métricas

1. **`assessment_stats_overview`** - Estatísticas gerais (total, médias, recentes)
2. **`assessment_by_interview`** - Avaliações por entrevista com scores min/max/avg
3. **`assessment_type_distribution`** - Distribuição por tipo com taxa de ajuste manual
4. **`assessment_concordance_stats`** - Concordância IA vs humano (diferenças, taxas)
5. **`assessment_performance_timeline`** - Timeline diária de avaliações

**Função:** `get_assessment_metrics(company_id)` retorna 8 métricas consolidadas

---

## 🚀 API Endpoints

### Base URL: `/api/live-assessments`

---

### 1. **Criar Avaliação**

```http
POST /api/live-assessments
```

**Request Body (Avaliação Automática):**
```json
{
  "interview_id": "uuid",
  "question_id": "uuid",              // Ou question_text
  "answer_id": "uuid",                // Ou answer_text
  "assessment_type": "technical",
  "response_time_seconds": 180,
  "auto_evaluate": true               // Chama IA para avaliar
}
```

**Request Body (Manual - Sem IA):**
```json
{
  "interview_id": "uuid",
  "question_text": "Como você lida com feedback negativo?",
  "answer_text": "Eu sempre procuro ouvir atentamente...",
  "assessment_type": "behavioral",
  "auto_evaluate": false
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "Avaliação criada com sucesso",
  "data": {
    "id": "uuid",
    "score_auto": 8.5,
    "feedback_auto": {
      "nota": 8.5,
      "feedback": "Resposta técnica bem fundamentada...",
      "pontosFortesResposta": ["conhecimento de arquitetura", "clareza"],
      "pontosMelhoria": ["detalhar estratégias de fallback"]
    },
    "status": "auto_evaluated"
  }
}
```

---

### 2. **Listar Avaliações**

```http
GET /api/live-assessments
```

**Query Parameters:**
- `interview_id` - Filtrar por entrevista
- `status` - pending | auto_evaluated | manually_adjusted | validated | invalidated
- `assessment_type` - behavioral | technical | situational | cultural | general
- `sort_by` - created_at | score_final | status
- `order` - ASC | DESC
- `page` - Página (default: 1)
- `limit` - Itens por página (default: 20, max: 100)

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "score_final": 8.5,
      "status": "auto_evaluated",
      "question_text": "Explique event-driven architecture",
      "answer_text": "Event-driven é...",
      "feedback_auto": {...},
      "created_at": "2025-11-22T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

---

### 3. **Obter Detalhes**

```http
GET /api/live-assessments/:id
```

**Response 200:** Retorna avaliação completa com pergunta, resposta, entrevista e nomes dos usuários.

---

### 4. **Atualizar Avaliação (Ajuste Manual)**

```http
PUT /api/live-assessments/:id
```

**Request Body:**
```json
{
  "score_manual": 9.0,
  "feedback_manual": "Excelente resposta técnica. Demonstrou conhecimento profundo.",
  "status": "validated"
}
```

**Comportamento:**
- `score_manual` altera `status` para `manually_adjusted`
- `evaluated_by` e `evaluated_at` são preenchidos automaticamente
- `score_final` é recalculado (prioriza `score_manual` sobre `score_auto`)

---

### 5. **Invalidar Avaliação**

```http
DELETE /api/live-assessments/:id
```

**Permissões:** ADMIN, SUPER_ADMIN

**Comportamento:** Soft delete + `status = 'invalidated'`

---

### 6. **Avaliações por Entrevista**

```http
GET /api/live-assessments/interview/:interview_id
```

**Response 200:**
```json
{
  "success": true,
  "data": [ /* array de avaliações */ ],
  "stats": {
    "total_assessments": 10,
    "avg_score": "8.25",
    "auto_evaluated": 7,
    "manually_adjusted": 3
  }
}
```

---

### 7. **Métricas Consolidadas**

```http
GET /api/dashboard/assessments/metrics
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "metrics": {
      "total_assessments": { "value": 156, "label": "Total de avaliações realizadas" },
      "auto_evaluated_count": { "value": 120, "label": "Avaliações automáticas (IA)" },
      "manually_adjusted_count": { "value": 36, "label": "Avaliações ajustadas manualmente" },
      "manual_adjustment_rate": { "value": 23.08, "label": "% ajustadas manualmente" },
      "avg_score_final": { "value": 7.85, "label": "Score médio final" },
      "concordance_rate": { "value": 78.50, "label": "% concordância IA vs humano (diff <= 1)" },
      "avg_response_time": { "value": 142.30, "label": "Tempo médio de resposta (segundos)" },
      "assessments_last_7_days": { "value": 23, "label": "Avaliações nos últimos 7 dias" }
    },
    "by_type": [
      { "assessment_type": "technical", "total_count": 65, "avg_score": 8.10, "manual_adjustment_rate": 20.00 },
      { "assessment_type": "behavioral", "total_count": 45, "avg_score": 7.80, "manual_adjustment_rate": 25.00 }
    ],
    "concordance": {
      "dual_scored_count": 36,
      "avg_score_difference": 0.85,
      "concordance_rate": 78.50,
      "discordance_rate": 12.50
    }
  }
}
```

---

### 8. **Timeline de Avaliações**

```http
GET /api/dashboard/assessments/timeline?days=30
```

**Response 200:** Retorna array com estatísticas diárias dos últimos N dias.

---

### 9. **Avaliações por Entrevista (Dashboard)**

```http
GET /api/dashboard/assessments/by-interview
```

**Response 200:** Retorna últimas 50 entrevistas com estatísticas de avaliação.

---

## 🔐 Segurança e Permissões

| Endpoint | SUPER_ADMIN | ADMIN | RECRUITER | CANDIDATE |
|----------|-------------|-------|-----------|-----------|
| POST /live-assessments | ✅ | ✅ | ✅ | ❌ |
| GET /live-assessments | ✅ | ✅ | ✅ | ❌ |
| GET /live-assessments/:id | ✅ | ✅ | ✅ | ❌ |
| PUT /live-assessments/:id | ✅ | ✅ | ✅ | ❌ |
| DELETE /live-assessments/:id | ✅ | ✅ | ❌ | ❌ |
| GET /dashboard/assessments/* | ✅ | ✅ | ✅ | ❌ |

---

## 🧪 Testes

**Arquivo:** `RF6_ASSESSMENTS_API_COLLECTION.http`

**Total:** 45+ requests cobrindo:
1. Autenticação (1 request)
2. CRUD Básico (4 requests)
3. Listagem e Filtros (8 requests)
4. Detalhamento (1 request)
5. Update (4 requests)
6. Delete (2 requests)
7. Métricas (4 requests)
8. Validações e Segurança (4 requests)
9. Performance (4 requests)
10. Fluxo Completo E2E (5 requests)

---

## 📊 Métricas e KPIs

### 1. Volume de Avaliações
- Total de avaliações criadas
- Avaliações por período (7/30 dias)
- Distribuição por tipo (behavioral, technical, etc.)

### 2. Qualidade das Avaliações
- Score médio final
- Score médio IA vs manual
- Distribuição de scores (min/max/stddev)

### 3. Concordância IA vs Humano
- Taxa de ajuste manual (%)
- Diferença média entre score_auto e score_manual
- Taxa de concordância (diferença <= 1 ponto)
- Taxa de discordância (diferença > 3 pontos)

### 4. Performance
- Tempo médio de resposta dos candidatos
- Tempo de processamento da IA
- Avaliações por entrevista

---

## 🎯 Fluxo de Uso Típico

1. **Durante a Entrevista:**
   - Candidato responde pergunta
   - Sistema registra resposta (`interview_answers`)
   - Sistema chama `POST /live-assessments` com `auto_evaluate: true`
   - IA avalia e retorna score + feedback
   - Recrutador vê avaliação em tempo real

2. **Após a Entrevista:**
   - Recrutador revisa avaliações via `GET /live-assessments/interview/:id`
   - Ajusta scores/feedback via `PUT /live-assessments/:id`
   - Valida avaliações finais (status → `validated`)

3. **Análise de Métricas:**
   - Dashboard mostra concordância IA vs humano
   - Identifica padrões de discordância
   - Ajusta prompts da IA baseado em feedback

---

## ✅ Status de Implementação

**Data:** 22/11/2025

**Migrations:**
- ✅ 018_live_assessments.sql - Tabela (19 colunas, 8 índices, 1 trigger, 1 função)
- ✅ 019_assessment_metrics_views.sql - 5 views + função get_assessment_metrics()

**API Endpoints:**
- ✅ POST /api/live-assessments - Criar (automático via IA ou manual)
- ✅ GET /api/live-assessments - Listar com 7 filtros
- ✅ GET /api/live-assessments/:id - Detalhes
- ✅ PUT /api/live-assessments/:id - Ajuste manual
- ✅ DELETE /api/live-assessments/:id - Invalidar
- ✅ GET /api/live-assessments/interview/:id - Avaliações por entrevista
- ✅ GET /api/dashboard/assessments/metrics - Métricas consolidadas
- ✅ GET /api/dashboard/assessments/timeline - Timeline de avaliações
- ✅ GET /api/dashboard/assessments/by-interview - Estatísticas por entrevista

**Integração IA:**
- ✅ openRouterService.avaliarResposta() - Avaliação automática via Grok

**Testes:**
- ✅ RF6_ASSESSMENTS_API_COLLECTION.http - 45+ requests

**Documentação:**
- ✅ RF6_DOCUMENTACAO.md (este arquivo)

**Próximos Passos:**
- ⏳ Testes reais contra servidor
- ⏳ Seed data para demonstração
- ⏳ Frontend Flutter (telas de entrevista com avaliações)

---

**Responsável:** Time de Desenvolvimento TalentMatchIA
