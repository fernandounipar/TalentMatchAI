-- Migration 014: Adicionar colunas para CRUD completo de vagas (RF2)
-- Data: 22/11/2025

-- ============================================================================
-- 1. ADICIONAR COLUNAS NA TABELA JOBS
-- ============================================================================

-- Adicionar salary_min (salário mínimo)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'salary_min'
  ) THEN
    ALTER TABLE jobs ADD COLUMN salary_min NUMERIC(10, 2);
  END IF;
END $$;

-- Adicionar salary_max (salário máximo)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'salary_max'
  ) THEN
    ALTER TABLE jobs ADD COLUMN salary_max NUMERIC(10, 2);
  END IF;
END $$;

-- Adicionar contract_type (tipo de contrato: CLT, PJ, etc)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'contract_type'
  ) THEN
    ALTER TABLE jobs ADD COLUMN contract_type TEXT;
  END IF;
END $$;

-- Adicionar department (área/departamento)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'department'
  ) THEN
    ALTER TABLE jobs ADD COLUMN department TEXT;
  END IF;
END $$;

-- Adicionar unit (unidade/filial)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'unit'
  ) THEN
    ALTER TABLE jobs ADD COLUMN unit TEXT;
  END IF;
END $$;

-- Adicionar benefits (benefícios em JSONB)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'benefits'
  ) THEN
    ALTER TABLE jobs ADD COLUMN benefits JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Adicionar skills_required (skills necessárias em JSONB)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'skills_required'
  ) THEN
    ALTER TABLE jobs ADD COLUMN skills_required JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Adicionar is_remote (vaga totalmente remota)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'is_remote'
  ) THEN
    ALTER TABLE jobs ADD COLUMN is_remote BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Adicionar published_at (data de publicação)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'published_at'
  ) THEN
    ALTER TABLE jobs ADD COLUMN published_at TIMESTAMP;
  END IF;
END $$;

-- Adicionar closed_at (data de encerramento)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'closed_at'
  ) THEN
    ALTER TABLE jobs ADD COLUMN closed_at TIMESTAMP;
  END IF;
END $$;

-- Adicionar created_by (usuário que criou)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'created_by'
  ) THEN
    ALTER TABLE jobs ADD COLUMN created_by UUID REFERENCES users(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Adicionar updated_by (usuário que atualizou)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'updated_by'
  ) THEN
    ALTER TABLE jobs ADD COLUMN updated_by UUID REFERENCES users(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Adicionar version (controle de versão simples)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'jobs' 
    AND column_name = 'version'
  ) THEN
    ALTER TABLE jobs ADD COLUMN version INTEGER DEFAULT 1;
  END IF;
END $$;

-- ============================================================================
-- 2. CRIAR CONSTRAINT DE STATUS
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'jobs_status_check'
  ) THEN
    ALTER TABLE jobs ADD CONSTRAINT jobs_status_check 
    CHECK (status IN ('draft', 'open', 'paused', 'closed', 'archived'));
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 3. CRIAR TABELA DE HISTÓRICO DE ALTERAÇÕES (job_revisions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS job_revisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  title TEXT,
  description TEXT,
  requirements TEXT,
  seniority TEXT,
  location_type TEXT,
  status TEXT,
  salary_min NUMERIC(10, 2),
  salary_max NUMERIC(10, 2),
  contract_type TEXT,
  department TEXT,
  unit TEXT,
  benefits JSONB,
  skills_required JSONB,
  is_remote BOOLEAN,
  changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT now(),
  change_notes TEXT
);

-- ============================================================================
-- 4. CRIAR ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índice para company_id + status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_jobs_company_status'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_jobs_company_status ON jobs(company_id, status) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para department
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_jobs_department'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_jobs_department ON jobs(company_id, department) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para published_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_jobs_published_at'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_jobs_published_at ON jobs(company_id, published_at DESC) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para job_revisions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_job_revisions_job_version'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_job_revisions_job_version ON job_revisions(job_id, version DESC);
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- 5. CRIAR TRIGGER PARA ATUALIZAR updated_at E CRIAR REVISÃO
-- ============================================================================

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_jobs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_update_jobs_updated_at'
  ) THEN
    CREATE TRIGGER trigger_update_jobs_updated_at
      BEFORE UPDATE ON jobs
      FOR EACH ROW
      EXECUTE FUNCTION update_jobs_updated_at();
  END IF;
END $$;

-- Trigger para criar revisão em cada update significativo
CREATE OR REPLACE FUNCTION create_job_revision()
RETURNS TRIGGER AS $$
BEGIN
  -- Só cria revisão se houver mudança em campos importantes
  IF (OLD.title IS DISTINCT FROM NEW.title
      OR OLD.description IS DISTINCT FROM NEW.description
      OR OLD.requirements IS DISTINCT FROM NEW.requirements
      OR OLD.seniority IS DISTINCT FROM NEW.seniority
      OR OLD.salary_min IS DISTINCT FROM NEW.salary_min
      OR OLD.salary_max IS DISTINCT FROM NEW.salary_max
      OR OLD.status IS DISTINCT FROM NEW.status) THEN
    
    -- Incrementar versão
    NEW.version = COALESCE(OLD.version, 1) + 1;
    
    -- Inserir revisão
    INSERT INTO job_revisions (
      job_id, company_id, version, title, description, requirements,
      seniority, location_type, status, salary_min, salary_max,
      contract_type, department, unit, benefits, skills_required,
      is_remote, changed_by, changed_at
    ) VALUES (
      NEW.id, NEW.company_id, OLD.version, OLD.title, OLD.description, OLD.requirements,
      OLD.seniority, OLD.location_type, OLD.status, OLD.salary_min, OLD.salary_max,
      OLD.contract_type, OLD.department, OLD.unit, OLD.benefits, OLD.skills_required,
      OLD.is_remote, NEW.updated_by, now()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_create_job_revision'
  ) THEN
    CREATE TRIGGER trigger_create_job_revision
      BEFORE UPDATE ON jobs
      FOR EACH ROW
      EXECUTE FUNCTION create_job_revision();
  END IF;
END $$;

-- ============================================================================
-- FIM DA MIGRATION 014
-- ============================================================================
