/**
 * Migration 026: Dashboard Presets & Configurations
 * RF9 - Dashboard de Acompanhamento
 * 
 * Cria tabela para salvar configurações de dashboard (presets/favoritos)
 * permitindo usuários personalizar visualizações e filtros
 */

-- ============================================================================
-- Tabela: dashboard_presets
-- ============================================================================
-- Armazena configurações personalizadas de dashboard por usuário
-- Permite salvar combinações de filtros, visualizações e preferências

CREATE TABLE IF NOT EXISTS dashboard_presets (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL,
  company_id        UUID NOT NULL,
  name              VARCHAR(100) NOT NULL,
  description       TEXT,
  
  -- Configurações do preset (JSONB flexível)
  filters           JSONB DEFAULT '{}',
  -- Exemplo: {"period": "30days", "status": ["open", "closed"], "department": "RH"}
  
  layout            JSONB DEFAULT '{}',
  -- Exemplo: {"widgets": ["jobs", "interviews", "resumes"], "order": [1,2,3]}
  
  preferences       JSONB DEFAULT '{}',
  -- Exemplo: {"theme": "dark", "chartType": "bar", "showLegend": true}
  
  -- Configurações de visibilidade/compartilhamento
  is_default        BOOLEAN DEFAULT FALSE,
  is_shared         BOOLEAN DEFAULT FALSE,
  shared_with_roles TEXT[], -- ['ADMIN', 'RECRUITER']
  
  -- Metadados
  usage_count       INTEGER DEFAULT 0,
  last_used_at      TIMESTAMP,
  
  -- Auditoria
  created_at        TIMESTAMP DEFAULT NOW(),
  updated_at        TIMESTAMP DEFAULT NOW(),
  deleted_at        TIMESTAMP,
  
  -- Foreign Keys
  CONSTRAINT fk_dashboard_presets_user 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_dashboard_presets_company 
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Constraints
  CONSTRAINT dashboard_presets_name_not_empty 
    CHECK (LENGTH(TRIM(name)) > 0),
  CONSTRAINT dashboard_presets_usage_count_positive 
    CHECK (usage_count >= 0)
);

-- ============================================================================
-- Índices para Performance
-- ============================================================================

-- Índice composto user + company (query principal)
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_user_company
  ON dashboard_presets(user_id, company_id)
  WHERE deleted_at IS NULL;

-- Índice para busca por company (admins)
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_company
  ON dashboard_presets(company_id)
  WHERE deleted_at IS NULL;

-- Índice para presets default
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_default
  ON dashboard_presets(user_id, is_default)
  WHERE deleted_at IS NULL AND is_default = TRUE;

-- Índice para presets compartilhados
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_shared
  ON dashboard_presets(company_id, is_shared)
  WHERE deleted_at IS NULL AND is_shared = TRUE;

-- Índice para busca textual (nome/descrição)
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_search
  ON dashboard_presets USING gin(to_tsvector('portuguese', name || ' ' || COALESCE(description, '')))
  WHERE deleted_at IS NULL;

-- Índice GIN para queries em filters (busca por filtros específicos)
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_filters_gin
  ON dashboard_presets USING gin(filters);

-- Índice para ordenação por uso
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_usage
  ON dashboard_presets(company_id, usage_count DESC, last_used_at DESC)
  WHERE deleted_at IS NULL;

-- Índice para criação recente
CREATE INDEX IF NOT EXISTS idx_dashboard_presets_created_at
  ON dashboard_presets(created_at DESC)
  WHERE deleted_at IS NULL;

-- ============================================================================
-- Triggers
-- ============================================================================

-- Trigger para auto-atualizar updated_at
CREATE OR REPLACE FUNCTION update_dashboard_presets_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_dashboard_presets ON dashboard_presets;
CREATE TRIGGER trigger_update_dashboard_presets
  BEFORE UPDATE ON dashboard_presets
  FOR EACH ROW
  EXECUTE FUNCTION update_dashboard_presets_timestamps();

-- Trigger para incrementar usage_count e atualizar last_used_at
-- Nota: Será chamado manualmente via UPDATE na aplicação quando preset é usado
CREATE OR REPLACE FUNCTION increment_preset_usage()
RETURNS TRIGGER AS $$
BEGIN
  -- Este trigger pode ser usado para logs ou ações adicionais
  -- O incremento real será feito via UPDATE explícito na aplicação
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- View: dashboard_presets_overview
-- ============================================================================
-- View simplificada para listagem de presets com informações do usuário

CREATE OR REPLACE VIEW dashboard_presets_overview AS
SELECT
  dp.id,
  dp.user_id,
  dp.company_id,
  dp.name,
  dp.description,
  dp.is_default,
  dp.is_shared,
  dp.shared_with_roles,
  dp.usage_count,
  dp.last_used_at,
  dp.created_at,
  dp.updated_at,
  u.full_name as created_by_name,
  u.email as created_by_email,
  c.name as company_name
FROM dashboard_presets dp
LEFT JOIN users u ON dp.user_id = u.id
LEFT JOIN companies c ON dp.company_id = c.id
WHERE dp.deleted_at IS NULL;

-- ============================================================================
-- Comentários nas tabelas/colunas
-- ============================================================================

COMMENT ON TABLE dashboard_presets IS 
  'RF9: Presets/favoritos de dashboard salvos por usuários para personalizar visualizações e filtros';

COMMENT ON COLUMN dashboard_presets.filters IS 
  'JSONB: Filtros aplicados (período, status, departamento, etc)';

COMMENT ON COLUMN dashboard_presets.layout IS 
  'JSONB: Layout de widgets e ordenação';

COMMENT ON COLUMN dashboard_presets.preferences IS 
  'JSONB: Preferências visuais (tema, tipo de gráfico, etc)';

COMMENT ON COLUMN dashboard_presets.is_default IS 
  'Se TRUE, este preset é carregado automaticamente ao acessar dashboard';

COMMENT ON COLUMN dashboard_presets.is_shared IS 
  'Se TRUE, preset está disponível para outros usuários (conforme shared_with_roles)';

COMMENT ON COLUMN dashboard_presets.usage_count IS 
  'Contador de vezes que o preset foi usado (para identificar favoritos)';
