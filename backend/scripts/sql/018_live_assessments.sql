-- Migration 018: Live Assessments (RF6 - Avaliação em Tempo Real)
-- Data: 22/11/2025

-- ============================================================================
-- 1. TABELA: live_assessments
-- Armazena avaliações automáticas e manuais de respostas de entrevista
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'live_assessments'
  ) THEN
    CREATE TABLE live_assessments (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      company_id UUID NOT NULL REFERENCES companies(id),
      interview_id UUID NOT NULL REFERENCES interviews(id),
      question_id UUID REFERENCES interview_questions(id),
      answer_id UUID REFERENCES interview_answers(id),
      
      -- Scores
      score_auto NUMERIC(4,2),                    -- Score automático da IA (0-10)
      score_manual NUMERIC(4,2),                  -- Score ajustado manualmente (0-10)
      score_final NUMERIC(4,2),                   -- Score final (manual se existir, senão auto)
      
      -- Feedback estruturado (JSONB)
      feedback_auto JSONB,                        -- { nota, feedback, pontosFortesResposta, pontosMelhoria }
      feedback_manual TEXT,                       -- Comentário adicional do entrevistador
      
      -- Metadados
      assessment_type TEXT CHECK (assessment_type IN ('behavioral', 'technical', 'situational', 'cultural', 'general')),
      status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'auto_evaluated', 'manually_adjusted', 'validated', 'invalidated')),
      
      -- Tempo de resposta (para métricas)
      response_time_seconds INTEGER,              -- Tempo que o candidato levou para responder
      
      -- Auditoria
      evaluated_by UUID REFERENCES users(id),     -- Quem fez ajuste manual
      evaluated_at TIMESTAMP,                     -- Quando foi ajustado manualmente
      created_by UUID REFERENCES users(id),
      created_at TIMESTAMP DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now(),
      deleted_at TIMESTAMP
    );
    
    RAISE NOTICE '✅ Tabela live_assessments criada com sucesso';
  ELSE
    RAISE NOTICE '⚠️  Tabela live_assessments já existe';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ Erro ao criar live_assessments: %', SQLERRM;
END $$;

-- ============================================================================
-- 2. ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índice por company_id (multitenant)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_company'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_company ON live_assessments(company_id, deleted_at) WHERE deleted_at IS NULL;
    RAISE NOTICE '✅ Índice idx_live_assessments_company criado';
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice por interview_id (listar avaliações de uma entrevista)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_interview'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_interview ON live_assessments(interview_id, deleted_at) WHERE deleted_at IS NULL;
    RAISE NOTICE '✅ Índice idx_live_assessments_interview criado';
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice por question_id (avaliações por pergunta)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_question'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_question ON live_assessments(question_id, deleted_at) WHERE deleted_at IS NULL;
    RAISE NOTICE '✅ Índice idx_live_assessments_question criado';
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice por status (filtrar por status)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_status'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_status ON live_assessments(company_id, status, deleted_at) WHERE deleted_at IS NULL;
    RAISE NOTICE '✅ Índice idx_live_assessments_status criado';
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice por tipo (filtrar por tipo de avaliação)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_type'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_type ON live_assessments(assessment_type, company_id) WHERE deleted_at IS NULL;
    RAISE NOTICE '✅ Índice idx_live_assessments_type criado';
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice por created_at (ordenação temporal)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_created'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_created ON live_assessments(company_id, created_at DESC) WHERE deleted_at IS NULL;
    RAISE NOTICE '✅ Índice idx_live_assessments_created criado';
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- 3. TRIGGERS PARA AUTO-ATUALIZAÇÃO
-- ============================================================================

-- Função para atualizar updated_at e score_final
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'update_live_assessments_timestamps'
  ) THEN
    CREATE FUNCTION update_live_assessments_timestamps()
    RETURNS TRIGGER AS $func$
    BEGIN
      -- Atualizar updated_at
      NEW.updated_at = now();
      
      -- Calcular score_final (priorizar manual sobre auto)
      NEW.score_final = COALESCE(NEW.score_manual, NEW.score_auto);
      
      -- Atualizar status baseado em mudanças
      IF NEW.score_manual IS NOT NULL AND OLD.score_manual IS NULL THEN
        NEW.status = 'manually_adjusted';
        NEW.evaluated_at = now();
      ELSIF NEW.status = 'pending' AND NEW.score_auto IS NOT NULL THEN
        NEW.status = 'auto_evaluated';
      END IF;
      
      RETURN NEW;
    END;
    $func$ LANGUAGE plpgsql;
    
    RAISE NOTICE '✅ Função update_live_assessments_timestamps criada';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️  Função update_live_assessments_timestamps já existe ou erro: %', SQLERRM;
END $$;

-- Trigger BEFORE UPDATE
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_update_live_assessments'
  ) THEN
    CREATE TRIGGER trigger_update_live_assessments
    BEFORE UPDATE ON live_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_live_assessments_timestamps();
    
    RAISE NOTICE '✅ Trigger trigger_update_live_assessments criado';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️  Trigger trigger_update_live_assessments já existe ou erro: %', SQLERRM;
END $$;

-- ============================================================================
-- 4. COMENTÁRIOS NA TABELA
-- ============================================================================

COMMENT ON TABLE live_assessments IS 'RF6 - Avaliações automáticas e manuais de respostas de entrevista em tempo real';
COMMENT ON COLUMN live_assessments.score_auto IS 'Score automático gerado pela IA (0-10)';
COMMENT ON COLUMN live_assessments.score_manual IS 'Score ajustado manualmente pelo entrevistador (0-10)';
COMMENT ON COLUMN live_assessments.score_final IS 'Score final calculado (prioriza manual, fallback para auto)';
COMMENT ON COLUMN live_assessments.feedback_auto IS 'Feedback estruturado da IA: { nota, feedback, pontosFortesResposta, pontosMelhoria }';
COMMENT ON COLUMN live_assessments.feedback_manual IS 'Comentário adicional do entrevistador';
COMMENT ON COLUMN live_assessments.status IS 'pending | auto_evaluated | manually_adjusted | validated | invalidated';
COMMENT ON COLUMN live_assessments.response_time_seconds IS 'Tempo em segundos que o candidato levou para responder';

-- ============================================================================
-- FIM DA MIGRATION 018
-- ============================================================================
