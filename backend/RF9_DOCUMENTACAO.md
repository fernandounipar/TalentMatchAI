# RF9 - Dashboard de Acompanhamento

## 📋 Índice
- [Visão Geral](#visão-geral)
- [Estrutura de Banco de Dados](#estrutura-de-banco-de-dados)
- [API Endpoints](#api-endpoints)
- [Fluxos de Uso](#fluxos-de-uso)
- [Exemplos de Integração](#exemplos-de-integração)
- [Segurança e Permissões](#segurança-e-permissões)
- [Performance e Otimizações](#performance-e-otimizações)
- [Troubleshooting](#troubleshooting)

---

## Visão Geral

O **RF9 - Dashboard de Acompanhamento** é o sistema de visualização consolidada de métricas do TalentMatchIA. Ele agrega dados de todos os módulos (vagas, currículos, entrevistas, relatórios, usuários) em um único ponto de acesso, com recursos de personalização e salvamento de configurações.

### Funcionalidades Principais

1. **Overview Consolidado**: 26+ métricas em uma única chamada de API
2. **Activity Timeline**: Rastreamento diário de atividades ao longo do tempo
3. **Conversion Funnel**: Análise de taxas de conversão (vagas → currículos → entrevistas → aprovações)
4. **Dashboard Presets**: Salvar e compartilhar configurações customizadas de dashboard
5. **Filtros Flexíveis**: JSONB permite qualquer estrutura de filtros sem mudanças de schema

### Status de Implementação

- ✅ **Migrations**: 026-027 (tabela + views + função)
- ✅ **API Endpoints**: 8 endpoints (3 overview + 5 CRUD presets)
- ✅ **Testes**: RF9_DASHBOARD_API_COLLECTION.http (57 requests)
- ✅ **Documentação**: RF9_DOCUMENTACAO.md (este arquivo)
- ✅ **Multitenant**: Isolamento completo por company_id
- ✅ **Performance**: 8 índices otimizados + 5 views agregadas

---

## Estrutura de Banco de Dados

### Migration 026: Dashboard Presets

#### Tabela `dashboard_presets`

Armazena configurações customizadas de dashboard (filtros, layout, preferências).

**Colunas (16):**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id` | UUID | Primary key |
| `user_id` | UUID | FK → users (dono do preset) |
| `company_id` | UUID | FK → companies (isolamento multitenant) |
| `name` | VARCHAR(100) | Nome do preset |
| `description` | TEXT | Descrição opcional |
| `filters` | JSONB | Filtros aplicados (período, status, etc) |
| `layout` | JSONB | Layout de widgets e ordenação |
| `preferences` | JSONB | Preferências visuais (tema, gráficos) |
| `is_default` | BOOLEAN | Se TRUE, carrega automaticamente |
| `is_shared` | BOOLEAN | Se TRUE, outros usuários podem ver |
| `shared_with_roles` | TEXT[] | Roles com acesso (ex: ['ADMIN', 'RECRUITER']) |
| `usage_count` | INTEGER | Contador de uso (incrementa ao acessar) |
| `last_used_at` | TIMESTAMP | Última vez que foi usado |
| `created_at` | TIMESTAMP | Data de criação |
| `updated_at` | TIMESTAMP | Última atualização (auto-updated por trigger) |
| `deleted_at` | TIMESTAMP | Soft delete |

**Foreign Keys:**
- `fk_dashboard_presets_user`: user_id → users(id) ON DELETE CASCADE
- `fk_dashboard_presets_company`: company_id → companies(id) ON DELETE CASCADE

**Constraints:**
- `dashboard_presets_name_not_empty`: CHECK (LENGTH(TRIM(name)) > 0)
- `dashboard_presets_usage_count_positive`: CHECK (usage_count >= 0)

**Índices (8):**

1. `idx_dashboard_presets_user_company` (user_id, company_id) - Query principal
2. `idx_dashboard_presets_company` (company_id) - Admins listando todos
3. `idx_dashboard_presets_default` (user_id, is_default) - Carregar default
4. `idx_dashboard_presets_shared` (company_id, is_shared) - Presets compartilhados
5. `idx_dashboard_presets_search` (GIN to_tsvector) - Busca textual full-text
6. `idx_dashboard_presets_filters_gin` (GIN filters) - Queries em JSONB
7. `idx_dashboard_presets_usage` (company_id, usage_count DESC, last_used_at DESC) - Ranking
8. `idx_dashboard_presets_created_at` (created_at DESC) - Recentes

**Trigger:**
- `trigger_update_dashboard_presets`: Auto-atualiza updated_at = NOW() em qualquer UPDATE

**View:**
- `dashboard_presets_overview`: LEFT JOIN com users e companies para listagem com nomes

---

### Migration 027: Dashboard Metrics Views

#### View 1: `dashboard_global_overview`

13 métricas consolidadas por company.

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `company_id` | UUID | Company ID |
| `total_jobs` | BIGINT | Total de vagas |
| `active_jobs` | BIGINT | Vagas abertas (status='open') |
| `total_resumes` | BIGINT | Total de currículos |
| `total_candidates` | BIGINT | Total de candidatos |
| `total_interviews` | BIGINT | Total de entrevistas |
| `completed_interviews` | BIGINT | Entrevistas concluídas |
| `total_reports` | BIGINT | Total de relatórios |
| `total_users` | BIGINT | Total de usuários |
| `active_users` | BIGINT | Usuários ativos |
| `jobs_last_7_days` | BIGINT | Vagas criadas últimos 7 dias |
| `resumes_last_7_days` | BIGINT | Currículos últimos 7 dias |
| `interviews_last_7_days` | BIGINT | Entrevistas últimos 7 dias |
| `last_activity_at` | TIMESTAMP | Última atividade registrada |

**Estratégia:** UNION ALL de todos os recursos, GROUP BY company_id

---

#### View 2: `dashboard_activity_timeline`

Timeline diária de atividades (7 métricas por dia).

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `company_id` | UUID | Company ID |
| `activity_date` | DATE | Data da atividade |
| `jobs_created` | BIGINT | Vagas criadas no dia |
| `resumes_uploaded` | BIGINT | Currículos enviados no dia |
| `interviews_scheduled` | BIGINT | Entrevistas agendadas no dia |
| `reports_generated` | BIGINT | Relatórios gerados no dia |
| `users_registered` | BIGINT | Usuários registrados no dia |
| `total_activities` | BIGINT | Soma de todas as atividades |

**Estratégia:** UNION ALL de todos os recursos, GROUP BY company_id + DATE(created_at)

**Uso:**
```sql
SELECT * FROM dashboard_activity_timeline
WHERE company_id = 'xxx' AND activity_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY activity_date DESC;
```

---

#### View 3: `dashboard_preset_usage_stats`

Estatísticas de uso de presets (11 métricas).

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `company_id` | UUID | Company ID |
| `total_presets` | BIGINT | Total de presets |
| `default_presets` | BIGINT | Presets marcados como default |
| `shared_presets` | BIGINT | Presets compartilhados |
| `users_with_presets` | BIGINT | Usuários com pelo menos 1 preset |
| `total_usage` | NUMERIC | Soma de usage_count de todos |
| `avg_usage_per_preset` | NUMERIC | Média de uso por preset |
| `max_usage` | INTEGER | Maior usage_count |
| `used_last_7_days` | BIGINT | Presets usados últimos 7 dias |
| `used_last_30_days` | BIGINT | Presets usados últimos 30 dias |
| `most_recent_usage` | TIMESTAMP | Último uso registrado |
| `most_recent_creation` | TIMESTAMP | Último preset criado |

---

#### View 4: `dashboard_top_presets`

Ranking de presets por uso (com ROW_NUMBER particionado).

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `id` | UUID | Preset ID |
| `company_id` | UUID | Company ID |
| `user_id` | UUID | Dono do preset |
| `name` | VARCHAR(100) | Nome do preset |
| `usage_count` | INTEGER | Contador de uso |
| `last_used_at` | TIMESTAMP | Último uso |
| `is_shared` | BOOLEAN | Se está compartilhado |
| `shared_with_roles` | TEXT[] | Roles com acesso |
| `usage_rank` | BIGINT | Ranking dentro da company |

**Uso:**
```sql
-- Top 5 presets mais usados da company
SELECT * FROM dashboard_top_presets
WHERE company_id = 'xxx' AND usage_rank <= 5
ORDER BY usage_rank;
```

---

#### View 5: `dashboard_conversion_funnel`

Funil de conversão por vaga (6 métricas + 2 taxas calculadas).

**Colunas:**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `company_id` | UUID | Company ID |
| `job_id` | UUID | Vaga ID |
| `job_title` | VARCHAR(200) | Título da vaga |
| `job_status` | VARCHAR(50) | Status da vaga |
| `job_created_at` | TIMESTAMP | Data de criação da vaga |
| `total_resumes` | BIGINT | Currículos para esta vaga |
| `total_interviews` | BIGINT | Entrevistas agendadas |
| `completed_interviews` | BIGINT | Entrevistas concluídas |
| `approved_candidates` | BIGINT | Candidatos aprovados (recommendation='APPROVE') |
| `resume_to_interview_rate` | NUMERIC | % currículos → entrevistas |
| `interview_to_approval_rate` | NUMERIC | % entrevistas → aprovações |

**Estratégia:**
- LEFT JOIN: jobs → resumes (via job_id) → applications → interviews (via application_id) → interview_reports
- Taxas calculadas: `(COUNT(DISTINCT interviews) / COUNT(DISTINCT resumes)) * 100`

**Uso:**
```sql
-- Vagas com melhor taxa de aprovação
SELECT job_title, total_resumes, total_interviews, approved_candidates,
       resume_to_interview_rate, interview_to_approval_rate
FROM dashboard_conversion_funnel
WHERE company_id = 'xxx' AND job_status = 'open'
ORDER BY interview_to_approval_rate DESC
LIMIT 10;
```

---

#### Função: `get_dashboard_overview(company_id UUID)`

Retorna JSON consolidado com 26+ métricas em 3 seções.

**Parâmetros:**
- `p_company_id` (UUID): Company ID

**Retorno:** JSON
```json
{
  "global": {
    "total_jobs": 15,
    "active_jobs": 8,
    "total_resumes": 142,
    "total_candidates": 98,
    "total_interviews": 45,
    "completed_interviews": 32,
    "total_reports": 28,
    "total_users": 12,
    "active_users": 10,
    "jobs_last_7_days": 3,
    "resumes_last_7_days": 24,
    "interviews_last_7_days": 8,
    "last_activity_at": "2025-01-22T14:30:00Z"
  },
  "presets": {
    "total_presets": 5,
    "default_presets": 2,
    "shared_presets": 1,
    "users_with_presets": 4,
    "total_usage": 127,
    "avg_usage_per_preset": 25.4,
    "max_usage": 45,
    "used_last_7_days": 4
  },
  "conversion": {
    "total_jobs": 15,
    "avg_resumes_per_job": 9.5,
    "avg_interviews_per_job": 3.0,
    "avg_resume_to_interview_rate": 31.6,
    "avg_interview_to_approval_rate": 62.2
  }
}
```

**Uso:**
```sql
SELECT get_dashboard_overview('company-uuid-here');
```

---

#### Índices Adicionais (3)

Para acelerar queries de timeline:

1. `idx_jobs_company_created_date` ON jobs(company_id, DATE(created_at))
2. `idx_resumes_company_created_date` ON resumes(company_id, DATE(created_at))
3. `idx_interviews_company_created_date` ON interviews(company_id, DATE(created_at))

---

## API Endpoints

### Overview Consolidado (3 endpoints)

#### 1. GET /api/dashboard/overview

Retorna overview consolidado (26+ métricas em uma chamada).

**Request:**
```http
GET /api/dashboard/overview
Authorization: Bearer <token>
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "global": { /* 13 métricas */ },
    "presets": { /* 8 métricas */ },
    "conversion": { /* 5 métricas */ }
  }
}
```

**Casos de Uso:**
- Carregar tela inicial do dashboard
- Atualizar métricas em tempo real (polling/refresh)
- Exportar snapshot de métricas

---

#### 2. GET /api/dashboard/activity-timeline

Timeline diária de atividades.

**Request:**
```http
GET /api/dashboard/activity-timeline?days=30
Authorization: Bearer <token>
```

**Query Params:**
- `days` (opcional, default: 30): Período em dias

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "activity_date": "2025-01-22",
      "jobs_created": 2,
      "resumes_uploaded": 15,
      "interviews_scheduled": 5,
      "reports_generated": 3,
      "users_registered": 1,
      "total_activities": 26
    },
    // ... mais dias
  ],
  "period": {
    "days": 30,
    "from": "2024-12-23",
    "to": "2025-01-22"
  }
}
```

**Casos de Uso:**
- Gráficos de linha/área mostrando tendências
- Identificar picos de atividade
- Comparar períodos (7 vs 30 vs 90 dias)

---

#### 3. GET /api/dashboard/conversion-funnel

Funil de conversão por vaga.

**Request:**
```http
GET /api/dashboard/conversion-funnel?status=open&sort=resume_to_interview_rate&order=DESC&limit=20
Authorization: Bearer <token>
```

**Query Params:**
- `status` (opcional): Filtrar por status da vaga (open, closed, filled, etc)
- `sort` (opcional, default: 'resume_to_interview_rate'): Campo de ordenação
  - Opções: `total_resumes`, `total_interviews`, `approved_candidates`, `resume_to_interview_rate`, `interview_to_approval_rate`
- `order` (opcional, default: 'DESC'): ASC ou DESC
- `limit` (opcional, default: 20): Máximo de vagas

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "job_id": "uuid",
      "job_title": "Senior Developer",
      "job_status": "open",
      "job_created_at": "2025-01-10T10:00:00Z",
      "total_resumes": 45,
      "total_interviews": 12,
      "completed_interviews": 10,
      "approved_candidates": 8,
      "resume_to_interview_rate": 26.67,
      "interview_to_approval_rate": 80.00
    },
    // ... mais vagas
  ],
  "stats": {
    "total_jobs": 15,
    "total_resumes": 547,
    "total_interviews": 123,
    "total_approved": 67,
    "avg_resume_to_interview_rate": 22.48,
    "avg_interview_to_approval_rate": 54.47
  }
}
```

**Casos de Uso:**
- Identificar gargalos (vagas com baixa taxa de conversão)
- Comparar performance de vagas
- Análise de efetividade do recrutamento

---

### Dashboard Presets CRUD (5 endpoints)

#### 4. POST /api/dashboard/presets

Criar novo preset.

**Request:**
```http
POST /api/dashboard/presets
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Meu Dashboard Principal",
  "description": "Visão geral focada em vagas abertas",
  "filters": {
    "period": "last_30_days",
    "jobStatus": ["open"],
    "interviewStatus": ["scheduled", "in_progress"]
  },
  "layout": {
    "widgets": ["kpi-cards", "activity-chart", "conversion-funnel"],
    "order": ["kpis", "timeline", "funnel"]
  },
  "preferences": {
    "theme": "light",
    "chartType": "line",
    "showLegends": true
  },
  "is_default": true,
  "is_shared": false
}
```

**Validações:**
- `name` obrigatório e não vazio (trimmed)
- Se `is_default=true`, desmarca outros defaults do usuário

**Response 201:**
```json
{
  "success": true,
  "message": "Preset criado com sucesso",
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "company_id": "uuid",
    "name": "Meu Dashboard Principal",
    "description": "Visão geral focada em vagas abertas",
    "filters": { /* ... */ },
    "layout": { /* ... */ },
    "preferences": { /* ... */ },
    "is_default": true,
    "is_shared": false,
    "shared_with_roles": [],
    "usage_count": 0,
    "last_used_at": null,
    "created_at": "2025-01-22T10:00:00Z",
    "updated_at": "2025-01-22T10:00:00Z",
    "deleted_at": null
  }
}
```

**Erros:**
- **400**: Nome vazio ou apenas espaços
- **401**: Token ausente/inválido
- **500**: Erro interno

---

#### 5. GET /api/dashboard/presets

Listar presets do usuário (próprios + compartilhados).

**Request:**
```http
GET /api/dashboard/presets?search=entrevista&is_shared=true&sort=usage_count&order=DESC&page=1&limit=20
Authorization: Bearer <token>
```

**Query Params:**
- `search` (opcional): Busca textual em nome/descrição (ILIKE)
- `is_shared` (opcional): Filtrar por compartilhados (true/false)
- `is_default` (opcional): Filtrar por defaults (true/false)
- `sort` (opcional, default: 'usage_count'): Campo de ordenação
  - Opções: `usage_count`, `last_used_at`, `created_at`, `name`
- `order` (opcional, default: 'DESC'): ASC ou DESC
- `page` (opcional, default: 1): Página atual
- `limit` (opcional, default: 20, max: 100): Itens por página

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "company_id": "uuid",
      "name": "Dashboard de Entrevistas",
      "description": "Acompanhamento detalhado de entrevistas",
      "filters": { /* ... */ },
      "layout": { /* ... */ },
      "preferences": { /* ... */ },
      "is_default": false,
      "is_shared": true,
      "shared_with_roles": ["ADMIN", "RECRUITER"],
      "usage_count": 45,
      "last_used_at": "2025-01-22T09:30:00Z",
      "created_at": "2025-01-10T10:00:00Z",
      "updated_at": "2025-01-15T14:00:00Z",
      "user_name": "João Silva",
      "company_name": "Empresa XYZ"
    },
    // ... mais presets
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1
  }
}
```

**Lógica de Acesso:**
- Usuário vê seus próprios presets (`user_id = usuario.id`)
- + Presets compartilhados com seu role (`is_shared=TRUE AND usuario.role IN shared_with_roles`)

---

#### 6. GET /api/dashboard/presets/:id

Buscar preset específico.

**Request:**
```http
GET /api/dashboard/presets/{preset_id}
Authorization: Bearer <token>
```

**Comportamento:**
- Incrementa `usage_count` + 1
- Atualiza `last_used_at` = NOW()

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Dashboard Principal",
    "description": "...",
    "filters": { /* ... */ },
    "layout": { /* ... */ },
    "preferences": { /* ... */ },
    "usage_count": 23,
    "last_used_at": "2025-01-22T10:15:00Z",
    "user_name": "João Silva",
    "company_name": "Empresa XYZ"
    // ... outros campos
  }
}
```

**Erros:**
- **404**: Preset não encontrado / sem permissão
- **401**: Token ausente/inválido

---

#### 7. PUT /api/dashboard/presets/:id

Atualizar preset (apenas campos enviados).

**Request:**
```http
PUT /api/dashboard/presets/{preset_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Dashboard Principal (Atualizado)",
  "is_default": true
}
```

**Campos atualizáveis:**
- `name`, `description`, `filters`, `layout`, `preferences`
- `is_default`, `is_shared`, `shared_with_roles`

**Validações:**
- Apenas dono do preset pode atualizar
- Se `is_default=true`, desmarca outros defaults do usuário
- Ao menos 1 campo deve ser enviado

**Response 200:**
```json
{
  "success": true,
  "message": "Preset atualizado com sucesso",
  "data": {
    "id": "uuid",
    "name": "Dashboard Principal (Atualizado)",
    "is_default": true,
    "updated_at": "2025-01-22T10:20:00Z"
    // ... outros campos
  }
}
```

**Erros:**
- **400**: Nenhum campo para atualizar
- **404**: Preset não encontrado / sem permissão
- **401**: Token ausente/inválido

---

#### 8. DELETE /api/dashboard/presets/:id

Deletar preset (soft delete).

**Request:**
```http
DELETE /api/dashboard/presets/{preset_id}
Authorization: Bearer <token>
```

**Validações:**
- Apenas dono do preset pode deletar

**Response 200:**
```json
{
  "success": true,
  "message": "Preset deletado com sucesso",
  "data": {
    "id": "uuid",
    "name": "Dashboard Principal"
  }
}
```

**Comportamento:**
- Marca `deleted_at = NOW()`
- Preset não aparece mais em listagens
- Dados preservados para auditoria

**Erros:**
- **404**: Preset não encontrado / sem permissão
- **401**: Token ausente/inválido

---

## Fluxos de Uso

### Fluxo 1: Carregar Dashboard Inicial

```
1. Frontend faz login → recebe token
2. GET /api/dashboard/overview
   → Retorna 26+ métricas consolidadas
