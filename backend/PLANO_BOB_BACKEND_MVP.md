# Plano Bob — Backend MVP (pente-fino)

## Pendências de RFs (backend)
- CRUDs MVP exigidos ainda não padronizados: vagas (/api/jobs sem alias /vagas e bug no /search), candidatos (campos mistos pt/en), aplicações (falta PUT/DELETE), entrevistas (features de IA estão no legado /api/entrevistas; /api/interviews só agenda), currículos (não existe /api/curriculos/upload; /api/resumes só lida com metadados), relatórios (rotas atuais quebradas), dashboard (exposição gigante via views; precisa versão enxuta para KPIs do MVP).
- RFs de segurança/instrumentação pendentes: helmet, rate limiting global, validação de entrada, tratamento centralizado de erros, sanitização.

## Mapa atual de rotas (server.js → src/api/index.js)
- `/api/auth` → OK (autenticacaoService, JWT, refresh).
- `/api/user` → OK parcial (empresa/me/profile/avatar). Usa autenticacaoService + db.
- `/api/usuarios` → CRUD admin de usuários multi-tenant. OK.
- `/api/jobs` → CRUD de vagas com filtros/paginação. Falta alias /vagas, corrigir ordem do `/search` (hoje vem após `/:id` e nunca é alcançado), padronizar status/DTO.
- `/api/candidates` → CRUD + skills; retorna campos em pt (nome) e en (full_name). Também recebe `/api/candidates/:id/github` (rotas github.js).
- `/api/applications` → Criar/listar/mover estágio + histórico/notes. Não há PUT/DELETE padrão nem listagem com filtros avançados.
- `/api/interviews` → Agenda/edita/deleta entrevistas (novo domínio). Não gera perguntas/chat/relatório.
- `/api/entrevistas` → Legado (tabelas vagas/curriculos/perguntas/relatorios/mensagens). Único lugar com geração de perguntas, chat e relatório. Precisa migrar para o domínio novo ou remover.
- `/api/resumes` → Lista/CRUD metadados + reanálise; falta upload multipart (/curriculos/upload inexistente) e ingestão de arquivo.
- `/api/files` → Upload genérico autenticado (salva em `files` + disco).
- `/api/ingestion` → GET de ingestion_jobs por id.
- `/api/dashboard` → Grande conjunto de métricas (jobs/resumes/question-sets/assessments/reports/interviews/users/overview). Depende de várias views/functions SQL; avaliar escopo MVP.
- `/api/historico` → Timeline mistura tabelas novas (interviews, ingestion) e legadas (entrevistas, relatorios antigos).
- `/api/companies`, `/api/skills`, `/api/api-keys`, `/jobs/:jobId/pipeline` (pipelines), `/files` → usados pontualmente.
- **Quebrados**: `/api/interview-question-sets`, `/api/live-assessments`, `/api/reports` importam middlewares inexistentes (`authMiddleware`, `permissoes`) e criam pools próprios; hoje derrubam o server ao requerir. Precisam ser reescritos ou removidos do index.

## Controladores/serviços/modelos
- Em uso: `servicos/autenticacaoService.js`, `servicos/iaService.js` (OpenAI/OpenRouter), `servicos/openRouterService.js`, `servicos/githubService.js`, `servicos/documento.js` + `servicos/validacao.js` (duplicados), middlewares `autenticacao.js`, `tenant.js`, `audit.js`, `company.js`, `lgpd.js`, config `config/database.js`.
- Legado/sem referência: `controladores/*`, `modelos/*`, `servicos/analiseCurriculoService.js`, `servicos/openAIService.js`, middlewares ausentes referenciados (`authMiddleware`, `permissoes`).
- Migração necessária: lógicas de IA/chat/relatório em `api/rotas/entrevistas.js` devem ir para o domínio novo de entrevistas; `dashboard.js` deve ser fatiado em agregações essenciais; `resumes.js` precisa incorporar upload/parse; `jobs.js` corrigir rota `/search` e alinhar DTO; `api/index.js` precisa deixar de montar rotas quebradas.

