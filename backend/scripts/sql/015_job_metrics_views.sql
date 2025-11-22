-- Migration 015: Views de métricas para gerenciamento de vagas (RF2)
-- Data: 22/11/2025

-- ============================================================================
-- 1. VIEW: job_stats_overview
-- Estatísticas gerais de vagas por empresa
-- ============================================================================

CREATE OR REPLACE VIEW job_stats_overview AS
SELECT 
  j.company_id,
  
  -- Total de vagas
  COUNT(*) as total_jobs,
  COUNT(*) FILTER (WHERE j.deleted_at IS NULL) as active_jobs,
  
  -- Por status
  COUNT(*) FILTER (WHERE j.status = 'draft' AND j.deleted_at IS NULL) as draft_jobs,
  COUNT(*) FILTER (WHERE j.status = 'open' AND j.deleted_at IS NULL) as open_jobs,
  COUNT(*) FILTER (WHERE j.status = 'paused' AND j.deleted_at IS NULL) as paused_jobs,
  COUNT(*) FILTER (WHERE j.status = 'closed' AND j.deleted_at IS NULL) as closed_jobs,
  COUNT(*) FILTER (WHERE j.status = 'archived' AND j.deleted_at IS NULL) as archived_jobs,
  
  -- Vagas recentes (últimos 7 e 30 dias)
  COUNT(*) FILTER (WHERE j.created_at >= now() - interval '7 days' AND j.deleted_at IS NULL) as jobs_last_7_days,
  COUNT(*) FILTER (WHERE j.created_at >= now() - interval '30 days' AND j.deleted_at IS NULL) as jobs_last_30_days,
  
  -- Vagas publicadas e fechadas recentemente
  COUNT(*) FILTER (WHERE j.published_at >= now() - interval '30 days' AND j.deleted_at IS NULL) as published_last_30_days,
  COUNT(*) FILTER (WHERE j.closed_at >= now() - interval '30 days') as closed_last_30_days,
  
  -- Tempo médio até publicação (em dias)
  AVG(
    CASE 
      WHEN j.published_at IS NOT NULL AND j.published_at > j.created_at 
      THEN EXTRACT(epoch FROM (j.published_at - j.created_at)) / 86400.0
      ELSE NULL 
    END
  ) as avg_days_to_publish,
  
  -- Tempo médio em aberto (em dias)
  AVG(
    CASE 
      WHEN j.closed_at IS NOT NULL AND j.published_at IS NOT NULL
      THEN EXTRACT(epoch FROM (j.closed_at - j.published_at)) / 86400.0
      ELSE NULL 
    END
  ) as avg_days_open

FROM jobs j
WHERE j.deleted_at IS NULL
GROUP BY j.company_id;

-- ============================================================================
-- 2. VIEW: job_crud_stats
-- Estatísticas de operações CRUD por dia
-- ============================================================================

CREATE OR REPLACE VIEW job_crud_stats AS
SELECT 
  j.company_id,
  DATE(j.created_at) as operation_date,
  
  -- Vagas criadas
  COUNT(*) as jobs_created,
  
  -- Por status inicial
  COUNT(*) FILTER (WHERE j.status = 'draft') as created_as_draft,
  COUNT(*) FILTER (WHERE j.status = 'open') as created_as_open,
  
  -- Por tipo de localização
  COUNT(*) FILTER (WHERE j.is_remote = true) as remote_jobs,
  COUNT(*) FILTER (WHERE j.location_type = 'hybrid') as hybrid_jobs,
  COUNT(*) FILTER (WHERE j.location_type = 'onsite') as onsite_jobs,
  
  -- Por senioridade
  COUNT(*) FILTER (WHERE j.seniority = 'junior') as junior_jobs,
  COUNT(*) FILTER (WHERE j.seniority = 'pleno') as pleno_jobs,
  COUNT(*) FILTER (WHERE j.seniority = 'senior') as senior_jobs,
  COUNT(*) FILTER (WHERE j.seniority = 'lead') as lead_jobs,
  
  -- Vagas atualizadas no dia
  COUNT(*) FILTER (WHERE DATE(j.updated_at) = DATE(j.created_at) AND j.updated_at > j.created_at) as jobs_updated_same_day,
  
  -- Vagas deletadas no dia
  COUNT(*) FILTER (WHERE DATE(j.deleted_at) = DATE(j.created_at)) as jobs_deleted_same_day

