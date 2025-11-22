-- Migration 021: Interview Reports Metrics Views
-- RF7 - Métricas e KPIs de Relatórios de Entrevistas
-- Data: 22/11/2025

DO $$
BEGIN
  RAISE NOTICE '=== Migration 021: Interview Reports Metrics ===';

  -- =============================================
  -- 1. VIEW: report_stats_overview
  -- =============================================
  
  DROP VIEW IF EXISTS report_stats_overview CASCADE;
  
  CREATE VIEW report_stats_overview AS
  SELECT
    company_id,
    COUNT(*) as total_reports,
    COUNT(*) FILTER (WHERE is_final = true) as final_reports,
    COUNT(*) FILTER (WHERE is_final = false) as draft_reports,
    COUNT(*) FILTER (WHERE recommendation = 'APPROVE') as approved_count,
    COUNT(*) FILTER (WHERE recommendation = 'REJECT') as rejected_count,
    COUNT(*) FILTER (WHERE recommendation = 'MAYBE') as maybe_count,
    COUNT(*) FILTER (WHERE recommendation = 'PENDING') as pending_count,
    ROUND(AVG(overall_score)::numeric, 2) as avg_overall_score,
    COUNT(*) FILTER (WHERE format = 'pdf') as pdf_reports,
    COUNT(*) FILTER (WHERE format = 'json') as json_reports,
    COUNT(*) FILTER (WHERE created_at >= now() - interval '7 days') as reports_last_7_days,
    COUNT(*) FILTER (WHERE created_at >= now() - interval '30 days') as reports_last_30_days
  FROM interview_reports
  WHERE deleted_at IS NULL
  GROUP BY company_id;
  
  RAISE NOTICE '✓ View report_stats_overview criada';

  -- =============================================
  -- 2. VIEW: reports_by_recommendation
  -- =============================================
  
  DROP VIEW IF EXISTS reports_by_recommendation CASCADE;
  
  CREATE VIEW reports_by_recommendation AS
  SELECT
    company_id,
    recommendation,
    COUNT(*) as report_count,
    ROUND(AVG(overall_score)::numeric, 2) as avg_score,
    MIN(overall_score) as min_score,
    MAX(overall_score) as max_score,
    COUNT(*) FILTER (WHERE is_final = true) as final_count,
    COUNT(*) FILTER (WHERE is_final = false) as draft_count
  FROM interview_reports
  WHERE deleted_at IS NULL
    AND recommendation IS NOT NULL
  GROUP BY company_id, recommendation
  ORDER BY company_id, recommendation;
  
  RAISE NOTICE '✓ View reports_by_recommendation criada';

  -- =============================================
  -- 3. VIEW: reports_by_type
  -- =============================================
  
  DROP VIEW IF EXISTS reports_by_type CASCADE;
  
  CREATE VIEW reports_by_type AS
  SELECT
    company_id,
    report_type,
    COUNT(*) as report_count,
    ROUND(AVG(overall_score)::numeric, 2) as avg_score,
    COUNT(*) FILTER (WHERE format = 'pdf') as pdf_count,
    COUNT(*) FILTER (WHERE format = 'json') as json_count,
    COUNT(*) FILTER (WHERE is_final = true) as final_count
  FROM interview_reports
  WHERE deleted_at IS NULL
  GROUP BY company_id, report_type
  ORDER BY company_id, report_type;
  
  RAISE NOTICE '✓ View reports_by_type criada';

  -- =============================================
  -- 4. VIEW: report_generation_timeline
  -- =============================================
  
  DROP VIEW IF EXISTS report_generation_timeline CASCADE;
  
  CREATE VIEW report_generation_timeline AS
  SELECT
    company_id,
    DATE(generated_at) as generation_date,
    COUNT(*) as reports_generated,
    COUNT(*) FILTER (WHERE is_final = true) as final_reports,
    ROUND(AVG(overall_score)::numeric, 2) as avg_score,
    COUNT(DISTINCT interview_id) as unique_interviews,
    COUNT(*) FILTER (WHERE recommendation = 'APPROVE') as approved,
    COUNT(*) FILTER (WHERE recommendation = 'REJECT') as rejected
  FROM interview_reports
  WHERE deleted_at IS NULL
    AND generated_at IS NOT NULL
  GROUP BY company_id, DATE(generated_at)
  ORDER BY company_id, generation_date DESC;
  
  RAISE NOTICE '✓ View report_generation_timeline criada';

  -- =============================================
  -- 5. VIEW: reports_by_interview
  -- =============================================
  
  DROP VIEW IF EXISTS reports_by_interview CASCADE;
  
  CREATE VIEW reports_by_interview AS
  SELECT
    r.company_id,
    r.interview_id,
    r.candidate_name,
    r.job_title,
    COUNT(*) as total_versions,
    MAX(r.version) as latest_version,
    MAX(r.overall_score) FILTER (WHERE r.is_final = true) as final_score,
    MAX(r.recommendation) FILTER (WHERE r.is_final = true) as final_recommendation,
    MAX(r.generated_at) as last_generated_at,
    COUNT(*) FILTER (WHERE r.is_final = true) as final_count,
    COUNT(*) FILTER (WHERE r.is_final = false) as draft_count
  FROM interview_reports r
  WHERE r.deleted_at IS NULL
  GROUP BY r.company_id, r.interview_id, r.candidate_name, r.job_title
  ORDER BY r.company_id, last_generated_at DESC;
  
  RAISE NOTICE '✓ View reports_by_interview criada';

  -- =============================================
  -- 6. FUNÇÃO: get_report_metrics
  -- =============================================
  
  CREATE OR REPLACE FUNCTION get_report_metrics(p_company_id UUID)
  RETURNS JSON AS $func$
  DECLARE
    v_result JSON;
  BEGIN
    SELECT json_build_object(
      'total_reports', COALESCE(total_reports, 0),
      'final_reports', COALESCE(final_reports, 0),
      'draft_reports', COALESCE(draft_reports, 0),
      'approval_rate', CASE 
        WHEN COALESCE(total_reports, 0) > 0 
        THEN ROUND((COALESCE(approved_count, 0)::numeric / total_reports * 100), 2)
        ELSE 0
      END,
      'rejection_rate', CASE 
        WHEN COALESCE(total_reports, 0) > 0 
        THEN ROUND((COALESCE(rejected_count, 0)::numeric / total_reports * 100), 2)
        ELSE 0
      END,
      'avg_overall_score', COALESCE(avg_overall_score, 0),
      'reports_last_7_days', COALESCE(reports_last_7_days, 0),
      'reports_last_30_days', COALESCE(reports_last_30_days, 0),
      'pdf_reports', COALESCE(pdf_reports, 0),
      'json_reports', COALESCE(json_reports, 0)
    )
    INTO v_result
    FROM report_stats_overview
    WHERE company_id = p_company_id;
    
    -- Se não houver dados, retornar zeros
    IF v_result IS NULL THEN
      v_result := json_build_object(
        'total_reports', 0,
        'final_reports', 0,
        'draft_reports', 0,
        'approval_rate', 0,
        'rejection_rate', 0,
        'avg_overall_score', 0,
        'reports_last_7_days', 0,
        'reports_last_30_days', 0,
        'pdf_reports', 0,
        'json_reports', 0
      );
    END IF;
    
    RETURN v_result;
  END;
  $func$ LANGUAGE plpgsql STABLE;
  
  RAISE NOTICE '✓ Função get_report_metrics criada';

  -- =============================================
  -- 7. ÍNDICES ADICIONAIS PARA PERFORMANCE
  -- =============================================
  
  RAISE NOTICE 'Criando índices adicionais para queries de métricas...';
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_score 
    ON interview_reports(overall_score) WHERE deleted_at IS NULL AND overall_score IS NOT NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interview_reports_company_recommendation 
    ON interview_reports(company_id, recommendation) WHERE deleted_at IS NULL;
  
  RAISE NOTICE '✓ 2 índices adicionais criados';

  -- =============================================
  -- 8. COMENTÁRIOS
  -- =============================================
  
  COMMENT ON VIEW report_stats_overview IS 'RF7 - Estatísticas gerais de relatórios por empresa';
  COMMENT ON VIEW reports_by_recommendation IS 'RF7 - Relatórios agrupados por recomendação (APPROVE/REJECT/MAYBE)';
  COMMENT ON VIEW reports_by_type IS 'RF7 - Relatórios agrupados por tipo (full/summary/technical/behavioral)';
  COMMENT ON VIEW report_generation_timeline IS 'RF7 - Timeline diária de geração de relatórios';
  COMMENT ON VIEW reports_by_interview IS 'RF7 - Relatórios agrupados por entrevista com versionamento';
  COMMENT ON FUNCTION get_report_metrics IS 'RF7 - Retorna métricas consolidadas de relatórios para dashboard';

  RAISE NOTICE '=== Migration 021 concluída com sucesso ===';

END $$;
