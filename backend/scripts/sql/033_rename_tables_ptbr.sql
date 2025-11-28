-- ============================================================================
-- Migration 033: Renomear Tabelas para PT-BR
-- ============================================================================

BEGIN;

-- 1) Autenticação e Gestão
ALTER TABLE public.companies RENAME TO empresas;
ALTER TABLE public.users RENAME TO usuarios;
ALTER TABLE public.sessions RENAME TO sessoes;
ALTER TABLE public.refresh_tokens RENAME TO tokens_atualizacao;
ALTER TABLE public.password_resets RENAME TO redefinicao_senhas;
ALTER TABLE public.api_keys RENAME TO chaves_api;

-- 2) Vagas e Pipeline
ALTER TABLE public.jobs RENAME TO vagas;
ALTER TABLE public.job_revisions RENAME TO revisoes_vagas;
-- pipelines mantido como pipelines
ALTER TABLE public.pipeline_stages RENAME TO etapas_pipeline;
ALTER TABLE public.job_skills RENAME TO habilidades_vaga;

-- 3) Candidatos e Skills
ALTER TABLE public.candidates RENAME TO candidatos;
ALTER TABLE public.skills RENAME TO habilidades;
ALTER TABLE public.candidate_skills RENAME TO habilidades_candidato;
ALTER TABLE public.candidate_github_profiles RENAME TO perfis_github_candidato;

-- 4) Aplicações
ALTER TABLE public.applications RENAME TO candidaturas;
ALTER TABLE public.application_stages RENAME TO etapas_candidatura;
ALTER TABLE public.application_status_history RENAME TO historico_status_candidatura;
ALTER TABLE public.notes RENAME TO anotacoes;

-- 5) Currículos
ALTER TABLE public.resumes RENAME TO curriculos;
ALTER TABLE public.resume_analysis RENAME TO analise_curriculos;
ALTER TABLE public.resume_processing_stats RENAME TO estatisticas_processamento_curriculo;

-- 6) Entrevistas
ALTER TABLE public.interviews RENAME TO entrevistas;
ALTER TABLE public.interview_sessions RENAME TO sessoes_entrevista;
ALTER TABLE public.interview_questions RENAME TO perguntas_entrevista;
ALTER TABLE public.interview_answers RENAME TO respostas_entrevista;
ALTER TABLE public.interview_messages RENAME TO mensagens_entrevista;
ALTER TABLE public.ai_feedback RENAME TO feedback_ia;
ALTER TABLE public.interview_reports RENAME TO relatorios_entrevista;

-- 7) Infraestrutura
ALTER TABLE public.audit_logs RENAME TO logs_auditoria;
ALTER TABLE public.files RENAME TO arquivos;
ALTER TABLE public.ingestion_jobs RENAME TO processos_ingestao;
ALTER TABLE public.calendar_events RENAME TO eventos_calendario;

-- Renomear Sequences (Exemplos principais, ajustar conforme necessidade real do banco)
ALTER SEQUENCE IF EXISTS public.companies_id_seq RENAME TO empresas_id_seq;
ALTER SEQUENCE IF EXISTS public.users_id_seq RENAME TO usuarios_id_seq;
ALTER SEQUENCE IF EXISTS public.jobs_id_seq RENAME TO vagas_id_seq;
ALTER SEQUENCE IF EXISTS public.candidates_id_seq RENAME TO candidatos_id_seq;
ALTER SEQUENCE IF EXISTS public.applications_id_seq RENAME TO candidaturas_id_seq;
ALTER SEQUENCE IF EXISTS public.resumes_id_seq RENAME TO curriculos_id_seq;
ALTER SEQUENCE IF EXISTS public.interviews_id_seq RENAME TO entrevistas_id_seq;
ALTER SEQUENCE IF EXISTS public.interview_reports_id_seq RENAME TO relatorios_entrevista_id_seq;
ALTER SEQUENCE IF EXISTS public.audit_logs_id_seq RENAME TO logs_auditoria_id_seq;
ALTER SEQUENCE IF EXISTS public.files_id_seq RENAME TO arquivos_id_seq;

-- Renomear PK Constraints (Exemplos)
ALTER INDEX IF EXISTS public.companies_pkey RENAME TO empresas_pkey;
ALTER INDEX IF EXISTS public.users_pkey RENAME TO usuarios_pkey;
ALTER INDEX IF EXISTS public.jobs_pkey RENAME TO vagas_pkey;
ALTER INDEX IF EXISTS public.candidates_pkey RENAME TO candidatos_pkey;
ALTER INDEX IF EXISTS public.applications_pkey RENAME TO candidaturas_pkey;
ALTER INDEX IF EXISTS public.resumes_pkey RENAME TO curriculos_pkey;
ALTER INDEX IF EXISTS public.interviews_pkey RENAME TO entrevistas_pkey;

COMMIT;
