/**
 * RF10 - Gerenciamento de Usuários (CRUD Completo)
 * 
 * Endpoints:
 * - POST   /api/usuarios                  - Criar usuário (admin)
 * - POST   /api/usuarios/invite           - Convidar usuário (admin)
 * - POST   /api/usuarios/accept-invite    - Aceitar convite (público)
 * - GET    /api/usuarios                  - Listar usuários (admin)
 * - GET    /api/usuarios/:id              - Detalhes do usuário (admin)
 * - PUT    /api/usuarios/:id              - Atualizar usuário (admin)
 * - DELETE /api/usuarios/:id              - Soft delete (admin)
 */

const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { exigirAutenticacao, exigirRole } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');
const { validaDocumento, normalizaDocumento } = require('../../servicos/documento');

// Todas as rotas (exceto /accept-invite) exigem autenticação
router.use((req, res, next) => {
  if (req.path === '/accept-invite') return next();
  return exigirAutenticacao(req, res, next);
});

/**
 * POST /api/usuarios
 * Criar novo usuário diretamente (sem convite)
 * Requer ADMIN ou SUPER_ADMIN
 */
router.post('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const {
      full_name, email, password,
      role = 'USER',
      phone, department, job_title, bio,
      is_active = true,
      email_verified = false,
      company
    } = req.body;

    // Validações
    if (!full_name || !email) {
      return res.status(400).json({ error: { code: 'MISSING_FIELDS', message: 'full_name and email are required' } });
    }

    if (!['USER', 'RECRUITER', 'ADMIN', 'SUPER_ADMIN'].includes(role)) {
      return res.status(400).json({ error: { code: 'INVALID_ROLE', message: 'Invalid role' } });
    }

    // Resolver company_id
    let companyId = req.usuario.company_id;
    if (company && company.document && company.type) {
      const tipo = String(company.type).toUpperCase();
      const documento = normalizaDocumento(company.document);
      if (!['CPF', 'CNPJ'].includes(tipo) || !validaDocumento(tipo, documento)) {
        return res.status(400).json({ error: { code: 'INVALID_DOCUMENT', message: 'Invalid company type/document' } });
      }
      const companyResult = await db.query(
        `INSERT INTO companies (type, document, name)
         VALUES ($1, $2, $3)
         ON CONFLICT (document) DO UPDATE SET type = EXCLUDED.type, name = EXCLUDED.name
         RETURNING id`,
        [tipo, documento, company.name || null]
      );
      companyId = companyResult.rows[0].id;
    }

    // Hash da senha (se fornecida, senão usuário deve resetar)
    let passwordHash = null;
    if (password) {
      passwordHash = await bcrypt.hash(password, 10);
    }

    // Inserir usuário
    const result = await db.query(
      `INSERT INTO users (
        company_id, full_name, email, password_hash, role,
        phone, department, job_title, bio,
        is_active, email_verified
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING
        id, company_id, full_name, email, role,
        phone, department, job_title, bio,
        is_active, email_verified, created_at`,
      [
        companyId, full_name, email.toLowerCase(), passwordHash, role,
        phone || null, department || null, job_title || null, bio || null,
        is_active, email_verified
      ]
    );

    const user = result.rows[0];
    await audit(req, 'create', 'users', user.id, { email: user.email, role: user.role });

    res.status(201).json({ data: user });
  } catch (error) {
    if (error.message?.includes('duplicate') || error.code === '23505') {
      return res.status(409).json({ error: { code: 'EMAIL_EXISTS', message: 'Email already exists' } });
    }
    console.error('Error creating user:', error);
    res.status(500).json({ error: { code: 'CREATE_USER_FAILED', message: 'Failed to create user' } });
  }
});

/**
 * POST /api/usuarios/invite
 * Enviar convite para novo usuário
 * Gera token de convite e envia email (TODO: integração com serviço de email)
 * Requer ADMIN ou SUPER_ADMIN
 */
