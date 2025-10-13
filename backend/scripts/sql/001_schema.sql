-- Esquema básico (MVP)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  senha_hash TEXT NOT NULL,
  perfil TEXT NOT NULL DEFAULT 'RECRUTADOR',
  aceitou_lgpd BOOLEAN NOT NULL DEFAULT false,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS vagas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  descricao TEXT NOT NULL,
  requisitos TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'aberta',
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS candidatos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  email TEXT UNIQUE,
  github TEXT UNIQUE,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS curriculos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidato_id UUID REFERENCES candidatos(id) ON DELETE CASCADE,
  nome_arquivo TEXT NOT NULL,
  mimetype TEXT NOT NULL,
  tamanho INTEGER NOT NULL,
  texto LONGTEXT,
  analise_json JSONB,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS entrevistas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vaga_id UUID REFERENCES vagas(id) ON DELETE CASCADE,
  candidato_id UUID REFERENCES candidatos(id) ON DELETE CASCADE,
  curriculo_id UUID REFERENCES curriculos(id) ON DELETE SET NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS perguntas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entrevista_id UUID REFERENCES entrevistas(id) ON DELETE CASCADE,
  texto TEXT NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS relatorios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entrevista_id UUID UNIQUE REFERENCES entrevistas(id) ON DELETE CASCADE,
  html TEXT NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT now()
);

-- Índices simples
CREATE INDEX IF NOT EXISTS idx_curriculos_candidato ON curriculos(candidato_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_vaga ON entrevistas(vaga_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_candidato ON entrevistas(candidato_id);
