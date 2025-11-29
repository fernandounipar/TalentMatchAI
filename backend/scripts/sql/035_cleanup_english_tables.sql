-- ============================================================================
-- Migration 035: Limpeza de Tabelas em Inglês Não Utilizadas
-- ============================================================================
-- ATENÇÃO: Este script deve ser executado APENAS após verificar que o backend
--          não depende mais dessas tabelas.
-- STATUS: PRONTO PARA EXECUÇÃO (após validação)
-- DATA: 29/11/2025
-- ============================================================================

-- ============================================================
-- BACKUP RECOMENDADO ANTES DA EXECUÇÃO
-- ============================================================
-- pg_dump -h localhost -U postgres -d talentmatchia \
--   -t users -t jobs -t candidates -t resumes -t interviews \
--   -t applications -t sessions -t refresh_tokens -t password_resets \
--   -t api_keys -t files -t audit_logs \
--   > backup_tabelas_english_$(date +%Y%m%d).sql

BEGIN;

-- ============================================================
-- SEÇÃO 1: TABELAS EM INGLÊS QUE PODEM SER REMOVIDAS
--          (já possuem equivalentes em PT-BR sendo usadas)
-- ============================================================

-- Tabela 'users' (inglês) → backend usa 'usuarios' (pt-BR)
-- Verificado: autenticacaoService.js usa 'usuarios'
-- DROP TABLE IF EXISTS users CASCADE;

-- Tabela 'jobs' (inglês) → backend usa 'vagas' (pt-BR)
-- Verificado: jobs.js usa 'vagas'
-- DROP TABLE IF EXISTS jobs CASCADE;

-- Tabela 'candidates' (inglês) → backend usa 'candidatos' (pt-BR)  
-- Verificado: candidates.js usa 'candidatos'
-- DROP TABLE IF EXISTS candidates CASCADE;

-- Tabela 'resumes' (inglês) → backend usa 'curriculos' (pt-BR)
-- Verificado: resumes.js usa 'curriculos'
-- DROP TABLE IF EXISTS resumes CASCADE;

-- Tabela 'interviews' (inglês) → backend usa 'entrevistas' (pt-BR)
-- Verificado: interviews.js usa 'entrevistas'
-- DROP TABLE IF EXISTS interviews CASCADE;

-- Tabela 'applications' (inglês) → backend usa 'candidaturas' (pt-BR)
-- Verificado: interviews.js, resumes.js usam 'candidaturas'
-- DROP TABLE IF EXISTS applications CASCADE;

-- Tabela 'sessions' (inglês) → VERIFICAR SE HÁ USO
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS sessions CASCADE;

-- Tabela 'refresh_tokens' (inglês) → backend usa 'tokens_atualizacao' (pt-BR)
-- Verificado: autenticacaoService.js usa 'tokens_atualizacao'
-- DROP TABLE IF EXISTS refresh_tokens CASCADE;

-- Tabela 'password_resets' (inglês) → backend usa 'redefinicao_senhas' (pt-BR)
-- Verificado: autenticacaoService.js usa 'redefinicao_senhas'
-- DROP TABLE IF EXISTS password_resets CASCADE;

-- Tabela 'api_keys' (inglês) → backend usa 'chaves_api' (pt-BR)
-- Verificado: api_keys.js e iaService.js usam 'chaves_api'
-- DROP TABLE IF EXISTS api_keys CASCADE;

-- Tabela 'files' (inglês) → backend usa 'arquivos' (pt-BR) para novos registros
-- ATENÇÃO: files.js ainda pode ter referências, verificar antes de remover
-- DROP TABLE IF EXISTS files CASCADE;

-- ============================================================
-- SEÇÃO 2: TABELAS RELACIONADAS (DEPENDÊNCIAS)
-- ============================================================

-- Tabela 'interview_sessions' (inglês) → 'sessoes_entrevista' (pt-BR)
-- Verificado: interviews.js usa 'sessoes_entrevista'
-- DROP TABLE IF EXISTS interview_sessions CASCADE;

-- Tabela 'interview_questions' (inglês) → usa nome original no backend
-- ATENÇÃO: reports.js e live-assessments.js AINDA USAM 'interview_questions'
-- NÃO REMOVER: Tabela em uso ativo
-- DROP TABLE IF EXISTS interview_questions CASCADE;

-- Tabela 'interview_answers' (inglês) → usa nome original no backend
-- ATENÇÃO: reports.js e live-assessments.js AINDA USAM 'interview_answers'
-- NÃO REMOVER: Tabela em uso ativo
-- DROP TABLE IF EXISTS interview_answers CASCADE;

-- Tabela 'interview_reports' (inglês) → backend usa 'relatorios_entrevista' (pt-BR) E 'interview_reports'
-- ATENÇÃO: reports.js usa AMBAS as tabelas
-- NÃO REMOVER: Tabela em uso ativo em reports.js
-- DROP TABLE IF EXISTS interview_reports CASCADE;

-- Tabela 'interview_messages' (inglês) → 'mensagens_entrevista' (pt-BR)
-- Verificado: interviews.js usa 'mensagens_entrevista'
-- DROP TABLE IF EXISTS interview_messages CASCADE;