router.post('/invite', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const {
      full_name, email, role = 'USER',
      phone, department, job_title,
      expires_in_days = 7
    } = req.body;

    // Validações
    if (!full_name || !email) {
      return res.status(400).json({ error: { code: 'MISSING_FIELDS', message: 'full_name and email are required' } });
    }

    if (!['USER', 'RECRUITER', 'ADMIN', 'SUPER_ADMIN'].includes(role)) {
      return res.status(400).json({ error: { code: 'INVALID_ROLE', message: 'Invalid role' } });
    }

    // Verificar se email já existe
    const existingUser = await db.query(
      'SELECT id FROM users WHERE LOWER(email) = LOWER($1) AND deleted_at IS NULL',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: { code: 'EMAIL_EXISTS', message: 'User with this email already exists' } });
    }

    // Gerar token único
    const invitationToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expires_in_days);

    // Criar usuário com convite pendente
    const result = await db.query(
      `INSERT INTO users (
        company_id, full_name, email, role,
        phone, department, job_title,
        invitation_token, invitation_expires_at, invited_by,
        is_active, email_verified
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, FALSE, FALSE)
      RETURNING
        id, company_id, full_name, email, role,
        phone, department, job_title,
        invitation_token, invitation_expires_at, invited_by,
        created_at`,
      [
        req.usuario.company_id, full_name, email.toLowerCase(), role,
        phone || null, department || null, job_title || null,
        invitationToken, expiresAt, req.usuario.id
      ]
    );

    const user = result.rows[0];
    await audit(req, 'invite', 'users', user.id, { email: user.email, role: user.role });

    // TODO: Enviar email com link de convite
    // const inviteLink = `${process.env.FRONTEND_URL}/accept-invite?token=${invitationToken}`;
    // await emailService.sendInvitation(email, full_name, inviteLink);

    res.status(201).json({
      data: {
        ...user,
        message: 'Invitation sent successfully'
      }
    });
  } catch (error) {
    console.error('Error sending invitation:', error);
    res.status(500).json({ error: { code: 'INVITE_FAILED', message: 'Failed to send invitation' } });
  }
});

/**
 * POST /api/usuarios/accept-invite
 * Aceitar convite e definir senha
 * Rota pública (não exige autenticação)
 */
router.post('/accept-invite', async (req, res) => {
  try {
    const { invitation_token, password, preferences } = req.body;

    if (!invitation_token || !password) {
      return res.status(400).json({ error: { code: 'MISSING_FIELDS', message: 'invitation_token and password are required' } });
    }

    // Buscar convite
    const userResult = await db.query(
      `SELECT id, full_name, email, invitation_expires_at
       FROM users
       WHERE invitation_token = $1
         AND deleted_at IS NULL`,
      [invitation_token]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: { code: 'INVALID_TOKEN', message: 'Invalid invitation token' } });
    }

    const user = userResult.rows[0];

    // Verificar expiração
    if (new Date(user.invitation_expires_at) < new Date()) {
      return res.status(410).json({ error: { code: 'TOKEN_EXPIRED', message: 'Invitation has expired' } });
    }

    // Hash da senha
    const passwordHash = await bcrypt.hash(password, 10);

    // Atualizar usuário: definir senha, limpar token, marcar como verificado
    await db.query(
      `UPDATE users
       SET password_hash = $1,
           invitation_token = NULL,
           invitation_expires_at = NULL,
           email_verified = TRUE,
           email_verified_at = NOW(),
           is_active = TRUE,
           preferences = COALESCE($2::jsonb, '{}'),
           updated_at = NOW()
       WHERE id = $3`,
      [passwordHash, preferences ? JSON.stringify(preferences) : null, user.id]
    );

    res.json({
      data: {
        message: 'Invitation accepted successfully',
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email
        }
      }
    });
  } catch (error) {
    console.error('Error accepting invitation:', error);
    res.status(500).json({ error: { code: 'ACCEPT_INVITE_FAILED', message: 'Failed to accept invitation' } });
  }
});

/**
 * GET /api/usuarios
 * Listar usuários com filtros
 * Requer ADMIN ou SUPER_ADMIN
 */
