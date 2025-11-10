-- Migration: Tornar company_id opcional em users
-- Permite criar usuários sem empresa (onboarding gradual)

BEGIN;

-- Remove a constraint NOT NULL de company_id
ALTER TABLE users 
  ALTER COLUMN company_id DROP NOT NULL;

-- Adiciona índice para melhorar performance de queries por company_id
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id) WHERE company_id IS NOT NULL;

-- Adiciona comentário explicativo
COMMENT ON COLUMN users.company_id IS 'Opcional - usuário pode cadastrar empresa depois nas configurações';

COMMIT;
