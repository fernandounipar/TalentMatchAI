const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

router.get('/', async (req, res) => {
  try {
  const companyId = req.usuario.company_id;
    const legacy = await db.query(
      `SELECT e.id, e.criado_em, v.titulo AS vaga, c.nome AS candidato,
              EXISTS(SELECT 1 FROM relatorios r2 WHERE r2.entrevista_id = e.id) AS tem_relatorio
         FROM entrevistas e
         JOIN vagas v ON v.id = e.vaga_id
         JOIN candidatos c ON c.id = e.candidato_id
        WHERE e.company_id=$1
        ORDER BY e.criado_em DESC LIMIT 25`,
      [companyId]
    );
    const modern = await db.query(
      `SELECT i.id, i.created_at AS criado_em, j.title AS vaga, cand.full_name AS candidato,
              EXISTS(SELECT 1 FROM interview_reports ir WHERE ir.interview_id = i.id) AS tem_relatorio
         FROM interviews i
         JOIN applications a ON a.id = i.application_id
         JOIN jobs j ON j.id = a.job_id
         JOIN candidates cand ON cand.id = a.candidate_id
        WHERE i.company_id=$1
        ORDER BY i.created_at DESC LIMIT 25`,
      [companyId]
    );
    res.json([...legacy.rows, ...modern.rows].sort((a,b)=> (new Date(b.criado_em)) - (new Date(a.criado_em))));
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;
