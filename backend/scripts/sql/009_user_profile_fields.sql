-- Migration 009: Adicionar campos de perfil do usuário
-- Criado em: 2025-11-14
-- Descrição: Adiciona campos 'cargo' e 'foto_url' na tabela users

-- Adicionar coluna cargo (Admin, Recrutador(a), Gestor(a))
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS cargo VARCHAR(50);

-- Adicionar coluna foto_url (URL do avatar/foto do usuário)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- Comentários para documentação
COMMENT ON COLUMN users.cargo IS 'Cargo do usuário: Admin, Recrutador(a) ou Gestor(a)';
COMMENT ON COLUMN users.foto_url IS 'URL da foto de perfil do usuário (opcional)';

-- Índice para busca por cargo (útil para filtros futuros)
CREATE INDEX IF NOT EXISTS idx_users_cargo ON users(cargo);

-- Log da migration
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 009 aplicada: campos cargo e foto_url adicionados à tabela users';
END $$;
