# RF3 - Geração de Perguntas para Entrevistas (Interview Question Sets)

## 📋 Visão Geral

O RF3 implementa o sistema de **geração, gerenciamento e reutilização de perguntas para entrevistas** do TalentMatchIA. Permite que recrutadores criem conjuntos de perguntas manualmente, gerem automaticamente via IA, editem, organizem por tipo (behavioral, technical, situational, cultural, general) e reutilizem como templates.

### Principais Funcionalidades

- ✅ **Criar conjuntos de perguntas** (manuais ou via IA)
- ✅ **Gerar perguntas via IA** baseadas em vaga + currículo
- ✅ **Listar e filtrar** conjuntos (por vaga, template, texto)
- ✅ **Editar perguntas** (texto, tipo, ordem)
- ✅ **Deletar** conjuntos e perguntas (soft delete)
- ✅ **Templates reutilizáveis** para padronizar entrevistas
- ✅ **Métricas e KPIs** (uso, tipos, IA vs manual)
- ✅ **Categorização** por tipo de pergunta
- ✅ **Ordenação customizada** de perguntas

---

## 🗄️ Banco de Dados

### Migration 016: Tabela `interview_question_sets`

```sql
CREATE TABLE interview_question_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),           -- Vaga associada (opcional)
  resume_id UUID REFERENCES resumes(id),     -- Currículo associado (opcional)
  title TEXT NOT NULL,                       -- Ex: "Perguntas Backend Sênior"
  description TEXT,                          -- Contexto do conjunto
  is_template BOOLEAN DEFAULT false,         -- Se é reutilizável
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  deleted_at TIMESTAMP                       -- Soft delete
);
```

**Índices:**
- `idx_question_sets_company` (company_id, deleted_at)
- `idx_question_sets_job` (job_id, deleted_at)
- `idx_question_sets_template` (is_template, deleted_at)
- `idx_question_sets_set_order` (set_id, "order", deleted_at)
- `idx_question_sets_type` (type, company_id)

**Triggers:**
- `trigger_update_question_sets_updated_at`: Atualiza `updated_at` automaticamente

---

### Migration 016: Colunas Adicionadas à `interview_questions`

Tabela original tinha: `id, company_id, interview_id, origin, kind, prompt, created_at`

**Novas colunas:**
```sql
ALTER TABLE interview_questions ADD COLUMN set_id UUID REFERENCES interview_question_sets(id);
ALTER TABLE interview_questions ADD COLUMN type TEXT CHECK (type IN ('behavioral', 'technical', 'situational', 'cultural', 'general'));
ALTER TABLE interview_questions ADD COLUMN text TEXT;     -- Texto da pergunta
ALTER TABLE interview_questions ADD COLUMN "order" INTEGER; -- Ordem de exibição
ALTER TABLE interview_questions ADD COLUMN updated_at TIMESTAMP;
ALTER TABLE interview_questions ADD COLUMN deleted_at TIMESTAMP;
```

**Estrutura Final (13 colunas):**
1. `id` - UUID
2. `company_id` - UUID (multitenant)
3. `interview_id` - UUID (link para entrevista realizada, nullable)
4. `set_id` - UUID (link para conjunto, nullable)
5. `type` - TEXT (behavioral|technical|situational|cultural|general)
6. `text` - TEXT (pergunta em si)
7. `order` - INTEGER (ordem de exibição)
8. `origin` - TEXT (ai_generated|manual|ai_edited)
9. `kind` - TEXT (mantido por compatibilidade)
10. `prompt` - TEXT (mantido por compatibilidade)
11. `created_at` - TIMESTAMP
12. `updated_at` - TIMESTAMP
13. `deleted_at` - TIMESTAMP

---

### Migration 017: Views de Métricas

#### 1. `question_sets_stats`
Estatísticas agregadas por empresa:
- Total de conjuntos (ativos, templates, últimos 7/30 dias)
- Média de perguntas por conjunto
- Total de perguntas criadas

```sql
SELECT * FROM question_sets_stats WHERE company_id = 'xxx';
```

#### 2. `question_sets_by_job`
Conjuntos agrupados por vaga:
- Total de conjuntos por vaga
- Total de perguntas
- Breakdown por tipo (behavioral, technical, etc.)
- Última atualização

```sql
SELECT * FROM question_sets_by_job WHERE company_id = 'xxx' ORDER BY total_questions DESC;
```