## Padrão por domínio (proposto)
Estrutura alvo em `src/domains/<dominio>/{modelo,servico,controlador,rotas}.js`:
- `auth`: fluxos atuais de login/register/refresh/logout/forgot/reset/change + me.
- `usuarios`: CRUD/admin + convite; unificar com `/api/user` (me/avatar/profile) em um único controller/rotas.
- `vagas`: mover `api/rotas/jobs.js` → `domains/vagas`, corrigir `/search`, adicionar alias `/api/vagas`.
- `candidatos`: mover `api/rotas/candidates.js` e GitHub integration; normalizar DTO/nomes.
- `aplicacoes`: mover `api/rotas/applications.js` + pipelines; completar PUT/DELETE padrão e enums de stage/status.
- `entrevistas`: fundir `api/rotas/interviews.js` (agenda) com IA/chat/perguntas/relatorio do legado; expor em `/api/entrevistas` e `/api/interviews`.
- `curriculos`/`resumes`: upload multipart + parse + análise (RF1) em um fluxo único; usar `files`/`ingestion` apenas como plumbing interno.
- `relatorios`: novo controller para RF7 baseado em `interview_reports`; descartar rota quebrada atual.
- `dashboard`: reduzir a um controller com KPIs do MVP (vagas, candidatos, curriculos, entrevistas, relatorios) + timelines simples; demais views ficam fora do MVP.

### Task de limpeza (instrução para Alex)
- **Pode apagar/desregistrar**: `src/controladores/*`, `src/modelos/*`, `src/servicos/analiseCurriculoService.js`, `src/servicos/openAIService.js`, rotas quebradas (`api/rotas/interview-question-sets.js`, `api/rotas/live-assessments.js`, `api/rotas/reports.js`) até haver reimplementação, `minimal_server.js`/`test_server.js` se não usados.
- **Migrar/refatorar**: 
  - `api/rotas/entrevistas.js` → mover geração de perguntas/chat/relatório para o domínio `entrevistas` novo e depois remover tabelas legadas.
  - `api/rotas/jobs.js` → corrigir ordem das rotas (`/search` antes de `/:id`), padronizar status/DTO e criar alias `/api/vagas`.
  - `api/rotas/candidates.js` → alinhar campos (full_name/email/phone/linkedin/github/skills[]) e soft delete.
  - `api/rotas/applications.js` → adicionar GET detail/PUT/DELETE e enum de status/stage; garantir audit.
  - `api/rotas/interviews.js` → incluir geração de perguntas/chat/relatorio/notes; remover dependência de tabelas legadas.
  - `api/rotas/resumes.js` → incluir upload multipart + parse + vínculo com candidates/jobs; expor `/api/curriculos/upload`.
  - `api/rotas/dashboard.js` → recortar para KPIs essenciais do MVP e remover dependências de views secundárias.
  - `api/index.js` → registrar apenas rotas estáveis; isolar rotas legacy em namespace separado ou remover.

