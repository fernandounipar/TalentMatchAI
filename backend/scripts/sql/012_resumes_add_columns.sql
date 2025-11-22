-- ============================================================
-- 012_resumes_add_columns.sql
-- Adicionar colunas necessárias para CRUD completo de currículos (RF1)
-- ============================================================

-- Adicionar colunas à tabela resumes uma por vez
DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS job_id UUID REFERENCES jobs(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS file_size BIGINT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS mime_type TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS notes TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT false;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE resumes ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Criar índices para performance
DO $$ BEGIN
  CREATE INDEX idx_resumes_job ON resumes(company_id, job_id) WHERE deleted_at IS NULL;
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX idx_resumes_status ON resumes(company_id, status) WHERE deleted_at IS NULL;
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX idx_resumes_favorite ON resumes(company_id, is_favorite) WHERE deleted_at IS NULL AND is_favorite = true;
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX idx_resumes_created_at ON resumes(company_id, created_at DESC) WHERE deleted_at IS NULL;
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

DO $$ BEGIN
  CREATE INDEX idx_resumes_deleted_at ON resumes(deleted_at) WHERE deleted_at IS NOT NULL;
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

-- Adicionar constraint para status
DO $$ BEGIN
  ALTER TABLE resumes ADD CONSTRAINT resumes_status_check 
  CHECK (status IN ('pending', 'reviewed', 'accepted', 'rejected'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Criar tabela de análises de currículo se não existir
CREATE TABLE IF NOT EXISTS resume_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resume_id UUID NOT NULL REFERENCES resumes(id) ON DELETE CASCADE,
  summary JSONB,
  score NUMERIC(5,2),
  questions JSONB,
  provider TEXT,
  model TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Índices para resume_analysis
CREATE INDEX IF NOT EXISTS idx_resume_analysis_resume ON resume_analysis(resume_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_resume_analysis_provider ON resume_analysis(provider, model);
CREATE INDEX IF NOT EXISTS idx_resume_analysis_score ON resume_analysis(score);
CREATE INDEX IF NOT EXISTS idx_resume_analysis_created_at ON resume_analysis(created_at DESC);

-- Comentários
COMMENT ON COLUMN resumes.job_id IS 'Vaga à qual o currículo está vinculado (opcional)';
COMMENT ON COLUMN resumes.status IS 'Status do currículo: pending, reviewed, accepted, rejected';
COMMENT ON COLUMN resumes.notes IS 'Observações internas do recrutador';
COMMENT ON COLUMN resumes.is_favorite IS 'Currículo marcado como favorito';
COMMENT ON COLUMN resumes.deleted_at IS 'Soft delete - data de exclusão';
COMMENT ON TABLE resume_analysis IS 'Análises de currículo realizadas pela IA';

-- Atualizar registros existentes
UPDATE resumes 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Criar trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_resumes_updated_at ON resumes;
CREATE TRIGGER update_resumes_updated_at
    BEFORE UPDATE ON resumes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TRIGGER update_resumes_updated_at ON resumes IS 'Atualiza automaticamente o campo updated_at';
