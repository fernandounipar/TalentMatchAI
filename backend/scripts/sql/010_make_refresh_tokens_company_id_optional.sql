-- Migration: Tornar company_id opcional em refresh_tokens
-- Permite criar tokens para usuários sem empresa

BEGIN;

-- Remove a constraint NOT NULL de company_id
ALTER TABLE refresh_tokens 
  ALTER COLUMN company_id DROP NOT NULL;

-- Adiciona comentário explicativo
COMMENT ON COLUMN refresh_tokens.company_id IS 'Opcional - pode ser NULL para usuários sem empresa cadastrada';

COMMIT;