FROM jobs j
GROUP BY j.company_id, DATE(j.created_at)
ORDER BY operation_date DESC;

-- ============================================================================
-- 3. VIEW: job_by_department_stats
-- Estatísticas de vagas por departamento
-- ============================================================================

CREATE OR REPLACE VIEW job_by_department_stats AS
SELECT 
  j.company_id,
  COALESCE(j.department, 'Sem departamento') as department,
  
  -- Total de vagas
  COUNT(*) as total_jobs,
  COUNT(*) FILTER (WHERE j.deleted_at IS NULL) as active_jobs,
  
  -- Por status
  COUNT(*) FILTER (WHERE j.status = 'open' AND j.deleted_at IS NULL) as open_jobs,
  COUNT(*) FILTER (WHERE j.status = 'closed' AND j.deleted_at IS NULL) as closed_jobs,
  
  -- Média salarial
  AVG(j.salary_min) as avg_salary_min,
  AVG(j.salary_max) as avg_salary_max,
  
  -- Taxa de preenchimento (vagas fechadas / total)
  CASE 
    WHEN COUNT(*) > 0 
    THEN ROUND((COUNT(*) FILTER (WHERE j.status = 'closed') * 100.0) / COUNT(*), 2)
    ELSE 0
  END as fill_rate_percentage

FROM jobs j
WHERE j.deleted_at IS NULL
GROUP BY j.company_id, COALESCE(j.department, 'Sem departamento')
ORDER BY total_jobs DESC;

-- ============================================================================
-- 4. VIEW: job_revision_history
-- Histórico de revisões de vagas
-- ============================================================================

CREATE OR REPLACE VIEW job_revision_history AS
SELECT 
  jr.company_id,
  jr.job_id,
  j.title as current_title,
  jr.version,
  jr.title as revision_title,
  jr.status as revision_status,
  jr.changed_by,
  u.full_name as changed_by_name,
  u.email as changed_by_email,
  jr.changed_at,
  jr.change_notes,
  
  -- Diferenças detectadas
  (jr.title IS DISTINCT FROM j.title) as title_changed,
  (jr.description IS DISTINCT FROM j.description) as description_changed,
  (jr.requirements IS DISTINCT FROM j.requirements) as requirements_changed,
  (jr.status IS DISTINCT FROM j.status) as status_changed,
  (jr.salary_min IS DISTINCT FROM j.salary_min OR jr.salary_max IS DISTINCT FROM j.salary_max) as salary_changed

FROM job_revisions jr
JOIN jobs j ON j.id = jr.job_id
LEFT JOIN users u ON u.id = jr.changed_by
ORDER BY jr.changed_at DESC;

-- ============================================================================
-- 5. VIEW: job_performance_by_period
-- Performance de vagas por período (útil para relatórios)
-- ============================================================================

CREATE OR REPLACE VIEW job_performance_by_period AS
SELECT 
  j.company_id,
  DATE_TRUNC('month', j.created_at) as period_month,
  DATE_TRUNC('week', j.created_at) as period_week,
  
  -- Vagas criadas no período
  COUNT(*) as jobs_created,
  
  -- Vagas publicadas
  COUNT(*) FILTER (WHERE j.published_at IS NOT NULL) as jobs_published,
  
  -- Vagas fechadas
  COUNT(*) FILTER (WHERE j.closed_at IS NOT NULL) as jobs_closed,
  
  -- Tempo médio de publicação
  AVG(
    CASE 
      WHEN j.published_at IS NOT NULL 
      THEN EXTRACT(epoch FROM (j.published_at - j.created_at)) / 86400.0
      ELSE NULL 
    END
  ) as avg_days_to_publish,
  
  -- Tempo médio em aberto
  AVG(
    CASE 
      WHEN j.closed_at IS NOT NULL AND j.published_at IS NOT NULL
      THEN EXTRACT(epoch FROM (j.closed_at - j.published_at)) / 86400.0
      ELSE NULL 
    END
  ) as avg_days_open