#### 3. `question_type_distribution`
Distribuição de perguntas por tipo:
- Contagem por tipo
- Percentual de cada tipo
- Número de conjuntos que usam cada tipo

```sql
SELECT * FROM question_type_distribution WHERE company_id = 'xxx';
```

#### 4. `question_sets_usage`
Uso de conjuntos (para identificar os mais populares):
- Quantas perguntas tem cada conjunto
- Quantas vezes foi usado em entrevistas (`times_used`)
- Criador do conjunto

```sql
SELECT * FROM question_sets_usage WHERE company_id = 'xxx' ORDER BY times_used DESC LIMIT 10;
```

#### 5. `question_editing_stats`
Estatísticas de origem das perguntas:
- Geradas por IA (`ai_generated`)
- Criadas manualmente (`manual`)
- Editadas após IA (`ai_edited`)
- Percentuais

```sql
SELECT * FROM question_editing_stats WHERE company_id = 'xxx';
```

#### Função: `get_question_set_metrics(company_id UUID)`

Retorna 6 métricas principais:

| metric_name | metric_value | metric_label |
|-------------|--------------|--------------|
| total_sets | 15 | Total de conjuntos de perguntas |
| template_sets | 5 | Conjuntos modelo (reutilizáveis) |
| total_questions | 120 | Total de perguntas criadas |
| avg_questions_per_set | 8.00 | Média de perguntas por conjunto |
| ai_generated_percentage | 65.00 | % de perguntas geradas por IA |
| sets_last_30_days | 3 | Conjuntos criados nos últimos 30 dias |

---

## 🚀 API Endpoints

### Base URL
```
/api/interview-question-sets
```

Todos os endpoints requerem autenticação via `Authorization: Bearer <token>`.

---

### 1. **Listar Conjuntos de Perguntas**

```http
GET /api/interview-question-sets
```

**Query Parameters:**

| Parâmetro | Tipo | Descrição | Exemplo |
|-----------|------|-----------|---------|
| `job_id` | UUID | Filtrar por vaga | `?job_id=abc123...` |
| `is_template` | Boolean | Apenas templates | `?is_template=true` |
| `q` | String | Busca em título/descrição | `?q=backend` |
| `sort_by` | String | Campo de ordenação | `?sort_by=created_at` |
| `order` | String | ASC ou DESC | `?order=DESC` |
| `page` | Integer | Página (padrão: 1) | `?page=2` |
| `limit` | Integer | Itens por página (padrão: 20, max: 100) | `?limit=50` |

**Campos de Ordenação (`sort_by`):**
- `created_at` (padrão)
- `updated_at`
- `title`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "company_id": "uuid",
      "job_id": "uuid",
      "resume_id": null,
      "title": "Perguntas Backend Sênior",
      "description": "Perguntas técnicas para desenvolvedores backend",
      "is_template": true,
      "created_by": "uuid",
      "updated_by": "uuid",
      "created_at": "2025-11-22T10:00:00Z",
      "updated_at": "2025-11-22T10:00:00Z",
      "job_title": "Desenvolvedor Backend Sênior",
      "job_seniority": "senior",
      "question_count": 8,
      "usage_count": 5,
      "created_by_name": "Admin User"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 15,
    "totalPages": 1
  }
}
```

**Exemplos:**
```http
# Listar todos os templates
GET /api/interview-question-sets?is_template=true

# Buscar por palavra-chave
GET /api/interview-question-sets?q=desenvolvedor&sort_by=created_at&order=DESC

