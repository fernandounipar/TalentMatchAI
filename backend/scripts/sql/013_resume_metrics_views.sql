-- ============================================================
-- 013_resume_metrics_views.sql
-- Views de métricas para RF1 - Triagem de Currículos
-- ============================================================

-- View: resume_processing_stats
-- Estatísticas de processamento de currículos
CREATE OR REPLACE VIEW resume_processing_stats AS
SELECT
  r.company_id,
  COUNT(*) AS total_resumes,
  COUNT(*) FILTER (WHERE r.created_at >= CURRENT_DATE - INTERVAL '7 days') AS resumes_last_7_days,
  COUNT(*) FILTER (WHERE r.created_at >= CURRENT_DATE - INTERVAL '30 days') AS resumes_last_30_days,
  COUNT(*) FILTER (WHERE r.status = 'pending') AS pending_count,
  COUNT(*) FILTER (WHERE r.status = 'reviewed') AS reviewed_count,
  COUNT(*) FILTER (WHERE r.status = 'accepted') AS accepted_count,
  COUNT(*) FILTER (WHERE r.status = 'rejected') AS rejected_count,
  COUNT(*) FILTER (WHERE r.is_favorite = true) AS favorites_count,
  COUNT(DISTINCT r.job_id) AS jobs_with_resumes,
  AVG(EXTRACT(EPOCH FROM (r.updated_at - r.created_at))) AS avg_processing_time_seconds,
  (
    SELECT AVG(ra.score)
    FROM resume_analysis ra
    INNER JOIN resumes r2 ON r2.id = ra.resume_id
    WHERE r2.company_id = r.company_id
  ) AS avg_score,
  (
    SELECT COUNT(*)
    FROM resume_analysis ra
    INNER JOIN resumes r2 ON r2.id = ra.resume_id
    WHERE r2.company_id = r.company_id
      AND ra.created_at >= CURRENT_DATE - INTERVAL '24 hours'
  ) AS analyses_last_24h
FROM resumes r
WHERE r.deleted_at IS NULL
GROUP BY r.company_id;

COMMENT ON VIEW resume_processing_stats IS 'Estatísticas gerais de processamento de currículos por empresa';

