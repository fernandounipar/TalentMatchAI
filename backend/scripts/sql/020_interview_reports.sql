-- Migration 020: Interview Reports Table
-- RF7 - Relatórios Detalhados de Entrevistas
-- Data: 22/11/2025

DO $$
BEGIN
  RAISE NOTICE '=== Migration 020: Interview Reports ===';

  -- =============================================
  -- 1. TABELA INTERVIEW_REPORTS
  -- =============================================
  
  -- Verificar se tabela já existe (pode ter sido criada em 007_users_multitenant.sql)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'interview_reports'
  ) THEN
    RAISE NOTICE 'Criando tabela interview_reports...';
    
    CREATE TABLE interview_reports (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      company_id UUID NOT NULL,
      interview_id UUID NOT NULL,
      
      -- Identificação
      title TEXT NOT NULL DEFAULT 'Relatório de Entrevista',
      report_type TEXT NOT NULL DEFAULT 'full' CHECK (report_type IN ('full', 'summary', 'technical', 'behavioral')),
      
      -- Conteúdo estruturado
      content JSONB NOT NULL DEFAULT '{}'::jsonb,
      
      -- Campos extraídos para queries rápidas
      summary_text TEXT,
      candidate_name TEXT,
      job_title TEXT,
      
      -- Avaliação geral
      overall_score NUMERIC(4,2) CHECK (overall_score >= 0 AND overall_score <= 10),
      recommendation TEXT CHECK (recommendation IN ('APPROVE', 'MAYBE', 'REJECT', 'PENDING')),
      
      -- Pontos fortes e riscos
      strengths JSONB DEFAULT '[]'::jsonb,
      weaknesses JSONB DEFAULT '[]'::jsonb,
      risks JSONB DEFAULT '[]'::jsonb,
      
      -- Formato e arquivo
      format TEXT NOT NULL DEFAULT 'json' CHECK (format IN ('json', 'pdf', 'html', 'markdown')),
      file_path TEXT,
      file_size INTEGER,
      
      -- Metadados
      generated_by UUID,
      generated_at TIMESTAMP DEFAULT now(),
      is_final BOOLEAN DEFAULT false,
      version INTEGER DEFAULT 1,
      
      -- Auditoria
      created_by UUID,
      created_at TIMESTAMP NOT NULL DEFAULT now(),
      updated_at TIMESTAMP DEFAULT now(),
      deleted_at TIMESTAMP,
      
      -- Constraints
      CONSTRAINT fk_interview_reports_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
      CONSTRAINT fk_interview_reports_interview FOREIGN KEY (interview_id) REFERENCES interviews(id) ON DELETE CASCADE,
      CONSTRAINT fk_interview_reports_generated_by FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE SET NULL,
      CONSTRAINT fk_interview_reports_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
    );
    
    RAISE NOTICE '✓ Tabela interview_reports criada';
  ELSE
    RAISE NOTICE '⊙ Tabela interview_reports já existe';
    
    -- Dropar constraints antigos para recriar com novos valores
    ALTER TABLE interview_reports DROP CONSTRAINT IF EXISTS interview_reports_recommendation_check;
    ALTER TABLE interview_reports DROP CONSTRAINT IF EXISTS interview_reports_format_check;
    ALTER TABLE interview_reports DROP CONSTRAINT IF EXISTS interview_reports_report_type_check;
    ALTER TABLE interview_reports DROP CONSTRAINT IF EXISTS interview_reports_overall_score_check;
    
    -- Adicionar colunas que podem não existir na versão antiga
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='title') THEN
      ALTER TABLE interview_reports ADD COLUMN title TEXT NOT NULL DEFAULT 'Relatório de Entrevista';
      RAISE NOTICE '✓ Adicionada coluna title';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='report_type') THEN
      ALTER TABLE interview_reports ADD COLUMN report_type TEXT NOT NULL DEFAULT 'full' CHECK (report_type IN ('full', 'summary', 'technical', 'behavioral'));
      RAISE NOTICE '✓ Adicionada coluna report_type';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='content') THEN
      ALTER TABLE interview_reports ADD COLUMN content JSONB NOT NULL DEFAULT '{}'::jsonb;
      RAISE NOTICE '✓ Adicionada coluna content';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='candidate_name') THEN
      ALTER TABLE interview_reports ADD COLUMN candidate_name TEXT;
      RAISE NOTICE '✓ Adicionada coluna candidate_name';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='job_title') THEN
      ALTER TABLE interview_reports ADD COLUMN job_title TEXT;
      RAISE NOTICE '✓ Adicionada coluna job_title';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='overall_score') THEN
      ALTER TABLE interview_reports ADD COLUMN overall_score NUMERIC(4,2) CHECK (overall_score >= 0 AND overall_score <= 10);
      RAISE NOTICE '✓ Adicionada coluna overall_score';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='weaknesses') THEN
      ALTER TABLE interview_reports ADD COLUMN weaknesses JSONB DEFAULT '[]'::jsonb;
      RAISE NOTICE '✓ Adicionada coluna weaknesses';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='format') THEN
      ALTER TABLE interview_reports ADD COLUMN format TEXT NOT NULL DEFAULT 'json' CHECK (format IN ('json', 'pdf', 'html', 'markdown'));
      RAISE NOTICE '✓ Adicionada coluna format';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='file_path') THEN
      ALTER TABLE interview_reports ADD COLUMN file_path TEXT;
      RAISE NOTICE '✓ Adicionada coluna file_path';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='file_size') THEN
      ALTER TABLE interview_reports ADD COLUMN file_size INTEGER;
      RAISE NOTICE '✓ Adicionada coluna file_size';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='generated_by') THEN
      ALTER TABLE interview_reports ADD COLUMN generated_by UUID;
      RAISE NOTICE '✓ Adicionada coluna generated_by';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='generated_at') THEN
      ALTER TABLE interview_reports ADD COLUMN generated_at TIMESTAMP DEFAULT now();
      RAISE NOTICE '✓ Adicionada coluna generated_at';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='is_final') THEN
      ALTER TABLE interview_reports ADD COLUMN is_final BOOLEAN DEFAULT false;
      RAISE NOTICE '✓ Adicionada coluna is_final';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='version') THEN
      ALTER TABLE interview_reports ADD COLUMN version INTEGER DEFAULT 1;
      RAISE NOTICE '✓ Adicionada coluna version';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='created_by') THEN
      ALTER TABLE interview_reports ADD COLUMN created_by UUID;
      RAISE NOTICE '✓ Adicionada coluna created_by';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='updated_at') THEN
      ALTER TABLE interview_reports ADD COLUMN updated_at TIMESTAMP DEFAULT now();
      RAISE NOTICE '✓ Adicionada coluna updated_at';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='interview_reports' AND column_name='deleted_at') THEN
      ALTER TABLE interview_reports ADD COLUMN deleted_at TIMESTAMP;
      RAISE NOTICE '✓ Adicionada coluna deleted_at';
    END IF;
    
    -- Recriar constraints com valores corretos
    ALTER TABLE interview_reports 
      ADD CONSTRAINT interview_reports_recommendation_check 
      CHECK (recommendation IN ('APPROVE', 'MAYBE', 'REJECT', 'PENDING'));
    
    ALTER TABLE interview_reports 
      ADD CONSTRAINT interview_reports_format_check 
      CHECK (format IN ('json', 'pdf', 'html', 'markdown'));
    
    ALTER TABLE interview_reports 
      ADD CONSTRAINT interview_reports_report_type_check 
      CHECK (report_type IN ('full', 'summary', 'technical', 'behavioral'));
    
    ALTER TABLE interview_reports 
      ADD CONSTRAINT interview_reports_overall_score_check 
      CHECK (overall_score >= 0 AND overall_score <= 10);
    
    RAISE NOTICE '✓ Constraints atualizados';
  END IF;

  -- =============================================
  -- 2. ÍNDICES
  -- =============================================
  
  RAISE NOTICE 'Criando índices...';
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_company 
    ON interview_reports(company_id) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_interview 
    ON interview_reports(interview_id) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_created_at 
    ON interview_reports(created_at DESC) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_recommendation 
    ON interview_reports(recommendation) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_report_type 
    ON interview_reports(report_type) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_generated_at 
    ON interview_reports(generated_at DESC) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_is_final 
    ON interview_reports(is_final) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_content_gin 
    ON interview_reports USING gin(content);
  
  RAISE NOTICE '✓ 8 índices criados/verificados';

  -- =============================================
  -- 3. TRIGGER PARA UPDATED_AT
  -- =============================================
  
  -- Função para atualizar updated_at
  CREATE OR REPLACE FUNCTION update_interview_reports_timestamps()
  RETURNS TRIGGER AS $func$
  BEGIN
    NEW.updated_at = now();
    RETURN NEW;
  END;
  $func$ LANGUAGE plpgsql;
  
  -- Criar trigger se não existir
  DROP TRIGGER IF EXISTS trigger_update_interview_reports ON interview_reports;
  CREATE TRIGGER trigger_update_interview_reports
    BEFORE UPDATE ON interview_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_interview_reports_timestamps();
  
  RAISE NOTICE '✓ Trigger update_interview_reports_timestamps criado';

  -- =============================================
  -- 4. COMENTÁRIOS
  -- =============================================
  
  COMMENT ON TABLE interview_reports IS 'RF7 - Relatórios consolidados de entrevistas gerados via IA';
  COMMENT ON COLUMN interview_reports.content IS 'Conteúdo completo do relatório em JSONB (flexível para diferentes formatos)';
  COMMENT ON COLUMN interview_reports.report_type IS 'Tipo: full (completo), summary (resumo), technical (técnico), behavioral (comportamental)';
  COMMENT ON COLUMN interview_reports.overall_score IS 'Score geral 0-10 calculado pela IA';
  COMMENT ON COLUMN interview_reports.recommendation IS 'APPROVE (aprovar), MAYBE (dúvida), REJECT (reprovar), PENDING (pendente)';
  COMMENT ON COLUMN interview_reports.is_final IS 'Indica se é a versão final (true) ou rascunho (false)';
  COMMENT ON COLUMN interview_reports.version IS 'Número da versão (incrementa a cada regeneração)';

  RAISE NOTICE '=== Migration 020 concluída com sucesso ===';

END $$;
