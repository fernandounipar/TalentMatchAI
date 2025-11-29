const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

router.get('/:id', async (req, res) => {
  const r = await db.query('SELECT * FROM processos_ingestao WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
  const job = r.rows[0];
  if (!job) return res.status(404).json({ erro: 'Job não encontrado' });
  res.json(job);
});

module.exports = router;