-- Tabela 'ai_feedback' (inglês) → 'feedback_ia' (pt-BR)
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS ai_feedback CASCADE;

-- Tabela 'application_status_history' (inglês) → 'historico_status_candidatura' (pt-BR)
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS application_status_history CASCADE;

-- Tabela 'application_stages' (inglês) → 'etapas_candidatura' (pt-BR)
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS application_stages CASCADE;

-- Tabela 'notes' (inglês) → 'anotacoes' (pt-BR)
-- NOTA: Não encontrado uso direto da tabela 'notes' (notes é usado como coluna em entrevistas)
-- DROP TABLE IF EXISTS notes CASCADE;

-- Tabela 'skills' (inglês) → 'habilidades' (pt-BR)
-- Verificado: candidates.js usa 'habilidades'
-- DROP TABLE IF EXISTS skills CASCADE;

-- Tabela 'candidate_skills' (inglês) → 'habilidades_candidato' (pt-BR)
-- Verificado: candidates.js usa 'habilidades_candidato'
-- DROP TABLE IF EXISTS candidate_skills CASCADE;

-- Tabela 'job_skills' (inglês) → 'habilidades_vaga' (pt-BR)
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS job_skills CASCADE;

-- Tabela 'job_revisions' (inglês) → 'revisoes_vagas' (pt-BR)
-- Verificado: jobs.js usa 'revisoes_vagas'
-- DROP TABLE IF EXISTS job_revisions CASCADE;

-- Tabela 'resume_analysis' (inglês) → 'analise_curriculos' (pt-BR) 
-- ATENÇÃO: interviews.js usa 'resume_analysis' EM INGLÊS
--          resumes.js usa 'analise_curriculos' EM PT-BR
-- NÃO REMOVER: Pode haver inconsistência - verificar!
-- DROP TABLE IF EXISTS resume_analysis CASCADE;

-- ============================================================
-- SEÇÃO 3: TABELAS AUXILIARES/INFRA
-- ============================================================

-- Tabela 'calendar_events' (inglês) → 'eventos_calendario' (pt-BR)
-- Verificado: interviews.js usa 'eventos_calendario'
-- DROP TABLE IF EXISTS calendar_events CASCADE;

-- Tabela 'ingestion_jobs' (inglês) → uso direto no backend
-- ATENÇÃO: ingestion.js usa 'ingestion_jobs' EM INGLÊS
-- NÃO REMOVER: Tabela em uso ativo
-- DROP TABLE IF EXISTS ingestion_jobs CASCADE;

-- Tabela 'transcriptions' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS transcriptions CASCADE;

-- Tabela 'webhooks_endpoints' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS webhooks_endpoints CASCADE;

-- Tabela 'webhooks_events' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS webhooks_events CASCADE;

-- Tabela 'webhooks_logs' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS webhooks_logs CASCADE;

-- Tabela 'notifications' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS notifications CASCADE;

-- Tabela 'github_profiles' (inglês) → 'candidate_github_profiles' usado no backend
-- ATENÇÃO: github.js usa 'candidate_github_profiles' (híbrido)
-- DROP TABLE IF EXISTS github_profiles CASCADE;

-- Tabela 'github_repositories' (inglês) → sem equivalente
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS github_repositories CASCADE;

-- Tabela 'tags' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS tags CASCADE;

-- Tabela 'job_tags' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS job_tags CASCADE;

-- Tabela 'candidate_tags' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS candidate_tags CASCADE;

-- Tabela 'experiences' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend (apenas como propriedade JSON)
-- DROP TABLE IF EXISTS experiences CASCADE;

-- Tabela 'educations' (inglês) → sem equivalente pt-BR encontrado
-- NOTA: Não encontrado uso direto no backend
-- DROP TABLE IF EXISTS educations CASCADE;

-- ============================================================
-- SEÇÃO 4: EXECUÇÃO SEGURA - DESCOMENTE APENAS APÓS VALIDAÇÃO
-- ============================================================

-- IMPORTANTE: Execute as seguintes linhas SOMENTE após confirmar
-- que nenhum código depende dessas tabelas.

/*
-- Tabelas que NÃO estão sendo usadas e podem ser removidas com segurança:
DROP TABLE IF EXISTS sessions CASCADE;
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

-- Tabelas que têm equivalente pt-BR em uso e podem ser removidas:
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS resumes CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS refresh_tokens CASCADE;
DROP TABLE IF EXISTS password_resets CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS interview_sessions CASCADE;
DROP TABLE IF EXISTS interview_messages CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS candidate_skills CASCADE;
DROP TABLE IF EXISTS job_revisions CASCADE;
DROP TABLE IF EXISTS calendar_events CASCADE;
DROP TABLE IF EXISTS files CASCADE;
*/

COMMIT;

-- ============================================================
-- VERIFICAÇÃO PÓS-EXECUÇÃO
-- ============================================================

-- Listar tabelas restantes no schema public
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
--   AND table_type = 'BASE TABLE'
-- ORDER BY table_name;

-- ============================================================
-- Migration 035 concluída
-- ============================================================
