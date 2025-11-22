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
           WHERE r.company_id = $1
             AND r.deleted_at IS NULL)                             AS curriculos,

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

/**
 * GET /api/dashboard/resumes/metrics - Métricas detalhadas de currículos (RF1 - David)
 */
router.get('/resumes/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Buscar estatísticas de processamento
    const processingStats = await db.query(
      `SELECT * FROM resume_processing_stats WHERE company_id = $1`,
      [companyId]
    );

    // Buscar estatísticas CRUD dos últimos 30 dias
    const crudStats = await db.query(
      `SELECT * FROM resume_crud_stats 
       WHERE company_id = $1 
         AND date >= CURRENT_DATE - INTERVAL '30 days'
       ORDER BY date DESC`,
      [companyId]
    );

    // Buscar performance de análises
    const analysisPerformance = await db.query(
      `SELECT * FROM resume_analysis_performance WHERE company_id = $1`,
      [companyId]
    );

    // Buscar estatísticas por vaga
    const jobStats = await db.query(
      `SELECT * FROM resume_by_job_stats 
       WHERE company_id = $1 
       ORDER BY total_resumes DESC 
       LIMIT 10`,
      [companyId]
    );

    // Buscar métricas consolidadas usando função
    const consolidatedMetrics = await db.query(
      `SELECT * FROM get_resume_metrics($1)`,
      [companyId]
    );

    res.json({
      processing: processingStats.rows[0] || {},
      crud_stats: crudStats.rows || [],
      analysis_performance: analysisPerformance.rows || [],
      top_jobs: jobStats.rows || [],
      consolidated: consolidatedMetrics.rows.reduce((acc, row) => {
        acc[row.metric_name] = {
          value: parseFloat(row.metric_value),
          unit: row.metric_unit
        };
        return acc;
      }, {})
    });
  } catch (error) {
    console.error('❌ Erro ao buscar métricas de currículos:', error);
    res.status(500).json({ 
      erro: 'Erro ao buscar métricas de currículos', 
      detalhes: error.message 
    });
  }
});

/**
 * GET /api/dashboard/resumes/timeline - Timeline de currículos recebidos
 */
router.get('/resumes/timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const timeline = await db.query(
      `SELECT 
         DATE(created_at) as date,
         COUNT(*) as count,
         COUNT(*) FILTER (WHERE status = 'pending') as pending,
         COUNT(*) FILTER (WHERE status = 'reviewed') as reviewed,
         COUNT(*) FILTER (WHERE status = 'accepted') as accepted,
         COUNT(*) FILTER (WHERE status = 'rejected') as rejected
       FROM resumes
       WHERE company_id = $1 
         AND deleted_at IS NULL
         AND created_at >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'
       GROUP BY DATE(created_at)
       ORDER BY DATE(created_at) ASC`,
      [companyId]
    );

    res.json(timeline.rows);
  } catch (error) {
    console.error('❌ Erro ao buscar timeline de currículos:', error);
    res.status(500).json({ 
      erro: 'Erro ao buscar timeline', 
      detalhes: error.message 
    });
  }
});

module.exports = router;

