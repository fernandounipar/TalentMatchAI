const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao, exigirRole } = require('../../middlewares/autenticacao');

// Todas as rotas exigem usuário autenticado
router.use(exigirAutenticacao);

/**
 * GET /api/api-keys
 * Lista API Keys do tenant atual
 */
router.get('/', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    if (!companyId) {
      return res.status(400).json({ erro: 'Usuário sem company_id. Cadastre a empresa primeiro.' });
    }

    const r = await db.query(
      `SELECT
         id,
         provider,
         label,
         created_at,
         last_used_at,
         is_active,
         CASE
           WHEN token IS NULL OR token = '' THEN NULL
           WHEN length(token) <= 8 THEN '••••••••'
           ELSE substr(token, 1, 3) || '...' || right(token, 4)
         END AS token_preview
       FROM api_keys
       WHERE company_id = $1 AND is_active = true
       ORDER BY created_at DESC`,
      [companyId]
    );

    return res.json(r.rows);
  } catch (e) {
    console.error('❌ Erro ao listar API Keys:', e.message);
    return res.status(500).json({ erro: 'Falha ao listar API Keys' });
  }
});

/**
 * POST /api/api-keys
 * Cria uma nova API Key para o tenant atual
 * Body: { provider?: 'OPENAI' | string, token: string, label?: string }
 * Restrito a ADMIN / SUPER_ADMIN
 */
router.post('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;

    if (!companyId) {
      return res.status(400).json({ erro: 'Usuário sem company_id. Cadastre a empresa primeiro.' });
    }

    const { provider, token, label } = req.body || {};
    const prov = String(provider || 'OPENAI').toUpperCase();

    if (!token || typeof token !== 'string' || !token.trim()) {
      return res.status(400).json({ erro: 'API Key é obrigatória.' });
    }

    const tok = token.trim();
    const lab = (label && String(label).trim()) || `${prov} Key`;

    const insert = await db.query(
      `INSERT INTO api_keys (company_id, user_id, provider, label, token)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, provider, label, created_at, is_active`,
      [companyId, userId, prov, lab, tok]
    );

    const row = insert.rows[0];
    const preview =
      tok.length <= 8 ? '••••••••' : tok.substring(0, 3) + '...' + tok.substring(tok.length - 4);

    return res.status(201).json({
      id: row.id,
      provider: row.provider,
      label: row.label,
      created_at: row.created_at,
      is_active: row.is_active,
      token_preview: preview
    });
  } catch (e) {
    console.error('❌ Erro ao criar API Key:', e.message);
    return res.status(500).json({ erro: 'Falha ao criar API Key' });
  }
});

/**
 * DELETE /api/api-keys/:id
 * Remove uma API Key do tenant atual
 * Restrito a ADMIN / SUPER_ADMIN
 */
router.delete('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  console.log('🗑️  DELETE /api/api-keys/:id chamado');
  console.log('   ID:', req.params.id);
  console.log('   Usuario:', req.usuario);
  
  try {
    const companyId = req.usuario.company_id;
    const id = req.params.id;

    if (!companyId) {
      console.log('❌ Usuário sem company_id');
      return res.status(400).json({ erro: 'Usuário sem company_id. Cadastre a empresa primeiro.' });
    }

    console.log('   Company ID:', companyId);
    console.log('   Executando UPDATE...');

    const result = await db.query(
      `UPDATE api_keys 
       SET is_active = false, last_used_at = now()
       WHERE id = $1 AND company_id = $2
       RETURNING id`,
      [id, companyId]
    );

    console.log('   Linhas afetadas:', result.rowCount);

    // Mesmo que nenhuma linha seja afetada (já removida ou pertença a outro tenant),
    // retornamos 204 para manter a operação idempotente do ponto de vista da API.
    return res.status(204).send();
  } catch (e) {
    console.error('❌ Erro ao deletar API Key:', e.message);
    return res.status(500).json({ erro: 'Falha ao deletar API Key' });
  }
});

module.exports = router;
