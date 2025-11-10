-- Políticas RLS opcionais (não habilitadas por padrão)
-- Para ativar em produção, executar manualmente:
--   ALTER TABLE <tabela> ENABLE ROW LEVEL SECURITY;
--   ALTER TABLE <tabela> FORCE ROW LEVEL SECURITY; -- opcional
-- E na aplicação, setar por sessão/conexão: set_config('app.tenant_id','<uuid>', true)

-- Criação opcional de políticas RLS com detecção de versão
DO $$
DECLARE
  vver INT := current_setting('server_version_num')::INT;
BEGIN
  -- Se PostgreSQL não suportar RLS (antes de 9.5), apenas ignore
  IF vver < 90500 THEN
    RAISE NOTICE 'RLS não suportado nesta versão (server_version_num=%). Pulando 006_rls.sql', vver;
    RETURN;
  END IF;

  -- Para cada tabela abaixo, cria a policy se ainda não existir
  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'usuarios' AND policyname = 'tenant_isolation_usuarios';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_usuarios ON usuarios USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'vagas' AND policyname = 'tenant_isolation_vagas';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_vagas ON vagas USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'candidatos' AND policyname = 'tenant_isolation_candidatos';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_candidatos ON candidatos USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'curriculos' AND policyname = 'tenant_isolation_curriculos';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_curriculos ON curriculos USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'entrevistas' AND policyname = 'tenant_isolation_entrevistas';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_entrevistas ON entrevistas USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'perguntas' AND policyname = 'tenant_isolation_perguntas';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_perguntas ON perguntas USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'relatorios' AND policyname = 'tenant_isolation_relatorios';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_relatorios ON relatorios USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'mensagens' AND policyname = 'tenant_isolation_mensagens';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_mensagens ON mensagens USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'audit_logs' AND policyname = 'tenant_isolation_audit_logs';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_audit_logs ON audit_logs USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

  PERFORM 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'webhooks_logs' AND policyname = 'tenant_isolation_webhooks';
  IF NOT FOUND THEN
    EXECUTE 'CREATE POLICY tenant_isolation_webhooks ON webhooks_logs USING (company_id = current_setting(''app.tenant_id'', true)::uuid)';
  END IF;

EXCEPTION
  WHEN undefined_table OR undefined_column THEN
    -- Se alguma tabela não existir, ignore silenciosamente (compat com ambientes que não usam legado)
    NULL;
END $$ LANGUAGE plpgsql;
