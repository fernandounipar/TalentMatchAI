-- ============================================================================
-- Migration 030: Interview Chat and Dashboard
-- ============================================================================
-- Ajustes para entrevistas (chat/perguntas/relatórios) e KPI simples de dashboard
-- Objetivo: alinhar schema ao backend atual (rotas em /api/interviews) e ao dashboard enxuto.

-- ============================================================
-- 1) Garantir colunas atuais em interview_questions
-- ============================================================

-- Adicionar coluna text (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name = 'interview_questions' AND column_name = 'text'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN text TEXT;
    -- Preenche a partir de prompt, se existente
    UPDATE interview_questions SET text = prompt WHERE text IS NULL AND prompt IS NOT NULL;
  END IF;
END $$;

-- Adicionar coluna order (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name = 'interview_questions' AND column_name = 'order'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN "order" INTEGER DEFAULT 0;
  END IF;
END $$;

-- Adicionar coluna updated_at (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name = 'interview_questions' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN updated_at TIMESTAMP DEFAULT now();
  END IF;
END $$;

-- Adicionar coluna deleted_at (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name = 'interview_questions' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE interview_questions ADD COLUMN deleted_at TIMESTAMP;
  END IF;
END $$;

-- Criar índice (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname='public' AND c.relname='idx_interview_questions_interview_order'
  ) THEN
    CREATE INDEX idx_interview_questions_interview_order 
      ON interview_questions(interview_id, "order", created_at) 
      WHERE deleted_at IS NULL;
  END IF;
END $$;

-- ============================================================
-- 2) Tabela de mensagens do chat de entrevista (nova)
-- ============================================================

CREATE TABLE IF NOT EXISTS interview_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  interview_id UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  sender TEXT NOT NULL CHECK (sender IN ('user','assistant','system')),
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Criar índice se tabela foi criada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname='public' AND c.relname='idx_interview_messages_company'
  ) THEN
    CREATE INDEX idx_interview_messages_company 
      ON interview_messages(company_id, interview_id, created_at);
  END IF;
END $$;

-- ============================================================
-- 3) Garantir colunas modernas em interview_reports (RF7)
-- ============================================================

-- Adicionar colunas uma por uma (se não existirem)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='content'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN content JSONB NOT NULL DEFAULT '{}'::jsonb;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='summary_text'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN summary_text TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='candidate_name'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN candidate_name TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='job_title'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN job_title TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='overall_score'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN overall_score NUMERIC(4,2);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='recommendation'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN recommendation TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='strengths'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN strengths JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='weaknesses'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN weaknesses JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='risks'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN risks JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='format'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN format TEXT DEFAULT 'json';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='version'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN version INTEGER DEFAULT 1;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='generated_by'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN generated_by UUID REFERENCES users(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='generated_at'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN generated_at TIMESTAMP DEFAULT now();
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='is_final'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN is_final BOOLEAN DEFAULT false;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='deleted_at'
  ) THEN
    ALTER TABLE interview_reports ADD COLUMN deleted_at TIMESTAMP;
  END IF;
END $$;

-- Criar índice para interview_reports
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname='public' AND c.relname='idx_interview_reports_company_interview'
  ) THEN
    CREATE INDEX idx_interview_reports_company_interview 
      ON interview_reports(company_id, interview_id) 
      WHERE deleted_at IS NULL;
  END IF;
END $$;

-- ============================================================
-- 4) Function simples para dashboard overview (RF9)
-- ============================================================

-- Dropar função existente se houver (para recriar com estrutura correta)
DROP FUNCTION IF EXISTS get_dashboard_overview(uuid);

-- Criar função com estrutura correta
CREATE OR REPLACE FUNCTION get_dashboard_overview(p_company uuid)
RETURNS TABLE(
  vagas INT,
  curriculos INT,
  entrevistas INT,
  relatorios INT,
  candidatos INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INT FROM jobs j WHERE j.company_id = p_company AND j.deleted_at IS NULL) AS vagas,
    (SELECT COUNT(*)::INT FROM resumes r WHERE r.company_id = p_company AND r.deleted_at IS NULL) AS curriculos,
    (SELECT COUNT(*)::INT FROM interviews i WHERE i.company_id = p_company AND i.deleted_at IS NULL) AS entrevistas,
    (SELECT COUNT(*)::INT FROM interview_reports ir WHERE ir.company_id = p_company AND ir.deleted_at IS NULL) AS relatorios,
    (SELECT COUNT(*)::INT FROM candidates c WHERE c.company_id = p_company AND c.deleted_at IS NULL) AS candidatos;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Migration 030 concluída
-- ============================================================
