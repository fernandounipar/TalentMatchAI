-- ============================================================================
-- Migration 032: Limpeza de Conflitos de Nomes (Pre-Rename)
-- ============================================================================
-- Remove tabelas com nomes em PT-BR que já existem e conflitam com a renomeação
-- Assumindo que as tabelas em INGLÊS são as ativas e corretas.

BEGIN;

DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS empresas CASCADE;
DROP TABLE IF EXISTS sessoes CASCADE;
DROP TABLE IF EXISTS tokens_atualizacao CASCADE;
DROP TABLE IF EXISTS redefinicao_senhas CASCADE;
DROP TABLE IF EXISTS chaves_api CASCADE;

DROP TABLE IF EXISTS revisoes_vagas CASCADE;
DROP TABLE IF EXISTS etapas_pipeline CASCADE;
DROP TABLE IF EXISTS habilidades_vaga CASCADE;

DROP TABLE IF EXISTS habilidades CASCADE;
DROP TABLE IF EXISTS habilidades_candidato CASCADE;
DROP TABLE IF EXISTS perfis_github_candidato CASCADE;

DROP TABLE IF EXISTS candidaturas CASCADE;
DROP TABLE IF EXISTS etapas_candidatura CASCADE;
DROP TABLE IF EXISTS historico_status_candidatura CASCADE;
DROP TABLE IF EXISTS anotacoes CASCADE;

DROP TABLE IF EXISTS analise_curriculos CASCADE;
DROP TABLE IF EXISTS estatisticas_processamento_curriculo CASCADE;

DROP TABLE IF EXISTS sessoes_entrevista CASCADE;
DROP TABLE IF EXISTS perguntas_entrevista CASCADE;
DROP TABLE IF EXISTS respostas_entrevista CASCADE;
DROP TABLE IF EXISTS mensagens_entrevista CASCADE;
DROP TABLE IF EXISTS feedback_ia CASCADE;
DROP TABLE IF EXISTS relatorios_entrevista CASCADE;

DROP TABLE IF EXISTS logs_auditoria CASCADE;
DROP TABLE IF EXISTS arquivos CASCADE;
DROP TABLE IF EXISTS processos_ingestao CASCADE;
DROP TABLE IF EXISTS eventos_calendario CASCADE;

COMMIT;