3. Renderiza KPI cards (vagas, currículos, entrevistas, etc)
4. GET /api/dashboard/presets?is_default=true
   → Retorna preset default do usuário (se houver)
5. Aplica filtros salvos no preset default
6. GET /api/dashboard/activity-timeline?days=30
   → Renderiza gráfico de atividades
7. GET /api/dashboard/conversion-funnel?status=open&limit=10
   → Renderiza tabela de funil
```

### Fluxo 2: Salvar Configuração Customizada

```
1. Usuário ajusta filtros (período, status, etc)
2. Usuário customiza layout (ordem de widgets, tipo de gráfico)
3. Usuário clica "Salvar Dashboard"
4. Frontend mostra modal com:
   - Campo: Nome do preset
   - Campo: Descrição (opcional)
   - Checkbox: Marcar como padrão?
   - Checkbox: Compartilhar com equipe?
   - Select: Roles com acesso (se compartilhado)
5. POST /api/dashboard/presets
   {
     "name": "Dashboard de Recrutamento",
     "filters": { /* filtros atuais */ },
     "layout": { /* layout atual */ },
     "preferences": { /* preferências atuais */ },
     "is_default": true,
     "is_shared": true,
     "shared_with_roles": ["RECRUITER"]
   }
6. Backend cria preset + desmarca outros defaults
7. Frontend exibe confirmação
```

### Fluxo 3: Carregar Preset Salvo

```
1. Usuário acessa dropdown "Meus Dashboards"
2. GET /api/dashboard/presets?sort=usage_count&order=DESC
   → Lista presets ordenados por uso
