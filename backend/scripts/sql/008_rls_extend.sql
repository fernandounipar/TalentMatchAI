-- Extensão das políticas RLS para as novas tabelas (opcionais)
-- Só efetivas quando RLS for habilitado por tabela

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='users' AND policyname='tenant_isolation_users'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_users ON users USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='sessions' AND policyname='tenant_isolation_sessions'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_sessions ON sessions USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='refresh_tokens' AND policyname='tenant_isolation_refresh_tokens'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_refresh_tokens ON refresh_tokens USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='password_resets' AND policyname='tenant_isolation_password_resets'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_password_resets ON password_resets USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='files' AND policyname='tenant_isolation_files'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_files ON files USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='jobs' AND policyname='tenant_isolation_jobs'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_jobs ON jobs USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='candidates' AND policyname='tenant_isolation_candidates'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_candidates ON candidates USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='applications' AND policyname='tenant_isolation_applications'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_applications ON applications USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='application_status_history' AND policyname='tenant_isolation_application_status_history'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_application_status_history ON application_status_history USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='notes' AND policyname='tenant_isolation_notes'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_notes ON notes USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='resumes' AND policyname='tenant_isolation_resumes'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_resumes ON resumes USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='skills' AND policyname='tenant_isolation_skills'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_skills ON skills USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='experiences' AND policyname='tenant_isolation_experiences'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_experiences ON experiences USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='educations' AND policyname='tenant_isolation_educations'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_educations ON educations USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='interviews' AND policyname='tenant_isolation_interviews'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_interviews ON interviews USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='interview_sessions' AND policyname='tenant_isolation_interview_sessions'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_interview_sessions ON interview_sessions USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='interview_questions' AND policyname='tenant_isolation_interview_questions'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_interview_questions ON interview_questions USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='interview_answers' AND policyname='tenant_isolation_interview_answers'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_interview_answers ON interview_answers USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='ai_feedback' AND policyname='tenant_isolation_ai_feedback'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_ai_feedback ON ai_feedback USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='interview_reports' AND policyname='tenant_isolation_interview_reports'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_interview_reports ON interview_reports USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='github_profiles' AND policyname='tenant_isolation_github_profiles'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_github_profiles ON github_profiles USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='github_repositories' AND policyname='tenant_isolation_github_repositories'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_github_repositories ON github_repositories USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='tags' AND policyname='tenant_isolation_tags'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_tags ON tags USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='pipelines' AND policyname='tenant_isolation_pipelines'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_pipelines ON pipelines USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='pipeline_stages' AND policyname='tenant_isolation_pipeline_stages'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_pipeline_stages ON pipeline_stages USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='application_stages' AND policyname='tenant_isolation_application_stages'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_application_stages ON application_stages USING (EXISTS (SELECT 1 FROM applications a JOIN pipeline_stages s ON s.id = application_stages.stage_id WHERE a.id = application_stages.application_id AND a.company_id = current_setting('app.tenant_id', true)::uuid AND s.company_id = current_setting('app.tenant_id', true)::uuid))$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='notifications' AND policyname='tenant_isolation_notifications'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_notifications ON notifications USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='calendar_events' AND policyname='tenant_isolation_calendar_events'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_calendar_events ON calendar_events USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='webhooks_endpoints' AND policyname='tenant_isolation_webhooks_endpoints'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_webhooks_endpoints ON webhooks_endpoints USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='webhooks_events' AND policyname='tenant_isolation_webhooks_events'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_webhooks_events ON webhooks_events USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='ingestion_jobs' AND policyname='tenant_isolation_ingestion_jobs'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_ingestion_jobs ON ingestion_jobs USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='transcriptions' AND policyname='tenant_isolation_transcriptions'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_transcriptions ON transcriptions USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
