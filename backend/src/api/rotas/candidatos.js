const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const dadosMockados = require('../../servicos/dadosMockados');

router.use(exigirAutenticacao);

router.get('/', async (_req, res) => {
  try {
    // Tentar buscar do banco, se falhar, usar dados mockados
    try {
      const r = await db.query(
        `SELECT c.*, 
                (SELECT COUNT(*) FROM curriculos cu WHERE cu.candidato_id = c.id) AS qtd_curriculos,
                (SELECT COUNT(*) FROM entrevistas e WHERE e.candidato_id = c.id) AS qtd_entrevistas
         FROM candidatos c ORDER BY criado_em DESC`);
      res.json(r.rows);
    } catch (dbError) {
      console.log('Usando dados mockados para candidatos:', dbError.message);
      res.json(dadosMockados.candidatos);
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;