3. Usuário clica em preset "Dashboard de Entrevistas"
4. GET /api/dashboard/presets/{id}
   → Retorna detalhes + incrementa usage_count
5. Frontend aplica:
   - filters → Atualiza filtros do dashboard
   - layout → Reorganiza widgets
   - preferences → Aplica tema/tipo de gráfico
6. Frontend busca dados com novos filtros aplicados
```

### Fluxo 4: Compartilhar Dashboard com Equipe

```
1. Usuário cria preset pessoal (is_shared=false)
2. Após refinamento, decide compartilhar
3. PUT /api/dashboard/presets/{id}
   {
     "is_shared": true,
     "shared_with_roles": ["ADMIN", "RECRUITER"]
   }
4. Backend atualiza preset
5. Usuários com roles ADMIN/RECRUITER podem ver:
   - GET /api/dashboard/presets?is_shared=true
6. Eles aplicam o preset e visualizam a mesma configuração
```

### Fluxo 5: Análise de Gargalos no Funil

```
1. Gestor acessa "Análise de Conversão"
2. GET /api/dashboard/conversion-funnel?sort=resume_to_interview_rate&order=ASC&limit=20
   → Retorna vagas com MENOR taxa de conversão (gargalos)
3. Frontend renderiza tabela destacando:
   - Vagas com < 20% conversão currículo→entrevista (ALERTA)
   - Vagas com < 40% conversão entrevista→aprovação (ATENÇÃO)
