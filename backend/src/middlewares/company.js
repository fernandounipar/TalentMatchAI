/**
 * Middleware para verificar se o usuário tem empresa cadastrada
 * Usar em rotas que exigem empresa (vagas, candidatos, etc)
 */
function exigirEmpresa(req, res, next) {
  if (!req.usuario || !req.usuario.company_id) {
    return res.status(403).json({ 
      erro: 'Empresa não cadastrada. Complete seu perfil em Configurações antes de usar este recurso.',
      code: 'COMPANY_REQUIRED'
    });
  }
  next();
}

module.exports = { exigirEmpresa };