FROM jobs j
GROUP BY j.company_id, DATE_TRUNC('month', j.created_at), DATE_TRUNC('week', j.created_at)
ORDER BY period_month DESC, period_week DESC;

-- ============================================================================
-- 6. FUNÇÃO: get_job_metrics(company_id UUID)
-- Retorna métricas consolidadas de vagas para uma empresa
-- ============================================================================

CREATE OR REPLACE FUNCTION get_job_metrics(p_company_id UUID)
RETURNS TABLE (
  metric_name TEXT,
  metric_value NUMERIC,
  metric_label TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    'total_jobs'::TEXT as metric_name,
    COUNT(*)::NUMERIC as metric_value,
    'Total de vagas cadastradas'::TEXT as metric_label
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'open_jobs'::TEXT,
    COUNT(*)::NUMERIC,
    'Vagas abertas'::TEXT
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.status = 'open'
    AND j.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'draft_jobs'::TEXT,
    COUNT(*)::NUMERIC,
    'Vagas em rascunho'::TEXT
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.status = 'draft'
    AND j.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'closed_jobs'::TEXT,
    COUNT(*)::NUMERIC,
    'Vagas fechadas'::TEXT
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.status = 'closed'
    AND j.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'jobs_last_30_days'::TEXT,
    COUNT(*)::NUMERIC,
    'Vagas criadas nos últimos 30 dias'::TEXT
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.created_at >= now() - interval '30 days'
    AND j.deleted_at IS NULL
  
  UNION ALL
  
  SELECT 
    'avg_days_to_publish'::TEXT,
    ROUND(AVG(
      CASE 
        WHEN j.published_at IS NOT NULL 
        THEN EXTRACT(epoch FROM (j.published_at - j.created_at)) / 86400.0
        ELSE NULL 
      END
    )::NUMERIC, 2),
    'Tempo médio até publicação (dias)'::TEXT
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.published_at IS NOT NULL
  
  UNION ALL
  
  SELECT 
    'avg_days_open'::TEXT,
    ROUND(AVG(
      CASE 
        WHEN j.closed_at IS NOT NULL AND j.published_at IS NOT NULL
        THEN EXTRACT(epoch FROM (j.closed_at - j.published_at)) / 86400.0
        ELSE NULL 
      END
    )::NUMERIC, 2),
    'Tempo médio de vaga aberta (dias)'::TEXT
  FROM jobs j
  WHERE j.company_id = p_company_id
    AND j.closed_at IS NOT NULL
    AND j.published_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. CRIAR ÍNDICES PARA PERFORMANCE DAS VIEWS
-- ============================================================================

-- Índice para company_id + created_at (usado em várias views)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_jobs_company_created'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_jobs_company_created ON jobs(company_id, created_at DESC) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para company_id + updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_jobs_company_updated'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_jobs_company_updated ON jobs(company_id, updated_at DESC) WHERE deleted_at IS NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para company_id + deleted_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_jobs_deleted_at'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_jobs_deleted_at ON jobs(company_id, deleted_at) WHERE deleted_at IS NOT NULL;
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- Índice para job_revisions + company_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
    AND c.relname = 'idx_job_revisions_company'
    AND n.nspname = 'public'
  ) THEN
    CREATE INDEX idx_job_revisions_company ON job_revisions(company_id, changed_at DESC);
  END IF;
EXCEPTION WHEN duplicate_table THEN NULL;
END $$;

-- ============================================================================
-- FIM DA MIGRATION 015
-- ============================================================================
