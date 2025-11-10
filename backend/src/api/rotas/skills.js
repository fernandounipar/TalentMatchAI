const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

router.get('/', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT s.id, s.name
         FROM skills s
        WHERE s.company_id = $1
        ORDER BY lower(s.name)`,
      [req.usuario.company_id]
    );
    res.json(r.rows);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao listar skills' });
  }
});

module.exports = router;
