/**
 * Migration 027: Dashboard Metrics Views & Consolidated KPIs
 * RF9 - Dashboard de Acompanhamento
 * 
 * Cria views consolidadas para métricas globais do dashboard
 * e função para retornar overview completo
 */

-- ============================================================================
-- View 1: dashboard_global_overview
-- ============================================================================
-- Métricas gerais consolidadas por company

CREATE OR REPLACE VIEW dashboard_global_overview AS
SELECT
  company_id,
  
  -- Contadores principais
  COUNT(DISTINCT CASE WHEN resource_type = 'job' THEN resource_id END) as total_jobs,
  COUNT(DISTINCT CASE WHEN resource_type = 'job' AND status = 'open' THEN resource_id END) as active_jobs,
  COUNT(DISTINCT CASE WHEN resource_type = 'resume' THEN resource_id END) as total_resumes,
  COUNT(DISTINCT CASE WHEN resource_type = 'candidate' THEN resource_id END) as total_candidates,
  COUNT(DISTINCT CASE WHEN resource_type = 'interview' THEN resource_id END) as total_interviews,
  COUNT(DISTINCT CASE WHEN resource_type = 'interview' AND status = 'completed' THEN resource_id END) as completed_interviews,
  COUNT(DISTINCT CASE WHEN resource_type = 'report' THEN resource_id END) as total_reports,
  COUNT(DISTINCT CASE WHEN resource_type = 'user' THEN resource_id END) as total_users,
  COUNT(DISTINCT CASE WHEN resource_type = 'user' AND status = 'active' THEN resource_id END) as active_users,
  
  -- Atividade recente (últimos 7 dias)
  COUNT(DISTINCT CASE 
    WHEN resource_type = 'job' AND created_at >= NOW() - INTERVAL '7 days' 
    THEN resource_id 
  END) as jobs_last_7_days,
  
  COUNT(DISTINCT CASE 
    WHEN resource_type = 'resume' AND created_at >= NOW() - INTERVAL '7 days' 
    THEN resource_id 
  END) as resumes_last_7_days,
  
  COUNT(DISTINCT CASE 
    WHEN resource_type = 'interview' AND created_at >= NOW() - INTERVAL '7 days' 
    THEN resource_id 
  END) as interviews_last_7_days,
  
  -- Última atualização
  MAX(created_at) as last_activity_at

FROM (
  -- Jobs
  SELECT id as resource_id, 'job' as resource_type, company_id, status, created_at
  FROM jobs WHERE deleted_at IS NULL
  
  UNION ALL
  
  -- Resumes
  SELECT id, 'resume', company_id, NULL as status, created_at
  FROM resumes WHERE deleted_at IS NULL
  
  UNION ALL
  
  -- Candidates
  SELECT id, 'candidate', company_id, NULL, created_at
  FROM candidates WHERE deleted_at IS NULL
  
  UNION ALL
  
  -- Interviews
  SELECT id, 'interview', company_id, status::text, created_at
  FROM interviews WHERE deleted_at IS NULL
  
  UNION ALL
  
  -- Reports
  SELECT id, 'report', company_id, NULL, created_at
  FROM interview_reports WHERE deleted_at IS NULL
  
  UNION ALL
  
  -- Users
  SELECT id, 'user', company_id, CASE WHEN is_active THEN 'active' ELSE 'inactive' END, created_at
  FROM users WHERE deleted_at IS NULL
) all_resources
GROUP BY company_id;

-- ============================================================================
-- View 2: dashboard_activity_timeline
-- ============================================================================
-- Timeline de atividades agregadas por dia

CREATE OR REPLACE VIEW dashboard_activity_timeline AS
SELECT
  company_id,
  DATE(created_at) as activity_date,
  
  -- Contadores por tipo de recurso
  COUNT(DISTINCT CASE WHEN resource_type = 'job' THEN resource_id END) as jobs_created,
  COUNT(DISTINCT CASE WHEN resource_type = 'resume' THEN resource_id END) as resumes_uploaded,
  COUNT(DISTINCT CASE WHEN resource_type = 'interview' THEN resource_id END) as interviews_scheduled,
  COUNT(DISTINCT CASE WHEN resource_type = 'report' THEN resource_id END) as reports_generated,
  COUNT(DISTINCT CASE WHEN resource_type = 'user' THEN resource_id END) as users_registered,
  
  -- Total geral de atividades
  COUNT(*) as total_activities

