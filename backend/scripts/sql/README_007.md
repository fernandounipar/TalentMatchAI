# 007_users_multitenant.sql

Cria o núcleo de identidade/segurança (`users`, `sessions`, `refresh_tokens`, `password_resets`, `audit_logs`, `files`, `webhooks_endpoints`, `webhooks_events`) e o domínio de recrutamento/entrevistas (`jobs`, `candidates`, `applications`, `application_status_history`, `notes`, `resumes`, `skills`, `candidate_skills`, `job_skills`, `experiences`, `educations`, `interviews`, `interview_sessions`, `interview_questions`, `interview_answers`, `ai_feedback`, `interview_reports`, `tags`, `job_tags`, `candidate_tags`, `pipelines`, `pipeline_stages`, `application_stages`, `notifications`, `calendar_events`, `ingestion_jobs`, `transcriptions`).

- Todas as tabelas possuem `company_id` (FK → `companies.id`) para isolamento lógico multi-tenant.
- Índices compostos começando por `company_id` foram adicionados para performance.
- `updated_at` é mantido por gatilho (`set_updated_at`) nas tabelas relevantes.
- Extensões `pg_trgm`/`btree_gin` são usadas para busca em texto (`resumes.parsed_text`).

Execução:

- `npm run db:apply` (aplica todas as migrações em ordem)
- ou `node scripts/apply_single_migration.js 007_users_multitenant.sql`

RLS (opcional):

- Políticas adicionais estão em `008_rls_extend.sql`. Ative RLS por tabela com `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` e configure `set_config('app.tenant_id','<uuid>', true)` por sessão.