# Filtrar por vaga específica
GET /api/interview-question-sets?job_id=abc123&limit=10
```

---

### 2. **Obter Detalhes de um Conjunto**

```http
GET /api/interview-question-sets/:id
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "company_id": "uuid",
    "job_id": "uuid",
    "resume_id": null,
    "title": "Perguntas Backend Sênior",
    "description": "Perguntas técnicas para desenvolvedores backend",
    "is_template": true,
    "created_by": "uuid",
    "updated_by": "uuid",
    "created_at": "2025-11-22T10:00:00Z",
    "updated_at": "2025-11-22T10:00:00Z",
    "job_title": "Desenvolvedor Backend Sênior",
    "job_seniority": "senior",
    "created_by_name": "Admin User",
    "updated_by_name": "Admin User",
    "questions": [
      {
        "id": "uuid",
        "set_id": "uuid",
        "type": "technical",
        "text": "Explique o conceito de API RESTful.",
        "order": 1,
        "origin": "ai_generated",
        "kind": "technical",
        "prompt": "Explique o conceito de API RESTful.",
        "created_at": "2025-11-22T10:00:00Z",
        "updated_at": "2025-11-22T10:00:00Z"
      }
    ]
  }
}
```

**Response 404:**
```json
{
  "success": false,
  "message": "Conjunto de perguntas não encontrado"
}
```

---

### 3. **Criar Conjunto de Perguntas**

```http
POST /api/interview-question-sets
```

**Permissões:** ADMIN, SUPER_ADMIN, RECRUITER

**Request Body (Manual):**
```json
{
  "title": "Perguntas Backend Sênior",
  "description": "Perguntas técnicas fundamentais",
  "is_template": true,
  "questions": [
    {
      "type": "technical",
      "text": "Explique o conceito de API RESTful.",
      "order": 1
    },
    {
      "type": "behavioral",
      "text": "Conte sobre um desafio técnico que você superou.",
      "order": 2
    }
  ]
}
```

**Request Body (Geração via IA):**
```json
{
  "job_id": "uuid-da-vaga",
  "resume_id": "uuid-do-curriculo",  // Opcional
  "title": "Perguntas Personalizadas - João Silva",
  "description": "Gerado automaticamente pela IA",
  "is_template": false,
  "generate_via_ai": true
}
```

**Tipos de Perguntas (`type`):**
- `behavioral` - Comportamentais (ex: "Como você lida com conflitos?")
- `technical` - Técnicas (ex: "Explique o conceito de cache.")
- `situational` - Situacionais (ex: "O que você faria se...")
- `cultural` - Fit cultural (ex: "Quais valores você prioriza?")
- `general` - Gerais (ex: "Por que essa vaga?")

**Response 201:**
```json
{
  "success": true,
  "message": "Conjunto de perguntas criado com sucesso",
  "data": {
    "id": "uuid",
    "company_id": "uuid",
    "title": "Perguntas Backend Sênior",
    "is_template": true,
    "questions": [
      {
        "id": "uuid",
        "text": "Explique o conceito de API RESTful.",
        "type": "technical",
        "order": 1,
        "origin": "manual"
      }
    ]
  }
}
```

**Response 400 (Validação):**
```json
{
  "success": false,
  "message": "Título é obrigatório"
}
```

**Response 403 (Sem Permissão):**
```json
{
  "success": false,
  "message": "Sem permissão para criar conjuntos de perguntas"
}
```

---

### 4. **Atualizar Conjunto de Perguntas**

```http
PUT /api/interview-question-sets/:id
```

**Permissões:** ADMIN, SUPER_ADMIN, RECRUITER

**Request Body (Atualizar metadados):**
```json
{
  "title": "Novo Título (Atualizado)",
  "description": "Nova descrição",
  "is_template": true
}
```

**Request Body (Editar perguntas existentes):**
```json
{
  "questions": [
    {
      "id": "uuid-da-pergunta",
      "text": "Texto atualizado da pergunta",
      "type": "technical",
      "order": 1
    }
  ]
}
```

**Request Body (Adicionar novas perguntas):**
```json
{
  "questions": [
    {
      "type": "cultural",
      "text": "Nova pergunta adicionada",
      "order": 5
    }
  ]
}
```

**Notas:**
- Campos opcionais: só envia os que deseja alterar
- Perguntas com `id`: são atualizadas (origem vira `ai_edited`)
- Perguntas sem `id`: são criadas como novas (origem `manual`)

**Response 200:**
```json
{
  "success": true,
  "message": "Conjunto de perguntas atualizado com sucesso",
  "data": {
    "id": "uuid",
    "title": "Novo Título (Atualizado)",
    "questions": [...]
  }
}
```

---

### 5. **Deletar Conjunto de Perguntas**

```http
DELETE /api/interview-question-sets/:id
```

**Permissões:** ADMIN, SUPER_ADMIN

**Comportamento:**
- Soft delete do conjunto (`deleted_at = now()`)
- Soft delete das perguntas **NÃO vinculadas a entrevistas**
- Perguntas já usadas em entrevistas **NÃO são deletadas** (preservação de histórico)

**Response 200:**
```json
{
  "success": true,
  "message": "Conjunto de perguntas deletado com sucesso"
}
```

**Response 404:**
```json
{
  "success": false,
  "message": "Conjunto de perguntas não encontrado"
}
```

---

### 6. **Deletar Pergunta Específica**

```http
DELETE /api/interview-question-sets/:setId/questions/:questionId
```

**Permissões:** ADMIN, SUPER_ADMIN, RECRUITER

**Comportamento:**
- Soft delete da pergunta (`deleted_at = now()`)
- **Só permite deletar perguntas NÃO usadas em entrevistas** (`interview_id IS NULL`)

**Response 200:**
```json
{
  "success": true,
  "message": "Pergunta deletada com sucesso"
}
```

**Response 400 (Pergunta usada):**
```json
{
  "success": false,
  "message": "Não é possível deletar perguntas já usadas em entrevistas"
}
```

---

### 7. **Métricas de Question Sets**

```http
GET /api/dashboard/question-sets/metrics
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "metrics": {
      "total_sets": {
        "value": 15,
        "label": "Total de conjuntos de perguntas"
      },
      "template_sets": {
        "value": 5,
        "label": "Conjuntos modelo (reutilizáveis)"
      },
      "total_questions": {
        "value": 120,
        "label": "Total de perguntas criadas"
      },
      "avg_questions_per_set": {
        "value": 8.00,
        "label": "Média de perguntas por conjunto"
      },
      "ai_generated_percentage": {
        "value": 65.00,
        "label": "% de perguntas geradas por IA"
      },
      "sets_last_30_days": {
        "value": 3,
        "label": "Conjuntos criados nos últimos 30 dias"
      }
    },
    "by_type": [
      {
        "company_id": "uuid",
        "type": "technical",
        "total_questions": 50,
        "sets_with_this_type": 10,
        "percentage": 41.67
      },
      {
        "company_id": "uuid",
        "type": "behavioral",
        "total_questions": 35,
        "sets_with_this_type": 8,
        "percentage": 29.17
      }
    ],
    "top_sets": [
      {
        "set_id": "uuid",
        "company_id": "uuid",
        "title": "Perguntas Backend Sênior",
        "is_template": true,
        "question_count": 10,
        "times_used": 15,
        "created_at": "2025-11-22T10:00:00Z",
        "created_by_name": "Admin User"
      }
    ]
  }
}
```

---

### 8. **Estatísticas de Edição (IA vs Manual)**

```http
GET /api/dashboard/question-sets/editing-stats
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "company_id": "uuid",
    "ai_generated": 78,
    "manual_created": 30,
    "ai_edited": 12,
    "ai_generated_percentage": 65.00,
    "ai_edited_percentage": 10.00,
    "total_questions": 120
  }
}
```

---

### 9. **Conjuntos por Vaga**

```http
GET /api/dashboard/question-sets/by-job
```

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "company_id": "uuid",
      "job_id": "uuid",
      "job_title": "Desenvolvedor Backend Sênior",
      "total_sets": 3,
      "total_questions": 25,
      "behavioral_questions": 8,
      "technical_questions": 12,
      "situational_questions": 3,
      "cultural_questions": 2,
      "last_updated": "2025-11-22T10:00:00Z"
    }
  ]
}
```

