-- Migration 016: Interview Question Sets (RF3)
-- Data: 22/11/2025
-- Objetivo: Permitir CRUD de conjuntos de perguntas reutilizáveis para entrevistas

-- ============================================================================
-- 1. CRIAR TABELA interview_question_sets
-- ============================================================================

CREATE TABLE IF NOT EXISTS interview_question_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
  resume_id UUID REFERENCES resumes(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_template BOOLEAN DEFAULT false,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),
  deleted_at TIMESTAMP
);

-- ============================================================================
-- 2. REESTRUTURAR TABELA interview_questions
-- ============================================================================

-- Adicionar set_id (referência ao conjunto)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'interview_questions' 
    AND column_name = 'set_id'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN set_id UUID REFERENCES interview_question_sets(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Adicionar type (comportamental, técnica, situacional)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'interview_questions' 
    AND column_name = 'type'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN type TEXT DEFAULT 'technical';
  END IF;
END $$;

-- Adicionar text (texto da pergunta, substituindo prompt)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'interview_questions' 
    AND column_name = 'text'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN text TEXT;
    -- Copiar conteúdo de prompt para text se existir
    UPDATE interview_questions SET text = prompt WHERE text IS NULL AND prompt IS NOT NULL;
  END IF;
END $$;

-- Adicionar order (ordem de exibição)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'interview_questions' 
    AND column_name = 'order'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN "order" INTEGER DEFAULT 0;
  END IF;
END $$;

-- Adicionar updated_at
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'interview_questions' 
    AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN updated_at TIMESTAMP DEFAULT now();
  END IF;
END $$;

-- Adicionar deleted_at (soft delete)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'interview_questions' 
    AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN deleted_at TIMESTAMP;
  END IF;
END $$;

-- ============================================================================
-- 3. CRIAR CONSTRAINT DE TYPE
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'interview_questions_type_check'
  ) THEN
    ALTER TABLE interview_questions ADD CONSTRAINT interview_questions_type_check 
    CHECK (type IN ('behavioral', 'technical', 'situational', 'cultural', 'general'));
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 4. CRIAR ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índice para question_sets por company_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_question_sets_company'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_question_sets_company ON interview_question_sets(company_id) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para question_sets por job_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_question_sets_job'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_question_sets_job ON interview_question_sets(company_id, job_id) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para question_sets templates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_question_sets_template'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_question_sets_template ON interview_question_sets(company_id, is_template) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para interview_questions por set_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_interview_questions_set'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_interview_questions_set ON interview_questions(set_id, "order") WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para interview_questions por type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_interview_questions_type'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_interview_questions_type ON interview_questions(company_id, type) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- 5. CRIAR TRIGGER PARA updated_at
-- ============================================================================

-- Trigger para question_sets
CREATE OR REPLACE FUNCTION update_question_sets_updated_at()
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
    WHERE tgname = 'trigger_update_question_sets_updated_at'
  ) THEN
    CREATE TRIGGER trigger_update_question_sets_updated_at
      BEFORE UPDATE ON interview_question_sets
      FOR EACH ROW
      EXECUTE FUNCTION update_question_sets_updated_at();
  END IF;
END $$;

-- Trigger para interview_questions
CREATE OR REPLACE FUNCTION update_interview_questions_updated_at()
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
    WHERE tgname = 'trigger_update_interview_questions_updated_at'
  ) THEN
    CREATE TRIGGER trigger_update_interview_questions_updated_at
      BEFORE UPDATE ON interview_questions
      FOR EACH ROW
      EXECUTE FUNCTION update_interview_questions_updated_at();
  END IF;
END $$;

-- ============================================================================
-- FIM DA MIGRATION 016
-- ============================================================================