4. Gestor identifica vaga "Senior Developer" com:
   - 80 currículos → 5 entrevistas (6.25% taxa)
5. Gestor clica na vaga para investigar:
   - Requisitos muito restritivos?
   - Triagem inadequada?
   - Problema na descrição da vaga?
6. Ajustes são feitos na vaga
7. Após 2 semanas, gestor refaz a análise
8. Nova taxa: 80 currículos → 20 entrevistas (25% taxa) ✅
```

---

## Exemplos de Integração

### Frontend (Flutter Web)

#### Carregar Overview

```dart
Future<Map<String, dynamic>> carregarOverview() async {
  final response = await http.get(
    Uri.parse('$baseUrl/dashboard/overview'),
    headers: {'Authorization': 'Bearer $token'}
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data']; // { global: {...}, presets: {...}, conversion: {...} }
  }
  throw Exception('Erro ao carregar overview');
}

Widget buildKPICards(Map<String, dynamic> overview) {
  final global = overview['global'];
  return Row(
    children: [
      KPICard(title: 'Vagas Abertas', value: global['active_jobs']),
      KPICard(title: 'Currículos', value: global['total_resumes']),
      KPICard(title: 'Entrevistas', value: global['total_interviews']),
      KPICard(title: 'Relatórios', value: global['total_reports']),
    ]
  );
}
```

#### Salvar Preset

```dart
Future<void> salvarPreset(DashboardConfig config) async {
  final response = await http.post(
    Uri.parse('$baseUrl/dashboard/presets'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    },
    body: jsonEncode({
      'name': config.name,
      'description': config.description,
      'filters': config.filters,
      'layout': config.layout,
      'preferences': config.preferences,
      'is_default': config.isDefault,
      'is_shared': config.isShared,
      'shared_with_roles': config.sharedWithRoles
    })
  );
  
  if (response.statusCode == 201) {
    showSnackBar('Preset salvo com sucesso!');
  } else {
    showSnackBar('Erro ao salvar preset');
  }
}
```

#### Aplicar Preset

```dart
Future<void> aplicarPreset(String presetId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/dashboard/presets/$presetId'),
    headers: {'Authorization': 'Bearer $token'}
  );
  
  if (response.statusCode == 200) {
    final preset = jsonDecode(response.body)['data'];
    
    // Aplicar filtros
    setState(() {
      filtrosPeriodo = preset['filters']['period'];
      filtrosStatus = List<String>.from(preset['filters']['jobStatus'] ?? []);
    });
    
    // Aplicar layout
    reorganizarWidgets(preset['layout']['order']);
    
    // Aplicar preferências
    aplicarTema(preset['preferences']['theme']);
    aplicarTipoGrafico(preset['preferences']['chartType']);
    
    // Recarregar dados
    await recarregarDashboard();
  }
}
```

---

## Segurança e Permissões

### Isolamento Multitenant

Todas as queries filtram por `company_id` do usuário logado:

```javascript
const companyId = req.usuario.company_id; // Extraído do token

