-- Migration: Adiciona campos de candidato aprovado na tabela vagas
-- Data: 2025-11-30
-- Descrição: Suporta o fluxo de finalização de vaga com candidato aprovado

-- Adicionar novos campos para candidato aprovado
ALTER TABLE vagas 
ADD COLUMN IF NOT EXISTS hired_candidate_id UUID REFERENCES candidatos(id),
ADD COLUMN IF NOT EXISTS hired_candidate_name TEXT,
ADD COLUMN IF NOT EXISTS hired_candidate_email TEXT,
ADD COLUMN IF NOT EXISTS hired_at TIMESTAMP;

-- Adicionar comentários explicativos
COMMENT ON COLUMN vagas.hired_candidate_id IS 'ID do candidato aprovado/contratado para esta vaga';
COMMENT ON COLUMN vagas.hired_candidate_name IS 'Nome do candidato aprovado (cache para exibição rápida)';
COMMENT ON COLUMN vagas.hired_candidate_email IS 'Email do candidato aprovado (cache para exibição rápida)';
COMMENT ON COLUMN vagas.hired_at IS 'Data/hora em que o candidato foi aprovado e a vaga foi preenchida';

-- Criar índice para busca por status 'filled'
CREATE INDEX IF NOT EXISTS idx_vagas_status_filled ON vagas(status) WHERE status = 'filled';

-- Atualizar comentário do campo status para incluir novo valor
COMMENT ON COLUMN vagas.status IS 'Status da vaga: open (aberta), closed (fechada), draft (rascunho), filled (preenchida)';
