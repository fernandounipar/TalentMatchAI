const express = require('express');
const router = express.Router();
const authService = require('../../servicos/autenticacaoService');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

/**
 * POST /api/user/company
 * Cria ou atualiza a empresa do usuário logado
 * Body: { type: 'CPF'|'CNPJ', document, name }
 * Requer autenticação
 */
router.post('/company', exigirAutenticacao, async (req, res) => {
  try {
    const user_id = req.usuario.id;
    const resultado = await authService.criarOuAtualizarEmpresa(user_id, req.body);
    res.json(resultado);
  } catch (error) {
    console.error('❌ Erro ao criar/atualizar empresa:', error.message);
    res.status(400).json({ erro: error.message });
  }
});

/**
 * GET /api/user/me
 * Retorna dados do usuário logado (incluindo empresa se existir)
 * Requer autenticação
 */
router.get('/me', exigirAutenticacao, async (req, res) => {
  try {
    const user_id = req.usuario.id;
    const db = require('../../config/database');
    
    const result = await db.query(
      `SELECT u.id, u.company_id, u.full_name, u.email, u.role, u.is_active,
              c.tipo as company_type, c.documento as company_document, c.nome as company_name
       FROM users u
       LEFT JOIN companies c ON c.id = u.company_id
       WHERE u.id = $1 AND u.deleted_at IS NULL`,
      [user_id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado' });
    }
    
    const user = result.rows[0];
    
    res.json({
      usuario: {
        id: user.id,
        nome: user.full_name,
        email: user.email,
        perfil: user.role,
        company: user.company_id ? {
          id: user.company_id,
          type: user.company_type,
          document: user.company_document,
          name: user.company_name
        } : null
      }
    });
  } catch (error) {
    console.error('❌ Erro ao buscar usuário:', error.message);
    res.status(500).json({ erro: 'Erro ao buscar dados do usuário' });
  }
});

module.exports = router;
