-- Migration 024: User Management Improvements
-- RF10 - Gerenciamento de Usuários
-- Data: 22/11/2025

DO $$
BEGIN
  RAISE NOTICE '=== Migration 024: User Management Improvements ===';

  -- =============================================
  -- 1. ADICIONAR COLUNAS À TABELA USERS
  -- =============================================
  
  RAISE NOTICE 'Adicionando/verificando colunas na tabela users...';
  
  -- Phone (telefone)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
    ALTER TABLE users ADD COLUMN phone VARCHAR(20);
    RAISE NOTICE '✓ Adicionada coluna phone';
  END IF;
  
  -- Department (departamento)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='department') THEN
    ALTER TABLE users ADD COLUMN department VARCHAR(100);
    RAISE NOTICE '✓ Adicionada coluna department';
  END IF;
  
  -- Job title (substituir cargo se necessário)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='job_title') THEN
    ALTER TABLE users ADD COLUMN job_title VARCHAR(150);
    -- Migrar dados de cargo para job_title se cargo existir
    UPDATE users SET job_title = cargo WHERE cargo IS NOT NULL AND job_title IS NULL;
    RAISE NOTICE '✓ Adicionada coluna job_title';
  END IF;
  
  -- Last login tracking
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='last_login_at') THEN
    ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna last_login_at';
  END IF;
  
  -- Login IP tracking
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='last_login_ip') THEN
    ALTER TABLE users ADD COLUMN last_login_ip VARCHAR(45);
    RAISE NOTICE '✓ Adicionada coluna last_login_ip';
  END IF;
  
  -- Failed login attempts counter
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='failed_login_attempts') THEN
    ALTER TABLE users ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
    RAISE NOTICE '✓ Adicionada coluna failed_login_attempts';
  END IF;
  
  -- Account locked until
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='locked_until') THEN
    ALTER TABLE users ADD COLUMN locked_until TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna locked_until';
  END IF;
  
  -- Email verified flag
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='email_verified') THEN
    ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
    -- Marcar emails existentes como verificados (retroativo)
    UPDATE users SET email_verified = TRUE WHERE email_verified IS NULL;
    RAISE NOTICE '✓ Adicionada coluna email_verified';
  END IF;
  
  -- Email verified at
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='email_verified_at') THEN
    ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna email_verified_at';
  END IF;
  
  -- Invitation token (para fluxo de convite)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='invitation_token') THEN
    ALTER TABLE users ADD COLUMN invitation_token VARCHAR(255);
    RAISE NOTICE '✓ Adicionada coluna invitation_token';
  END IF;
  
  -- Invitation expires at
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='invitation_expires_at') THEN
    ALTER TABLE users ADD COLUMN invitation_expires_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna invitation_expires_at';
  END IF;
  
  -- Invited by (user_id que convidou)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='invited_by') THEN
    ALTER TABLE users ADD COLUMN invited_by UUID;
    RAISE NOTICE '✓ Adicionada coluna invited_by';
  END IF;
  
  -- Bio/notes
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='bio') THEN
    ALTER TABLE users ADD COLUMN bio TEXT;
    RAISE NOTICE '✓ Adicionada coluna bio';
  END IF;
  
  -- Preferences (JSONB)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='preferences') THEN
    ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}'::jsonb;
    RAISE NOTICE '✓ Adicionada coluna preferences';
  END IF;
  
  -- Garantir que updated_at existe
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='updated_at') THEN
    ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT now();
    RAISE NOTICE '✓ Adicionada coluna updated_at';
  END IF;
  
  -- Garantir que deleted_at existe (soft delete)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='deleted_at') THEN
    ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP;
    RAISE NOTICE '✓ Adicionada coluna deleted_at';
  END IF;

  -- =============================================
  -- 2. ATUALIZAR CONSTRAINT DE ROLE
  -- =============================================
  
  RAISE NOTICE 'Atualizando constraint de role...';
  
  -- Dropar constraint antiga se existir
  ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
  
  -- Adicionar nova constraint com valores padronizados
  ALTER TABLE users 
    ADD CONSTRAINT users_role_check 
    CHECK (role IN ('USER', 'RECRUITER', 'ADMIN', 'SUPER_ADMIN'));
  
  RAISE NOTICE '✓ Constraint users_role_check atualizada';

  -- =============================================
  -- 3. FOREIGN KEY PARA INVITED_BY
  -- =============================================
  
  RAISE NOTICE 'Adicionando foreign key invited_by...';
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_users_invited_by'
  ) THEN
    ALTER TABLE users 
      ADD CONSTRAINT fk_users_invited_by 
      FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL;
    RAISE NOTICE '✓ FK invited_by → users';
  END IF;

  -- =============================================
  -- 4. ÍNDICES DE PERFORMANCE
  -- =============================================
  
  RAISE NOTICE 'Criando índices...';
  
  CREATE INDEX IF NOT EXISTS idx_users_company 
    ON users(company_id) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_email 
    ON users(LOWER(email)) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_role 
    ON users(role) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_is_active 
    ON users(is_active) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_created_at 
    ON users(created_at DESC) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_last_login 
    ON users(last_login_at DESC) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_invitation_token 
    ON users(invitation_token) WHERE invitation_token IS NOT NULL AND deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_preferences_gin 
    ON users USING gin(preferences);
  
  RAISE NOTICE '✓ 8 índices criados/verificados';

  -- =============================================
  -- 5. TRIGGER PARA AUTO-UPDATE DE UPDATED_AT
  -- =============================================
  
  CREATE OR REPLACE FUNCTION update_users_timestamps()
  RETURNS TRIGGER AS $func$
  BEGIN
    NEW.updated_at = now();
    RETURN NEW;
  END;
  $func$ LANGUAGE plpgsql;
  
  DROP TRIGGER IF EXISTS trigger_update_users ON users;
  CREATE TRIGGER trigger_update_users
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_timestamps();
  
  RAISE NOTICE '✓ Trigger update_users_timestamps criado';

  -- =============================================
  -- 6. FUNÇÃO DE BLOQUEIO POR TENTATIVAS FALHAS
  -- =============================================
  
  CREATE OR REPLACE FUNCTION check_and_lock_user_account()
  RETURNS TRIGGER AS $func$
  BEGIN
    -- Se atingir 5 tentativas falhas, bloquear por 15 minutos
    IF NEW.failed_login_attempts >= 5 THEN
      NEW.locked_until = now() + interval '15 minutes';
      RAISE NOTICE 'Conta bloqueada por tentativas falhas: user_id=%', NEW.id;
    END IF;
    RETURN NEW;
  END;
  $func$ LANGUAGE plpgsql;
  
  DROP TRIGGER IF EXISTS trigger_check_lock_account ON users;
  CREATE TRIGGER trigger_check_lock_account
    BEFORE UPDATE OF failed_login_attempts ON users
    FOR EACH ROW
    EXECUTE FUNCTION check_and_lock_user_account();
  
  RAISE NOTICE '✓ Trigger check_and_lock_user_account criado';

  -- =============================================
  -- 7. VIEW PARA USUÁRIOS ATIVOS
  -- =============================================
  
  DROP VIEW IF EXISTS active_users_overview CASCADE;
  
  CREATE VIEW active_users_overview AS
  SELECT
    u.id,
    u.company_id,
    u.full_name,
    u.email,
    u.role,
    u.is_active,
    u.email_verified,
    u.last_login_at,
    u.created_at,
    u.department,
    u.job_title,
    c.name as company_name
  FROM users u
  LEFT JOIN companies c ON c.id = u.company_id
  WHERE u.deleted_at IS NULL
    AND u.is_active = TRUE;
  
  RAISE NOTICE '✓ View active_users_overview criada';

  -- =============================================
  -- 8. COMENTÁRIOS
  -- =============================================
  
  COMMENT ON COLUMN users.phone IS 'RF10 - Telefone do usuário';
  COMMENT ON COLUMN users.department IS 'RF10 - Departamento do usuário';
  COMMENT ON COLUMN users.job_title IS 'RF10 - Cargo/título do usuário';
  COMMENT ON COLUMN users.last_login_at IS 'RF10 - Último login do usuário';
  COMMENT ON COLUMN users.last_login_ip IS 'RF10 - IP do último login';
  COMMENT ON COLUMN users.failed_login_attempts IS 'RF10 - Contador de tentativas falhas de login';
  COMMENT ON COLUMN users.locked_until IS 'RF10 - Conta bloqueada até este timestamp';
  COMMENT ON COLUMN users.email_verified IS 'RF10 - Email foi verificado?';
  COMMENT ON COLUMN users.email_verified_at IS 'RF10 - Quando o email foi verificado';
  COMMENT ON COLUMN users.invitation_token IS 'RF10 - Token para fluxo de convite';
  COMMENT ON COLUMN users.invitation_expires_at IS 'RF10 - Expiração do convite';
  COMMENT ON COLUMN users.invited_by IS 'RF10 - ID do usuário que convidou';
  COMMENT ON COLUMN users.bio IS 'RF10 - Biografia/notas do usuário';
  COMMENT ON COLUMN users.preferences IS 'RF10 - Preferências do usuário (JSONB)';
  
  COMMENT ON VIEW active_users_overview IS 'RF10 - Visão de usuários ativos';

  RAISE NOTICE '=== Migration 024 concluída com sucesso ===';

END $$;