// Listar presets
WHERE dp.company_id = $1 AND (dp.user_id = $2 OR ...)

// Overview
SELECT get_dashboard_overview($1) -- company_id

// Activity Timeline
WHERE company_id = $1

// Conversion Funnel
WHERE company_id = $1
```

### Controle de Acesso a Presets

**Regras:**
1. Usuário vê seus próprios presets (`user_id = usuario.id`)
2. Usuário vê presets compartilhados com seu role (`is_shared=TRUE AND usuario.role IN shared_with_roles`)
3. Apenas dono pode atualizar/deletar

**Exemplos:**

```sql
-- João (RECRUITER) vê:
-- - Seus próprios presets
-- - Presets compartilhados com role RECRUITER

SELECT * FROM dashboard_presets
WHERE company_id = 'company-xyz'
  AND deleted_at IS NULL
  AND (
    user_id = 'joao-uuid'  -- próprios
    OR (is_shared = TRUE AND 'RECRUITER' = ANY(shared_with_roles))  -- compartilhados
  )
```

### Proteções Implementadas

1. **Token JWT obrigatório**: Middleware `exigirAutenticacao` em todas as rotas
2. **Company isolation**: Todos os endpoints filtram por `company_id`
3. **Ownership validation**: Update/delete só permitido para dono do preset
4. **Soft delete**: Dados nunca são removidos fisicamente
5. **Input validation**: Nome obrigatório, trim de espaços, constraints de banco

### Auditoria

**Campos rastreados:**
- `created_at`: Quando preset foi criado
- `updated_at`: Última modificação (auto-updated por trigger)
- `deleted_at`: Quando foi deletado (soft delete)
- `last_used_at`: Último acesso ao preset
- `usage_count`: Quantas vezes foi usado

**Logs:**
```javascript
console.log('[RF9] Preset criado:', { userId, companyId, name });
console.log('[RF9] Preset atualizado:', { id, userId, fields });
console.log('[RF9] Preset deletado:', { id, userId });
```

---

## Performance e Otimizações

### Índices Estratégicos

**1. Query principal (listagem de presets):**
```sql
idx_dashboard_presets_user_company (user_id, company_id WHERE deleted_at IS NULL)
```
- Cobre 90% das queries de listagem
- Filtro parcial elimina registros deletados

**2. Busca de default:**
```sql
idx_dashboard_presets_default (user_id, is_default WHERE deleted_at IS NULL AND is_default = TRUE)
```
- Usado ao carregar dashboard inicial
- Garante acesso rápido ao preset padrão

**3. Full-text search:**
```sql
idx_dashboard_presets_search (GIN to_tsvector('portuguese', name || ' ' || COALESCE(description, '')))
```
- Busca textual em nome + descrição
- Suporta múltiplas palavras, stemming

**4. JSONB queries:**
```sql
idx_dashboard_presets_filters_gin (GIN filters)
```
- Permite queries como: `filters @> '{"period": "last_30_days"}'`
- Buscar presets com filtro específico

**5. Ranking por uso:**
```sql
idx_dashboard_presets_usage (company_id, usage_count DESC, last_used_at DESC WHERE deleted_at IS NULL)
```
- Suporta ordenação por popularidade
- Identifica presets mais utilizados

### Views Otimizadas

**1. dashboard_global_overview:**
- Agrega dados de 6 tabelas (jobs, resumes, candidates, interviews, reports, users)
- Executa em ~50ms mesmo com 10k+ registros
- Pode ser materializada se necessário: `CREATE MATERIALIZED VIEW`

**2. dashboard_activity_timeline:**
- GROUP BY em DATE(created_at) cria agregações diárias
- Índices em `(company_id, DATE(created_at))` aceleram queries
- Limitar a períodos razoáveis (30-90 dias)

**3. dashboard_conversion_funnel:**
- LEFT JOINs podem ser pesados com muitos dados
- Adicionar `LIMIT` sempre que possível
- Considerar materializar se cálculos ficarem lentos

### Função `get_dashboard_overview`

**Otimização:**
- Executa apenas 3 queries (uma por view)
- Retorna JSON (sem overhead de múltiplas respostas HTTP)
- COALESCE garante valores default (evita NULL propagation)

**Alternativa para alta carga:**
```sql
-- Materializar view global
CREATE MATERIALIZED VIEW dashboard_global_overview_mat AS
SELECT * FROM dashboard_global_overview;

