-- Migration 019: Views de métricas para Live Assessments (RF6)
-- Data: 22/11/2025

-- ============================================================================
-- 1. VIEW: assessment_stats_overview
-- Estatísticas gerais de avaliações
-- ============================================================================

CREATE OR REPLACE VIEW assessment_stats_overview AS
SELECT 
  la.company_id,
  
  -- Contadores totais
  COUNT(*) as total_assessments,
  COUNT(*) FILTER (WHERE la.deleted_at IS NULL) as active_assessments,
  COUNT(*) FILTER (WHERE la.status = 'auto_evaluated') as auto_evaluated_count,
  COUNT(*) FILTER (WHERE la.status = 'manually_adjusted') as manually_adjusted_count,
  COUNT(*) FILTER (WHERE la.status = 'validated') as validated_count,
  COUNT(*) FILTER (WHERE la.status = 'invalidated') as invalidated_count,
  
  -- Médias de scores
  ROUND(AVG(la.score_final)::numeric, 2) as avg_score_final,
  ROUND(AVG(la.score_auto)::numeric, 2) as avg_score_auto,
  ROUND(AVG(la.score_manual)::numeric, 2) as avg_score_manual,
  
  -- Tempo médio de resposta
  ROUND(AVG(la.response_time_seconds)::numeric, 2) as avg_response_time_seconds,
  
  -- Avaliações recentes
  COUNT(*) FILTER (WHERE la.created_at >= now() - interval '7 days' AND la.deleted_at IS NULL) as assessments_last_7_days,
  COUNT(*) FILTER (WHERE la.created_at >= now() - interval '30 days' AND la.deleted_at IS NULL) as assessments_last_30_days

FROM live_assessments la
WHERE la.deleted_at IS NULL
GROUP BY la.company_id;

-- ============================================================================
-- 2. VIEW: assessment_by_interview
-- Avaliações agrupadas por entrevista
-- ============================================================================

CREATE OR REPLACE VIEW assessment_by_interview AS
SELECT 
  la.company_id,
  la.interview_id,
  i.scheduled_at as interview_date,
  i.status as interview_status,
  
  -- Contadores
  COUNT(la.id) as total_assessments,
  COUNT(la.id) FILTER (WHERE la.status = 'auto_evaluated') as auto_count,
  COUNT(la.id) FILTER (WHERE la.status = 'manually_adjusted') as manual_count,
  
  -- Scores
  ROUND(AVG(la.score_final)::numeric, 2) as avg_score,
  ROUND(MIN(la.score_final)::numeric, 2) as min_score,
  ROUND(MAX(la.score_final)::numeric, 2) as max_score,
  
  -- Tempo médio de resposta
  ROUND(AVG(la.response_time_seconds)::numeric, 2) as avg_response_time,
  
  -- Última avaliação
  MAX(la.created_at) as last_assessment_at

FROM live_assessments la
LEFT JOIN interviews i ON i.id = la.interview_id
WHERE la.deleted_at IS NULL
GROUP BY la.company_id, la.interview_id, i.scheduled_at, i.status;

-- ============================================================================
-- 3. VIEW: assessment_type_distribution
-- Distribuição de avaliações por tipo
-- ============================================================================

CREATE OR REPLACE VIEW assessment_type_distribution AS
SELECT 
  la.company_id,
  la.assessment_type,
  
  -- Contadores
  COUNT(*) as total_count,
  ROUND(AVG(la.score_final)::numeric, 2) as avg_score,
  ROUND(STDDEV(la.score_final)::numeric, 2) as stddev_score,
  
  -- Taxa de ajuste manual
  COUNT(*) FILTER (WHERE la.score_manual IS NOT NULL) as manually_adjusted_count,
  ROUND(
    (COUNT(*) FILTER (WHERE la.score_manual IS NOT NULL) * 100.0) / NULLIF(COUNT(*), 0),
    2
  ) as manual_adjustment_rate,
  
  -- Percentual do total
  ROUND(
    (COUNT(*) * 100.0) / NULLIF(
      (SELECT COUNT(*) FROM live_assessments WHERE company_id = la.company_id AND deleted_at IS NULL),
      0
    ),
    2
  ) as percentage_of_total

FROM live_assessments la
WHERE la.deleted_at IS NULL
GROUP BY la.company_id, la.assessment_type
ORDER BY total_count DESC;

-- ============================================================================
-- 4. VIEW: assessment_concordance_stats
-- Estatísticas de concordância entre IA e avaliador humano
-- ============================================================================

