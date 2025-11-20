const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

// KPIs agregados do dashboard (multi-tenant, domínio novo)
router.get('/', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Contagens principais usando o modelo normalizado
    const r = await db.query(
      `SELECT
         -- Vagas abertas (jobs.status = 'open' e não deletadas)
         (SELECT COUNT(*)::int
            FROM jobs j
           WHERE j.company_id = $1
             AND j.status = 'open'
             AND j.deleted_at IS NULL)                             AS vagas,

         -- Currículos/resumes cadastrados
         (SELECT COUNT(*)::int
            FROM resumes r
           WHERE r.company_id = $1)                                AS curriculos,

         -- Entrevistas criadas nos últimos 30 dias
         (SELECT COUNT(*)::int
            FROM interviews i
           WHERE i.company_id = $1
             AND i.created_at >= now() - interval '30 days')       AS entrevistas,

         -- Relatórios de entrevistas gerados
         (SELECT COUNT(*)::int
            FROM interview_reports ir
           WHERE ir.company_id = $1)                               AS relatorios,

         -- Candidatos ativos (não deletados)
         (SELECT COUNT(*)::int
            FROM candidates c
           WHERE c.company_id = $1
             AND c.deleted_at IS NULL)                             AS candidatos
      `,
      [companyId]
    );

    const row = r.rows[0] || {};

    res.json({
      vagas: row.vagas || 0,
      curriculos: row.curriculos || 0,
      entrevistas: row.entrevistas || 0,
      relatorios: row.relatorios || 0,
      candidatos: row.candidatos || 0,
      // Placeholder para futuros insights; mantido como lista vazia
      // para o frontend exibir mensagem padrão sem usar mocks numéricos.
      tendencias: [],
    });
  } catch (error) {
    res.status(500).json({ erro: error.message || 'Falha ao carregar dashboard' });
  }
});

module.exports = router;

