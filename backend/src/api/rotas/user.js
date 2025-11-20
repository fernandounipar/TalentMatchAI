const express = require('express');
const router = express.Router();
const authService = require('../../servicos/autenticacaoService');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const db = require('../../config/database');

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
    const userId = req.usuario.id;

    const result = await db.query(
      `SELECT 
         u.id,
         u.company_id,
         u.full_name,
         u.email,
         u.role,
         u.is_active,
         u.cargo,
         u.foto_url,
         -- Colunas de companies (schema normalizado em inglês)
         c.id as company_id_db,
         c.type AS company_type,
         c.document AS company_document,
         c.name AS company_name
       FROM users u
       LEFT JOIN companies c ON c.id = u.company_id
       WHERE u.id = $1 AND u.deleted_at IS NULL`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado' });
    }

    const row = result.rows[0];

    const company =
      row.company_id_db && row.company_type && row.company_document
        ? {
            id: row.company_id_db,
            type: row.company_type,
            document: row.company_document,
            name: row.company_name
          }
        : null;

    const user = {
      id: row.id,
      company_id: row.company_id,
      full_name: row.full_name,
      email: row.email,
      role: row.role,
      is_active: row.is_active,
      cargo: row.cargo || null,
      foto_url: row.foto_url || null
    };

    res.json({
      user,
      company,
      // Campo legado para compatibilidade com clientes antigos
      usuario: {
        id: row.id,
        nome: row.full_name,
        email: row.email,
        perfil: row.role,
        cargo: row.cargo,
        foto_url: row.foto_url,
        company
      }
    });
  } catch (error) {
    console.error('❌ Erro ao buscar usuário:', error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ erro: 'Erro ao buscar dados do usuário' });
  }
});

/**
 * PUT /api/user/profile
 * Atualiza dados do perfil do usuário logado
 * Body: { full_name?, cargo? }
 * Requer autenticação
 */
router.put('/profile', exigirAutenticacao, async (req, res) => {
  try {
    const userId = req.usuario.id;
    const { full_name, cargo } = req.body;

    console.log('📝 PUT /api/user/profile - Dados recebidos:', { full_name, cargo, userId });

    // Validar cargo se fornecido (aceita null para remover cargo)
    const cargosValidos = ['Admin', 'Recrutador(a)', 'Gestor(a)', null];
    if (cargo !== undefined && !cargosValidos.includes(cargo)) {
      return res.status(400).json({
        erro: `Cargo inválido. Valores aceitos: ${cargosValidos.filter(c => c !== null).join(', ')} ou null`
      });
    }

    // Construir query dinamicamente
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (full_name !== undefined) {
      updates.push(`full_name = $${paramCount++}`);
      values.push(full_name);
    }

    if (cargo !== undefined) {
      updates.push(`cargo = $${paramCount++}`);
      values.push(cargo);
    }

    if (updates.length === 0) {
      return res.status(400).json({ erro: 'Nenhum campo para atualizar' });
    }

    updates.push(`updated_at = NOW()`);
    values.push(userId);

    const query = `
      UPDATE users 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount} AND deleted_at IS NULL
      RETURNING id, full_name, email, role, cargo, foto_url
    `;

    console.log('📊 Query SQL:', query);
    console.log('📊 Valores:', values);

    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado' });
    }

    console.log('✅ Perfil atualizado:', result.rows[0]);

    res.json({
      mensagem: 'Perfil atualizado com sucesso',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Erro ao atualizar perfil:', error.message);
    res.status(500).json({ erro: 'Erro ao atualizar perfil' });
  }
});

/**
 * POST /api/user/avatar
 * Atualiza URL da foto do usuário logado
 * Body: { foto_url: string }
 * Requer autenticação
 */
router.post('/avatar', exigirAutenticacao, async (req, res) => {
  try {
    const userId = req.usuario.id;
    const { foto_url } = req.body;

    if (!foto_url) {
      return res.status(400).json({ erro: 'foto_url é obrigatório' });
    }

    const result = await db.query(
      `UPDATE users 
       SET foto_url = $1, updated_at = NOW()
       WHERE id = $2 AND deleted_at IS NULL
       RETURNING id, full_name, foto_url`,
      [foto_url, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado' });
    }

    res.json({
      mensagem: 'Foto atualizada com sucesso',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Erro ao atualizar foto:', error.message);
    res.status(500).json({ erro: 'Erro ao atualizar foto' });
  }
});

module.exports = router;
