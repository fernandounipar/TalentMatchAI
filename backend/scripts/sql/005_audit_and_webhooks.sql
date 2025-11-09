-- Tabelas operacionais multi-tenant
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- audit_logs: registra ações do usuário no escopo da company
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  company_id UUID NOT NULL,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  diff JSONB,
  ip INET,
  ua TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  CONSTRAINT audit_logs_company_fk FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_company_created ON audit_logs(company_id, created_at DESC);

-- webhooks_logs: registros de eventos externos por tenant
CREATE TABLE IF NOT EXISTS webhooks_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL,
  provider TEXT NOT NULL,
  event TEXT NOT NULL,
  payload JSONB,
  status INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  CONSTRAINT webhooks_logs_company_fk FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_webhooks_company_created ON webhooks_logs(company_id, created_at DESC);

