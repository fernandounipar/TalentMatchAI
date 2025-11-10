const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

// Busca simples por termos em resumes.parsed_text
router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || String(q).trim() === '') return res.json([]);
    const term = `%${String(q).toLowerCase()}%`;
    const r = await db.query(
      `SELECT r.id, r.candidate_id, r.file_id, r.original_filename, r.created_at,
              c.full_name, c.email
         FROM resumes r
         JOIN candidates c ON c.id = r.candidate_id
        WHERE r.company_id=$1 AND lower(r.parsed_text) LIKE $2
        ORDER BY r.created_at DESC LIMIT 50`,
      [req.usuario.company_id, term]
    );
    res.json(r.rows);
  } catch (e) {
    res.status(500).json({ erro: 'Falha na busca' });
  }
});

module.exports = router;