## APIs oficiais (MVP)
- **Envelope**: sucesso `{ data, meta? }`; erro `{ error: { code, message, details? } }`. Paginação: `meta: { page, limit, total, total_pages }`.
- **Auth/Users**: `/api/auth/*` (já feitos). `/api/usuarios` CRUD admin. `/api/user/me|profile|avatar` integrar ao mesmo domínio e payload `{ id, company_id, full_name, email, role, foto_url }`.
- **Vagas** (`/api/vagas` alias `/api/jobs`): fields `{ id, company_id, title, description, requirements, status: draft|open|paused|closed, seniority?, location_type?, is_remote, salary_min?, salary_max?, contract_type?, department?, unit?, skills_required: [], benefits: [], published_at?, closed_at?, created_at, updated_at, created_by?, updated_by?, candidates_count }`.
- **Candidatos** (`/api/candidatos` alias `/api/candidates`): `{ id, company_id, full_name, email, phone?, linkedin_url?, github_url?, skills: [{id,name,level?}], created_at, updated_at }`.
- **Aplicacoes** (`/api/aplicacoes` alias `/api/applications`): `{ id, company_id, job_id, candidate_id, stage, status: open|in_review|offer|closed, notes?, created_at, updated_at, history?[] }`. Endpoints: POST, GET list/detail, PUT (update stage/status/notes), DELETE (soft).
- **Entrevistas** (`/api/entrevistas` alias `/api/interviews`): `{ id, company_id, application_id, job_id, candidate_id, scheduled_at, ends_at?, mode: online|on_site, status: scheduled|completed|cancelled|no_show, result: approved|rejected|pending, overall_score?, interviewer_id?, notes?, metadata? }` + subrotas `/:id/perguntas`, `/:id/chat`, `/:id/relatorio`.
- **Curriculos** (`/api/curriculos` alias `/api/resumes`): upload multipart `file` + `job_id?` + `candidate_id?`; response `{ id, file_id, candidate_id, job_id?, original_filename, mime_type, size, status: pending|reviewed|accepted|rejected, parsed_text?, analysis:last? }`; reanálise `POST /:id/analyze`.
- **Relatorios** (`/api/relatorios`): baseado em `interview_reports` com `{ id, interview_id, title, summary_text, recommendation: APPROVE|MAYBE|REJECT|PENDING, strengths[], weaknesses[], risks[], overall_score?, content, created_at, version }`.
- **Dashboard** (`/api/dashboard`): mínimo `{ vagas, curriculos, entrevistas, relatorios, candidatos }` + timelines simples (resumes, jobs, interviews) com filtros por `days`.

## Multitenant, segurança e padrões cross-cutting
- **company_id em tudo**: JWT → `req.usuario { id, company_id, role }`; todas as queries filtram por `company_id` e têm índice em `company_id`. Evitar pools próprios; usar `config/database.js` para herdar RLS/set_config.
- **Auth/role**: manter `exigirAutenticacao` e criar `autorizacao(role[])` reutilizável (ADMIN, RECRUITER, USER). Substituir middlewares ausentes (`authMiddleware`, `permissoes`) por este padrão.
- **Erros/validação**: middleware de erro central (`next(err)` → `{ error: { code, message, details } }`), validação com Joi/Yup por rota, sanitização básica e helmet + rate limit global.
- **Respostas**: padronizar data/meta, nunca misturar pt/en em campos; preferir snake_case no banco e camelCase no payload.

## Checklist de banco para David
- **Tabelas necessárias (MVP)**: companies, users (com company_id, role, foto_url, invitation_*), refresh_tokens, password_resets, api_keys, audit_logs; jobs + job_revisions; skills + candidate_skills; candidates; files; resumes (+ resume_analysis, resume_processing_stats opcional); ingestion_jobs; pipelines + pipeline_stages; applications + application_stages + application_status_history + notes; interviews + interview_sessions + calendar_events; interview_questions/answers opcional para chat; interview_reports.
- **Legacy/sobrando**: tabelas em pt (`vagas`, `candidatos`, `curriculos`, `entrevistas`, `perguntas`, `relatorios`, `mensagens`) podem ser mantidas só para migração de dados e depois drop; views auxiliares de dashboard fora do MVP podem ser desativadas.
- **Ajustes**: garantir `company_id` NOT NULL + índice em todas as tabelas do MVP, colunas `created_at/updated_at/deleted_at`, enums coerentes para status/stage/result, FK ON DELETE SET NULL/RESTRICT onde aplicável, índices para filtros frequentes (status, job_id, candidate_id, created_at). Validar que funções `get_*` usadas pelo dashboard recebem `company_id` como parâmetro.
