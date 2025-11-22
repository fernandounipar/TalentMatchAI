-- Migration 025: User Metrics Views
-- RF10 - Métricas e KPIs de Gerenciamento de Usuários
-- Data: 22/11/2025

DO $$
BEGIN
  RAISE NOTICE '=== Migration 025: User Metrics Views ===';

  -- =============================================
  -- 1. VIEW: user_stats_overview
  -- =============================================
  
  DROP VIEW IF EXISTS user_stats_overview CASCADE;
  
  CREATE VIEW user_stats_overview AS
  SELECT
    u.company_id,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE u.is_active = TRUE) as active_users,
    COUNT(*) FILTER (WHERE u.is_active = FALSE) as inactive_users,
    COUNT(*) FILTER (WHERE u.email_verified = TRUE) as verified_users,
    COUNT(*) FILTER (WHERE u.email_verified = FALSE) as unverified_users,
    COUNT(*) FILTER (WHERE u.role = 'SUPER_ADMIN') as super_admin_count,
    COUNT(*) FILTER (WHERE u.role = 'ADMIN') as admin_count,
    COUNT(*) FILTER (WHERE u.role = 'RECRUITER') as recruiter_count,
    COUNT(*) FILTER (WHERE u.role = 'USER') as user_count,
    COUNT(*) FILTER (WHERE u.locked_until IS NOT NULL AND u.locked_until > now()) as locked_users,
    COUNT(*) FILTER (WHERE u.created_at >= now() - interval '7 days') as users_last_7_days,
    COUNT(*) FILTER (WHERE u.created_at >= now() - interval '30 days') as users_last_30_days,
    COUNT(*) FILTER (WHERE u.last_login_at >= now() - interval '7 days') as logins_last_7_days,
    COUNT(*) FILTER (WHERE u.last_login_at >= now() - interval '30 days') as logins_last_30_days,
    COUNT(*) FILTER (WHERE u.invitation_token IS NOT NULL AND u.invitation_expires_at > now()) as pending_invitations
  FROM users u
  WHERE u.deleted_at IS NULL
  GROUP BY u.company_id;
  
  RAISE NOTICE '✓ View user_stats_overview criada';

  -- =============================================
  -- 2. VIEW: users_by_role
  -- =============================================
  
  DROP VIEW IF EXISTS users_by_role CASCADE;
  
  CREATE VIEW users_by_role AS
  SELECT
    u.company_id,
    u.role,
    COUNT(*) as user_count,
    COUNT(*) FILTER (WHERE u.is_active = TRUE) as active_count,
    COUNT(*) FILTER (WHERE u.email_verified = TRUE) as verified_count,
    MAX(u.last_login_at) as most_recent_login
  FROM users u
  WHERE u.deleted_at IS NULL
  GROUP BY u.company_id, u.role
  ORDER BY u.company_id, user_count DESC;
  
  RAISE NOTICE '✓ View users_by_role criada';

  -- =============================================
  -- 3. VIEW: users_by_department
  -- =============================================
  
  DROP VIEW IF EXISTS users_by_department CASCADE;
  
  CREATE VIEW users_by_department AS
  SELECT
    u.company_id,
    COALESCE(u.department, 'Não definido') as department,
    COUNT(*) as user_count,
    COUNT(*) FILTER (WHERE u.is_active = TRUE) as active_count
  FROM users u
  WHERE u.deleted_at IS NULL
  GROUP BY u.company_id, u.department
  ORDER BY u.company_id, user_count DESC;
  
  RAISE NOTICE '✓ View users_by_department criada';

  -- =============================================
  -- 4. VIEW: user_login_timeline
  -- =============================================
  
  DROP VIEW IF EXISTS user_login_timeline CASCADE;
  
  CREATE VIEW user_login_timeline AS
  SELECT
    u.company_id,
    DATE(u.last_login_at) as login_date,
    COUNT(DISTINCT u.id) as unique_users_logged,
    COUNT(*) as total_logins
  FROM users u
  WHERE u.deleted_at IS NULL
    AND u.last_login_at IS NOT NULL
  GROUP BY u.company_id, DATE(u.last_login_at)
  ORDER BY u.company_id, login_date DESC;
  
  RAISE NOTICE '✓ View user_login_timeline criada';

  -- =============================================
  -- 5. VIEW: user_registration_timeline
  -- =============================================
  
  DROP VIEW IF EXISTS user_registration_timeline CASCADE;
  
  CREATE VIEW user_registration_timeline AS
  SELECT
    u.company_id,
    DATE(u.created_at) as registration_date,
    COUNT(*) as users_registered,
    COUNT(*) FILTER (WHERE u.is_active = TRUE) as active_registered,
    COUNT(*) FILTER (WHERE u.email_verified = TRUE) as verified_registered
  FROM users u
  WHERE u.deleted_at IS NULL
  GROUP BY u.company_id, DATE(u.created_at)
  ORDER BY u.company_id, registration_date DESC;
  
  RAISE NOTICE '✓ View user_registration_timeline criada';

  -- =============================================
  -- 6. VIEW: user_security_stats
  -- =============================================
  
  DROP VIEW IF EXISTS user_security_stats CASCADE;
  
  CREATE VIEW user_security_stats AS
  SELECT
    u.company_id,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE u.failed_login_attempts > 0) as users_with_failed_attempts,
    COUNT(*) FILTER (WHERE u.locked_until IS NOT NULL AND u.locked_until > now()) as currently_locked,
    AVG(u.failed_login_attempts) as avg_failed_attempts,
    MAX(u.failed_login_attempts) as max_failed_attempts,
    COUNT(*) FILTER (WHERE u.email_verified = FALSE) as unverified_emails
  FROM users u
  WHERE u.deleted_at IS NULL
  GROUP BY u.company_id;
  
  RAISE NOTICE '✓ View user_security_stats criada';

  -- =============================================
  -- 7. VIEW: user_invitation_stats
  -- =============================================
  
  DROP VIEW IF EXISTS user_invitation_stats CASCADE;
  
  CREATE VIEW user_invitation_stats AS
  SELECT
    u.company_id,
    COUNT(*) FILTER (WHERE u.invitation_token IS NOT NULL) as total_invitations,
    COUNT(*) FILTER (WHERE u.invitation_token IS NOT NULL AND u.invitation_expires_at > now()) as pending_invitations,
    COUNT(*) FILTER (WHERE u.invitation_token IS NOT NULL AND u.invitation_expires_at <= now()) as expired_invitations,
    COUNT(*) FILTER (WHERE u.invited_by IS NOT NULL AND u.invitation_token IS NULL) as accepted_invitations
  FROM users u
  WHERE u.deleted_at IS NULL
  GROUP BY u.company_id;
  
  RAISE NOTICE '✓ View user_invitation_stats criada';

  -- =============================================
  -- 8. FUNÇÃO: get_user_metrics
  -- =============================================
  
  CREATE OR REPLACE FUNCTION get_user_metrics(p_company_id UUID)
  RETURNS JSON AS $func$
  DECLARE
    v_result JSON;
  BEGIN
    SELECT json_build_object(
      'total_users', COALESCE(total_users, 0),
      'active_users', COALESCE(active_users, 0),
      'inactive_users', COALESCE(inactive_users, 0),
      'verified_users', COALESCE(verified_users, 0),
      'unverified_users', COALESCE(unverified_users, 0),
      'super_admin_count', COALESCE(super_admin_count, 0),
      'admin_count', COALESCE(admin_count, 0),
      'recruiter_count', COALESCE(recruiter_count, 0),
      'user_count', COALESCE(user_count, 0),
      'locked_users', COALESCE(locked_users, 0),
      'users_last_7_days', COALESCE(users_last_7_days, 0),
      'users_last_30_days', COALESCE(users_last_30_days, 0),
      'logins_last_7_days', COALESCE(logins_last_7_days, 0),
      'logins_last_30_days', COALESCE(logins_last_30_days, 0),
      'pending_invitations', COALESCE(pending_invitations, 0),
      'active_rate', CASE 
        WHEN COALESCE(total_users, 0) > 0 
        THEN ROUND((COALESCE(active_users, 0)::numeric / total_users * 100), 2)
        ELSE 0
      END,
      'verification_rate', CASE 
        WHEN COALESCE(total_users, 0) > 0 
        THEN ROUND((COALESCE(verified_users, 0)::numeric / total_users * 100), 2)
        ELSE 0
      END
    )
    INTO v_result
    FROM user_stats_overview
    WHERE company_id = p_company_id;
    
    -- Se não houver dados, retornar zeros
    IF v_result IS NULL THEN
      v_result := json_build_object(
        'total_users', 0,
        'active_users', 0,
        'inactive_users', 0,
        'verified_users', 0,
        'unverified_users', 0,
        'super_admin_count', 0,
        'admin_count', 0,
        'recruiter_count', 0,
        'user_count', 0,
        'locked_users', 0,
        'users_last_7_days', 0,
        'users_last_30_days', 0,
        'logins_last_7_days', 0,
        'logins_last_30_days', 0,
        'pending_invitations', 0,
        'active_rate', 0,
        'verification_rate', 0
      );
    END IF;
    
    RETURN v_result;
  END;
  $func$ LANGUAGE plpgsql STABLE;
  
  RAISE NOTICE '✓ Função get_user_metrics criada';

  -- =============================================
  -- 9. ÍNDICES ADICIONAIS PARA PERFORMANCE
  -- =============================================
  
  RAISE NOTICE 'Criando índices adicionais para queries de métricas...';
  
  CREATE INDEX IF NOT EXISTS idx_users_company_role 
    ON users(company_id, role) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_company_active 
    ON users(company_id, is_active) WHERE deleted_at IS NULL;
  
  CREATE INDEX IF NOT EXISTS idx_users_registration_date 
    ON users(DATE(created_at)) WHERE deleted_at IS NULL;
  
  RAISE NOTICE '✓ 3 índices adicionais criados';

  -- =============================================
  -- 10. COMENTÁRIOS
  -- =============================================
  
  COMMENT ON VIEW user_stats_overview IS 'RF10 - Estatísticas gerais de usuários por empresa';
  COMMENT ON VIEW users_by_role IS 'RF10 - Usuários agrupados por role';
  COMMENT ON VIEW users_by_department IS 'RF10 - Usuários agrupados por departamento';
  COMMENT ON VIEW user_login_timeline IS 'RF10 - Timeline de logins';
  COMMENT ON VIEW user_registration_timeline IS 'RF10 - Timeline de registros';
  COMMENT ON VIEW user_security_stats IS 'RF10 - Estatísticas de segurança';
  COMMENT ON VIEW user_invitation_stats IS 'RF10 - Estatísticas de convites';
  COMMENT ON FUNCTION get_user_metrics IS 'RF10 - Retorna métricas consolidadas de usuários para dashboard';

  RAISE NOTICE '=== Migration 025 concluída com sucesso ===';

END $$;
