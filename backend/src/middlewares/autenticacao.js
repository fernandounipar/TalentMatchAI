const jwt = require('jsonwebtoken');
const { setTenant } = require('./tenant');

/**
 * Middleware de autenticação JWT
 * Extrai o token do header Authorization, verifica e injeta dados do usuário no req
 */
function exigirAutenticacao(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  
  if (!token) {
    return res.status(401).json({ erro: 'Token de autenticação não fornecido' });
  }
  
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev');
    
    // Injeta dados do usuário e empresa no request
    req.usuario = {
      id: payload.sub || payload.id,
      email: payload.email,
      nome: payload.nome,
      perfil: payload.perfil || payload.role,
      company_id: payload.company_id
    };
    
    // Injeta tenant para isolamento (RLS se configurado)
    setTenant(req, res, next);
  } catch (e) {
    if (e.name === 'TokenExpiredError') {
      return res.status(401).json({ erro: 'Token expirado' });
    }
    return res.status(401).json({ erro: 'Token inválido' });
  }
}

/**
 * Middleware que exige perfil ADMIN
 */
function exigirAdmin(req, res, next) {
  try {
    const perfil = req.usuario?.perfil || '';
    if (perfil !== 'ADMIN' && perfil !== 'SUPER_ADMIN') {
      return res.status(403).json({ erro: 'Acesso restrito a administradores' });
    }
    return next();
  } catch (e) {
    return res.status(403).json({ erro: 'Acesso restrito a administradores' });
  }
}

/**
 * Middleware que exige uma das roles especificadas
 * @param {...string} roles - Lista de roles permitidas
 * @returns {Function} middleware
 */
function exigirRole(...roles) {
  return (req, res, next) => {
    try {
      const role = req.usuario?.perfil || '';
      if (!roles.includes(role)) {
        return res.status(403).json({ erro: 'Permissão insuficiente' });
      }
      return next();
    } catch (_) {
      return res.status(403).json({ erro: 'Permissão insuficiente' });
    }
  };
}

/**
 * Middleware opcional de autenticação (não bloqueia se não houver token)
 * Útil para rotas públicas que podem ter comportamento diferente se autenticado
 */
function autenticacaoOpcional(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  
  if (!token) {
    return next();
  }
  
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev');
    req.usuario = {
      id: payload.sub || payload.id,
      email: payload.email,
      nome: payload.nome,
      perfil: payload.perfil || payload.role,
      company_id: payload.company_id
    };
  } catch (e) {
    // Ignora erros em autenticação opcional
  }
  
  return next();
}

module.exports = { 
  exigirAutenticacao, 
  exigirAdmin, 
  exigirRole,
  autenticacaoOpcional
};
