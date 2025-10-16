-- Multi-tenant: company_id em todas as tabelas e tabela companies
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo TEXT NOT NULL CHECK (tipo IN ('CPF','CNPJ')),
  documento TEXT NOT NULL UNIQUE,
  nome TEXT,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

-- Adicionar colunas company_id (se não existirem)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='usuarios' AND column_name='company_id'
  ) THEN
    ALTER TABLE usuarios ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='vagas' AND column_name='company_id'
  ) THEN
    ALTER TABLE vagas ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='candidatos' AND column_name='company_id'
  ) THEN
    ALTER TABLE candidatos ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='curriculos' AND column_name='company_id'
  ) THEN
    ALTER TABLE curriculos ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='entrevistas' AND column_name='company_id'
  ) THEN
    ALTER TABLE entrevistas ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='perguntas' AND column_name='company_id'
  ) THEN
    ALTER TABLE perguntas ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='relatorios' AND column_name='company_id'
  ) THEN
    ALTER TABLE relatorios ADD COLUMN company_id UUID;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='mensagens' AND column_name='company_id'
  ) THEN
    ALTER TABLE mensagens ADD COLUMN company_id UUID;
  END IF;
END $$;

-- Criar companhia padrão e popular company_id em registros existentes
DO $$
DECLARE
  default_company UUID;
BEGIN
  INSERT INTO companies (tipo, documento, nome)
  VALUES ('CNPJ','00000000000000','Default Company')
  ON CONFLICT (documento) DO UPDATE SET nome=EXCLUDED.nome
  RETURNING id INTO default_company;

  UPDATE usuarios SET company_id = COALESCE(company_id, default_company);
  UPDATE vagas SET company_id = COALESCE(company_id, default_company);
  UPDATE candidatos SET company_id = COALESCE(company_id, default_company);
  UPDATE curriculos SET company_id = COALESCE(company_id, default_company);
  UPDATE entrevistas SET company_id = COALESCE(company_id, default_company);
  UPDATE perguntas SET company_id = COALESCE(company_id, default_company);
  UPDATE relatorios SET company_id = COALESCE(company_id, default_company);
  UPDATE mensagens SET company_id = COALESCE(company_id, default_company);
END $$;

-- Vincular FKs e NOT NULL
ALTER TABLE usuarios    ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE vagas       ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE candidatos  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE curriculos  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE entrevistas ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE perguntas   ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE relatorios  ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE mensagens   ALTER COLUMN company_id SET NOT NULL;

DO $$ BEGIN
  ALTER TABLE usuarios    ADD CONSTRAINT usuarios_company_fk    FOREIGN KEY (company_id) REFERENCES companies(id)    ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE vagas       ADD CONSTRAINT vagas_company_fk       FOREIGN KEY (company_id) REFERENCES companies(id)       ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE candidatos  ADD CONSTRAINT candidatos_company_fk  FOREIGN KEY (company_id) REFERENCES companies(id)  ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE curriculos  ADD CONSTRAINT curriculos_company_fk  FOREIGN KEY (company_id) REFERENCES companies(id)  ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE entrevistas ADD CONSTRAINT entrevistas_company_fk FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE perguntas   ADD CONSTRAINT perguntas_company_fk   FOREIGN KEY (company_id) REFERENCES companies(id)   ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE relatorios  ADD CONSTRAINT relatorios_company_fk  FOREIGN KEY (company_id) REFERENCES companies(id)  ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE mensagens   ADD CONSTRAINT mensagens_company_fk   FOREIGN KEY (company_id) REFERENCES companies(id)   ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Ajustar unicidades para escopo da company
-- USUÁRIOS: email único por company
DO $$ BEGIN
  ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_email_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uniq_usuarios_company_email ON usuarios(company_id, lower(email));
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

-- CANDIDATOS: email/github únicos por company (permite NULL)
DO $$ BEGIN
  ALTER TABLE candidatos DROP CONSTRAINT IF EXISTS candidatos_email_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE candidatos DROP CONSTRAINT IF EXISTS candidatos_github_key;
EXCEPTION WHEN undefined_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uniq_candidatos_company_email ON candidatos(company_id, lower(email));
EXCEPTION WHEN duplicate_table THEN NULL; END $$;
DO $$ BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS uniq_candidatos_company_github ON candidatos(company_id, lower(github));
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

-- Índices por companhia para performance
CREATE INDEX IF NOT EXISTS idx_vagas_company ON vagas(company_id);
CREATE INDEX IF NOT EXISTS idx_candidatos_company ON candidatos(company_id);
CREATE INDEX IF NOT EXISTS idx_curriculos_company ON curriculos(company_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_company ON entrevistas(company_id);
CREATE INDEX IF NOT EXISTS idx_perguntas_company ON perguntas(company_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_company ON relatorios(company_id);
CREATE INDEX IF NOT EXISTS idx_mensagens_company ON mensagens(company_id);

