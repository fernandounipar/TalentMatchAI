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

module.exports = { exigirAutenticacao };

