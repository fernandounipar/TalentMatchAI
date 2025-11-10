-- Compatibiliza tabela password_resets com serviço de autenticação
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='password_resets' AND column_name='token'
  ) THEN
    ALTER TABLE password_resets ADD COLUMN token TEXT;
  END IF;
END $$;

-- Permite company_id nulo caso a coluna exista como NOT NULL
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='password_resets' AND column_name='company_id'
  ) THEN
    ALTER TABLE password_resets ALTER COLUMN company_id DROP NOT NULL;
  END IF;
EXCEPTION WHEN others THEN NULL; END $$;

-- Índice auxiliar
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_password_resets_token ON password_resets(token);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

