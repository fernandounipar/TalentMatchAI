const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/database');
const { validarDocumento, normalizarDocumento } = require('./validacao');
const { agora, expiracaoEmDias, expiracaoEmHoras, jaExpirou } = require('../utils/dateUtils');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_in_production';
const ACCESS_TOKEN_EXPIRATION = process.env.JWT_ACCESS_EXPIRATION || '15m';
const REFRESH_TOKEN_EXPIRATION = process.env.JWT_REFRESH_EXPIRATION || '7d';

/**
 * Gera access token JWT
 */
function gerarAccessToken(usuario) {
  return jwt.sign(
    {
      sub: usuario.id,
      id: usuario.id,
      email: usuario.email,
      nome: usuario.full_name,
      perfil: usuario.role,
      company_id: usuario.company_id
    },
    JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRATION }
  );
}

/**
 * Gera refresh token (opaco, armazenado no banco)
 */
function gerarRefreshToken() {
  return crypto.randomBytes(64).toString('hex');
}

/**
 * Calcula data de expiracao do refresh token (horario de Brasilia)
 */
function calcularExpiracaoRefresh() {
  const days = parseInt(REFRESH_TOKEN_EXPIRATION) || 7;
  return expiracaoEmDias(days);
}

/**
 * Registra novo usuário (SEM criar empresa - onboarding gradual)
 * @param {object} data - { full_name, email, password }
 * @returns {object} - { usuario, access_token, refresh_token }
 */
async function registrar(data) {
  const { full_name, email, password } = data;

  // Valida dados do usuário
  if (!full_name || !email || !password) {
    throw new Error('Dados incompletos (full_name, email, password).');
  }

  // Valida email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new Error('Email inválido.');
  }

  // Valida senha (mínimo 6 caracteres)
  if (password.length < 6) {
    throw new Error('Senha deve ter no mínimo 6 caracteres.');
  }

  try {
    // Verifica se email já existe
    const emailCheck = await db.query(
      'SELECT id FROM usuarios WHERE email = $1',
      [email.toLowerCase()]
    );

    if (emailCheck.rows.length > 0) {
      throw new Error('Este email já está cadastrado.');
    }

    // Hash da senha
    const password_hash = await bcrypt.hash(password, 10);

    // Cria usuário SEM company_id (será preenchido depois nas configurações)
    const role = 'USER'; // Usuário comum - pode virar ADMIN depois de criar empresa
    const userResult = await db.query(
      `INSERT INTO usuarios (full_name, email, password_hash, role, is_active) 
       VALUES ($1, $2, $3, $4, true) 
       RETURNING id, company_id, full_name, email, role, is_active, created_at`,
      [full_name, email.toLowerCase(), password_hash, role]
    );

    const createdUser = userResult.rows[0];

    // Gera tokens
    const access_token = gerarAccessToken(createdUser);
    const refresh_token = gerarRefreshToken();
    const refresh_expires_at = calcularExpiracaoRefresh();

    // Armazena refresh token
    await db.query(
      `INSERT INTO tokens_atualizacao (user_id, token_hash, expires_at) 
       VALUES ($1, $2, $3)`,
      [createdUser.id, refresh_token, refresh_expires_at]
    );

    return {
      usuario: {
        id: createdUser.id,
        company_id: createdUser.company_id, // null inicialmente
        nome: createdUser.full_name,
        email: createdUser.email,
        perfil: createdUser.role
      },
      access_token,
      refresh_token
    };
  } catch (error) {
    throw error;
  }
}

/**
 * Login com email e senha
 * @param {string} email 
 * @param {string} senha 
 * @returns {object} - { usuario, access_token, refresh_token }
 */
async function login(email, senha) {
  if (!email || !senha) {
    throw new Error('Email e senha são obrigatórios.');
  }

  // Busca usuário
  const result = await db.query(
    `SELECT id, company_id, full_name, email, password_hash, role, is_active 
     FROM usuarios 
     WHERE email = $1 AND deleted_at IS NULL`,
    [email.toLowerCase()]
  );

  if (result.rows.length === 0) {
    throw new Error('Credenciais inválidas.');
  }

  const usuario = result.rows[0];

  if (!usuario.is_active) {
    throw new Error('Usuário inativo.');
  }

  // Verifica senha
  const senhaValida = await bcrypt.compare(senha, usuario.password_hash);
  if (!senhaValida) {
    throw new Error('Credenciais inválidas.');
  }

  // Gera tokens
  const access_token = gerarAccessToken(usuario);
  const refresh_token = gerarRefreshToken();
  const refresh_expires_at = calcularExpiracaoRefresh();

  // Armazena refresh token
  await db.query(
    `INSERT INTO tokens_atualizacao (user_id, token_hash, expires_at) 
     VALUES ($1, $2, $3)`,
    [usuario.id, refresh_token, refresh_expires_at]
  );

  return {
    usuario: {
      id: usuario.id,
      company_id: usuario.company_id,
      nome: usuario.full_name,
      email: usuario.email,
      perfil: usuario.role
    },
    access_token,
    refresh_token
  };
}

