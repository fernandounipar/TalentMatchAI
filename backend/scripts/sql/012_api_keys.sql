-- 012_api_keys.sql
-- Tabela de API Keys multi-tenant (company_id + user_id)

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  label TEXT,
  token TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  last_used_at TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT true
);

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_api_keys_company_provider
    ON api_keys(company_id, provider, created_at DESC);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

COMMENT ON TABLE api_keys IS 'API Keys por tenant/usuário, escopo multi-tenant';
COMMENT ON COLUMN api_keys.token IS 'Segredo da API key (sensível, proteger em produção)';

