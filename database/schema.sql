-- ================================================================
-- TalentMatchIA - Schema Unificado do Banco de Dados
-- ================================================================
-- Versão: 1.0.0 (MVP)
-- Data: 2025-11-30
-- Descrição: Este arquivo contém todas as tabelas necessárias 
--            para o funcionamento do TalentMatchIA MVP
-- ================================================================
-- 
-- REQUISITOS FUNCIONAIS ATENDIDOS:
-- RF1:  Upload e análise de currículos (PDF/TXT)
-- RF2:  Cadastro e gerenciamento de vagas
-- RF3:  Geração de perguntas para entrevistas
-- RF7:  Relatórios detalhados de entrevistas
-- RF8:  Histórico de entrevistas
-- RF9:  Dashboard de acompanhamento
-- RF10: Gerenciamento de usuários (recrutadores/gestores)
--
-- ================================================================

-- Habilitar extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ================================================================
-- TABELAS PRINCIPAIS (CORE)
-- ================================================================

-- --------------------------------------------
-- Empresas (Multi-tenant)
-- Cada empresa tem seus próprios dados isolados
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,                -- Tipo: 'PJ', 'PF'
  document TEXT NOT NULL,            -- CNPJ ou CPF
  name TEXT,                         -- Nome da empresa
  criado_em TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Usuários do Sistema (RF10)
-- Recrutadores, gestores e administradores
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES empresas(id),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'USER',  -- SUPER_ADMIN, ADMIN, USER
  is_active BOOLEAN DEFAULT true,
  cargo VARCHAR(50),
  foto_url TEXT,
  phone VARCHAR(20),
  department VARCHAR(100),
  job_title VARCHAR(150),
  last_login_at TIMESTAMP,
  last_login_ip VARCHAR(45),
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMP,
  email_verified BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMP,
  invitation_token VARCHAR(255),
  invitation_expires_at TIMESTAMP,
  invited_by UUID REFERENCES usuarios(id),
  bio TEXT,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Vagas (RF2)
-- Gerenciamento de vagas abertas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS vagas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  title TEXT NOT NULL,
  slug TEXT,
  description TEXT NOT NULL,
  requirements TEXT,
  seniority TEXT,                    -- Junior, Pleno, Senior
  location_type TEXT,                -- Presencial, Remoto, Híbrido
  status TEXT DEFAULT 'open',        -- open, closed, draft
  salary_min NUMERIC,
  salary_max NUMERIC,
  contract_type TEXT,                -- CLT, PJ, Estágio
  department TEXT,
  unit TEXT,
  benefits JSONB DEFAULT '[]',
  skills_required JSONB DEFAULT '[]',
  is_remote BOOLEAN DEFAULT false,
  published_at TIMESTAMP,
  closed_at TIMESTAMP,
  created_by UUID REFERENCES usuarios(id),
  updated_by UUID REFERENCES usuarios(id),
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Candidatos
-- Pessoas que se candidatam às vagas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS candidatos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  linkedin TEXT,
  github_url TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Currículos (RF1)
-- Armazena currículos enviados
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS curriculos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  candidate_id UUID NOT NULL REFERENCES candidatos(id),
  job_id UUID REFERENCES vagas(id),
  file_id UUID,
  original_filename TEXT,
  mime_type TEXT,
  file_size BIGINT,
  parsed_text TEXT,                  -- Texto extraído do PDF
  parsed_json JSONB,                 -- Dados estruturados
  status TEXT DEFAULT 'pending',     -- pending, processing, analyzed, error
  notes TEXT,
  is_favorite BOOLEAN DEFAULT false,
  updated_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Análise de Currículos (RF1)
-- Resultados da análise de IA
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS analise_curriculos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resume_id UUID NOT NULL REFERENCES curriculos(id),
  summary JSONB,                     -- Resumo gerado pela IA
  score NUMERIC,                     -- Pontuação de compatibilidade
  questions JSONB,                   -- Perguntas sugeridas
  provider TEXT,                     -- openai, openrouter
  model TEXT,                        -- Modelo usado
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Candidaturas
-- Relação entre candidato e vaga
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS candidaturas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  job_id UUID NOT NULL REFERENCES vagas(id),
  candidate_id UUID NOT NULL REFERENCES candidatos(id),
  source TEXT,                       -- Origem: upload, linkedin, etc
  stage TEXT,                        -- Etapa atual no pipeline
  status TEXT,                       -- Em análise, aprovado, rejeitado
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- ================================================================
-- TABELAS DE ENTREVISTAS (RF3, RF7, RF8)
-- ================================================================

