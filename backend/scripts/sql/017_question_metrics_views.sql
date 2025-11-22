-- Migration 017: Views de métricas para Question Sets (RF3)
-- Data: 22/11/2025

-- ============================================================================
-- 1. VIEW: question_sets_stats
-- Estatísticas de conjuntos de perguntas
-- ============================================================================

CREATE OR REPLACE VIEW question_sets_stats AS
SELECT 
  qs.company_id,
  
  -- Total de conjuntos
  COUNT(*) as total_sets,
  COUNT(*) FILTER (WHERE qs.deleted_at IS NULL) as active_sets,
  COUNT(*) FILTER (WHERE qs.is_template = true AND qs.deleted_at IS NULL) as template_sets,
  
  -- Conjuntos recentes
  COUNT(*) FILTER (WHERE qs.created_at >= now() - interval '7 days' AND qs.deleted_at IS NULL) as sets_last_7_days,
  COUNT(*) FILTER (WHERE qs.created_at >= now() - interval '30 days' AND qs.deleted_at IS NULL) as sets_last_30_days,
  
  -- Média de perguntas por conjunto
  AVG(
    (
      SELECT COUNT(*) 
      FROM interview_questions iq 
      WHERE iq.set_id = qs.id 
      AND iq.deleted_at IS NULL
    )
  )::numeric(10,2) as avg_questions_per_set,
  
  -- Total de perguntas
  (
    SELECT COUNT(*) 
    FROM interview_questions iq 
    WHERE iq.company_id = qs.company_id 
    AND iq.deleted_at IS NULL
  ) as total_questions

FROM interview_question_sets qs
WHERE qs.deleted_at IS NULL
GROUP BY qs.company_id;

-- ============================================================================
-- 2. VIEW: question_sets_by_job
-- Conjuntos de perguntas por vaga
-- ============================================================================

CREATE OR REPLACE VIEW question_sets_by_job AS
SELECT 
  qs.company_id,
  qs.job_id,
  j.title as job_title,
  
  -- Contadores
  COUNT(DISTINCT qs.id) as total_sets,
  COUNT(DISTINCT iq.id) as total_questions,
  
  -- Tipos de perguntas
  COUNT(DISTINCT iq.id) FILTER (WHERE iq.type = 'behavioral') as behavioral_questions,
  COUNT(DISTINCT iq.id) FILTER (WHERE iq.type = 'technical') as technical_questions,
  COUNT(DISTINCT iq.id) FILTER (WHERE iq.type = 'situational') as situational_questions,
  COUNT(DISTINCT iq.id) FILTER (WHERE iq.type = 'cultural') as cultural_questions,
  
  -- Última atualização
  MAX(qs.updated_at) as last_updated

FROM interview_question_sets qs
LEFT JOIN jobs j ON j.id = qs.job_id
LEFT JOIN interview_questions iq ON iq.set_id = qs.id AND iq.deleted_at IS NULL
WHERE qs.deleted_at IS NULL
  AND qs.job_id IS NOT NULL
GROUP BY qs.company_id, qs.job_id, j.title;

-- ============================================================================
-- 3. VIEW: question_type_distribution
-- Distribuição de perguntas por tipo
-- ============================================================================

CREATE OR REPLACE VIEW question_type_distribution AS
SELECT 
  iq.company_id,
  iq.type,
  
  -- Contadores
  COUNT(*) as total_questions,
  COUNT(DISTINCT iq.set_id) as sets_with_this_type,
  
  -- Percentual
  ROUND(
    (COUNT(*) * 100.0) / NULLIF(
      (SELECT COUNT(*) FROM interview_questions WHERE company_id = iq.company_id AND deleted_at IS NULL), 
      0
    ), 
    2
  ) as percentage

FROM interview_questions iq
WHERE iq.deleted_at IS NULL
GROUP BY iq.company_id, iq.type
ORDER BY total_questions DESC;

-- ============================================================================
-- 4. VIEW: question_sets_usage
-- Uso de conjuntos de perguntas (reutilização)
-- ============================================================================

CREATE OR REPLACE VIEW question_sets_usage AS
SELECT 
  qs.id as set_id,
  qs.company_id,
  qs.title,
  qs.is_template,
  
  -- Contadores
  (
    SELECT COUNT(*) 
    FROM interview_questions iq 
    WHERE iq.set_id = qs.id 
    AND iq.deleted_at IS NULL
  ) as question_count,
  
  -- Uso em entrevistas (via interview_id)
  (
    SELECT COUNT(DISTINCT iq.interview_id) 
    FROM interview_questions iq 
    WHERE iq.set_id = qs.id 
    AND iq.interview_id IS NOT NULL
  ) as times_used,
  
  -- Metadados
  qs.created_at,
  qs.updated_at,
  u.full_name as created_by_name