/**
 * Renova access token usando refresh token
 * @param {string} token 
 */
async function refresh(token) {
  if (!token) {
    throw new Error('Refresh token não fornecido.');
  }

  // Busca token no banco
  const result = await db.query(
    `SELECT t.*, u.id as user_id, u.company_id, u.full_name, u.email, u.role, u.is_active
     FROM tokens_atualizacao t
     JOIN usuarios u ON t.user_id = u.id
     WHERE t.token_hash = $1`,
    [token]
  );

  if (result.rows.length === 0) {
    throw new Error('Refresh token inválido.');
  }

  const storedToken = result.rows[0];

  // Verifica se foi revogado
  if (storedToken.revoked_at) {
    throw new Error('Refresh token revogado.');
  }

  // Verifica expiracao (horario de Brasilia)
  if (jaExpirou(storedToken.expires_at)) {
    throw new Error('Refresh token expirado.');
  }

  // Rotação de token: revoga o atual e cria um novo
  await db.query(
    `UPDATE tokens_atualizacao SET revoked_at = NOW() WHERE id = $1`,
    [storedToken.id]
  );

  const new_access_token = gerarAccessToken({
    id: storedToken.user_id,
    company_id: storedToken.company_id,
    full_name: storedToken.full_name,
    email: storedToken.email,
    role: storedToken.role
  });

  const new_refresh_token = gerarRefreshToken();
  const new_refresh_expires_at = calcularExpiracaoRefresh();

  await db.query(
    `INSERT INTO tokens_atualizacao (user_id, token_hash, expires_at) 
     VALUES ($1, $2, $3)`,
    [storedToken.user_id, new_refresh_token, new_refresh_expires_at]
  );

  return {
    access_token: new_access_token,
    refresh_token: new_refresh_token
  };
}

/**
 * Logout (revoga refresh token)
 * @param {string} token 
 */
async function logout(token) {
  if (!token) return;

  await db.query(
    `UPDATE tokens_atualizacao SET revoked_at = NOW() WHERE token_hash = $1`,
    [token]
  );
}

/**
 * Solicita reset de senha
 * @param {string} email 
 */
async function solicitarResetSenha(email) {
  if (!email) {
    throw new Error('Email é obrigatório.');
  }

  const result = await db.query(
    'SELECT id FROM usuarios WHERE email = $1 AND deleted_at IS NULL',
    [email.toLowerCase()]
  );

  if (result.rows.length === 0) {
    return null;
  }

  const user = result.rows[0];
  const reset_token = crypto.randomBytes(32).toString('hex');
  const expires_at = expiracaoEmHoras(1); // 1 hora (horario de Brasilia)

  await db.query(
    `INSERT INTO redefinicao_senhas (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [user.id, reset_token, expires_at]
  );

  return { reset_token };
}

/**
 * Reseta senha usando token
 * @param {string} token 
 * @param {string} nova_senha 
 */
async function resetSenha(token, nova_senha) {
  if (!token || !nova_senha) {
    throw new Error('Token e nova senha são obrigatórios.');
  }

  if (nova_senha.length < 6) {
    throw new Error('Nova senha deve ter no mínimo 6 caracteres.');
  }

  const result = await db.query(
    `SELECT r.*, u.id as user_id 
     FROM redefinicao_senhas r
     JOIN usuarios u ON r.user_id = u.id
     WHERE r.token_hash = $1`,
    [token]
  );

  if (result.rows.length === 0) {
    throw new Error('Token de reset inválido.');
  }

  const tokenData = result.rows[0];

  if (tokenData.used_at) {
    throw new Error('Token de reset já foi utilizado.');
  }

  if (jaExpirou(tokenData.expires_at)) {
    throw new Error('Token de reset expirado.');
  }

  const password_hash = await bcrypt.hash(nova_senha, 10);

  await db.query(
    `UPDATE usuarios SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
    [password_hash, tokenData.user_id]
  );

  await db.query(
    `UPDATE redefinicao_senhas SET used_at = NOW() WHERE id = $1`,
    [tokenData.id]
  );

  // Invalida todos os refresh tokens do usuário
  await db.query(
    `UPDATE tokens_atualizacao SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL`,
    [tokenData.user_id]
  );
}