FROM (
  SELECT id as resource_id, 'job' as resource_type, company_id, created_at
  FROM jobs WHERE deleted_at IS NULL
  
  UNION ALL
  
  SELECT id, 'resume', company_id, created_at
  FROM resumes WHERE deleted_at IS NULL
  
  UNION ALL
  
  SELECT id, 'interview', company_id, created_at
  FROM interviews WHERE deleted_at IS NULL
  
  UNION ALL
  
  SELECT id, 'report', company_id, created_at
  FROM interview_reports WHERE deleted_at IS NULL
  
  UNION ALL
  
  SELECT id, 'user', company_id, created_at
  FROM users WHERE deleted_at IS NULL
) all_activities
GROUP BY company_id, DATE(created_at);

-- ============================================================================
-- View 3: dashboard_preset_usage_stats
-- ============================================================================
-- Estatísticas de uso de presets por company

CREATE OR REPLACE VIEW dashboard_preset_usage_stats AS
SELECT
  company_id,
  
  -- Contadores
  COUNT(*) as total_presets,
  COUNT(CASE WHEN is_default THEN 1 END) as default_presets,
  COUNT(CASE WHEN is_shared THEN 1 END) as shared_presets,
  COUNT(DISTINCT user_id) as users_with_presets,
  
  -- Métricas de uso
  SUM(usage_count) as total_usage,
  AVG(usage_count) as avg_usage_per_preset,
  MAX(usage_count) as max_usage,
  
  -- Atividade recente
  COUNT(CASE WHEN last_used_at >= NOW() - INTERVAL '7 days' THEN 1 END) as used_last_7_days,
  COUNT(CASE WHEN last_used_at >= NOW() - INTERVAL '30 days' THEN 1 END) as used_last_30_days,
  
  -- Timestamps
  MAX(last_used_at) as most_recent_usage,
  MAX(created_at) as most_recent_creation

FROM dashboard_presets
WHERE deleted_at IS NULL
GROUP BY company_id;

-- ============================================================================
-- View 4: dashboard_top_presets
-- ============================================================================
-- Presets mais usados por company

CREATE OR REPLACE VIEW dashboard_top_presets AS
SELECT
  dp.company_id,
  dp.id as preset_id,
  dp.name as preset_name,
  dp.description,
  dp.is_shared,
  dp.shared_with_roles,
  dp.usage_count,
  dp.last_used_at,
  dp.created_at,
  u.full_name as created_by,
  
  -- Ranking por company
  ROW_NUMBER() OVER (
    PARTITION BY dp.company_id 
    ORDER BY dp.usage_count DESC, dp.last_used_at DESC NULLS LAST
  ) as usage_rank

FROM dashboard_presets dp
LEFT JOIN users u ON dp.user_id = u.id
WHERE dp.deleted_at IS NULL
ORDER BY dp.company_id, usage_rank;

-- ============================================================================
-- View 5: dashboard_conversion_funnel
-- ============================================================================
-- Funil de conversão: vagas → currículos → entrevistas → contratações

CREATE OR REPLACE VIEW dashboard_conversion_funnel AS
SELECT
  j.company_id,
  j.id as job_id,
  j.title as job_title,
  j.status as job_status,
  j.created_at as job_created_at,
  
  -- Contadores do funil
  COUNT(DISTINCT r.id) as total_resumes,
  COUNT(DISTINCT i.id) as total_interviews,
  COUNT(DISTINCT CASE WHEN i.status = 'completed' THEN i.id END) as completed_interviews,
  COUNT(DISTINCT CASE WHEN ir.recommendation = 'APPROVE' THEN ir.id END) as approved_candidates,
  
  -- Taxas de conversão (percentuais)
  CASE 
    WHEN COUNT(DISTINCT r.id) > 0 
    THEN ROUND((COUNT(DISTINCT i.id)::NUMERIC / COUNT(DISTINCT r.id)) * 100, 2)
    ELSE 0
  END as resume_to_interview_rate,
  
  CASE 
    WHEN COUNT(DISTINCT i.id) > 0 
    THEN ROUND((COUNT(DISTINCT CASE WHEN ir.recommendation = 'APPROVE' THEN ir.id END)::NUMERIC / COUNT(DISTINCT i.id)) * 100, 2)
    ELSE 0
  END as interview_to_approval_rate

