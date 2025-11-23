/**
 * Middleware de Permissões - TalentMatchIA
 * 
 * Controla o acesso baseado em roles (papéis) dos usuários.
 * Integrado com o sistema de autenticação JWT.
 * 
 * Roles disponíveis:
 * - admin: Acesso total ao sistema
 * - recruiter: Gerencia vagas e conduz entrevistas
 * - interviewer: Apenas conduz entrevistas
 * - viewer: Apenas visualiza informações
 */

/**
 * Verifica se o usuário tem permissão para acessar o recurso
 * @param {Array<string>} rolesPermitidas - Lista de roles que podem acessar
 * @returns {Function} Middleware Express
 */
function verificarPermissao(rolesPermitidas = []) {
  return (req, res, next) => {
    try {
      // O middleware de autenticação já injetou req.usuario
      if (!req.usuario) {
        return res.status(401).json({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Autenticação necessária'
          }
        });
      }

      const { role } = req.usuario;

      // Admin tem acesso total
      if (role === 'admin') {
        return next();
      }

      // Verifica se o role do usuário está na lista de permitidos
      if (rolesPermitidas.length === 0 || rolesPermitidas.includes(role)) {
        return next();
      }

      // Usuário não tem permissão
      return res.status(403).json({
        error: {
          code: 'FORBIDDEN',
          message: 'Você não tem permissão para acessar este recurso'
        }
      });

    } catch (error) {
      console.error('Erro no middleware de permissões:', error);
      return res.status(500).json({
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Erro ao verificar permissões'
        }
      });
    }
  };
}

/**
 * Verifica se o usuário é proprietário do recurso ou admin
 * @param {Function} getResourceOwner - Função que retorna o ID do proprietário
 * @returns {Function} Middleware Express
 */
function verificarProprietario(getResourceOwner) {
  return async (req, res, next) => {
    try {
      if (!req.usuario) {
        return res.status(401).json({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Autenticação necessária'
          }
        });
      }

      // Admin pode acessar tudo
      if (req.usuario.role === 'admin') {
        return next();
      }

      // Obtém o ID do proprietário do recurso
      const ownerId = await getResourceOwner(req);

      // Verifica se o usuário é o proprietário
      if (req.usuario.id === ownerId) {
        return next();
      }

      return res.status(403).json({
        error: {
          code: 'FORBIDDEN',
          message: 'Você não tem permissão para acessar este recurso'
        }
      });

    } catch (error) {
      console.error('Erro ao verificar proprietário:', error);
      return res.status(500).json({
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Erro ao verificar permissões'
        }
      });
    }
  };
}

/**
 * Middleware que garante que apenas admin pode acessar
 */
const apenasAdmin = verificarPermissao(['admin']);

/**
 * Middleware que garante que apenas admin e recruiter podem acessar
 */
const apenasRecrutadores = verificarPermissao(['admin', 'recruiter']);

/**
 * Middleware que garante que admin, recruiter e interviewer podem acessar
 */
const apenasEntrevistadores = verificarPermissao(['admin', 'recruiter', 'interviewer']);

module.exports = {
  verificarPermissao,
  verificarProprietario,
  apenasAdmin,
  apenasRecrutadores,
  apenasEntrevistadores
};
