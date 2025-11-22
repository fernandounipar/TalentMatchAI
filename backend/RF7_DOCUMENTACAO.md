# RF7 - Relatórios Detalhados de Entrevistas

## 📋 Visão Geral

O RF7 implementa o sistema de **geração e gerenciamento de relatórios consolidados de entrevistas** do TalentMatchIA. Permite gerar relatórios automáticos via IA ou manuais, com versionamento, múltiplos formatos e métricas de qualidade.

### Principais Funcionalidades

- ✅ **Geração automática via IA** (integração com iaService.gerarRelatorioEntrevista)
- ✅ **Criação manual** de relatórios customizados
- ✅ **Versionamento** (regenerar relatórios cria novas versões)
- ✅ **Múltiplos tipos** (full, summary, technical, behavioral)
- ✅ **Múltiplos formatos** (json, pdf, html, markdown)
- ✅ **CRUD completo** com soft delete
- ✅ **Métricas e KPIs** (taxa de aprovação, scores médios, timeline)
- ✅ **Busca e filtros avançados**

---

## 🗄️ Banco de Dados

### Migration 020: Tabela `interview_reports`

```sql
CREATE TABLE interview_reports (
  id UUID PRIMARY KEY,
  company_id UUID NOT NULL,
  interview_id UUID NOT NULL,
  
  -- Identificação
  title TEXT NOT NULL DEFAULT 'Relatório de Entrevista',
  report_type TEXT CHECK (type IN ('full', 'summary', 'technical', 'behavioral')),
  
  -- Conteúdo estruturado
  content JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- Campos extraídos
  summary_text TEXT,
  candidate_name TEXT,
  job_title TEXT,
  
  -- Avaliação
  overall_score NUMERIC(4,2) CHECK (score >= 0 AND score <= 10),
  recommendation TEXT CHECK (rec IN ('APPROVE', 'MAYBE', 'REJECT', 'PENDING')),
  
  -- Análise
  strengths JSONB DEFAULT '[]'::jsonb,
  weaknesses JSONB DEFAULT '[]'::jsonb,
  risks JSONB DEFAULT '[]'::jsonb,
  
  -- Formato
  format TEXT CHECK (format IN ('json', 'pdf', 'html', 'markdown')),
  file_path TEXT,
  file_size INTEGER,
  
  -- Metadados
  generated_by UUID,
  generated_at TIMESTAMP,
  is_final BOOLEAN DEFAULT false,
  version INTEGER DEFAULT 1,
  
  -- Auditoria
  created_by UUID,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  deleted_at TIMESTAMP
);
```

**Índices:** 10 índices (company, interview, created_at, recommendation, type, generated_at, is_final, content_gin, score, company_recommendation)

**Triggers:** `trigger_update_interview_reports` - Auto-atualiza `updated_at`

---

### Migration 021: Views de Métricas

1. **`report_stats_overview`** - Estatísticas gerais (total, finais, rascunhos, aprovações, scores)
2. **`reports_by_recommendation`** - Distribuição por recomendação (APPROVE/REJECT/MAYBE)
3. **`reports_by_type`** - Distribuição por tipo (full/summary/technical/behavioral)
4. **`report_generation_timeline`** - Timeline diária de geração
5. **`reports_by_interview`** - Relatórios agrupados por entrevista com versionamento

**Função:** `get_report_metrics(company_id)` retorna 10 métricas consolidadas

---

## 🚀 API Endpoints

### Base URL: `/api/reports`

---

### 1. **Criar Relatório**

```http
POST /api/reports
```

**Request Body (Automático via IA):**
```json
{
  "interview_id": "uuid",
  "title": "Relatório Completo de Entrevista",
  "report_type": "full",              // full | summary | technical | behavioral
  "format": "json",                    // json | pdf | html | markdown
  "generate_via_ai": true,             // Chama iaService.gerarRelatorioEntrevista
  "is_final": false
}
```

**Request Body (Manual - Sem IA):**
```json
{
  "interview_id": "uuid",
  "title": "Relatório Manual",
  "report_type": "summary",
  "format": "json",
  "generate_via_ai": false,
  "summary_text": "Candidato demonstrou...",
  "overall_score": 8.5,
  "recommendation": "APPROVE",
  "strengths": ["Node.js", "Comunicação"],
  "weaknesses": ["Testes"],
  "risks": [],
  "is_final": false
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "Relatório criado com sucesso",
  "data": {
    "id": "uuid",
    "interview_id": "uuid",
    "version": 1,
    "title": "Relatório Completo de Entrevista",
    "report_type": "full",
    "format": "json",
    "generated_via_ai": true,
    "is_final": false,
    "created_at": "2025-11-22T10:00:00Z"
  }
}
```

---

### 2. **Listar Relatórios**

```http
GET /api/reports
```