CREATE OR REPLACE VIEW assessment_concordance_stats AS
SELECT 
  la.company_id,
  
  -- Avaliações com ambos os scores
  COUNT(*) FILTER (WHERE la.score_auto IS NOT NULL AND la.score_manual IS NOT NULL) as dual_scored_count,
  
  -- Diferença média entre scores
  ROUND(AVG(ABS(la.score_manual - la.score_auto))::numeric, 2) as avg_score_difference,
  
  -- Concordância (diferença <= 1 ponto)
  COUNT(*) FILTER (WHERE ABS(la.score_manual - la.score_auto) <= 1.0) as concordant_count,
  ROUND(
    (COUNT(*) FILTER (WHERE ABS(la.score_manual - la.score_auto) <= 1.0) * 100.0) / 
    NULLIF(COUNT(*) FILTER (WHERE la.score_auto IS NOT NULL AND la.score_manual IS NOT NULL), 0),
    2
  ) as concordance_rate,
  
  -- Discordância (diferença > 3 pontos)
  COUNT(*) FILTER (WHERE ABS(la.score_manual - la.score_auto) > 3.0) as discordant_count,
  ROUND(
    (COUNT(*) FILTER (WHERE ABS(la.score_manual - la.score_auto) > 3.0) * 100.0) / 
    NULLIF(COUNT(*) FILTER (WHERE la.score_auto IS NOT NULL AND la.score_manual IS NOT NULL), 0),
    2
  ) as discordance_rate,
  
  -- Médias de cada tipo
  ROUND(AVG(la.score_auto)::numeric, 2) as avg_auto_score,
  ROUND(AVG(la.score_manual)::numeric, 2) as avg_manual_score

FROM live_assessments la
WHERE la.deleted_at IS NULL
  AND la.score_auto IS NOT NULL
  AND la.score_manual IS NOT NULL
GROUP BY la.company_id;

-- ============================================================================
-- 5. VIEW: assessment_performance_timeline
-- Timeline de performance de avaliações
-- ============================================================================

CREATE OR REPLACE VIEW assessment_performance_timeline AS
SELECT 
  la.company_id,
  DATE(la.created_at) as assessment_date,
  
  -- Contadores diários
  COUNT(*) as daily_assessments,
  COUNT(*) FILTER (WHERE la.status = 'auto_evaluated') as auto_evaluated,
  COUNT(*) FILTER (WHERE la.status = 'manually_adjusted') as manually_adjusted,
  
  -- Médias diárias
  ROUND(AVG(la.score_final)::numeric, 2) as avg_daily_score,
  ROUND(AVG(la.response_time_seconds)::numeric, 2) as avg_response_time,
  
  -- Min/Max
  ROUND(MIN(la.score_final)::numeric, 2) as min_score,
  ROUND(MAX(la.score_final)::numeric, 2) as max_score

FROM live_assessments la
WHERE la.deleted_at IS NULL
GROUP BY la.company_id, DATE(la.created_at)
ORDER BY assessment_date DESC;

-- ============================================================================
-- 6. FUNÇÃO: get_assessment_metrics(company_id UUID)
-- Retorna métricas consolidadas de avaliações
-- ============================================================================

CREATE OR REPLACE FUNCTION get_assessment_metrics(p_company_id UUID)
RETURNS TABLE (
  metric_name TEXT,
  metric_value NUMERIC,
  metric_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    'total_assessments'::TEXT as metric_name,
    COUNT(*)::NUMERIC as metric_value,
    'Total de avaliações realizadas'::TEXT as metric_label
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'auto_evaluated_count'::TEXT,
    COUNT(*)::NUMERIC,
    'Avaliações automáticas (IA)'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.status = 'auto_evaluated'
    AND la.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'manually_adjusted_count'::TEXT,
    COUNT(*)::NUMERIC,
    'Avaliações ajustadas manualmente'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.status = 'manually_adjusted'
    AND la.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'manual_adjustment_rate'::TEXT,
    ROUND(
      (COUNT(*) FILTER (WHERE la.score_manual IS NOT NULL) * 100.0) / NULLIF(COUNT(*), 0),
      2
    )::NUMERIC,
    '% de avaliações ajustadas manualmente'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'avg_score_final'::TEXT,
    ROUND(AVG(la.score_final)::NUMERIC, 2),
    'Score médio final'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'concordance_rate'::TEXT,
    COALESCE(
      ROUND(
        (COUNT(*) FILTER (WHERE ABS(la.score_manual - la.score_auto) <= 1.0) * 100.0) / 
        NULLIF(COUNT(*) FILTER (WHERE la.score_auto IS NOT NULL AND la.score_manual IS NOT NULL), 0),
        2
      ),
      0
    )::NUMERIC,
    '% de concordância entre IA e avaliador (diff <= 1)'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'avg_response_time'::TEXT,
    ROUND(AVG(la.response_time_seconds)::NUMERIC, 2),
    'Tempo médio de resposta (segundos)'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.deleted_at IS NULL
    AND la.response_time_seconds IS NOT NULL
  
  UNION ALL
  
  SELECT 
    'assessments_last_7_days'::TEXT,
    COUNT(*)::NUMERIC,
    'Avaliações nos últimos 7 dias'::TEXT
  FROM live_assessments la
  WHERE la.company_id = p_company_id
    AND la.created_at >= now() - interval '7 days'
    AND la.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. ÍNDICES ADICIONAIS PARA PERFORMANCE DAS VIEWS
-- ============================================================================

-- Índice para score_auto e score_manual (concordância)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_scores'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_scores 
    ON live_assessments(company_id, score_auto, score_manual) 
    WHERE deleted_at IS NULL AND score_auto IS NOT NULL AND score_manual IS NOT NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para DATE(created_at) (timeline)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_live_assessments_date'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_live_assessments_date 
    ON live_assessments(company_id, (DATE(created_at))) 
    WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- FIM DA MIGRATION 019
-- ============================================================================
