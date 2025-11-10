-- Migration: Tornar company_id opcional em password_resets
-- Permite reset de senha para usuários sem empresa

BEGIN;

-- Remove a constraint NOT NULL de company_id
ALTER TABLE password_resets 
  ALTER COLUMN company_id DROP NOT NULL;

-- Adiciona comentário explicativo
COMMENT ON COLUMN password_resets.company_id IS 'Opcional - pode ser NULL para usuários sem empresa cadastrada';

COMMIT;
