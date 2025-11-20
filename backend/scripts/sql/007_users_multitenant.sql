-- 007_users_multitenant.sql
-- Núcleo de identidade/segurança + domínio de recrutamento, multi-tenant por company_id
-- Pré-requisitos: 004_multitenant.sql já criou companies(id) e adicionou company_id nas tabelas existentes

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Função utilitária para updated_at automático
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- USERS (núcleo de identidade)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('USER','ADMIN','SUPER_ADMIN')) DEFAULT 'USER',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- Unicidade de email por empresa
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_users_company_email ON users(company_id, lower(email));
EXCEPTION WHEN duplicate_table THEN NULL; WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_users_company_created ON users(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TRIGGER trg_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- SESSIONS / REFRESH TOKENS
CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ip INET,
  ua TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  revoked_at TIMESTAMP
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_sessions_company_user ON sessions(company_id, user_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP
);
DO $idx$ BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind = 'i'
       AND c.relname = 'uniq_refresh_token_hash'
       AND n.nspname = 'public'
  ) THEN
    CREATE UNIQUE INDEX uniq_refresh_token_hash ON refresh_tokens(token_hash);
  END IF;
END $idx$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_refresh_company_user ON refresh_tokens(company_id, user_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- PASSWORD RESETS
CREATE TABLE IF NOT EXISTS password_resets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP
);
DO $idx$ BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind = 'i'
       AND c.relname = 'uniq_password_resets_token'
       AND n.nspname = 'public'
  ) THEN
    CREATE UNIQUE INDEX uniq_password_resets_token ON password_resets(token_hash);
  END IF;
END $idx$;