router.get('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const {
      role, department, is_active, email_verified,
      search, sort = 'created_at', order = 'DESC',
      page = 1, limit = 50
    } = req.query;

    // Construir WHERE clause
    const conditions = ['deleted_at IS NULL', 'company_id = $1'];
    const params = [req.usuario.company_id];
    let paramIndex = 2;

    if (role) {
      conditions.push(`role = $${paramIndex}`);
      params.push(role);
      paramIndex++;
    }

    if (department) {
      conditions.push(`department = $${paramIndex}`);
      params.push(department);
      paramIndex++;
    }

    if (is_active !== undefined) {
      conditions.push(`is_active = $${paramIndex}`);
      params.push(is_active === 'true');
      paramIndex++;
    }

    if (email_verified !== undefined) {
      conditions.push(`email_verified = $${paramIndex}`);
      params.push(email_verified === 'true');
      paramIndex++;
    }

    if (search) {
      conditions.push(`(
        LOWER(full_name) LIKE LOWER($${paramIndex})
        OR LOWER(email) LIKE LOWER($${paramIndex})
        OR LOWER(department) LIKE LOWER($${paramIndex})
        OR LOWER(job_title) LIKE LOWER($${paramIndex})
      )`);
      params.push(`%${search}%`);
      paramIndex++;
    }

    const whereClause = conditions.join(' AND ');

    // Validar sort e order
    const allowedSort = ['created_at', 'full_name', 'email', 'role', 'last_login_at'];
    const sortColumn = allowedSort.includes(sort) ? sort : 'created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Paginação
    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Query principal
    const result = await db.query(
      `SELECT
         u.id, u.company_id, u.full_name, u.email, u.role,
         u.phone, u.department, u.job_title, u.bio, u.foto_url,
         u.is_active, u.email_verified, u.email_verified_at,
         u.last_login_at, u.last_login_ip,
         u.failed_login_attempts, u.locked_until,
         u.invitation_token IS NOT NULL as has_pending_invitation,
         u.invitation_expires_at,
         u.invited_by,
         u.created_at, u.updated_at,
         inv.full_name as invited_by_name
       FROM users u
       LEFT JOIN users inv ON u.invited_by = inv.id
       WHERE ${whereClause}
       ORDER BY ${sortColumn} ${sortOrder}
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...params, parseInt(limit), offset]
    );

    // Contar total
    const countResult = await db.query(
      `SELECT COUNT(*) as total FROM users WHERE ${whereClause}`,
      params
    );

    const total = parseInt(countResult.rows[0].total);

    res.json({
      data: result.rows,
      meta: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error listing users:', error);
    res.status(500).json({ error: { code: 'LIST_USERS_FAILED', message: 'Failed to list users' } });
  }
});

/**
 * GET /api/usuarios/:id
 * Detalhes de um usuário específico
 * Requer ADMIN ou SUPER_ADMIN
 */
router.get('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      `SELECT
         u.id, u.company_id, u.full_name, u.email, u.role,
         u.phone, u.department, u.job_title, u.bio, u.foto_url,
         u.is_active, u.email_verified, u.email_verified_at,
         u.last_login_at, u.last_login_ip,
         u.failed_login_attempts, u.locked_until,
         u.invitation_token, u.invitation_expires_at,
         u.invited_by,
         u.preferences,
         u.created_at, u.updated_at,
         c.name as company_name,
         inv.full_name as invited_by_name,
         inv.email as invited_by_email
       FROM users u
       LEFT JOIN companies c ON u.company_id = c.id
       LEFT JOIN users inv ON u.invited_by = inv.id
       WHERE u.id = $1
         AND u.company_id = $2
         AND u.deleted_at IS NULL`,
      [id, req.usuario.company_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
    }

    res.json({ data: result.rows[0] });
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ error: { code: 'GET_USER_FAILED', message: 'Failed to get user details' } });
  }
});

/**
 * PUT /api/usuarios/:id
 * Atualizar usuário
 * Requer ADMIN ou SUPER_ADMIN
 */
router.put('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      full_name, email, role,
      phone, department, job_title, bio,
      is_active, email_verified,
      preferences,
      password // opcional: redefinir senha
    } = req.body;

    // Verificar se usuário existe e pertence à company
    const existingUser = await db.query(
      'SELECT id, role FROM users WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL',
      [id, req.usuario.company_id]
    );

    if (existingUser.rows.length === 0) {
      return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
    }

    // Validar role se fornecido
    if (role && !['USER', 'RECRUITER', 'ADMIN', 'SUPER_ADMIN'].includes(role)) {
      return res.status(400).json({ error: { code: 'INVALID_ROLE', message: 'Invalid role' } });
    }

    // Construir SET clause dinamicamente
    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (full_name !== undefined) {
      updates.push(`full_name = $${paramIndex}`);
      params.push(full_name);
      paramIndex++;
    }

    if (email !== undefined) {
      updates.push(`email = $${paramIndex}`);
      params.push(email.toLowerCase());
      paramIndex++;
    }

    if (role !== undefined) {
      updates.push(`role = $${paramIndex}`);
      params.push(role);
      paramIndex++;
    }

    if (phone !== undefined) {
      updates.push(`phone = $${paramIndex}`);
      params.push(phone || null);
      paramIndex++;
    }

    if (department !== undefined) {
      updates.push(`department = $${paramIndex}`);
      params.push(department || null);
      paramIndex++;
    }

    if (job_title !== undefined) {
      updates.push(`job_title = $${paramIndex}`);
      params.push(job_title || null);
      paramIndex++;
    }

    if (bio !== undefined) {
      updates.push(`bio = $${paramIndex}`);
      params.push(bio || null);
      paramIndex++;
    }

    if (is_active !== undefined) {
      updates.push(`is_active = $${paramIndex}`);
      params.push(is_active);
      paramIndex++;
    }

    if (email_verified !== undefined) {
      updates.push(`email_verified = $${paramIndex}`);
      params.push(email_verified);
      paramIndex++;
      if (email_verified) {
        updates.push(`email_verified_at = NOW()`);
      }
    }

    if (preferences !== undefined) {
      updates.push(`preferences = $${paramIndex}::jsonb`);
      params.push(JSON.stringify(preferences));
      paramIndex++;
    }

    if (password) {
      const passwordHash = await bcrypt.hash(password, 10);
      updates.push(`password_hash = $${paramIndex}`);
      params.push(passwordHash);
      paramIndex++;
      // Reset failed attempts ao redefinir senha
      updates.push(`failed_login_attempts = 0, locked_until = NULL`);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: { code: 'NO_FIELDS', message: 'No fields to update' } });
    }

    // Adicionar updated_at
    updates.push('updated_at = NOW()');

    // Executar update
    params.push(id, req.usuario.company_id);
    const result = await db.query(
      `UPDATE users
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex} AND company_id = $${paramIndex + 1} AND deleted_at IS NULL
       RETURNING
         id, company_id, full_name, email, role,
         phone, department, job_title, bio,
         is_active, email_verified, email_verified_at,
         last_login_at, updated_at`,
      params
    );

    await audit(req, 'update', 'users', id, req.body);

    res.json({ data: result.rows[0] });
  } catch (error) {
    if (error.message?.includes('duplicate') || error.code === '23505') {
      return res.status(409).json({ error: { code: 'EMAIL_EXISTS', message: 'Email already exists' } });
    }
    console.error('Error updating user:', error);
    res.status(500).json({ error: { code: 'UPDATE_USER_FAILED', message: 'Failed to update user' } });
  }
});

/**
 * DELETE /api/usuarios/:id
 * Soft delete de usuário
 * Requer ADMIN ou SUPER_ADMIN
 */
router.delete('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se usuário existe e pertence à company
    const existingUser = await db.query(
      'SELECT id, email FROM users WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL',
      [id, req.usuario.company_id]
    );

    if (existingUser.rows.length === 0) {
      return res.status(404).json({ error: { code: 'USER_NOT_FOUND', message: 'User not found' } });
    }

    // Impedir auto-delete
    if (id === req.usuario.id) {
      return res.status(400).json({ error: { code: 'CANNOT_DELETE_SELF', message: 'Cannot delete your own account' } });
    }

    // Soft delete
    await db.query(
      'UPDATE users SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1',
      [id]
    );

    await audit(req, 'delete', 'users', id, { email: existingUser.rows[0].email });

    res.json({ data: { message: 'User deleted successfully' } });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: { code: 'DELETE_USER_FAILED', message: 'Failed to delete user' } });
  }
});

module.exports = router;