-- View: resume_crud_stats
-- Estatísticas de operações CRUD por período
CREATE OR REPLACE VIEW resume_crud_stats AS
SELECT
  r.company_id,
  DATE(r.created_at) AS date,
  COUNT(*) FILTER (WHERE r.created_at::date = DATE(r.created_at)) AS created_count,
  COUNT(*) FILTER (WHERE r.updated_at::date = DATE(r.created_at) AND r.updated_at > r.created_at) AS updated_count,
  COUNT(*) FILTER (WHERE r.deleted_at IS NOT NULL) AS deleted_count,
  COUNT(DISTINCT r.job_id) AS distinct_jobs,
  COUNT(DISTINCT r.candidate_id) AS distinct_candidates,
  AVG(r.file_size) AS avg_file_size_bytes,
  MAX(r.file_size) AS max_file_size_bytes,
  COUNT(*) FILTER (WHERE r.mime_type = 'application/pdf') AS pdf_count,
  COUNT(*) FILTER (WHERE r.mime_type = 'text/plain') AS txt_count,
  COUNT(*) FILTER (WHERE r.mime_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') AS docx_count
FROM resumes r
GROUP BY r.company_id, DATE(r.created_at)
ORDER BY r.company_id, DATE(r.created_at) DESC;

COMMENT ON VIEW resume_crud_stats IS 'Estatísticas diárias de operações CRUD em currículos';

-- View: resume_analysis_performance
-- Performance das análises de currículo (tempo de processamento)
CREATE OR REPLACE VIEW resume_analysis_performance AS
SELECT
  r.company_id,
  ra.provider,
  ra.model,
  COUNT(*) AS total_analyses,
  AVG(ra.score) AS avg_score,
  MIN(ra.score) AS min_score,
  MAX(ra.score) AS max_score,
  COUNT(*) FILTER (WHERE ra.score >= 85) AS high_score_count,
  COUNT(*) FILTER (WHERE ra.score >= 70 AND ra.score < 85) AS medium_score_count,
  COUNT(*) FILTER (WHERE ra.score < 70) AS low_score_count,
  AVG(EXTRACT(EPOCH FROM (ra.created_at - r.created_at))) AS avg_time_to_analysis_seconds,
  COUNT(*) FILTER (WHERE ra.created_at >= CURRENT_DATE - INTERVAL '7 days') AS analyses_last_7_days,
  COUNT(*) FILTER (WHERE ra.created_at >= CURRENT_DATE - INTERVAL '30 days') AS analyses_last_30_days
FROM resume_analysis ra
INNER JOIN resumes r ON r.id = ra.resume_id
WHERE r.deleted_at IS NULL
GROUP BY r.company_id, ra.provider, ra.model;

COMMENT ON VIEW resume_analysis_performance IS 'Performance e estatísticas das análises de currículo por provider/model';

-- View: resume_by_job_stats
-- Estatísticas de currículos por vaga
CREATE OR REPLACE VIEW resume_by_job_stats AS
SELECT
  j.company_id,
  j.id AS job_id,
  j.title AS job_title,
  j.status AS job_status,
  COUNT(r.id) AS total_resumes,
  COUNT(r.id) FILTER (WHERE r.status = 'pending') AS pending_resumes,
  COUNT(r.id) FILTER (WHERE r.status = 'reviewed') AS reviewed_resumes,
  COUNT(r.id) FILTER (WHERE r.status = 'accepted') AS accepted_resumes,
  COUNT(r.id) FILTER (WHERE r.status = 'rejected') AS rejected_resumes,
  COUNT(r.id) FILTER (WHERE r.is_favorite = true) AS favorite_resumes,
  (
    SELECT AVG(ra.score)
    FROM resume_analysis ra
    WHERE ra.resume_id IN (SELECT id FROM resumes WHERE job_id = j.id AND deleted_at IS NULL)
  ) AS avg_score,
  COUNT(r.id) FILTER (WHERE r.created_at >= CURRENT_DATE - INTERVAL '7 days') AS resumes_last_7_days,
  MAX(r.created_at) AS last_resume_received_at
FROM jobs j
LEFT JOIN resumes r ON r.job_id = j.id AND r.deleted_at IS NULL
WHERE j.deleted_at IS NULL
GROUP BY j.company_id, j.id, j.title, j.status
ORDER BY total_resumes DESC;

COMMENT ON VIEW resume_by_job_stats IS 'Estatísticas de currículos agrupadas por vaga';

-- View: candidate_resume_history
-- Histórico de currículos por candidato
CREATE OR REPLACE VIEW candidate_resume_history AS
SELECT
  c.company_id,
  c.id AS candidate_id,
  c.full_name,
  c.email,
  c.phone,
  COUNT(r.id) AS total_resumes_submitted,
  MAX(r.created_at) AS last_resume_date,
  MIN(r.created_at) AS first_resume_date,
  COUNT(DISTINCT r.job_id) AS jobs_applied_count,
  (
    SELECT AVG(ra.score)
    FROM resume_analysis ra
    WHERE ra.resume_id IN (SELECT id FROM resumes WHERE candidate_id = c.id AND deleted_at IS NULL)
  ) AS avg_score_across_submissions,
  COUNT(r.id) FILTER (WHERE r.status = 'accepted') AS accepted_count,
  COUNT(r.id) FILTER (WHERE r.status = 'rejected') AS rejected_count
FROM candidates c
LEFT JOIN resumes r ON r.candidate_id = c.id AND r.deleted_at IS NULL
WHERE c.deleted_at IS NULL
GROUP BY c.company_id, c.id, c.full_name, c.email, c.phone;

COMMENT ON VIEW candidate_resume_history IS 'Histórico de submissões de currículos por candidato';

-- Índices adicionais para performance das views
CREATE INDEX IF NOT EXISTS idx_resumes_created_at_company ON resumes(company_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_resumes_status_company ON resumes(company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_resumes_job_company ON resumes(company_id, job_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_resumes_favorite ON resumes(company_id, is_favorite) WHERE deleted_at IS NULL AND is_favorite = true;
CREATE INDEX IF NOT EXISTS idx_resume_analysis_provider ON resume_analysis(provider, model);
CREATE INDEX IF NOT EXISTS idx_resume_analysis_score ON resume_analysis(score);
CREATE INDEX IF NOT EXISTS idx_resume_analysis_created_at ON resume_analysis(created_at DESC);

-- Função auxiliar para obter métricas consolidadas
CREATE OR REPLACE FUNCTION get_resume_metrics(p_company_id UUID)
RETURNS TABLE(
  metric_name TEXT,
  metric_value NUMERIC,
  metric_unit TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 'total_resumes'::TEXT, COUNT(*)::NUMERIC, 'count'::TEXT
  FROM resumes WHERE company_id = p_company_id AND deleted_at IS NULL
  UNION ALL
  SELECT 'avg_processing_time'::TEXT, 
         AVG(EXTRACT(EPOCH FROM (updated_at - created_at)))::NUMERIC, 
         'seconds'::TEXT
  FROM resumes WHERE company_id = p_company_id AND deleted_at IS NULL
  UNION ALL
  SELECT 'avg_score'::TEXT,
         AVG(ra.score)::NUMERIC,
         'percentage'::TEXT
  FROM resume_analysis ra
  INNER JOIN resumes r ON r.id = ra.resume_id
  WHERE r.company_id = p_company_id AND r.deleted_at IS NULL
  UNION ALL
  SELECT 'analyses_last_24h'::TEXT,
         COUNT(*)::NUMERIC,
         'count'::TEXT
  FROM resume_analysis ra
  INNER JOIN resumes r ON r.id = ra.resume_id
  WHERE r.company_id = p_company_id 
    AND ra.created_at >= NOW() - INTERVAL '24 hours'
    AND r.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_resume_metrics(UUID) IS 'Retorna métricas consolidadas de currículos para uma empresa';
