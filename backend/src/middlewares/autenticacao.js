const jwt = require('jsonwebtoken');

function exigirAutenticacao(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ erro: 'Não autenticado' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev');
    req.usuario = payload;
    next();
  } catch (e) {
    return res.status(401).json({ erro: 'Token inválido' });
  }
}

function exigirAdmin(req, res, next) {
  try {
    const perfil = req.usuario?.perfil || '';
    if (perfil !== 'ADMIN') return res.status(403).json({ erro: 'Acesso restrito a administradores' });
    return next();
  } catch (e) {
    return res.status(403).json({ erro: 'Acesso restrito a administradores' });
  }
}

function exigirRole(...roles) {
  return (req, res, next) => {
    try {
      const role = req.usuario?.perfil || '';
      if (!roles.includes(role)) return res.status(403).json({ erro: 'Permissão insuficiente' });
      return next();
    } catch (_) {
      return res.status(403).json({ erro: 'Permissão insuficiente' });
    }
  };
}

module.exports = { exigirAutenticacao, exigirAdmin, exigirRole };