FROM interview_question_sets qs
LEFT JOIN users u ON u.id = qs.created_by
WHERE qs.deleted_at IS NULL
ORDER BY times_used DESC;

-- ============================================================================
-- 5. VIEW: question_editing_stats
-- Estatísticas de edição de perguntas (IA vs Manual)
-- ============================================================================

CREATE OR REPLACE VIEW question_editing_stats AS
SELECT 
  iq.company_id,
  
  -- Perguntas por origem
  COUNT(*) FILTER (WHERE iq.origin = 'ai_generated') as ai_generated,
  COUNT(*) FILTER (WHERE iq.origin = 'manual') as manual_created,
  COUNT(*) FILTER (WHERE iq.origin = 'ai_edited') as ai_edited,
  
  -- Percentuais
  ROUND(
    (COUNT(*) FILTER (WHERE iq.origin = 'ai_generated') * 100.0) / NULLIF(COUNT(*), 0), 
    2
  ) as ai_generated_percentage,
  
  ROUND(
    (COUNT(*) FILTER (WHERE iq.origin = 'ai_edited') * 100.0) / NULLIF(COUNT(*), 0), 
    2
  ) as ai_edited_percentage,
  
  -- Total
  COUNT(*) as total_questions

FROM interview_questions iq
WHERE iq.deleted_at IS NULL
GROUP BY iq.company_id;

-- ============================================================================
-- 6. FUNÇÃO: get_question_set_metrics(company_id UUID)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_question_set_metrics(p_company_id UUID)
RETURNS TABLE (
  metric_name TEXT,
  metric_value NUMERIC,
  metric_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    'total_sets'::TEXT as metric_name,
    COUNT(*)::NUMERIC as metric_value,
    'Total de conjuntos de perguntas'::TEXT as metric_label
  FROM interview_question_sets qs
  WHERE qs.company_id = p_company_id
    AND qs.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'template_sets'::TEXT,
    COUNT(*)::NUMERIC,
    'Conjuntos modelo (reutilizáveis)'::TEXT
  FROM interview_question_sets qs
  WHERE qs.company_id = p_company_id
    AND qs.is_template = true
    AND qs.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'total_questions'::TEXT,
    COUNT(*)::NUMERIC,
    'Total de perguntas criadas'::TEXT
  FROM interview_questions iq
  WHERE iq.company_id = p_company_id
    AND iq.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'avg_questions_per_set'::TEXT,
    ROUND(AVG(question_count)::NUMERIC, 2),
    'Média de perguntas por conjunto'::TEXT
  FROM (
    SELECT 
      qs.id,
      COUNT(iq.id) as question_count
    FROM interview_question_sets qs
    LEFT JOIN interview_questions iq ON iq.set_id = qs.id AND iq.deleted_at IS NULL
    WHERE qs.company_id = p_company_id
      AND qs.deleted_at IS NULL
    GROUP BY qs.id
  ) as counts
  
  UNION ALL
  
  SELECT 
    'ai_generated_percentage'::TEXT,
    ROUND(
      (COUNT(*) FILTER (WHERE iq.origin = 'ai_generated') * 100.0) / NULLIF(COUNT(*), 0), 
      2
    )::NUMERIC,
    '% de perguntas geradas por IA'::TEXT
  FROM interview_questions iq
  WHERE iq.company_id = p_company_id
    AND iq.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'sets_last_30_days'::TEXT,
    COUNT(*)::NUMERIC,
    'Conjuntos criados nos últimos 30 dias'::TEXT
  FROM interview_question_sets qs
  WHERE qs.company_id = p_company_id
    AND qs.created_at >= now() - interval '30 days'
    AND qs.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. CRIAR ÍNDICES ADICIONAIS PARA PERFORMANCE DAS VIEWS
-- ============================================================================

-- Índice para origin em interview_questions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_interview_questions_origin'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_interview_questions_origin ON interview_questions(company_id, origin) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para created_at em question_sets
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_question_sets_created'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_question_sets_created ON interview_question_sets(company_id, created_at DESC) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- FIM DA MIGRATION 017
-- ============================================================================