-- --------------------------------------------
-- Entrevistas (RF8)
-- Registro de entrevistas realizadas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS entrevistas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  application_id UUID NOT NULL REFERENCES candidaturas(id),
  interviewer_id UUID REFERENCES usuarios(id),
  scheduled_at TIMESTAMP,
  mode TEXT,                         -- presencial, video, telefone
  status TEXT,                       -- scheduled, in_progress, completed, cancelled
  result TEXT,                       -- approved, rejected, pending
  overall_score NUMERIC,
  notes TEXT,
  duration_minutes INTEGER,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Perguntas de Entrevista (RF3)
-- Perguntas geradas pela IA
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS perguntas_entrevista (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  interview_id UUID NOT NULL REFERENCES entrevistas(id),
  set_id UUID,
  text TEXT,
  type TEXT DEFAULT 'technical',     -- technical, behavioral, situational
  kind TEXT NOT NULL,
  origin TEXT NOT NULL,              -- ai, manual
  prompt TEXT NOT NULL,
  "order" INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Respostas de Entrevista
-- Respostas dadas pelos candidatos
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS respostas_entrevista (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  question_id UUID NOT NULL REFERENCES perguntas_entrevista(id),
  session_id UUID,
  raw_text TEXT,
  audio_file_id UUID,
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Relatórios de Entrevista (RF7)
-- Relatórios gerados após entrevistas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS relatorios_entrevista (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  interview_id UUID NOT NULL REFERENCES entrevistas(id),
  title TEXT DEFAULT 'Relatório de Entrevista',
  report_type TEXT DEFAULT 'full',   -- full, summary, technical
  candidate_name TEXT,
  job_title TEXT,
  overall_score NUMERIC,
  summary_text TEXT,
  strengths JSONB,                   -- Pontos fortes
  weaknesses JSONB DEFAULT '[]',     -- Pontos fracos
  risks JSONB,                       -- Riscos identificados
  recommendation TEXT,               -- Recomendação final
  content JSONB DEFAULT '{}',
  format TEXT DEFAULT 'json',
  file_id UUID,
  file_path TEXT,
  file_size INTEGER,
  is_final BOOLEAN DEFAULT false,
  version INTEGER DEFAULT 1,
  generated_by UUID REFERENCES usuarios(id),
  generated_at TIMESTAMP DEFAULT now(),
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- ================================================================
-- TABELAS DE SUPORTE
-- ================================================================

-- --------------------------------------------
-- Mensagens de Entrevista (Chat)
-- Histórico de conversa durante entrevista
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS mensagens_entrevista (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  interview_id UUID NOT NULL REFERENCES entrevistas(id),
  sender TEXT NOT NULL,              -- user, assistant, system
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Avaliações em Tempo Real (RF6)
-- Avaliações durante a entrevista
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS avaliacoes_tempo_real (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  interview_id UUID NOT NULL REFERENCES entrevistas(id),
  question_id UUID REFERENCES perguntas_entrevista(id),
  answer_id UUID REFERENCES respostas_entrevista(id),
  score_auto NUMERIC,
  score_manual NUMERIC,
  score_final NUMERIC,
  feedback_auto JSONB,
  feedback_manual TEXT,
  assessment_type TEXT,
  status TEXT DEFAULT 'pending',
  response_time_seconds INTEGER,
  evaluated_by UUID REFERENCES usuarios(id),
  evaluated_at TIMESTAMP,
  created_by UUID REFERENCES usuarios(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- --------------------------------------------
-- Feedback da IA
-- Feedback automático sobre respostas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS feedback_ia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  answer_id UUID NOT NULL REFERENCES respostas_entrevista(id),
  score NUMERIC,
  verdict TEXT,
  rationale_text TEXT,
  suggested_followups JSONB,
  created_at TIMESTAMP DEFAULT now()
);

-- ================================================================
-- TABELAS DE AUTENTICAÇÃO E SEGURANÇA
-- ================================================================

-- --------------------------------------------
-- Tokens de Atualização (Refresh Tokens)
-- Para renovação de sessão
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS tokens_atualizacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES empresas(id),
  user_id UUID NOT NULL REFERENCES usuarios(id),
  session_id UUID,
  token TEXT,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Redefinição de Senhas
-- Tokens para reset de senha
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS redefinicao_senhas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES empresas(id),
  user_id UUID NOT NULL REFERENCES usuarios(id),
  token TEXT,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Sessões de Usuário
-- Controle de sessões ativas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS sessoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  user_id UUID NOT NULL REFERENCES usuarios(id),
  ip INET,
  ua TEXT,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Chaves de API (OpenAI, etc)
-- Armazena chaves de API dos usuários
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS chaves_api (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  user_id UUID NOT NULL REFERENCES usuarios(id),
  provider TEXT NOT NULL,            -- openai, openrouter
  label TEXT,
  token TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Logs de Auditoria
-- Registro de ações do sistema
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS logs_auditoria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  user_id UUID REFERENCES usuarios(id),
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  diff JSONB,
  ip INET,
  ua TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- ================================================================
-- TABELAS AUXILIARES
-- ================================================================

-- --------------------------------------------
-- Habilidades
-- Cadastro de skills técnicas
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS habilidades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  name TEXT NOT NULL
);

-- --------------------------------------------
-- Habilidades do Candidato
-- Relaciona candidatos com skills
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS habilidades_candidato (
  candidate_id UUID NOT NULL REFERENCES candidatos(id),
  skill_id UUID NOT NULL REFERENCES habilidades(id),
  level TEXT,
  PRIMARY KEY (candidate_id, skill_id)
);

-- --------------------------------------------
-- Habilidades da Vaga
-- Skills requeridas pela vaga
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS habilidades_vaga (
  job_id UUID NOT NULL REFERENCES vagas(id),
  skill_id UUID NOT NULL REFERENCES habilidades(id),
  must_have BOOLEAN DEFAULT false,
  PRIMARY KEY (job_id, skill_id)
);

-- --------------------------------------------
-- Arquivos
-- Controle de arquivos enviados
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS arquivos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  storage_key TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime TEXT,
  size BIGINT,
  created_at TIMESTAMP DEFAULT now()
);

-- --------------------------------------------
-- Pipelines de Recrutamento
-- Etapas do processo seletivo
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS pipelines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  job_id UUID NOT NULL REFERENCES vagas(id),
  name TEXT NOT NULL
);

-- --------------------------------------------
-- Etapas do Pipeline
-- Cada etapa dentro de um pipeline
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS etapas_pipeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES empresas(id),
  pipeline_id UUID NOT NULL REFERENCES pipelines(id),
  name TEXT NOT NULL,
  position INTEGER NOT NULL
);

-- --------------------------------------------
-- Presets do Dashboard (RF9)
-- Configurações salvas do dashboard
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS presets_dashboard (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES usuarios(id),
  company_id UUID NOT NULL REFERENCES empresas(id),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  filters JSONB DEFAULT '{}',
  layout JSONB DEFAULT '{}',
  preferences JSONB DEFAULT '{}',
  is_default BOOLEAN DEFAULT false,
  is_shared BOOLEAN DEFAULT false,
  shared_with_roles TEXT[],
  usage_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- ================================================================
-- TABELAS OPCIONAIS (Não MVP)
-- ================================================================

-- --------------------------------------------
-- Perfis GitHub de Candidatos (RF4)
-- Integração com GitHub
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS perfis_github_candidato (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id UUID NOT NULL REFERENCES candidatos(id),
  company_id UUID NOT NULL REFERENCES empresas(id),
  username VARCHAR(100) NOT NULL,
  github_id INTEGER,
  avatar_url TEXT,
  profile_url TEXT,
  bio TEXT,
  location VARCHAR(200),
  blog VARCHAR(500),
  company VARCHAR(200),
  email VARCHAR(200),
  hireable BOOLEAN,
  public_repos INTEGER DEFAULT 0,
  public_gists INTEGER DEFAULT 0,
  followers INTEGER DEFAULT 0,
  following INTEGER DEFAULT 0,
  summary JSONB DEFAULT '{}',
  last_synced_at TIMESTAMP,
  sync_status VARCHAR(50) DEFAULT 'pending',
  sync_error TEXT,
  consent_given BOOLEAN DEFAULT false,
  consent_given_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

-- ================================================================
-- ÍNDICES PARA PERFORMANCE
-- ================================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_company ON usuarios(company_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_vagas_company ON vagas(company_id);
CREATE INDEX IF NOT EXISTS idx_vagas_status ON vagas(status);
CREATE INDEX IF NOT EXISTS idx_candidatos_company ON candidatos(company_id);
CREATE INDEX IF NOT EXISTS idx_curriculos_company ON curriculos(company_id);
CREATE INDEX IF NOT EXISTS idx_curriculos_candidate ON curriculos(candidate_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_company ON entrevistas(company_id);
CREATE INDEX IF NOT EXISTS idx_entrevistas_application ON entrevistas(application_id);
CREATE INDEX IF NOT EXISTS idx_relatorios_interview ON relatorios_entrevista(interview_id);
CREATE INDEX IF NOT EXISTS idx_perguntas_interview ON perguntas_entrevista(interview_id);

-- ================================================================
-- FIM DO SCHEMA
-- ================================================================