**Query Parameters:**
- `interview_id` - Filtrar por entrevista
- `report_type` - full | summary | technical | behavioral
- `recommendation` - APPROVE | REJECT | MAYBE | PENDING
- `is_final` - true | false
- `format` - json | pdf | html | markdown
- `date_from` - Data inicial (YYYY-MM-DD)
- `date_to` - Data final (YYYY-MM-DD)
- `search` - Busca textual (título, resumo, candidato, vaga)
- `sort_by` - created_at | generated_at | overall_score | version | title
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
      "interview_id": "uuid",
      "title": "Relatório Completo",
      "report_type": "full",
      "summary_text": "Candidato demonstrou...",
      "candidate_name": "João Silva",
      "job_title": "Desenvolvedor Backend",
      "overall_score": 8.5,
      "recommendation": "APPROVE",
      "format": "json",
      "is_final": true,
      "version": 2,
      "generated_at": "2025-11-22T10:00:00Z",
      "created_at": "2025-11-22T09:00:00Z"
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
GET /api/reports/:id
```

**Response 200:** Retorna relatório completo incluindo `content` (JSONB), nomes dos usuários que geraram/criaram, etc.

---

### 4. **Atualizar Relatório**

```http
PUT /api/reports/:id
```

**Request Body (Ajuste Manual):**
```json
{
  "title": "Relatório Atualizado",
  "summary_text": "Texto atualizado",
  "overall_score": 9.0,
  "recommendation": "APPROVE",
  "strengths": ["Excelente comunicação", "Liderança"],
  "weaknesses": ["Pouca experiência AWS"],
  "risks": [],
  "is_final": true
}
```

**Request Body (Regenerar - Nova Versão):**
```json
{
  "regenerate": true,
  "title": "Relatório Regenerado v2"
}
```

**Comportamento:**
- Update normal: Modifica campos do relatório existente
- `regenerate: true`: Cria nova versão (chama POST internamente, incrementa version)

---

### 5. **Arquivar Relatório**

```http
DELETE /api/reports/:id
```

**Permissões:** ADMIN, SUPER_ADMIN

**Comportamento:** Soft delete (seta `deleted_at`)

---

### 6. **Relatórios por Entrevista**

```http
GET /api/reports/interview/:interview_id
```

**Response 200:**
```json
{
  "success": true,
  "data": [ /* array de relatórios ordenados por versão */ ],
  "stats": {
    "total_versions": 3,
    "latest_version": 3,
    "final_reports": 1,
    "draft_reports": 2
  }
}
```

---

### 7. **Métricas Consolidadas**

```http
GET /api/dashboard/reports/metrics
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "metrics": {
      "total_reports": 156,
      "final_reports": 120,
      "draft_reports": 36,
      "approval_rate": 65.38,         // % de APPROVE
      "rejection_rate": 15.38,        // % de REJECT
      "avg_overall_score": 7.85,
      "reports_last_7_days": 23,
      "reports_last_30_days": 89,
      "pdf_reports": 45,
      "json_reports": 111
    },
    "by_type": [
      { "report_type": "full", "report_count": 85, "avg_score": 8.10, "pdf_count": 30, "final_count": 70 },
      { "report_type": "technical", "report_count": 45, "avg_score": 7.80, "pdf_count": 10, "final_count": 35 }
    ],
    "by_recommendation": [
      { "recommendation": "APPROVE", "report_count": 102, "avg_score": 8.50, "final_count": 90 },
      { "recommendation": "MAYBE", "report_count": 30, "avg_score": 6.80, "final_count": 20 },
      { "recommendation": "REJECT", "report_count": 24, "avg_score": 5.20, "final_count": 10 }
    ]
  }
}
```

---

### 8. **Timeline de Geração**

```http
GET /api/dashboard/reports/timeline?days=30
```

**Response 200:** Array com estatísticas diárias dos últimos N dias.

---

### 9. **Relatórios por Entrevista (Dashboard)**

```http
GET /api/dashboard/reports/by-interview?limit=50
```

**Response 200:** Últimas 50 entrevistas com stats de relatórios (total_versions, latest_version, final_score, final_recommendation).

---

## 🔐 Segurança e Permissões

| Endpoint | SUPER_ADMIN | ADMIN | RECRUITER | CANDIDATE |
|----------|-------------|-------|-----------|-----------|
| POST /reports | ✅ | ✅ | ✅ | ❌ |
| GET /reports | ✅ | ✅ | ✅ | ❌ |
| GET /reports/:id | ✅ | ✅ | ✅ | ❌ |
| PUT /reports/:id | ✅ | ✅ | ✅ | ❌ |
| DELETE /reports/:id | ✅ | ✅ | ❌ | ❌ |
| GET /dashboard/reports/* | ✅ | ✅ | ✅ | ❌ |

---

## 🧪 Testes

**Arquivo:** `RF7_REPORTS_API_COLLECTION.http`

**Total:** 42 requests cobrindo:
1. Autenticação (1 request)
2. CRUD Básico (5 requests: auto IA, manual, tipos full/technical/behavioral, validação)
3. Listagem e Filtros (12 requests: paginação, por entrevista/tipo/recomendação/final/formato/período, busca, ordenação, filtros combinados, relatórios por entrevista)
4. Detalhamento (2 requests: detalhes, inexistente)
5. Atualização (5 requests: título, score/recomendação, pontos fortes/fracos, marcar final, regenerar)
6. Exclusão (3 requests: arquivar, já deletado, inexistente)
7. Métricas (5 requests: consolidadas, timeline 7/30 dias, por entrevista)
8. Validações e Segurança (4 requests: sem auth, token inválido, cross-company, sem permissão)
9. Performance (4 requests: limite máximo, acima do máximo, múltiplos filtros, página vazia)
10. Fluxo Completo E2E (7 requests: login → criar → listar → ver → ajustar → métricas → timeline)

---

## 📊 Métricas e KPIs

### 1. Volume de Relatórios
- Total de relatórios gerados
- Relatórios finais vs rascunhos
- Relatórios por período (7/30 dias)
- Distribuição por tipo e formato

### 2. Qualidade e Decisões
- Taxa de aprovação (% APPROVE)
- Taxa de rejeição (% REJECT)
- Taxa de dúvida (% MAYBE)
- Score médio geral
- Scores médios por tipo de relatório

### 3. Versionamento
- Média de versões por entrevista
- Relatórios regenerados
- Tempo entre versões

### 4. Adoção
- % de entrevistas com relatório
- Formatos mais usados (JSON vs PDF)
- Tipos mais gerados (full vs summary)

---

## 🎯 Fluxo de Uso Típico

1. **Após Entrevista:**
   - Sistema ou recrutador chama `POST /api/reports` com `generate_via_ai: true`
   - IA analisa respostas + avaliações (live_assessments)
   - Gera relatório estruturado com summary, strengths, risks, recommendation
   - Relatório fica como rascunho (`is_final: false`)

2. **Revisão pelo Recrutador:**
   - Recrutador acessa `GET /api/reports/interview/:id`
   - Vê todas as versões do relatório
   - Ajusta manualmente via `PUT /api/reports/:id` (score, recomendação, pontos fortes/fracos)
   - Marca como final quando satisfeito (`is_final: true`)

3. **Regeneração (se necessário):**
   - Se avaliações forem atualizadas, recrutador regenera relatório
   - `PUT /api/reports/:id` com `regenerate: true`
   - Sistema cria nova versão (v2, v3...) preservando histórico

4. **Análise de Métricas:**
   - Dashboard mostra taxa de aprovação/rejeição
   - Identifica padrões (tipos de vagas com mais aprovações)
   - Timeline mostra volume de relatórios ao longo do tempo

---

## 🔄 Integração com IA (iaService)

O RF7 utiliza a função existente `gerarRelatorioEntrevista()` do `iaService.js`:

```javascript
const aiReport = await gerarRelatorioEntrevista({
  candidato: 'João Silva',
  vaga: 'Desenvolvedor Backend',
  respostas: [
    { pergunta: '...', resposta: '...', tipo: 'technical', score: 8.5 }
  ],
  feedbacks: [
    { topic: 'technical', score: 8.5, verdict: 'FORTE', comment: '...' }
  ],
  companyId: 'uuid'
});
```

**Retorno esperado:**
```json
{
  "summary_text": "Resumo da entrevista...",
  "strengths": ["Ponto forte 1", "Ponto forte 2"],
  "risks": ["Risco 1", "Risco 2"],
  "recommendation": "APROVAR" // Convertido para "APPROVE"
}
```

---

## ✅ Status de Implementação

**Data:** 22/11/2025

**Migrations:**
- ✅ 020_interview_reports.sql - Tabela (26 colunas, 10 índices, 1 trigger, 1 função)
- ✅ 021_report_metrics_views.sql - 5 views + função get_report_metrics()

**API Endpoints:**
- ✅ POST /api/reports - Criar (automático IA ou manual)
- ✅ GET /api/reports - Listar com 11 filtros
- ✅ GET /api/reports/:id - Detalhes
- ✅ PUT /api/reports/:id - Atualizar ou regenerar
- ✅ DELETE /api/reports/:id - Arquivar
- ✅ GET /api/reports/interview/:id - Relatórios por entrevista
- ✅ GET /api/dashboard/reports/metrics - Métricas consolidadas
- ✅ GET /api/dashboard/reports/timeline - Timeline de geração
- ✅ GET /api/dashboard/reports/by-interview - Estatísticas por entrevista

**Integração IA:**
- ✅ iaService.gerarRelatorioEntrevista() - Geração automática com análise de respostas + feedbacks

**Testes:**
- ✅ RF7_REPORTS_API_COLLECTION.http - 42 requests

**Documentação:**
- ✅ RF7_DOCUMENTACAO.md (este arquivo)

**Próximos Passos:**
- ⏳ Testes reais contra servidor
- ⏳ Geração de PDF (integrar lib como puppeteer ou pdfmake)
- ⏳ Frontend Flutter (telas de relatórios)
- ⏳ Export para CSV/Excel

---

**Responsável:** Time de Desenvolvimento TalentMatchIA
