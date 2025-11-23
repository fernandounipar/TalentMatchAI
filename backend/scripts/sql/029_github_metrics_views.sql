-- ============================================================================
-- Migration 029: GitHub Integration Metrics Views
-- ============================================================================
-- Views e função para métricas de integração GitHub

-- ============================================================================
-- View 1: github_integration_stats
-- ============================================================================
-- Estatísticas gerais de integração GitHub por company

CREATE OR REPLACE VIEW github_integration_stats AS
SELECT 
  company_id,
  
  -- Counts
  COUNT(*)::INTEGER as total_integrations,
  COUNT(*) FILTER (WHERE sync_status = 'success')::INTEGER as successful_syncs,
  COUNT(*) FILTER (WHERE sync_status = 'error')::INTEGER as failed_syncs,
  COUNT(*) FILTER (WHERE sync_status = 'pending')::INTEGER as pending_syncs,
  COUNT(*) FILTER (WHERE sync_status = 'rate_limited')::INTEGER as rate_limited,
  COUNT(*) FILTER (WHERE consent_given = TRUE)::INTEGER as with_consent,
  
  -- Averages
  ROUND(AVG(public_repos), 2) as avg_public_repos,
  ROUND(AVG(followers), 2) as avg_followers,
  ROUND(AVG(following), 2) as avg_following,
  
  -- Activity
  COUNT(*) FILTER (WHERE last_synced_at >= NOW() - INTERVAL '7 days')::INTEGER as synced_last_7_days,
  COUNT(*) FILTER (WHERE last_synced_at >= NOW() - INTERVAL '30 days')::INTEGER as synced_last_30_days,
  COUNT(*) FILTER (WHERE last_synced_at IS NULL OR last_synced_at < NOW() - INTERVAL '30 days')::INTEGER as stale_profiles,
  
  -- Timestamps
  MAX(last_synced_at) as most_recent_sync,
  MIN(created_at) as oldest_integration,
  MAX(created_at) as newest_integration

FROM candidate_github_profiles
WHERE deleted_at IS NULL
GROUP BY company_id;

COMMENT ON VIEW github_integration_stats IS 'Estatísticas gerais de integração GitHub por company';

-- ============================================================================
-- View 2: github_sync_timeline
-- ============================================================================
-- Timeline diária de sincronizações

