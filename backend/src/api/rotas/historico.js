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
        `SELECT e.id, e.criado_em, v.titulo AS vaga, c.nome AS candidato,
                EXISTS(SELECT 1 FROM relatorios r2 WHERE r2.entrevista_id = e.id) AS tem_relatorio
         FROM entrevistas e
         JOIN vagas v ON v.id = e.vaga_id
         JOIN candidatos c ON c.id = e.candidato_id
         ORDER BY e.criado_em DESC LIMIT 50`);
      res.json(r.rows);
    } catch (dbError) {
      console.log('Usando dados mockados para histórico:', dbError.message);
      res.json(dadosMockados.historico);
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;