FROM jobs j
LEFT JOIN resumes r ON r.job_id = j.id AND r.deleted_at IS NULL
LEFT JOIN applications app ON app.job_id = j.id AND app.deleted_at IS NULL
LEFT JOIN interviews i ON i.application_id = app.id AND i.deleted_at IS NULL
LEFT JOIN interview_reports ir ON ir.interview_id = i.id AND ir.deleted_at IS NULL
WHERE j.deleted_at IS NULL
GROUP BY j.company_id, j.id, j.title, j.status, j.created_at;

-- ============================================================================
-- Função: get_dashboard_overview(company_id UUID)
-- ============================================================================
-- Retorna overview consolidado com todas as métricas principais

CREATE OR REPLACE FUNCTION get_dashboard_overview(p_company_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    -- Métricas globais
    'global', (
      SELECT json_build_object(
        'total_jobs', COALESCE(total_jobs, 0),
        'active_jobs', COALESCE(active_jobs, 0),
        'total_resumes', COALESCE(total_resumes, 0),
        'total_candidates', COALESCE(total_candidates, 0),
        'total_interviews', COALESCE(total_interviews, 0),
        'completed_interviews', COALESCE(completed_interviews, 0),
        'total_reports', COALESCE(total_reports, 0),
        'total_users', COALESCE(total_users, 0),
        'active_users', COALESCE(active_users, 0),
        'jobs_last_7_days', COALESCE(jobs_last_7_days, 0),
        'resumes_last_7_days', COALESCE(resumes_last_7_days, 0),
        'interviews_last_7_days', COALESCE(interviews_last_7_days, 0),
        'last_activity_at', last_activity_at
      )
      FROM dashboard_global_overview
      WHERE company_id = p_company_id
    ),
    
    -- Estatísticas de presets
    'presets', (
      SELECT json_build_object(
        'total_presets', COALESCE(total_presets, 0),
        'default_presets', COALESCE(default_presets, 0),
        'shared_presets', COALESCE(shared_presets, 0),
        'users_with_presets', COALESCE(users_with_presets, 0),
        'total_usage', COALESCE(total_usage, 0),
        'avg_usage_per_preset', COALESCE(ROUND(avg_usage_per_preset::NUMERIC, 2), 0),
        'used_last_7_days', COALESCE(used_last_7_days, 0),
        'used_last_30_days', COALESCE(used_last_30_days, 0)
      )
      FROM dashboard_preset_usage_stats
      WHERE company_id = p_company_id
    ),
    
    -- Funil de conversão agregado
    'conversion', (
      SELECT json_build_object(
        'total_jobs', COUNT(*),
        'avg_resumes_per_job', COALESCE(ROUND(AVG(total_resumes)::NUMERIC, 2), 0),
        'avg_interviews_per_job', COALESCE(ROUND(AVG(total_interviews)::NUMERIC, 2), 0),
        'avg_resume_to_interview_rate', COALESCE(ROUND(AVG(resume_to_interview_rate)::NUMERIC, 2), 0),
        'avg_interview_to_approval_rate', COALESCE(ROUND(AVG(interview_to_approval_rate)::NUMERIC, 2), 0)
      )
      FROM dashboard_conversion_funnel
      WHERE company_id = p_company_id
    )
  ) INTO v_result;
  
  RETURN COALESCE(v_result, '{}'::json);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Índices Adicionais para Views
-- ============================================================================

-- Índice para acelerar queries de activity_timeline
CREATE INDEX IF NOT EXISTS idx_jobs_company_created_date
  ON jobs(company_id, DATE(created_at))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_resumes_company_created_date
  ON resumes(company_id, DATE(created_at))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_interviews_company_created_date
  ON interviews(company_id, DATE(created_at))
  WHERE deleted_at IS NULL;

-- ============================================================================
-- Comentários
-- ============================================================================

COMMENT ON VIEW dashboard_global_overview IS 
  'RF9: Overview global consolidado com 13 métricas principais por company';

COMMENT ON VIEW dashboard_activity_timeline IS 
  'RF9: Timeline diária de atividades com 7 métricas por tipo de recurso';

COMMENT ON VIEW dashboard_preset_usage_stats IS 
  'RF9: Estatísticas de uso de presets com 11 métricas';

COMMENT ON VIEW dashboard_top_presets IS 
  'RF9: Ranking de presets mais usados por company';

COMMENT ON VIEW dashboard_conversion_funnel IS 
  'RF9: Funil de conversão vagas → currículos → entrevistas → aprovações';

COMMENT ON FUNCTION get_dashboard_overview(UUID) IS 
  'RF9: Retorna JSON com overview consolidado (26+ métricas) para uma company';
