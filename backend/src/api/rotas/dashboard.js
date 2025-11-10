const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

router.get('/', async (req, res) => {
  try {
    const [v, c, e] = await Promise.all([
      db.query('SELECT COUNT(*)::int AS total FROM vagas WHERE company_id=$1', [req.usuario.company_id]),
      db.query('SELECT COUNT(*)::int AS total FROM candidatos WHERE company_id=$1', [req.usuario.company_id]),
      db.query('SELECT COUNT(*)::int AS total FROM entrevistas WHERE company_id=$1', [req.usuario.company_id]),
    ]);
    res.json({ 
      vagas: v.rows[0].total, 
      candidatos: c.rows[0].total, 
      entrevistas: e.rows[0].total 
    });
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;

