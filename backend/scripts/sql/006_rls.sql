-- Políticas RLS opcionais (não habilitadas por padrão)
-- Para ativar em produção, executar manualmente:
--   ALTER TABLE <tabela> ENABLE ROW LEVEL SECURITY;
--   ALTER TABLE <tabela> FORCE ROW LEVEL SECURITY; -- opcional
-- E na aplicação, setar por sessão/conexão: set_config('app.tenant_id','<uuid>', true)

DO $$ BEGIN
  -- Cria políticas nas tabelas de negócio; compatível com PostgreSQL < 16 (sem IF NOT EXISTS)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'usuarios' AND policyname = 'tenant_isolation_usuarios'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_usuarios ON usuarios USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'vagas' AND policyname = 'tenant_isolation_vagas'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_vagas ON vagas USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'candidatos' AND policyname = 'tenant_isolation_candidatos'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_candidatos ON candidatos USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'curriculos' AND policyname = 'tenant_isolation_curriculos'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_curriculos ON curriculos USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'entrevistas' AND policyname = 'tenant_isolation_entrevistas'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_entrevistas ON entrevistas USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'perguntas' AND policyname = 'tenant_isolation_perguntas'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_perguntas ON perguntas USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'relatorios' AND policyname = 'tenant_isolation_relatorios'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_relatorios ON relatorios USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'mensagens' AND policyname = 'tenant_isolation_mensagens'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_mensagens ON mensagens USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'audit_logs' AND policyname = 'tenant_isolation_audit_logs'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_audit_logs ON audit_logs USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'webhooks_logs' AND policyname = 'tenant_isolation_webhooks'
  ) THEN
    EXECUTE $pol$CREATE POLICY tenant_isolation_webhooks ON webhooks_logs USING (company_id = current_setting('app.tenant_id', true)::uuid)$pol$;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
