-- Migration 022: Interviews Table Improvements
-- RF8 - Histórico de Entrevistas
-- Data: 22/11/2025

DO $$
BEGIN
  RAISE NOTICE '=== Migration 022: Interviews Improvements ===';

  -- =============================================
  -- 1. ADICIONAR COLUNAS À TABELA INTERVIEWS
  -- =============================================
  
  RAISE NOTICE 'Adicionando colunas à tabela interviews...';
  
  -- Notas/observações da entrevista
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='notes') THEN
    ALTER TABLE interviews ADD COLUMN notes TEXT;
    RAISE NOTICE '✓ Adicionada coluna notes';
  END IF;
  
  -- Duração em minutos
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='duration_minutes') THEN
    ALTER TABLE interviews ADD COLUMN duration_minutes INTEGER;
    RAISE NOTICE '✓ Adicionada coluna duration_minutes';
  END IF;
  
  -- Data de conclusão
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='completed_at') THEN
    ALTER TABLE interviews ADD COLUMN completed_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna completed_at';
  END IF;
  
  -- Data de cancelamento
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='cancelled_at') THEN
    ALTER TABLE interviews ADD COLUMN cancelled_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna cancelled_at';
  END IF;
  
  -- Motivo do cancelamento
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='cancellation_reason') THEN
    ALTER TABLE interviews ADD COLUMN cancellation_reason TEXT;
    RAISE NOTICE '✓ Adicionada coluna cancellation_reason';
  END IF;
  
  -- ID do entrevistador (user)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='interviewer_id') THEN
    ALTER TABLE interviews ADD COLUMN interviewer_id UUID;
    RAISE NOTICE '✓ Adicionada coluna interviewer_id';
  END IF;
  
  -- Resultado/decisão final
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='result') THEN
    ALTER TABLE interviews ADD COLUMN result TEXT CHECK (result IN ('approved', 'rejected', 'pending', 'on_hold'));
    RAISE NOTICE '✓ Adicionada coluna result';
  END IF;
  
  -- Score geral da entrevista (0-10)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='overall_score') THEN
    ALTER TABLE interviews ADD COLUMN overall_score NUMERIC(4,2) CHECK (overall_score >= 0 AND overall_score <= 10);
    RAISE NOTICE '✓ Adicionada coluna overall_score';
  END IF;
  
  -- Metadados adicionais (JSONB)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='metadata') THEN
    ALTER TABLE interviews ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
    RAISE NOTICE '✓ Adicionada coluna metadata';
  END IF;
  
  -- Atualização timestamp
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='updated_at') THEN
    ALTER TABLE interviews ADD COLUMN updated_at TIMESTAMP DEFAULT now();
    RAISE NOTICE '✓ Adicionada coluna updated_at';
  END IF;
  
  -- Soft delete
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interviews' AND column_name='deleted_at') THEN
    ALTER TABLE interviews ADD COLUMN deleted_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna deleted_at';
  END IF;

  -- =============================================
  -- 2. ADICIONAR FOREIGN KEYS
  -- =============================================
  
  RAISE NOTICE 'Adicionando foreign keys...';
  
  -- FK para interviewer (users)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_interviews_interviewer'
  ) THEN
    ALTER TABLE interviews 
      ADD CONSTRAINT fk_interviews_interviewer 
      FOREIGN KEY (interviewer_id) REFERENCES users(id) ON DELETE SET NULL;
    RAISE NOTICE '✓ FK interviewer_id → users';
  END IF;

  -- =============================================
  -- 3. MIGRAR VALORES DE STATUS (PT→EN)
  -- =============================================
  
  RAISE NOTICE 'Migrando valores de status de português para inglês...';
  
  -- Mapeamento: PENDENTE→scheduled, EM_ANDAMENTO→in_progress, CONCLUIDA→completed, CANCELADA→cancelled
  UPDATE interviews SET status = 'scheduled' WHERE status = 'PENDENTE';
  UPDATE interviews SET status = 'in_progress' WHERE status = 'EM_ANDAMENTO';
  UPDATE interviews SET status = 'completed' WHERE status = 'CONCLUIDA' OR status = 'CONCLUÍDA';
  UPDATE interviews SET status = 'cancelled' WHERE status = 'CANCELADA';
  UPDATE interviews SET status = 'no_show' WHERE status = 'NAO_COMPARECEU' OR status = 'NÃO_COMPARECEU';
  
  RAISE NOTICE '✓ Status migrados para inglês';

  -- =============================================
  -- 4. ATUALIZAR CONSTRAINT DE STATUS
  -- =============================================
  
  -- Dropar constraint antigo se existir
  ALTER TABLE interviews DROP CONSTRAINT IF EXISTS interviews_status_check;
  
  -- Criar novo com mais valores
  ALTER TABLE interviews 
    ADD CONSTRAINT interviews_status_check 
    CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show'));
  
  RAISE NOTICE '✓ Constraint de status atualizado';

  -- =============================================
  -- 5. ÍNDICES
  -- =============================================
  
  RAISE NOTICE 'Criando índices...';
  
  CREATE INDEX IF NOT EXISTS idx_interviews_company 
    ON interviews(company_id) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_application 
    ON interviews(application_id) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_status 
    ON interviews(status) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_scheduled_at 
    ON interviews(scheduled_at) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_created_at 
    ON interviews(created_at DESC) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_result 
    ON interviews(result) WHERE deleted_at IS NULL AND result IS NOT NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_interviewer 
    ON interviews(interviewer_id) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_completed_at 
    ON interviews(completed_at DESC) WHERE deleted_at IS NULL AND completed_at IS NOT NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_metadata_gin 
    ON interviews USING gin(metadata);
  
  RAISE NOTICE '✓ 9 índices criados/verificados';

  -- =============================================
  -- 5. TRIGGER PARA UPDATED_AT
  -- =============================================
  
  -- Função para atualizar updated_at
  CREATE OR REPLACE FUNCTION update_interviews_timestamps()
  RETURNS TRIGGER AS $func$
  BEGIN
    NEW.updated_at = now();
    
    -- Auto-preencher completed_at quando status muda para completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.completed_at IS NULL THEN
      NEW.completed_at = now();
    END IF;
    
    -- Auto-preencher cancelled_at quando status muda para cancelled
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' AND NEW.cancelled_at IS NULL THEN
      NEW.cancelled_at = now();
    END IF;
    
    RETURN NEW;
  END;
  $func$ LANGUAGE plpgsql;
  
  -- Criar trigger se não existir
  DROP TRIGGER IF EXISTS trigger_update_interviews ON interviews;
  CREATE TRIGGER trigger_update_interviews
    BEFORE UPDATE ON interviews
    FOR EACH ROW
    EXECUTE FUNCTION update_interviews_timestamps();
  
  RAISE NOTICE '✓ Trigger update_interviews_timestamps criado';

  -- =============================================
  -- 6. COMENTÁRIOS
  -- =============================================
  
  COMMENT ON TABLE interviews IS 'RF8 - Entrevistas realizadas/agendadas';
  COMMENT ON COLUMN interviews.notes IS 'Observações do entrevistador sobre a entrevista';
  COMMENT ON COLUMN interviews.duration_minutes IS 'Duração real da entrevista em minutos';
  COMMENT ON COLUMN interviews.completed_at IS 'Data/hora de conclusão da entrevista';
  COMMENT ON COLUMN interviews.cancelled_at IS 'Data/hora de cancelamento';
  COMMENT ON COLUMN interviews.result IS 'Resultado: approved (aprovado), rejected (reprovado), pending (pendente), on_hold (em espera)';
  COMMENT ON COLUMN interviews.overall_score IS 'Score geral 0-10 (pode vir de live_assessments ou manual)';
  COMMENT ON COLUMN interviews.metadata IS 'Metadados adicionais em JSONB (link meet, gravação, etc)';
  COMMENT ON COLUMN interviews.status IS 'Status: scheduled (agendada), in_progress (em andamento), completed (concluída), cancelled (cancelada), no_show (faltou)';

  RAISE NOTICE '=== Migration 022 concluída com sucesso ===';

END $$;