---

## 🔐 Segurança e Permissões

### Autenticação
Todos os endpoints requerem token JWT válido via header:
```
Authorization: Bearer <token>
```

### Permissões por Endpoint

| Endpoint | SUPER_ADMIN | ADMIN | RECRUITER | CANDIDATE |
|----------|-------------|-------|-----------|-----------|
| GET /interview-question-sets | ✅ | ✅ | ✅ | ❌ |
| GET /interview-question-sets/:id | ✅ | ✅ | ✅ | ❌ |
| POST /interview-question-sets | ✅ | ✅ | ✅ | ❌ |
| PUT /interview-question-sets/:id | ✅ | ✅ | ✅ | ❌ |
| DELETE /interview-question-sets/:id | ✅ | ✅ | ❌ | ❌ |
| DELETE /:setId/questions/:questionId | ✅ | ✅ | ✅ | ❌ |
| GET /dashboard/question-sets/* | ✅ | ✅ | ✅ | ❌ |

### Isolamento Multitenant
- **Todos os queries filtram por `company_id`** extraído do token JWT
- Usuários **nunca** veem conjuntos de outras empresas
- Soft delete preserva dados para auditoria

---

## 🧪 Testes

### Arquivo: `RF3_QUESTIONS_API_COLLECTION.http`

**Total: 50+ requests** cobrindo:

1. **Autenticação** (2 requests)
   - Login
   - Obter perfil

2. **CRUD Básico** (6 requests)
   - Criar manual com perguntas
   - Criar vazio
   - Criar via IA (sem currículo)
   - Criar via IA (com vaga + currículo)
   - Validação título obrigatório
   - Validação job_id obrigatório para IA

3. **Listagem e Filtros** (8 requests)
   - Listar todos
   - Paginação
   - Filtrar por template
   - Filtrar por vaga
   - Busca textual
   - Ordenação por data
   - Ordenação alfabética
   - Filtros combinados

4. **Detalhamento** (1 request)
   - Obter detalhes completos

5. **Update** (5 requests)
   - Atualizar título/descrição
   - Tornar template
   - Editar perguntas existentes
   - Adicionar novas perguntas
   - Update parcial

6. **Delete** (3 requests)
   - Deletar conjunto
   - Deletar pergunta específica
   - Tentar deletar inexistente

7. **Métricas** (3 requests)
   - Métricas consolidadas
   - Estatísticas de edição
   - Conjuntos por vaga

8. **Validações e Segurança** (4 requests)
   - Sem autenticação
   - Token inválido
   - Cross-company access
   - Permissões de role

9. **Performance** (5 requests)
   - Limite máximo
   - Sobre-limite
   - Muitas perguntas (20+)
   - Busca vazia
   - Busca inexistente

10. **Fluxo Completo E2E** (5 requests)
    - Criar template
    - Listar templates
    - Duplicar para vaga
    - Editar pergunta
    - Ver métricas

---

## 📊 Métricas e KPIs

### 1. Uso de Conjuntos
- **Total de conjuntos criados**
- **Templates vs Conjuntos específicos**
- **Taxa de reutilização** (`times_used / total_sets`)

### 2. Perguntas
- **Total de perguntas criadas**
- **Média de perguntas por conjunto**
- **Distribuição por tipo** (behavioral, technical, etc.)

### 3. IA vs Manual
- **% perguntas geradas por IA**
- **% perguntas editadas após IA**
- **% perguntas criadas manualmente**

### 4. Tendências
- **Conjuntos criados nos últimos 7/30 dias**
- **Top 5 conjuntos mais usados**
- **Vagas com mais conjuntos associados**

---

## 🚀 Performance

### Índices Criados (Migration 016)
- `idx_question_sets_company` - Filtragem por empresa
- `idx_question_sets_job` - Filtragem por vaga
- `idx_question_sets_template` - Filtragem por template
- `idx_question_sets_set_order` - Ordenação de perguntas
- `idx_question_sets_type` - Filtragem por tipo

### Índices Adicionais (Migration 017)
- `idx_interview_questions_origin` - Estatísticas de origem
- `idx_question_sets_created` - Ordenação por data de criação

### Triggers
- `trigger_update_question_sets_updated_at` - Auto-atualização de `updated_at`
- `trigger_update_interview_questions_updated_at` - Auto-atualização de `updated_at`

### Views Materializadas
As 5 views criadas são **views regulares** (não materializadas) para garantir dados em tempo real. Para grandes volumes (10k+ conjuntos), considerar materialização com refresh automático.

---

## 🔄 Integração com IA

### Serviço: `openRouterService.gerarPerguntasEntrevista()`

**Localização:** `backend/src/servicos/openRouterService.js`

**Função:**
```javascript
async function gerarPerguntasEntrevista(vaga, curriculo) {
  // Gera array de perguntas via x-ai/grok-4.1-fast
  // Retorna: [{ tipo: 'technical', pergunta: '...' }, ...]
}
```

**Mapeamento de tipos:**
- IA retorna: `"técnica"` → Backend mapeia para `"technical"`
- IA retorna: `"comportamental"` → Backend mapeia para `"behavioral"`
- IA retorna: `"situacional"` → Backend mapeia para `"situational"`
- IA retorna: `"cultural"` → Backend mapeia para `"cultural"`
- IA retorna: outros → Backend usa `"general"`

**Fluxo:**
1. Cliente envia `POST /interview-question-sets` com `generate_via_ai: true`
2. Backend busca dados da vaga (`jobs` table)
3. Backend busca dados do currículo (`resumes` table, se `resume_id` fornecido)
4. Backend chama `gerarPerguntasEntrevista(vaga, curriculo)`
5. IA retorna array de perguntas
6. Backend cria conjunto + perguntas com `origin: 'ai_generated'`
7. Retorna conjunto criado para o cliente

---

## 📝 Exemplos de Uso

### Exemplo 1: Criar Template Reutilizável

```http
POST /api/interview-question-sets
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Template - Desenvolvedor Full Stack",
  "description": "Perguntas padrão para entrevistas de full stack",
  "is_template": true,
  "questions": [
    {
      "type": "technical",
      "text": "Como você estrutura uma aplicação React moderna?",
      "order": 1
    },
    {
      "type": "technical",
      "text": "Explique o conceito de state management e quando usar Redux vs Context API.",
      "order": 2
    },
    {
      "type": "behavioral",
      "text": "Conte sobre uma vez que você teve que refatorar código legado. Qual foi a abordagem?",
      "order": 3
    }
  ]
}
```

### Exemplo 2: Gerar Perguntas via IA para Vaga Específica

```http
POST /api/interview-question-sets
Authorization: Bearer <token>
Content-Type: application/json

{
  "job_id": "abc-123-def-456",
  "title": "Perguntas - Vaga Backend Sênior XYZ",
  "description": "Geradas automaticamente pela IA com base na descrição da vaga",
  "is_template": false,
  "generate_via_ai": true
}
```

**Resposta esperada:**
```json
{
  "success": true,
  "message": "Conjunto de perguntas criado com sucesso",
  "data": {
    "id": "uuid",
    "title": "Perguntas - Vaga Backend Sênior XYZ",
    "questions": [
      {
        "id": "uuid",
        "text": "Como você garante a escalabilidade de APIs REST?",
        "type": "technical",
        "order": 1,
        "origin": "ai_generated"
      },
      {
        "id": "uuid",
        "text": "Explique sua experiência com microsserviços e event-driven architecture.",
        "type": "technical",
        "order": 2,
        "origin": "ai_generated"
      }
    ]
  }
}
```

### Exemplo 3: Editar Perguntas de um Conjunto

```http
PUT /api/interview-question-sets/abc-123-def-456
Authorization: Bearer <token>
Content-Type: application/json

{
  "questions": [
    {
      "id": "pergunta-uuid-1",
      "text": "Como você garante a escalabilidade de APIs REST? Fale sobre caching, rate limiting e load balancing.",
      "order": 1
    }
  ]
}
```

**Resultado:**
- Pergunta com `id` existente é **atualizada**
- Campo `origin` vira `"ai_edited"` (se era `ai_generated`) ou mantém `"manual"`
- Campo `updated_at` é atualizado automaticamente via trigger

### Exemplo 4: Listar Templates e Duplicar para Nova Vaga

**Passo 1: Buscar templates**
```http
GET /api/interview-question-sets?is_template=true
Authorization: Bearer <token>
```

**Passo 2: Duplicar template**
```http
POST /api/interview-question-sets
Authorization: Bearer <token>
Content-Type: application/json

{
  "job_id": "nova-vaga-uuid",
  "title": "Perguntas - Vaga Frontend React (baseado em template)",
  "description": "Adaptado do template Full Stack",
  "is_template": false,
  "questions": [
    // Copiar perguntas do template retornado no passo 1
  ]
}
```

---

## 📚 Boas Práticas

### Para Recrutadores

1. **Use Templates:**
   - Crie templates para cargos recorrentes
   - Marque `is_template: true` para reutilização
   - Mantenha 8-12 perguntas por template (balanceado)

2. **Categorize Perguntas:**
   - Mix de tipos: 50% technical, 30% behavioral, 20% outros
   - Use `order` para controlar fluxo da entrevista
   - Comece com perguntas mais fáceis (warm-up)

3. **IA como Assistente:**
   - Gere perguntas via IA para economizar tempo
   - **Sempre revise e edite** perguntas geradas
   - Combine IA + perguntas manuais para personalização

4. **Não Delete Indiscriminadamente:**
   - Perguntas usadas em entrevistas **não podem ser deletadas** (preservação de histórico)
   - Use soft delete para manter auditoria
   - Prefira editar ao invés de deletar

### Para Desenvolvedores

1. **Multitenant:**
   - **Sempre** filtre por `company_id` em queries
   - Valide `company_id` do token JWT
   - Nunca exponha dados cross-company

2. **Performance:**
   - Use índices criados (company_id, job_id, type)
   - Limite paginação a max 100 itens
   - Views são real-time (não materializadas)

3. **Soft Delete:**
   - Nunca DELETE físico de `interview_questions` ou `interview_question_sets`
   - Use `deleted_at IS NULL` em WHERE clauses
   - Preserve histórico para auditoria

4. **IA:**
   - Trate timeouts (OpenRouter pode demorar 5-10s)
   - Valide formato retornado pela IA
   - Fallback: se IA falhar, permita criação manual

---

## 🐛 Troubleshooting

### Problema: Perguntas não aparecem após criação

**Causa:** Soft delete (`deleted_at IS NOT NULL`)

**Solução:**
```sql
SELECT * FROM interview_questions WHERE set_id = 'xxx' AND deleted_at IS NULL;
```

### Problema: Não consigo deletar uma pergunta

**Causa:** Pergunta vinculada a entrevista realizada (`interview_id IS NOT NULL`)

**Solução:**
- Perguntas usadas **não podem ser deletadas** por design
- Crie uma nova versão do conjunto ao invés de editar

### Problema: IA demora muito para gerar perguntas

**Causa:** OpenRouter/Grok pode levar 5-15s dependendo da complexidade

**Solução:**
- Implemente loading state no frontend
- Configure timeout de 30s no backend
- Considere cache de perguntas por vaga (feature futura)

### Problema: Métricas retornam `null`

**Causa:** Nenhum dado na tabela (`AVG(0)` retorna `null`)

**Solução:**
- Normalizar `null` para `0` no frontend
- Criar seed data para testes (migration seed)

---

## 🔜 Roadmap Futuro (Fora do MVP)

- [ ] **RF5 - Transcrição de Áudio:** Integrar perguntas com transcrição de respostas
- [ ] **RF6 - Avaliação em Tempo Real:** Avaliar respostas do candidato usando as perguntas do conjunto
- [ ] **Cache de Perguntas IA:** Evitar regerar perguntas idênticas para mesma vaga
- [ ] **Import/Export:** Exportar conjuntos como JSON/CSV para backup
- [ ] **Versionamento:** Histórico de mudanças em perguntas (tipo git diff)
- [ ] **Colaboração:** Múltiplos recrutadores editando mesmo conjunto
- [ ] **Tags/Categorias:** Além de `type`, adicionar tags customizadas
- [ ] **Perguntas de Followup:** Perguntas dinâmicas baseadas em resposta anterior

---

## 📊 Resumo de Implementação

| Item | Status | Detalhes |
|------|--------|----------|
| **Migration 016** | ✅ Aplicada | `interview_question_sets` + 6 colunas novas em `interview_questions` |
| **Migration 017** | ✅ Aplicada | 5 views + função `get_question_set_metrics()` |
| **CRUD Endpoints** | ✅ Implementados | 6 endpoints (GET, GET/:id, POST, PUT, DELETE x2) |
| **Métricas Dashboard** | ✅ Implementados | 3 endpoints (metrics, editing-stats, by-job) |
| **Testes HTTP** | ✅ Criados | 50+ requests em `RF3_QUESTIONS_API_COLLECTION.http` |
| **Documentação** | ✅ Completa | Este arquivo |
| **Validação Real** | ⏳ Pendente | Executar requests contra servidor real |

---

## 🎯 Checklist de Validação

- [ ] Aplicar migration 016 em produção
- [ ] Aplicar migration 017 em produção
- [ ] Testar criação manual de conjuntos
- [ ] Testar geração via IA (com e sem currículo)
- [ ] Testar edição de perguntas
- [ ] Testar soft delete (conjunto e perguntas)
- [ ] Validar filtros e paginação
- [ ] Validar métricas do dashboard
- [ ] Testar isolamento multitenant (2 empresas diferentes)
- [ ] Validar permissões de roles
- [ ] Medir performance (< 500ms para listagem, < 10s para IA)
- [ ] Verificar logs de auditoria

---

**Data:** 22/11/2025  
**Versão:** 1.0  
**Responsável:** Time de Desenvolvimento TalentMatchIA
