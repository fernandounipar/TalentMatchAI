-- ============================================================================
-- Migration 028: GitHub Integration
-- ============================================================================
-- Adiciona suporte para integração opcional com GitHub API
-- Permite vincular perfil GitHub a candidatos para enriquecer análise técnica

-- ============================================================================
-- Tabela: candidate_github_profiles
-- ============================================================================
-- Armazena dados do GitHub vinculados a candidatos

CREATE TABLE IF NOT EXISTS candidate_github_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id UUID NOT NULL,
  company_id UUID NOT NULL,
  
  -- GitHub data
  username VARCHAR(100) NOT NULL,
  github_id INTEGER,
  avatar_url TEXT,
  profile_url TEXT,
  bio TEXT,
  location VARCHAR(200),
  blog VARCHAR(500),
  company VARCHAR(200),
  email VARCHAR(200),
  hireable BOOLEAN,
  
  -- Stats
  public_repos INTEGER DEFAULT 0,
  public_gists INTEGER DEFAULT 0,
  followers INTEGER DEFAULT 0,
  following INTEGER DEFAULT 0,
  
  -- Analyzed data (JSONB for flexibility)
  summary JSONB DEFAULT '{}',
  -- Structure: {
  --   top_languages: [{name, percentage, repos_count}],
  --   total_stars: number,
  --   total_forks: number,
  --   top_repos: [{name, description, language, stars, forks, url}],
  --   contribution_streak: number,
  --   last_activity_date: timestamp,
  --   skills_detected: [string],
  --   profile_completeness_score: number (0-100)
  -- }
  
  -- Sync metadata
  last_synced_at TIMESTAMP,
  sync_status VARCHAR(50) DEFAULT 'pending', -- pending, success, error
  sync_error TEXT,
  
  -- Consent & Privacy
  consent_given BOOLEAN DEFAULT FALSE,
  consent_given_at TIMESTAMP,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP,
  
  -- Foreign Keys
  CONSTRAINT fk_github_candidate 
    FOREIGN KEY (candidate_id) 
    REFERENCES candidates(id) 
    ON DELETE CASCADE,
  
  CONSTRAINT fk_github_company 
    FOREIGN KEY (company_id) 
    REFERENCES companies(id) 
    ON DELETE CASCADE,
  
  -- Constraints
  CONSTRAINT github_username_not_empty 
    CHECK (LENGTH(TRIM(username)) > 0),
  
  CONSTRAINT github_sync_status_valid 
    CHECK (sync_status IN ('pending', 'syncing', 'success', 'error', 'rate_limited'))
);

-- Comentários
COMMENT ON TABLE candidate_github_profiles IS 'Perfis GitHub vinculados a candidatos (RF4)';
COMMENT ON COLUMN candidate_github_profiles.username IS 'Username do GitHub (obrigatório)';
COMMENT ON COLUMN candidate_github_profiles.summary IS 'Dados analisados (linguagens, repos, skills detectadas)';
COMMENT ON COLUMN candidate_github_profiles.consent_given IS 'Se candidato autorizou integração (LGPD)';
COMMENT ON COLUMN candidate_github_profiles.sync_status IS 'Status da última sincronização';

-- ============================================================================
-- Índices
-- ============================================================================

-- Query principal: buscar por candidato + company
CREATE INDEX idx_github_candidate_company 
  ON candidate_github_profiles(candidate_id, company_id) 
  WHERE deleted_at IS NULL;

-- Query por company (admins listando todos)
CREATE INDEX idx_github_company 
  ON candidate_github_profiles(company_id) 
  WHERE deleted_at IS NULL;

-- Query por username (validação de duplicados)
CREATE INDEX idx_github_username 
  ON candidate_github_profiles(company_id, LOWER(username)) 
  WHERE deleted_at IS NULL;

-- Query por status de sync (monitoramento)
CREATE INDEX idx_github_sync_status 
  ON candidate_github_profiles(company_id, sync_status, last_synced_at) 
  WHERE deleted_at IS NULL;

-- Full-text search em bio/location/company
CREATE INDEX idx_github_search 
  ON candidate_github_profiles 
  USING GIN (to_tsvector('portuguese', 
    COALESCE(bio, '') || ' ' || 
    COALESCE(location, '') || ' ' || 
    COALESCE(company, '')
  )) 
  WHERE deleted_at IS NULL;

-- Query em summary JSONB
CREATE INDEX idx_github_summary_gin 
  ON candidate_github_profiles 
  USING GIN (summary) 
  WHERE deleted_at IS NULL;

-- Query por data de sync (reprocessamento)
CREATE INDEX idx_github_last_synced 
  ON candidate_github_profiles(last_synced_at DESC) 
  WHERE deleted_at IS NULL AND sync_status = 'success';

-- ============================================================================
-- Trigger: Auto-update timestamps
-- ============================================================================

CREATE OR REPLACE FUNCTION update_github_profiles_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_github_profiles
  BEFORE UPDATE ON candidate_github_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_github_profiles_timestamps();

-- ============================================================================
-- View: candidate_github_profiles_overview
-- ============================================================================
-- View para listagem com dados de candidatos e companies

CREATE OR REPLACE VIEW candidate_github_profiles_overview AS
SELECT 
  gp.id,
  gp.candidate_id,
  gp.company_id,
  gp.username,
  gp.github_id,
  gp.avatar_url,
  gp.profile_url,
  gp.bio,
  gp.public_repos,
  gp.followers,
  gp.following,
  gp.summary,
  gp.last_synced_at,
  gp.sync_status,
  gp.consent_given,
  gp.created_at,
  gp.updated_at,
  
  -- Candidate data
  c.full_name as candidate_name,
  c.email as candidate_email,
  
  -- Company data
  co.name as company_name
  
FROM candidate_github_profiles gp
LEFT JOIN candidates c ON c.id = gp.candidate_id
LEFT JOIN companies co ON co.id = gp.company_id
WHERE gp.deleted_at IS NULL;

COMMENT ON VIEW candidate_github_profiles_overview IS 'Listagem de perfis GitHub com dados de candidatos/companies';