-- Refresh periódico (cron job a cada 5 minutos)
REFRESH MATERIALIZED VIEW dashboard_global_overview_mat;
```

### Caching no Frontend

**Estratégias recomendadas:**

1. **Cache de overview (5 minutos):**
   ```dart
   final cached = cache.get('dashboard-overview');
   if (cached != null && cached.age < Duration(minutes: 5)) {
     return cached.data;
   }
   final fresh = await fetchOverview();
   cache.set('dashboard-overview', fresh);
   ```

2. **Cache de presets (sessão):**
   - Carregar lista de presets apenas uma vez na sessão
   - Invalidar ao criar/atualizar/deletar

3. **Debounce em filtros:**
   - Aplicar debounce de 500ms ao digitar em busca
   - Evita requests a cada tecla pressionada

### Monitoramento

**Queries lentas a monitorar:**

```sql
-- Identificar queries lentas em dashboard
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE query LIKE '%dashboard%'
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Verificar uso de índices
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE tablename = 'dashboard_presets'
ORDER BY idx_scan ASC;
```

---

## Troubleshooting

### Problema: Overview retorna métricas zeradas

**Sintoma:**
```json
{
  "global": {
    "total_jobs": 0,
    "active_jobs": 0,
    "total_resumes": 0
  }
}
```

**Causas possíveis:**
1. Company sem dados cadastrados (novo usuário)
2. Company_id incorreto no token
3. Dados deletados (soft delete)

**Solução:**
```sql
-- Verificar se há dados para a company
SELECT 
  (SELECT COUNT(*) FROM jobs WHERE company_id = 'xxx') as jobs,
  (SELECT COUNT(*) FROM resumes WHERE company_id = 'xxx') as resumes,
  (SELECT COUNT(*) FROM interviews WHERE company_id = 'xxx') as interviews;

-- Se tudo zerado, criar dados de teste:
INSERT INTO jobs (company_id, title, status, ...) VALUES ('xxx', 'Test Job', 'open', ...);
```

---

### Problema: Preset não aparece na listagem

**Sintoma:** Usuário cria preset mas não consegue encontrar na lista.

**Causas possíveis:**
1. Preset de outro usuário sem is_shared=TRUE
2. Preset compartilhado mas role do usuário não está em shared_with_roles
3. Soft deleted (deleted_at IS NOT NULL)

**Solução:**
```sql
-- Verificar status do preset
SELECT id, name, user_id, is_shared, shared_with_roles, deleted_at
FROM dashboard_presets
WHERE id = 'preset-uuid';

-- Se deleted_at != NULL, restaurar:
UPDATE dashboard_presets SET deleted_at = NULL WHERE id = 'preset-uuid';

