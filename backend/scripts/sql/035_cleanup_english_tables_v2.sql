-- ============================================================================
-- Migration 035v2: Limpeza de Tabelas em Inglês Não Utilizadas
-- ============================================================================
-- VERIFICADO: Backend 100% migrado para tabelas PT-BR
-- DATA: 29/11/2025 - ATUALIZADO
-- ============================================================================

BEGIN;

-- ============================================================
-- SEÇÃO 1: TABELAS PRINCIPAIS EM INGLÊS → PT-BR EQUIVALENTE
-- (Backend já usa as tabelas PT-BR)
-- ============================================================

-- users → usuarios
DROP TABLE IF EXISTS users CASCADE;

-- jobs → vagas  
DROP TABLE IF EXISTS jobs CASCADE;

-- candidates → candidatos
DROP TABLE IF EXISTS candidates CASCADE;

-- resumes → curriculos
DROP TABLE IF EXISTS resumes CASCADE;

-- interviews → entrevistas
DROP TABLE IF EXISTS interviews CASCADE;

-- applications → candidaturas
DROP TABLE IF EXISTS applications CASCADE;

-- files → arquivos
DROP TABLE IF EXISTS files CASCADE;

-- skills → habilidades
DROP TABLE IF EXISTS skills CASCADE;

-- candidate_skills → habilidades_candidato
DROP TABLE IF EXISTS candidate_skills CASCADE;

-- ============================================================
-- SEÇÃO 2: TABELAS DE AUTENTICAÇÃO
-- ============================================================

-- sessions (não utilizado - sistema usa tokens)
DROP TABLE IF EXISTS sessions CASCADE;

-- refresh_tokens → tokens_atualizacao
DROP TABLE IF EXISTS refresh_tokens CASCADE;

-- password_resets → redefinicao_senhas
DROP TABLE IF EXISTS password_resets CASCADE;

-- api_keys → chaves_api
DROP TABLE IF EXISTS api_keys CASCADE;

-- ============================================================
-- SEÇÃO 3: TABELAS DE ENTREVISTA
-- ============================================================

-- interview_sessions → sessoes_entrevista
DROP TABLE IF EXISTS interview_sessions CASCADE;

-- interview_messages → mensagens_entrevista
DROP TABLE IF EXISTS interview_messages CASCADE;

-- interview_questions → perguntas_entrevista
DROP TABLE IF EXISTS interview_questions CASCADE;

-- interview_answers → respostas_entrevista
DROP TABLE IF EXISTS interview_answers CASCADE;

-- interview_reports → relatorios_entrevista
DROP TABLE IF EXISTS interview_reports CASCADE;

-- ============================================================
-- SEÇÃO 4: TABELAS RELACIONADAS/AUXILIARES
-- ============================================================

-- job_revisions → revisoes_vagas
DROP TABLE IF EXISTS job_revisions CASCADE;

-- calendar_events → eventos_calendario
DROP TABLE IF EXISTS calendar_events CASCADE;

-- resume_analysis → analise_curriculos
DROP TABLE IF EXISTS resume_analysis CASCADE;

-- audit_logs → logs_auditoria
DROP TABLE IF EXISTS audit_logs CASCADE;

-- ============================================================
-- SEÇÃO 5: TABELAS NÃO UTILIZADAS (sem equivalente PT-BR)
-- ============================================================

DROP TABLE IF EXISTS ai_feedback CASCADE;
DROP TABLE IF EXISTS application_status_history CASCADE;
DROP TABLE IF EXISTS application_stages CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS job_skills CASCADE;
DROP TABLE IF EXISTS transcriptions CASCADE;
DROP TABLE IF EXISTS webhooks_endpoints CASCADE;
DROP TABLE IF EXISTS webhooks_events CASCADE;
DROP TABLE IF EXISTS webhooks_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS github_profiles CASCADE;
DROP TABLE IF EXISTS github_repositories CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS job_tags CASCADE;
DROP TABLE IF EXISTS candidate_tags CASCADE;
DROP TABLE IF EXISTS experiences CASCADE;
DROP TABLE IF EXISTS educations CASCADE;

-- ============================================================
-- SEÇÃO 6: TABELAS RENOMEADAS NA MIGRATION 036
-- (Já foram renomeadas, não precisam ser dropadas)
-- ============================================================

-- live_assessments → avaliacoes_tempo_real (RENOMEADA)
-- interview_question_sets → conjuntos_perguntas_entrevista (RENOMEADA)
-- dashboard_presets → presets_dashboard (RENOMEADA)
-- ingestion_jobs → processos_ingestao (RENOMEADA)

-- ============================================================
-- SEÇÃO 7: COMPANIES (mantida por ora - em uso direto)
-- ============================================================

-- companies → empresas 
-- NOTA: Verificar se há uso de 'companies' antes de remover
DROP TABLE IF EXISTS companies CASCADE;

COMMIT;

-- ============================================================
-- VERIFICAÇÃO PÓS-EXECUÇÃO
-- ============================================================
-- Execute para listar tabelas restantes:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
-- ORDER BY table_name;
