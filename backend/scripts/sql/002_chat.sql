-- Tabela de mensagens para o chat da entrevista
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS mensagens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entrevista_id UUID NOT NULL REFERENCES entrevistas(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
  conteudo TEXT NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mensagens_entrevista ON mensagens(entrevista_id, criado_em);