-- Se problema de sharing, ajustar roles:
UPDATE dashboard_presets 
SET is_shared = TRUE, shared_with_roles = ARRAY['ADMIN', 'RECRUITER', 'USER']
WHERE id = 'preset-uuid';
```

---

### Problema: Múltiplos presets marcados como default

**Sintoma:** Usuário tem 2+ presets com `is_default=TRUE`.

**Causa:** Falha no trigger/lógica de desmarcar outros defaults.

**Solução:**
```sql
-- Verificar presets default do usuário
SELECT id, name, is_default FROM dashboard_presets
WHERE user_id = 'user-uuid' AND company_id = 'company-uuid' AND deleted_at IS NULL;

-- Corrigir: desmarcar todos exceto o mais recente
UPDATE dashboard_presets
SET is_default = FALSE
WHERE user_id = 'user-uuid' 
  AND company_id = 'company-uuid'
  AND id != (
    SELECT id FROM dashboard_presets
    WHERE user_id = 'user-uuid' AND company_id = 'company-uuid' AND is_default = TRUE
    ORDER BY created_at DESC LIMIT 1
  );
```

---

### Problema: Activity timeline sem dados

**Sintoma:** GET /activity-timeline retorna array vazio.

**Causas possíveis:**
1. Período solicitado sem atividades (ex: company criada hoje, pedindo últimos 30 dias)
2. Índices em DATE(created_at) não existem
3. View dashboard_activity_timeline não foi criada

**Solução:**
```sql
-- Verificar se view existe
SELECT * FROM pg_views WHERE viewname = 'dashboard_activity_timeline';

-- Testar view diretamente
SELECT * FROM dashboard_activity_timeline WHERE company_id = 'xxx' LIMIT 5;

-- Se vazio, verificar dados brutos
SELECT DATE(created_at), COUNT(*) FROM jobs
WHERE company_id = 'xxx' GROUP BY DATE(created_at) ORDER BY DATE(created_at) DESC;

-- Criar índices se ausentes (devem estar na migration 027)
CREATE INDEX IF NOT EXISTS idx_jobs_company_created_date 
  ON jobs(company_id, DATE(created_at)) WHERE deleted_at IS NULL;
```

---

### Problema: Conversion funnel com taxas NaN

**Sintoma:**
```json
{
  "resume_to_interview_rate": null,
  "interview_to_approval_rate": null
}
```

**Causa:** Divisão por zero quando `total_resumes=0` ou `total_interviews=0`.

**Solução:**
A view já trata isso com `CASE WHEN COUNT > 0 THEN ... ELSE 0 END`. Se ainda ocorrer:

```sql
-- Verificar dados da vaga
SELECT 
  j.id,
  COUNT(DISTINCT r.id) as resumes,
  COUNT(DISTINCT i.id) as interviews
FROM jobs j
LEFT JOIN resumes r ON r.job_id = j.id AND r.deleted_at IS NULL
LEFT JOIN applications app ON app.job_id = j.id AND app.deleted_at IS NULL
LEFT JOIN interviews i ON i.application_id = app.id AND i.deleted_at IS NULL
WHERE j.id = 'job-uuid'
GROUP BY j.id;
```

---

### Problema: Usage count não incrementa

**Sintoma:** Usuário acessa preset várias vezes mas `usage_count` permanece 0.

**Causa:** Query de incremento falhando silenciosamente.

**Solução:**
```javascript
// Verificar no backend se UPDATE está sendo executado
const result = await db.query(
  `UPDATE dashboard_presets 
   SET usage_count = usage_count + 1, last_used_at = NOW()
   WHERE id = $1
   RETURNING usage_count`,
  [id]
);
console.log('[DEBUG] Usage count atualizado:', result.rows[0]);
```

---

### Problema: Performance lenta ao listar presets

**Sintoma:** GET /presets demora 2-5 segundos.

**Causas possíveis:**
1. Muitos presets (100+) sem paginação
2. Índices ausentes
3. Query full-text search sem GIN index
4. JOINs com users/companies sem índices

**Solução:**
```sql
-- Analisar query plan
EXPLAIN ANALYZE
SELECT dp.*, u.nome, c.name
FROM dashboard_presets dp
LEFT JOIN users u ON u.id = dp.user_id
LEFT JOIN companies c ON c.id = dp.company_id
WHERE dp.company_id = 'xxx' AND dp.deleted_at IS NULL
ORDER BY dp.usage_count DESC
LIMIT 20;

-- Verificar uso de índices
-- Deve usar: idx_dashboard_presets_user_company ou idx_dashboard_presets_usage

-- Se não usar, forçar:
SET enable_seqscan = OFF;
```

---

### Problema: Preset compartilhado não aparece para outros usuários

**Sintoma:** Usuário A compartilha preset com role RECRUITER, mas usuário B (RECRUITER) não vê.

**Causas possíveis:**
1. `is_shared=FALSE` (não foi marcado ao criar/atualizar)
2. Role de B não está em `shared_with_roles` (typo: 'RECRUTADOR' vs 'RECRUITER')
3. Companies diferentes

**Solução:**
```sql
-- Verificar preset
SELECT id, name, user_id, company_id, is_shared, shared_with_roles
FROM dashboard_presets WHERE id = 'preset-uuid';

-- Verificar usuário B
SELECT id, nome, email, role, company_id FROM users WHERE id = 'user-b-uuid';

-- Garantir que:
-- 1. preset.company_id = user_b.company_id
-- 2. preset.is_shared = TRUE
-- 3. user_b.role IN preset.shared_with_roles