CREATE OR REPLACE VIEW github_sync_timeline AS
SELECT 
  company_id,
  DATE(last_synced_at) as sync_date,
  
  COUNT(*)::INTEGER as total_syncs,
  COUNT(*) FILTER (WHERE sync_status = 'success')::INTEGER as successful,
  COUNT(*) FILTER (WHERE sync_status = 'error')::INTEGER as failed,
  COUNT(*) FILTER (WHERE sync_status = 'rate_limited')::INTEGER as rate_limited,
  
  ROUND(
    (COUNT(*) FILTER (WHERE sync_status = 'success')::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 
    2
  ) as success_rate

FROM candidate_github_profiles
WHERE deleted_at IS NULL 
  AND last_synced_at IS NOT NULL
GROUP BY company_id, DATE(last_synced_at);

COMMENT ON VIEW github_sync_timeline IS 'Timeline diária de sincronizações GitHub';

-- ============================================================================
-- View 3: github_top_languages
-- ============================================================================
-- Linguagens mais populares entre candidatos com GitHub

CREATE OR REPLACE VIEW github_top_languages AS
SELECT 
  company_id,
  lang->>'name' as language,
  
  COUNT(DISTINCT candidate_id)::INTEGER as developers_count,
  ROUND(AVG((lang->>'percentage')::NUMERIC), 2) as avg_percentage,
  SUM((lang->>'repos_count')::INTEGER) as total_repos

FROM candidate_github_profiles gp,
     jsonb_array_elements(gp.summary->'top_languages') as lang
WHERE gp.deleted_at IS NULL
  AND gp.summary ? 'top_languages'
GROUP BY company_id, lang->>'name';

COMMENT ON VIEW github_top_languages IS 'Linguagens mais populares entre candidatos com GitHub';

-- ============================================================================
-- View 4: github_top_candidates
-- ============================================================================
-- Candidatos com perfis GitHub mais ativos/populares

CREATE OR REPLACE VIEW github_top_candidates AS
SELECT 
  gp.company_id,
  gp.candidate_id,
  gp.username,
  gp.avatar_url,
  gp.profile_url,
  
  -- Stats
  gp.public_repos,
  gp.followers,
  gp.following,
  (gp.summary->>'total_stars')::INTEGER as total_stars,
  (gp.summary->>'total_forks')::INTEGER as total_forks,
  (gp.summary->>'contribution_streak')::INTEGER as contribution_streak,
  (gp.summary->>'profile_completeness_score')::INTEGER as completeness_score,
  
  -- Ranking (ROW_NUMBER particionado por company)
  ROW_NUMBER() OVER (
    PARTITION BY gp.company_id 
    ORDER BY 
      COALESCE((gp.summary->>'total_stars')::INTEGER, 0) + 
      COALESCE(gp.followers, 0) * 2 + 
      COALESCE(gp.public_repos, 0) DESC
  ) as popularity_rank,
  
  gp.last_synced_at

FROM candidate_github_profiles gp
WHERE gp.deleted_at IS NULL
  AND gp.sync_status = 'success';

COMMENT ON VIEW github_top_candidates IS 'Ranking de candidatos por popularidade GitHub';

-- ============================================================================
-- View 5: github_skills_distribution
-- ============================================================================
-- Distribuição de skills detectadas via GitHub

CREATE OR REPLACE VIEW github_skills_distribution AS
SELECT 
  company_id,
  skill,
  
  COUNT(DISTINCT candidate_id)::INTEGER as candidates_count,
  ROUND(
    (COUNT(DISTINCT candidate_id)::NUMERIC / 
     NULLIF((SELECT COUNT(DISTINCT candidate_id) 
             FROM candidate_github_profiles 
             WHERE company_id = gp.company_id 
               AND deleted_at IS NULL), 0)) * 100,
    2
  ) as percentage_of_total

FROM candidate_github_profiles gp,
     jsonb_array_elements_text(gp.summary->'skills_detected') as skill
WHERE gp.deleted_at IS NULL
  AND gp.summary ? 'skills_detected'
GROUP BY company_id, skill;

COMMENT ON VIEW github_skills_distribution IS 'Distribuição de skills detectadas via GitHub';

-- ============================================================================
-- Função: get_github_metrics(company_id)
-- ============================================================================
-- Retorna métricas consolidadas de integração GitHub

CREATE OR REPLACE FUNCTION get_github_metrics(p_company_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    -- Stats gerais
    'stats', (
      SELECT json_build_object(
        'total_integrations', COALESCE(total_integrations, 0),
        'successful_syncs', COALESCE(successful_syncs, 0),
        'failed_syncs', COALESCE(failed_syncs, 0),
        'pending_syncs', COALESCE(pending_syncs, 0),
        'rate_limited', COALESCE(rate_limited, 0),
        'with_consent', COALESCE(with_consent, 0),
        'avg_public_repos', COALESCE(avg_public_repos, 0),
        'avg_followers', COALESCE(avg_followers, 0),
        'synced_last_7_days', COALESCE(synced_last_7_days, 0),
        'synced_last_30_days', COALESCE(synced_last_30_days, 0),
        'stale_profiles', COALESCE(stale_profiles, 0),
        'most_recent_sync', most_recent_sync
      )
      FROM github_integration_stats
      WHERE company_id = p_company_id
    ),
    
    -- Top 5 linguagens
    'top_languages', (
      SELECT json_agg(
        json_build_object(
          'language', language,
          'developers_count', developers_count,
          'avg_percentage', avg_percentage,
          'total_repos', total_repos
        )
      )
      FROM (
        SELECT * FROM github_top_languages
        WHERE company_id = p_company_id
        ORDER BY developers_count DESC, total_repos DESC
        LIMIT 5
      ) t
    ),
    
    -- Top 10 candidatos
    'top_candidates', (
      SELECT json_agg(
        json_build_object(
          'candidate_id', candidate_id,
          'username', username,
          'popularity_rank', popularity_rank,
          'public_repos', public_repos,
          'followers', followers,
          'total_stars', total_stars,
          'completeness_score', completeness_score
        )
      )
      FROM (
        SELECT * FROM github_top_candidates
        WHERE company_id = p_company_id
        ORDER BY popularity_rank
        LIMIT 10
      ) t
    ),
    
    -- Success rate últimos 7 dias
    'recent_success_rate', (
      SELECT COALESCE(ROUND(AVG(success_rate), 2), 0)
      FROM github_sync_timeline
      WHERE company_id = p_company_id
        AND sync_date >= CURRENT_DATE - INTERVAL '7 days'
    )
    
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_github_metrics IS 'Retorna métricas consolidadas de integração GitHub';

-- ============================================================================
-- Índices Adicionais
-- ============================================================================

-- Acelerar queries de timeline
CREATE INDEX IF NOT EXISTS idx_github_sync_date 
  ON candidate_github_profiles(company_id, DATE(last_synced_at)) 
  WHERE deleted_at IS NULL AND last_synced_at IS NOT NULL;

-- Acelerar queries de candidatos ativos
CREATE INDEX IF NOT EXISTS idx_github_candidate_active 
  ON candidate_github_profiles(candidate_id) 
  WHERE deleted_at IS NULL AND sync_status = 'success';

-- Acelerar queries de consent
CREATE INDEX IF NOT EXISTS idx_github_consent 
  ON candidate_github_profiles(company_id, consent_given) 
  WHERE deleted_at IS NULL;