/**
 * Trocar senha (usuário logado)
 * @param {string} user_id 
 * @param {string} senha_atual 
 * @param {string} nova_senha 
 */
async function trocarSenha(user_id, senha_atual, nova_senha) {
  if (!senha_atual || !nova_senha) {
    throw new Error('Senha atual e nova senha são obrigatórias.');
  }

  if (nova_senha.length < 6) {
    throw new Error('Nova senha deve ter no mínimo 6 caracteres.');
  }

  // Busca usuário
  const result = await db.query(
    `SELECT id, password_hash FROM usuarios WHERE id = $1 AND deleted_at IS NULL`,
    [user_id]
  );

  if (result.rows.length === 0) {
    throw new Error('Usuário não encontrado.');
  }

  const usuario = result.rows[0];

  // Verifica senha atual
  const senhaValida = await bcrypt.compare(senha_atual, usuario.password_hash);
  if (!senhaValida) {
    throw new Error('Senha atual incorreta.');
  }

  // Atualiza senha
  const password_hash = await bcrypt.hash(nova_senha, 10);
  await db.query(
    `UPDATE usuarios SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
    [password_hash, user_id]
  );

  // Invalida todos os refresh tokens (force re-login)
  await db.query(
    `UPDATE tokens_atualizacao SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL`,
    [user_id]
  );
}

/**
 * Cria ou atualiza empresa do usuário
 * @param {string} user_id 
 * @param {object} data - { type: 'CPF'|'CNPJ', document, name }
 * @returns {object} - { company }
 */
async function criarOuAtualizarEmpresa(user_id, data) {
  const { type, document, name } = data || {};

  if (!type || !document || !name) {
    throw new Error('Dados incompletos (type, document, name).');
  }

  const tipoUpper = String(type).toUpperCase();

  // Valida CPF/CNPJ usando utilitário central
  const validacao = validarDocumento(document, tipoUpper);
  if (!validacao.valid) {
    throw new Error(`${tipoUpper} inválido.`);
  }

  const documentoNormalizado = validacao.normalized || normalizarDocumento(document);

  // Busca usuário
  const userResult = await db.query(
    `SELECT id, company_id FROM usuarios WHERE id = $1 AND deleted_at IS NULL`,
    [user_id]
  );

  if (userResult.rows.length === 0) {
    throw new Error('Usuário não encontrado.');
  }

  const user = userResult.rows[0];

  try {
    if (user.company_id) {
      // Atualiza empresa existente
      const result = await db.query(
        `UPDATE empresas 
         SET type = $1, document = $2, name = $3 
         WHERE id = $4 
         RETURNING id, type, document, name, criado_em`,
        [tipoUpper, documentoNormalizado, name, user.company_id]
      );

      return { company: result.rows[0] };
    } else {
      // Cria nova empresa
      const companyResult = await db.query(
        `INSERT INTO empresas (type, document, name) 
         VALUES ($1, $2, $3) 
         RETURNING id, type, document, name, criado_em`,
        [tipoUpper, documentoNormalizado, name]
      );

      const company = companyResult.rows[0];

      // Vincula empresa ao usuário e promove para ADMIN
      await db.query(
        `UPDATE usuarios SET company_id = $1, role = 'ADMIN' WHERE id = $2`,
        [company.id, user_id]
      );

      // Busca usuário atualizado para gerar novo token
      const updatedUserResult = await db.query(
        `SELECT id, company_id, full_name, email, role FROM usuarios WHERE id = $1`,
        [user_id]
      );
      const updatedUser = updatedUserResult.rows[0];
      
      // Gera novo access token com company_id e role atualizados
      const access_token = gerarAccessToken(updatedUser);

      return { company, access_token, role_updated: true };
    }
  } catch (error) {
    // Chave única de documento já cadastrada
    if (error.code === '23505') {
      throw new Error('Este CPF/CNPJ já está cadastrado.');
    }
    throw error;
  }
}

module.exports = {
  registrar,
  login,
  refresh,
  logout,
  solicitarResetSenha,
  resetSenha,
  trocarSenha,
  criarOuAtualizarEmpresa,
  gerarAccessToken
};
