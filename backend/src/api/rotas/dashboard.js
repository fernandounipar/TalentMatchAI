const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const dadosMockados = require('../../servicos/dadosMockados');

router.use(exigirAutenticacao);

router.get('/', async (req, res) => {
  try {
    // Tentar buscar do banco, se falhar, usar dados mockados
    try {
      const [v, c, e] = await Promise.all([
        db.query('SELECT COUNT(*)::int AS total FROM vagas WHERE company_id=$1', [req.usuario.companyId]),
        db.query('SELECT COUNT(*)::int AS total FROM candidatos WHERE company_id=$1', [req.usuario.companyId]),
        db.query('SELECT COUNT(*)::int AS total FROM entrevistas WHERE company_id=$1', [req.usuario.companyId]),
      ]);
      res.json({ 
        vagas: v.rows[0].total, 
        candidatos: c.rows[0].total, 
        entrevistas: e.rows[0].total 
      });
    } catch (dbError) {
      console.log('Usando dados mockados para dashboard:', dbError.message);
      res.json(dadosMockados.dashboard);
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;

