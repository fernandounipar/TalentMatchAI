-- ============================================================================
-- Migration 036: Renomear Tabelas Faltantes para PT-BR (Fase 2)
-- Data: 29/11/2025
-- Objetivo: Completar migração de nomes de tabelas EN → PT-BR
-- ============================================================================
-- Tabelas a serem renomeadas:
--   live_assessments → avaliacoes_tempo_real
--   interview_question_sets → conjuntos_perguntas_entrevista
--   dashboard_presets → presets_dashboard
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. RENOMEAR live_assessments → avaliacoes_tempo_real
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'live_assessments')
     AND NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'avaliacoes_tempo_real')
  THEN
    ALTER TABLE public.live_assessments RENAME TO avaliacoes_tempo_real;
    RAISE NOTICE '✅ Tabela live_assessments renomeada para avaliacoes_tempo_real';
  ELSIF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'avaliacoes_tempo_real')
  THEN
    RAISE NOTICE '⚠️  Tabela avaliacoes_tempo_real já existe';
  ELSE
    RAISE NOTICE '⚠️  Tabela live_assessments não encontrada';
  END IF;
END $$;

-- Renomear índices de live_assessments
ALTER INDEX IF EXISTS idx_live_assessments_company RENAME TO idx_avaliacoes_tempo_real_company;
ALTER INDEX IF EXISTS idx_live_assessments_interview RENAME TO idx_avaliacoes_tempo_real_entrevista;
ALTER INDEX IF EXISTS idx_live_assessments_question RENAME TO idx_avaliacoes_tempo_real_pergunta;
ALTER INDEX IF EXISTS idx_live_assessments_status RENAME TO idx_avaliacoes_tempo_real_status;
ALTER INDEX IF EXISTS idx_live_assessments_score RENAME TO idx_avaliacoes_tempo_real_score;

-- ============================================================================
-- 2. RENOMEAR interview_question_sets → conjuntos_perguntas_entrevista
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'interview_question_sets')
     AND NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conjuntos_perguntas_entrevista')
  THEN
    ALTER TABLE public.interview_question_sets RENAME TO conjuntos_perguntas_entrevista;
    RAISE NOTICE '✅ Tabela interview_question_sets renomeada para conjuntos_perguntas_entrevista';
  ELSIF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conjuntos_perguntas_entrevista')
  THEN
    RAISE NOTICE '⚠️  Tabela conjuntos_perguntas_entrevista já existe';
  ELSE
    RAISE NOTICE '⚠️  Tabela interview_question_sets não encontrada';
  END IF;
END $$;

-- Renomear índices de interview_question_sets
ALTER INDEX IF EXISTS idx_interview_question_sets_company RENAME TO idx_conjuntos_perguntas_entrevista_company;
ALTER INDEX IF EXISTS idx_interview_question_sets_job RENAME TO idx_conjuntos_perguntas_entrevista_vaga;
ALTER INDEX IF EXISTS idx_interview_question_sets_resume RENAME TO idx_conjuntos_perguntas_entrevista_curriculo;
ALTER INDEX IF EXISTS idx_question_sets_company_id RENAME TO idx_conjuntos_perguntas_company_id;

-- ============================================================================
-- 3. RENOMEAR dashboard_presets → presets_dashboard
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'dashboard_presets')
     AND NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'presets_dashboard')
  THEN
    ALTER TABLE public.dashboard_presets RENAME TO presets_dashboard;
    RAISE NOTICE '✅ Tabela dashboard_presets renomeada para presets_dashboard';
  ELSIF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'presets_dashboard')
  THEN
    RAISE NOTICE '⚠️  Tabela presets_dashboard já existe';
  ELSE
    RAISE NOTICE '⚠️  Tabela dashboard_presets não encontrada';
  END IF;
END $$;

