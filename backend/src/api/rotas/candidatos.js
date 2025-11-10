const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

router.get('/', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT c.*, 
              (SELECT COUNT(*) FROM curriculos cu WHERE cu.candidato_id = c.id) AS qtd_curriculos,
              (SELECT COUNT(*) FROM entrevistas e WHERE e.candidato_id = c.id) AS qtd_entrevistas
       FROM candidatos c WHERE c.company_id=$1 ORDER BY criado_em DESC`,
       [req.usuario.company_id]
    );
    res.json(r.rows);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;

