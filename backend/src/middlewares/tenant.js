const db = require('../config/database');

/**
 * Middleware de isolamento multi-tenant
 * Seta o tenant_id da sessão no PostgreSQL para RLS (Row-Level Security)
 * Também garante que company_id está sempre disponível no request
 */
async function setTenant(req, _res, next) {
  try {
    const companyId = req.usuario?.company_id;
    
    if (!companyId) {
      // Se não há company_id, pode ser um problema de autenticação
      console.warn('⚠️  Usuário autenticado sem company_id:', req.usuario);
    } else {
      // Configura RLS no PostgreSQL (se habilitado)
      await db.query("SELECT set_config('app.tenant_id', $1, true)", [companyId]);
      
      // Adiciona helper para facilitar queries com filtro de tenant
      req.tenant = {
        company_id: companyId,
        // Helper para adicionar WHERE company_id = ?
        filter: () => `company_id = '${companyId}'`
      };
    }
  } catch (err) {
    // Em caso de erro no RLS, continua mas loga
    console.error('❌ Erro ao configurar tenant:', err.message);
  }
  
  return next();
}

/**
 * Middleware que garante que company_id está presente
 * Use após exigirAutenticacao quando a rota PRECISA de tenant
 */
function exigirTenant(req, res, next) {
  const companyId = req.usuario?.company_id;
  
  if (!companyId) {
    return res.status(403).json({ 
      erro: 'Tenant não identificado. Faça login novamente.' 
    });
  }
  
  return next();
}

module.exports = { setTenant, exigirTenant };