-- Renomear índices de dashboard_presets
ALTER INDEX IF EXISTS idx_dashboard_presets_user_company RENAME TO idx_presets_dashboard_usuario_empresa;
ALTER INDEX IF EXISTS idx_dashboard_presets_company RENAME TO idx_presets_dashboard_empresa;
ALTER INDEX IF EXISTS idx_dashboard_presets_default RENAME TO idx_presets_dashboard_padrao;
ALTER INDEX IF EXISTS idx_dashboard_presets_shared RENAME TO idx_presets_dashboard_compartilhado;
ALTER INDEX IF EXISTS idx_dashboard_presets_search RENAME TO idx_presets_dashboard_busca;
ALTER INDEX IF EXISTS idx_dashboard_presets_filters_gin RENAME TO idx_presets_dashboard_filtros_gin;
ALTER INDEX IF EXISTS idx_dashboard_presets_usage RENAME TO idx_presets_dashboard_uso;
ALTER INDEX IF EXISTS idx_dashboard_presets_created_at RENAME TO idx_presets_dashboard_criado_em;

-- ============================================================================
-- 4. ATUALIZAR COMENTÁRIOS DAS TABELAS (usando DO block para evitar erros)
-- ============================================================================
DO $$ BEGIN COMMENT ON TABLE avaliacoes_tempo_real IS 'RF6 - Avaliações em tempo real de respostas de entrevista'; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN COMMENT ON TABLE conjuntos_perguntas_entrevista IS 'RF3 - Conjuntos de perguntas reutilizáveis para entrevistas'; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN COMMENT ON TABLE presets_dashboard IS 'RF9 - Configurações personalizadas de dashboard por usuário'; EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- ============================================================================
-- 5. ATUALIZAR VIEWS QUE REFERENCIAM AS TABELAS (se existirem)
-- ============================================================================

-- View: entrevistas_por_status (substituindo interviews_by_status)
DROP VIEW IF EXISTS interviews_by_status CASCADE;
DROP VIEW IF EXISTS entrevistas_por_status CASCADE;

CREATE VIEW entrevistas_por_status AS
SELECT
  e.company_id,
  e.status,
  COUNT(*) as interview_count,
  ROUND(AVG(e.overall_score)::numeric, 2) as avg_score,
  ROUND(AVG(e.duration_minutes)::numeric, 0) as avg_duration,
  MIN(e.scheduled_at) as earliest_scheduled,
  MAX(e.scheduled_at) as latest_scheduled
FROM entrevistas e
WHERE e.deleted_at IS NULL
GROUP BY e.company_id, e.status
ORDER BY e.company_id, e.status;

-- View: entrevistas_por_resultado (substituindo interviews_by_result)
DROP VIEW IF EXISTS interviews_by_result CASCADE;
DROP VIEW IF EXISTS entrevistas_por_resultado CASCADE;

CREATE VIEW entrevistas_por_resultado AS
SELECT
  e.company_id,
  e.result,
  COUNT(*) as interview_count,
  ROUND(AVG(e.overall_score)::numeric, 2) as avg_score,
  COUNT(*) FILTER (WHERE e.status = 'completed') as completed_count
FROM entrevistas e
WHERE e.deleted_at IS NULL
  AND e.result IS NOT NULL
GROUP BY e.company_id, e.result
ORDER BY e.company_id, e.result;

COMMIT;

-- ============================================================================
-- VERIFICAÇÃO FINAL
-- ============================================================================
DO $$
DECLARE
  v_avaliacoes BOOLEAN;
  v_conjuntos BOOLEAN;
  v_presets BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'avaliacoes_tempo_real') INTO v_avaliacoes;
  SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conjuntos_perguntas_entrevista') INTO v_conjuntos;
  SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'presets_dashboard') INTO v_presets;
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '        VERIFICAÇÃO FASE 2             ';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'avaliacoes_tempo_real:          %', CASE WHEN v_avaliacoes THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'conjuntos_perguntas_entrevista: %', CASE WHEN v_conjuntos THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'presets_dashboard:              %', CASE WHEN v_presets THEN '✅' ELSE '❌' END;
  RAISE NOTICE '========================================';
END $$;
