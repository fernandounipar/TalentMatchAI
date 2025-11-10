-- Compatibiliza tabela refresh_tokens com serviço de autenticação
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='refresh_tokens' AND column_name='token'
  ) THEN
    ALTER TABLE refresh_tokens ADD COLUMN token TEXT;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='refresh_tokens' AND column_name='expires_at'
  ) THEN
    ALTER TABLE refresh_tokens ADD COLUMN expires_at TIMESTAMP;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='refresh_tokens' AND column_name='revoked_at'
  ) THEN
    ALTER TABLE refresh_tokens ADD COLUMN revoked_at TIMESTAMP;
  END IF;
END $$;

-- Alivia NOT NULL de company_id se existir e for NOT NULL (serviço infere via user)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='refresh_tokens' AND column_name='company_id'
  ) THEN
    ALTER TABLE refresh_tokens ALTER COLUMN company_id DROP NOT NULL;
  END IF;
EXCEPTION WHEN others THEN NULL; END $$;

-- Índice útil no token (não exclusivo, mas pode-se ajustar depois)
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

