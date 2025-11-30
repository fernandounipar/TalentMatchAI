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
    const rawRole = payload.role || payload.perfil || '';
    const role = typeof rawRole === 'string' ? rawRole.toLowerCase() : rawRole;

    const userId = payload.sub || payload.id;
    const companyId = payload.company_id || payload.companyId;

    req.usuario = {
      id: userId,
      email: payload.email,
      nome: payload.nome,
      // Mantém compatibilidade com código legado que usa `perfil` em caixa alta
      perfil: (payload.perfil || payload.role || '').toString().toUpperCase(),
      role, // Normalizado em minúsculas para os middlewares de permissão
      company_id: companyId,
      companyId, // Alias para rotas que esperam camelCase
      userId    // Alias para rotas que esperam camelCase
    };
    // Alias legado para rotas que ainda leem req.user
    req.user = req.usuario;
    
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
      console.log('🔐 exigirRole middleware');
      console.log('   Roles permitidas:', roles);
      console.log('   req.usuario:', req.usuario);
      
      const role = req.usuario?.perfil || '';
      console.log('   Role do usuário:', role);
      
      if (!roles.includes(role)) {
        console.log('❌ Permissão negada - role não está na lista');
        return res.status(403).json({ erro: 'Permissão insuficiente' });
      }
      
      console.log('✅ Permissão concedida');
      return next();
    } catch (err) {
      console.error('❌ Erro no middleware exigirRole:', err.message);
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
    const rawRole = payload.role || payload.perfil || '';
    const role = typeof rawRole === 'string' ? rawRole.toLowerCase() : rawRole;
    const userId = payload.sub || payload.id;
    const companyId = payload.company_id || payload.companyId;

    req.usuario = {
      id: userId,
      email: payload.email,
      nome: payload.nome,
      perfil: (payload.perfil || payload.role || '').toString().toUpperCase(),
      role,
      company_id: companyId,
      companyId,
      userId
    };
    req.user = req.usuario;
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
