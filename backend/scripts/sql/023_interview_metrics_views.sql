-- Migration 023: Interview History Metrics Views
-- RF8 - Métricas e KPIs de Histórico de Entrevistas
-- Data: 22/11/2025

DO $$
BEGIN
  RAISE NOTICE '=== Migration 023: Interview History Metrics ===';

  -- =============================================
  -- 1. VIEW: interview_stats_overview
  -- =============================================
  
  DROP VIEW IF EXISTS interview_stats_overview CASCADE;
  
  CREATE VIEW interview_stats_overview AS
  SELECT
    i.company_id,
    COUNT(*) as total_interviews,
    COUNT(*) FILTER (WHERE i.status = 'scheduled') as scheduled_count,
    COUNT(*) FILTER (WHERE i.status = 'in_progress') as in_progress_count,
    COUNT(*) FILTER (WHERE i.status = 'completed') as completed_count,
    COUNT(*) FILTER (WHERE i.status = 'cancelled') as cancelled_count,
    COUNT(*) FILTER (WHERE i.status = 'no_show') as no_show_count,
    COUNT(*) FILTER (WHERE i.result = 'approved') as approved_count,
    COUNT(*) FILTER (WHERE i.result = 'rejected') as rejected_count,
    COUNT(*) FILTER (WHERE i.result = 'pending') as pending_count,
    ROUND(AVG(i.overall_score)::numeric, 2) as avg_overall_score,
    ROUND(AVG(i.duration_minutes)::numeric, 0) as avg_duration_minutes,
    COUNT(*) FILTER (WHERE i.created_at >= now() - interval '7 days') as interviews_last_7_days,
    COUNT(*) FILTER (WHERE i.created_at >= now() - interval '30 days') as interviews_last_30_days,
    COUNT(*) FILTER (WHERE i.completed_at >= now() - interval '7 days') as completed_last_7_days,
    COUNT(*) FILTER (WHERE i.completed_at >= now() - interval '30 days') as completed_last_30_days
  FROM interviews i
  WHERE i.deleted_at IS NULL
  GROUP BY i.company_id;
  
  RAISE NOTICE '✓ View interview_stats_overview criada';

  -- =============================================
  -- 2. VIEW: interviews_by_status
  -- =============================================
  
  DROP VIEW IF EXISTS interviews_by_status CASCADE;
  
  CREATE VIEW interviews_by_status AS
  SELECT
    i.company_id,
    i.status,
    COUNT(*) as interview_count,
    ROUND(AVG(i.overall_score)::numeric, 2) as avg_score,
    ROUND(AVG(i.duration_minutes)::numeric, 0) as avg_duration,
    MIN(i.scheduled_at) as earliest_scheduled,
    MAX(i.scheduled_at) as latest_scheduled
  FROM interviews i
  WHERE i.deleted_at IS NULL
  GROUP BY i.company_id, i.status
  ORDER BY i.company_id, i.status;
  
  RAISE NOTICE '✓ View interviews_by_status criada';

  -- =============================================
  -- 3. VIEW: interviews_by_result
  -- =============================================
  
  DROP VIEW IF EXISTS interviews_by_result CASCADE;
  
  CREATE VIEW interviews_by_result AS
  SELECT
    i.company_id,
    i.result,
    COUNT(*) as interview_count,
    ROUND(AVG(i.overall_score)::numeric, 2) as avg_score,
    COUNT(*) FILTER (WHERE i.status = 'completed') as completed_count
  FROM interviews i
  WHERE i.deleted_at IS NULL
    AND i.result IS NOT NULL
  GROUP BY i.company_id, i.result
  ORDER BY i.company_id, i.result;
  
  RAISE NOTICE '✓ View interviews_by_result criada';

  -- =============================================
  -- 4. VIEW: interview_timeline
  -- =============================================
  
  DROP VIEW IF EXISTS interview_timeline CASCADE;
  
  CREATE VIEW interview_timeline AS
  SELECT
    i.company_id,
    DATE(i.created_at) as interview_date,
    COUNT(*) as interviews_created,
    COUNT(*) FILTER (WHERE i.status = 'scheduled') as scheduled,
    COUNT(*) FILTER (WHERE i.status = 'completed') as completed,
    COUNT(*) FILTER (WHERE i.status = 'cancelled') as cancelled,
    COUNT(*) FILTER (WHERE i.result = 'approved') as approved,
    COUNT(*) FILTER (WHERE i.result = 'rejected') as rejected,
    ROUND(AVG(i.overall_score)::numeric, 2) as avg_score,
    ROUND(AVG(i.duration_minutes)::numeric, 0) as avg_duration
  FROM interviews i
  WHERE i.deleted_at IS NULL
  GROUP BY i.company_id, DATE(i.created_at)
  ORDER BY i.company_id, interview_date DESC;
  
  RAISE NOTICE '✓ View interview_timeline criada';

  -- =============================================
  -- 5. VIEW: interviews_by_job
  -- =============================================
  
  DROP VIEW IF EXISTS interviews_by_job CASCADE;
  
  CREATE VIEW interviews_by_job AS
  SELECT
    i.company_id,
    a.job_id,
    j.title as job_title,
    COUNT(*) as total_interviews,
    COUNT(*) FILTER (WHERE i.status = 'completed') as completed_interviews,
    COUNT(*) FILTER (WHERE i.result = 'approved') as approved_count,
    COUNT(*) FILTER (WHERE i.result = 'rejected') as rejected_count,
    ROUND(AVG(i.overall_score)::numeric, 2) as avg_score,
    MAX(i.scheduled_at) as last_interview_date
  FROM interviews i
  JOIN applications a ON a.id = i.application_id
  LEFT JOIN jobs j ON j.id = a.job_id
  WHERE i.deleted_at IS NULL
  GROUP BY i.company_id, a.job_id, j.title
  ORDER BY i.company_id, total_interviews DESC;
  
  RAISE NOTICE '✓ View interviews_by_job criada';

  -- =============================================
  -- 6. VIEW: interviews_by_interviewer
  -- =============================================
  
  DROP VIEW IF EXISTS interviews_by_interviewer CASCADE;
  
  CREATE VIEW interviews_by_interviewer AS
  SELECT
    i.company_id,
    i.interviewer_id,
    u.full_name as interviewer_name,
    COUNT(*) as total_interviews,
    COUNT(*) FILTER (WHERE i.status = 'completed') as completed_count,
    COUNT(*) FILTER (WHERE i.result = 'approved') as approved_count,
    ROUND(AVG(i.overall_score)::numeric, 2) as avg_score,
    ROUND(AVG(i.duration_minutes)::numeric, 0) as avg_duration
  FROM interviews i
  LEFT JOIN users u ON u.id = i.interviewer_id
  WHERE i.deleted_at IS NULL
    AND i.interviewer_id IS NOT NULL
  GROUP BY i.company_id, i.interviewer_id, u.full_name
  ORDER BY i.company_id, total_interviews DESC;
  
  RAISE NOTICE '✓ View interviews_by_interviewer criada';

  -- =============================================
  -- 7. VIEW: interview_completion_rate
  -- =============================================
  
  DROP VIEW IF EXISTS interview_completion_rate CASCADE;
  
  CREATE VIEW interview_completion_rate AS
  SELECT
    i.company_id,
    DATE(i.scheduled_at) as scheduled_date,
    COUNT(*) as total_scheduled,
    COUNT(*) FILTER (WHERE i.status = 'completed') as completed,
    COUNT(*) FILTER (WHERE i.status = 'cancelled') as cancelled,
    COUNT(*) FILTER (WHERE i.status = 'no_show') as no_show,
    CASE 
      WHEN COUNT(*) > 0 
      THEN ROUND((COUNT(*) FILTER (WHERE i.status = 'completed')::numeric / COUNT(*) * 100), 2)
      ELSE 0
    END as completion_rate,
    CASE 
      WHEN COUNT(*) > 0 
      THEN ROUND((COUNT(*) FILTER (WHERE i.status = 'no_show')::numeric / COUNT(*) * 100), 2)
      ELSE 0
    END as no_show_rate
  FROM interviews i
  WHERE i.deleted_at IS NULL
    AND i.scheduled_at IS NOT NULL
  GROUP BY i.company_id, DATE(i.scheduled_at)
  ORDER BY i.company_id, scheduled_date DESC;
  
  RAISE NOTICE '✓ View interview_completion_rate criada';

  -- =============================================
  -- 8. FUNÇÃO: get_interview_metrics
  -- =============================================
  
  CREATE OR REPLACE FUNCTION get_interview_metrics(p_company_id UUID)
  RETURNS JSON AS $func$
  DECLARE
    v_result JSON;
  BEGIN
    SELECT json_build_object(
      'total_interviews', COALESCE(total_interviews, 0),
      'scheduled_count', COALESCE(scheduled_count, 0),
      'in_progress_count', COALESCE(in_progress_count, 0),
      'completed_count', COALESCE(completed_count, 0),
      'cancelled_count', COALESCE(cancelled_count, 0),
      'no_show_count', COALESCE(no_show_count, 0),
      'approval_rate', CASE 
        WHEN COALESCE(completed_count, 0) > 0 
        THEN ROUND((COALESCE(approved_count, 0)::numeric / completed_count * 100), 2)
        ELSE 0
      END,
      'rejection_rate', CASE 
        WHEN COALESCE(completed_count, 0) > 0 
        THEN ROUND((COALESCE(rejected_count, 0)::numeric / completed_count * 100), 2)
        ELSE 0
      END,
      'avg_overall_score', COALESCE(avg_overall_score, 0),
      'avg_duration_minutes', COALESCE(avg_duration_minutes, 0),
      'interviews_last_7_days', COALESCE(interviews_last_7_days, 0),
      'interviews_last_30_days', COALESCE(interviews_last_30_days, 0),
      'completed_last_7_days', COALESCE(completed_last_7_days, 0),
      'completed_last_30_days', COALESCE(completed_last_30_days, 0)
    )
    INTO v_result
    FROM interview_stats_overview
    WHERE company_id = p_company_id;
    
    -- Se não houver dados, retornar zeros
    IF v_result IS NULL THEN
      v_result := json_build_object(
        'total_interviews', 0,
        'scheduled_count', 0,
        'in_progress_count', 0,
        'completed_count', 0,
        'cancelled_count', 0,
        'no_show_count', 0,
        'approval_rate', 0,
        'rejection_rate', 0,
        'avg_overall_score', 0,
        'avg_duration_minutes', 0,
        'interviews_last_7_days', 0,
        'interviews_last_30_days', 0,
        'completed_last_7_days', 0,
        'completed_last_30_days', 0
      );
    END IF;
    
    RETURN v_result;
  END;
  $func$ LANGUAGE plpgsql STABLE;
  
  RAISE NOTICE '✓ Função get_interview_metrics criada';

  -- =============================================
  -- 9. ÍNDICES ADICIONAIS PARA PERFORMANCE
  -- =============================================
  
  RAISE NOTICE 'Criando índices adicionais para queries de métricas...';
  
  CREATE INDEX IF NOT EXISTS idx_interviews_company_status 
    ON interviews(company_id, status) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_company_result 
    ON interviews(company_id, result) WHERE deleted_at IS NULL AND result IS NOT NULL;
  
  CREATE INDEX IF NOT EXISTS idx_interviews_scheduled_date 
    ON interviews(DATE(scheduled_at)) WHERE deleted_at IS NULL AND scheduled_at IS NOT NULL;
  
  RAISE NOTICE '✓ 3 índices adicionais criados';

  -- =============================================
  -- 10. COMENTÁRIOS
  -- =============================================
  
  COMMENT ON VIEW interview_stats_overview IS 'RF8 - Estatísticas gerais de entrevistas por empresa';
  COMMENT ON VIEW interviews_by_status IS 'RF8 - Entrevistas agrupadas por status';
  COMMENT ON VIEW interviews_by_result IS 'RF8 - Entrevistas agrupadas por resultado (approved/rejected/pending)';
  COMMENT ON VIEW interview_timeline IS 'RF8 - Timeline diária de entrevistas';
  COMMENT ON VIEW interviews_by_job IS 'RF8 - Entrevistas agrupadas por vaga';
  COMMENT ON VIEW interviews_by_interviewer IS 'RF8 - Entrevistas agrupadas por entrevistador';
  COMMENT ON VIEW interview_completion_rate IS 'RF8 - Taxa de conclusão de entrevistas por dia';
  COMMENT ON FUNCTION get_interview_metrics IS 'RF8 - Retorna métricas consolidadas de entrevistas para dashboard';

  RAISE NOTICE '=== Migration 023 concluída com sucesso ===';

END $$;