-- AUDIT LOGS (trilha de auditoria)
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  action TEXT NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_audit_company_created ON audit_logs(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- WEBHOOKS ENDPOINTS / EVENTS
CREATE TABLE IF NOT EXISTS webhooks_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  secret TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_webhooks_endpoints_company ON webhooks_endpoints(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS webhooks_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  entity TEXT,
  entity_id TEXT,
  payload JSONB,
  status INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  delivered_at TIMESTAMP
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_webhooks_events_company ON webhooks_events(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- FILES (metadados de arquivos)
CREATE TABLE IF NOT EXISTS files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  storage_key TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime TEXT,
  size BIGINT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $idx$ BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relkind = 'i'
       AND c.relname = 'uniq_files_company_storage'
       AND n.nspname = 'public'
  ) THEN
    CREATE UNIQUE INDEX uniq_files_company_storage ON files(company_id, storage_key);
  END IF;
END $idx$;

-- JOBS (vagas)
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  slug TEXT,
  description TEXT NOT NULL,
  requirements TEXT,
  seniority TEXT,
  location_type TEXT,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_jobs_company_slug ON jobs(company_id, lower(slug));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_jobs_company_status ON jobs(company_id, status);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_jobs_company_created ON jobs(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TRIGGER trg_jobs_updated BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- CANDIDATES
CREATE TABLE IF NOT EXISTS candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  linkedin TEXT,
  github_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_candidates_company_email ON candidates(company_id, lower(email));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_candidates_company_created ON candidates(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TRIGGER trg_candidates_updated BEFORE UPDATE ON candidates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- APPLICATIONS (candidaturas)
CREATE TABLE IF NOT EXISTS applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  source TEXT,
  stage TEXT,
  status TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_applications_company_job ON applications(company_id, job_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_applications_company_candidate ON applications(company_id, candidate_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TRIGGER trg_applications_updated BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- APPLICATION STATUS HISTORY
CREATE TABLE IF NOT EXISTS application_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT,
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_ash_company_application ON application_status_history(company_id, application_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- NOTES (anotações)
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  entity TEXT NOT NULL,
  entity_id UUID NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_notes_company_entity ON notes(company_id, entity, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- RESUMES (currículos) + skills/experiences/educations
CREATE TABLE IF NOT EXISTS resumes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  file_id UUID REFERENCES files(id) ON DELETE SET NULL,
  original_filename TEXT,
  parsed_text TEXT,
  parsed_json JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_resumes_company_candidate ON resumes(company_id, candidate_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_resumes_parsed_text_gin ON resumes USING gin (parsed_text gin_trgm_ops);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_resumes_parsed_json_gin ON resumes USING gin (parsed_json);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_skills_company_name ON skills(company_id, lower(name));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS candidate_skills (
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  level TEXT,
  PRIMARY KEY (candidate_id, skill_id)
);

CREATE TABLE IF NOT EXISTS job_skills (
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  must_have BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (job_id, skill_id)
);

CREATE TABLE IF NOT EXISTS experiences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  company_name TEXT,
  role TEXT,
  start_date DATE,
  end_date DATE,
  description TEXT
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_experiences_company_candidate ON experiences(company_id, candidate_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS educations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  institution TEXT,
  degree TEXT,
  start_date DATE,
  end_date DATE,
  description TEXT
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_educations_company_candidate ON educations(company_id, candidate_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ENTREVISTAS / Q&A / FEEDBACK
CREATE TABLE IF NOT EXISTS interviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMP,
  mode TEXT,
  status TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_interviews_company_app ON interviews(company_id, application_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS interview_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  interview_id UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  transcript_file_id UUID REFERENCES files(id) ON DELETE SET NULL
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_interview_sessions_company ON interview_sessions(company_id, interview_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS interview_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  interview_id UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  origin TEXT NOT NULL CHECK (origin IN ('AI','MANUAL')),
  kind TEXT NOT NULL CHECK (kind IN ('TECNICA','COMPORTAMENTAL','SITUACIONAL')),
  prompt TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_interview_questions_company ON interview_questions(company_id, interview_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS interview_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES interview_questions(id) ON DELETE CASCADE,
  session_id UUID REFERENCES interview_sessions(id) ON DELETE SET NULL,
  raw_text TEXT,
  audio_file_id UUID REFERENCES files(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_interview_answers_company ON interview_answers(company_id, question_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS ai_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  answer_id UUID NOT NULL REFERENCES interview_answers(id) ON DELETE CASCADE,
  score NUMERIC,
  verdict TEXT CHECK (verdict IN ('FORTE','ADEQUADO','FRACO','INCONSISTENTE')),
  rationale_text TEXT,
  suggested_followups JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_ai_feedback_company ON ai_feedback(company_id, answer_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS interview_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  interview_id UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  summary_text TEXT,
  strengths JSONB,
  risks JSONB,
  recommendation TEXT CHECK (recommendation IN ('APROVAR','DÚVIDA','REPROVAR')),
  file_id UUID REFERENCES files(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_interview_reports_company ON interview_reports(company_id, interview_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- GITHUB PERFIS/REPOS
CREATE TABLE IF NOT EXISTS github_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  profile_url TEXT,
  fetched_at TIMESTAMP,
  stats JSONB
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_github_profile ON github_profiles(company_id, lower(username));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS github_repositories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES github_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  url TEXT,
  language TEXT,
  stars INTEGER,
  forks INTEGER,
  last_commit_at TIMESTAMP,
  metrics JSONB
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_github_repos_company ON github_repositories(company_id, profile_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- TAGS
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_tags_company_name ON tags(company_id, lower(name));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS job_tags (
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (job_id, tag_id)
);

CREATE TABLE IF NOT EXISTS candidate_tags (
  candidate_id UUID NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (candidate_id, tag_id)
);

-- PIPELINES
CREATE TABLE IF NOT EXISTS pipelines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  name TEXT NOT NULL
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_pipelines_company_job ON pipelines(company_id, job_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS pipeline_stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  position INTEGER NOT NULL
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_pipeline_stage_pos ON pipeline_stages(pipeline_id, position);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS application_stages (
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  stage_id UUID NOT NULL REFERENCES pipeline_stages(id) ON DELETE CASCADE,
  entered_at TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY (application_id, stage_id, entered_at)
);

-- NOTIFICAÇÕES / CALENDÁRIO
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  payload JSONB,
  read_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_notifications_company_user ON notifications(company_id, user_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  interview_id UUID REFERENCES interviews(id) ON DELETE SET NULL,
  ics_uid TEXT,
  starts_at TIMESTAMP NOT NULL,
  ends_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE UNIQUE INDEX uniq_calendar_ics ON calendar_events(company_id, ics_uid);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- LOGS de WEBHOOKs (já criado em 005, mantido aqui por compatibilidade)
CREATE TABLE IF NOT EXISTS webhooks_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  event TEXT NOT NULL,
  payload JSONB,
  status INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_webhooks_company_created ON webhooks_logs(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- INTEGRATION JOBS e TRANSCRIPTIONS
CREATE TABLE IF NOT EXISTS ingestion_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  entity TEXT,
  entity_id UUID,
  status TEXT,
  progress NUMERIC,
  metadata JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_ingestion_jobs_company ON ingestion_jobs(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TRIGGER trg_ingestion_jobs_updated BEFORE UPDATE ON ingestion_jobs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS transcriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  language TEXT,
  status TEXT,
  text TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_transcriptions_company ON transcriptions(company_id, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
