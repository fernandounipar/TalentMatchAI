-- Harmoniza colunas da tabela companies para (type, document, name)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='type'
  ) THEN
    ALTER TABLE companies ADD COLUMN type TEXT;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='document'
  ) THEN
    ALTER TABLE companies ADD COLUMN document TEXT;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='name'
  ) THEN
    ALTER TABLE companies ADD COLUMN name TEXT;
  END IF;
END $$;

-- Copia dados das colunas antigas, se existirem
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='tipo') THEN
    UPDATE companies SET type = COALESCE(type, CASE WHEN tipo IN ('CPF','CNPJ') THEN tipo ELSE NULL END);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='documento') THEN
    UPDATE companies SET document = COALESCE(document, documento);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='nome') THEN
    UPDATE companies SET name = COALESCE(name, nome);
  END IF;
END $$;

-- Restrições e unicidades
DO $$ BEGIN
  -- Garante NOT NULL quando possível (apenas se não houver nulos)
  IF EXISTS (SELECT 1 FROM companies WHERE type IS NULL) = FALSE THEN
    ALTER TABLE companies ALTER COLUMN type SET NOT NULL;
  END IF;
EXCEPTION WHEN others THEN NULL; END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM companies WHERE document IS NULL) = FALSE THEN
    ALTER TABLE companies ALTER COLUMN document SET NOT NULL;
  END IF;
EXCEPTION WHEN others THEN NULL; END $$;

-- Check de tipo
DO $$ BEGIN
  ALTER TABLE companies DROP CONSTRAINT IF EXISTS companies_type_check;
  ALTER TABLE companies ADD CONSTRAINT companies_type_check CHECK (type IN ('CPF','CNPJ'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Unicidade de documento
DO $$ BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uniq_companies_document ON companies(document);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Opcional: remover colunas antigas (comente se quiser manter)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='tipo') THEN
    ALTER TABLE companies DROP COLUMN tipo;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='documento') THEN
    ALTER TABLE companies DROP COLUMN documento;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='companies' AND column_name='nome') THEN
    ALTER TABLE companies DROP COLUMN nome;
  END IF;
END $$;