-- Corrigir se necessário:
UPDATE dashboard_presets
SET is_shared = TRUE, shared_with_roles = ARRAY['RECRUITER']
WHERE id = 'preset-uuid';
```

---

## Boas Práticas

### 1. Estrutura de Filtros JSONB

Padronizar chaves para facilitar reuso:

```json
{
  "filters": {
    "period": "last_30_days",  // "last_7_days" | "last_30_days" | "last_90_days" | "custom"
    "customDateRange": {
      "from": "2025-01-01",
      "to": "2025-01-31"
    },
    "jobStatus": ["open", "closed"],  // Array de status
    "interviewStatus": ["scheduled", "in_progress", "completed"],
    "department": "Engineering",
    "minResumes": 5,
    "showOnlyMyInterviews": true
  }
}
```

### 2. Estrutura de Layout JSONB

```json
{
  "layout": {
    "widgets": ["kpi-cards", "activity-chart", "conversion-funnel", "top-presets"],
    "order": ["kpis", "timeline", "funnel", "presets"],
    "grid": {
      "columns": 12,
      "rows": "auto"
    },
    "widgetConfig": {
      "kpi-cards": {
        "visible": true,
        "span": 12,
        "metrics": ["jobs", "resumes", "interviews", "reports"]
      },
      "activity-chart": {
        "visible": true,
        "span": 8,
        "height": 400
      }
    }
  }
}
```

### 3. Estrutura de Preferences JSONB

```json
{
  "preferences": {
    "theme": "light",  // "light" | "dark" | "system"
    "chartType": "line",  // "line" | "bar" | "area" | "pie"
    "showLegends": true,
    "showGridlines": true,
    "autoRefresh": 300,  // segundos (5 min)
    "animations": true,
    "compactMode": false,
    "locale": "pt-BR",
    "numberFormat": "br"  // 1.234,56 vs 1,234.56
  }
}
```

### 4. Nomes Descritivos de Presets

❌ Ruim:
- "Dashboard 1"
- "Teste"
- "Meu"

✅ Bom:
- "Dashboard Principal - Vagas Abertas"
- "Acompanhamento de Entrevistas Semanais"
- "Análise de Conversão - Q1 2025"
- "Visão Executiva Mensal"

### 5. Compartilhamento Consciente

- Presets pessoais/experimentais: `is_shared=FALSE`
- Presets estáveis/úteis para equipe: `is_shared=TRUE` + roles apropriados
- Presets executivos: compartilhar apenas com `ADMIN`
- Presets operacionais: compartilhar com `RECRUITER`, `USER`

### 6. Paginação

Sempre usar paginação ao listar presets:
```http
GET /api/dashboard/presets?page=1&limit=20
```

Evitar carregar 100+ presets de uma vez.

### 7. Polling Inteligente

Para atualização em tempo real:
```javascript
// Polling a cada 5 minutos
setInterval(async () => {
  if (document.visibilityState === 'visible') {  // Apenas se tab ativa
    await refreshOverview();
  }
}, 5 * 60 * 1000);
```

---

## Próximos Passos (Melhorias Futuras)

### 1. Preset Templates

Criar presets públicos/templates:
- "Dashboard de Recrutador" (template oficial)
- "Dashboard de Gestor" (template oficial)
- Usuários podem clonar e customizar

### 2. Preset Versioning

Rastrear mudanças em presets:
- Criar tabela `dashboard_preset_versions`
- Backup automático antes de atualizar
- Permitir rollback para versão anterior

### 3. Scheduled Reports

Enviar relatórios por email periodicamente:
- Diário: resumo de ontem
- Semanal: métricas da semana
- Mensal: análise consolidada

### 4. Comparações Temporais

Adicionar ao overview:
```json
{
  "global": {
    "total_jobs": 15,
    "total_jobs_change": "+3",  // vs período anterior
    "total_jobs_change_pct": "+25%"
  }
}
```

### 5. Alertas e Notificações

Disparar alertas quando:
- Taxa de conversão cai abaixo de X%
- Nenhuma entrevista nos últimos 7 dias
- Vaga aberta há mais de 60 dias sem progresso

### 6. Exportação de Dados

Permitir download de métricas:
- CSV/Excel (tabelas)
- PDF (relatório formatado)
- JSON (dados brutos)

### 7. Dashboard Mobile

Adaptar layout para mobile:
- Cards empilhados verticalmente
- Gráficos simplificados
- Swipe entre seções

---

## Conclusão

O **RF9 - Dashboard de Acompanhamento** fornece uma visão consolidada e customizável de todos os dados do TalentMatchIA. Com 8 endpoints, 26+ métricas agregadas, sistema de presets personalizáveis e compartilháveis, ele capacita recrutadores e gestores a monitorar o processo de recrutamento de forma eficiente e data-driven.

**Características principais:**
- ✅ Overview em uma única chamada (performance)
- ✅ JSONB flexível (extensibilidade sem schema changes)
- ✅ Sharing de configurações (colaboração)
- ✅ Tracking de uso (analytics de adoção)
- ✅ Multitenant (isolamento completo)
- ✅ Soft delete (auditoria preservada)

**Integração com outros RFs:**
- RF1: Currículos (total_resumes, resumes_last_7_days)
- RF2: Vagas (total_jobs, active_jobs, jobs_last_7_days)
- RF3: Question Sets (usado indiretamente via entrevistas)
- RF6: Assessments (usado indiretamente via entrevistas)
- RF7: Reports (total_reports, reports_generated)
- RF8: Interviews (total_interviews, completed_interviews, conversion funnel)
- RF10: Users (total_users, active_users, users_registered)

---

**Versão:** 1.0  
**Data:** 22/01/2025  
**Autor:** TalentMatchIA Team
