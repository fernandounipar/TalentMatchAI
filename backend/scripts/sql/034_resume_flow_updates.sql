-- ============================================================================
-- Migration 034: Updates for Resume Flow
-- ============================================================================

BEGIN;

-- 1) Garantir que candidaturas tem coluna status e suporta os novos valores
-- Como é TEXT, já suporta, mas vamos garantir índices se necessário
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'candidaturas' AND column_name = 'status'
  ) THEN
    ALTER TABLE candidaturas ADD COLUMN status TEXT DEFAULT 'open';
  END IF;
END $$;

-- Criar índice para filtrar candidaturas por status (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname='public' AND c.relname='idx_candidaturas_status'
  ) THEN
    CREATE INDEX idx_candidaturas_status ON candidaturas(status);
  END IF;
END $$;

-- 2) Garantir que entrevistas tem application_id (vinculo com candidatura)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'entrevistas' AND column_name = 'application_id'
  ) THEN
    ALTER TABLE entrevistas ADD COLUMN application_id UUID REFERENCES candidaturas(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 3) Garantir tabela de mensagens de entrevista (caso 030/033 não tenham rodado perfeitamente ou para reforço)
CREATE TABLE IF NOT EXISTS mensagens_entrevista (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  interview_id UUID NOT NULL REFERENCES entrevistas(id) ON DELETE CASCADE,
  sender TEXT NOT NULL CHECK (sender IN ('user','assistant','system')),
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 4) Garantir tabela de perguntas de entrevista
CREATE TABLE IF NOT EXISTS perguntas_entrevista (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  interview_id UUID NOT NULL REFERENCES entrevistas(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  "order" INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  deleted_at TIMESTAMP
);

COMMIT;
