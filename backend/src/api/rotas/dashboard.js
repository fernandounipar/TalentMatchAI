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

// ============================================================================
// GET /api/dashboard/jobs/metrics - Métricas de vagas
// ============================================================================
router.get('/jobs/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Métricas consolidadas da função SQL
    const metricsResult = await db.query(
      'SELECT * FROM get_job_metrics($1)',
      [companyId]
    );

    // Estatísticas por status
    const statusStats = await db.query(
      `SELECT 
        status,
        COUNT(*)::int as count,
        AVG(
          CASE 
            WHEN published_at IS NOT NULL AND created_at IS NOT NULL
            THEN EXTRACT(epoch FROM (published_at - created_at)) / 86400.0
            ELSE NULL
          END
        )::numeric(10,2) as avg_days_to_publish
      FROM jobs
      WHERE company_id = $1 AND deleted_at IS NULL
      GROUP BY status
      ORDER BY count DESC`,
      [companyId]
    );

    // Top departamentos
    const departmentStats = await db.query(
      `SELECT 
        COALESCE(department, 'Sem departamento') as department,
        COUNT(*)::int as total_jobs,
        COUNT(*) FILTER (WHERE status = 'open')::int as open_jobs,
        AVG(salary_min)::numeric(10,2) as avg_salary_min,
        AVG(salary_max)::numeric(10,2) as avg_salary_max
      FROM jobs
      WHERE company_id = $1 AND deleted_at IS NULL
      GROUP BY department
      ORDER BY total_jobs DESC
      LIMIT 10`,
      [companyId]
    );

    // Performance por período (últimos 6 meses)
    const performanceStats = await db.query(
      `SELECT 
        DATE_TRUNC('month', created_at) as month,
        COUNT(*)::int as jobs_created,
        COUNT(*) FILTER (WHERE published_at IS NOT NULL)::int as jobs_published,
        COUNT(*) FILTER (WHERE closed_at IS NOT NULL)::int as jobs_closed
      FROM jobs
      WHERE company_id = $1 
        AND created_at >= now() - interval '6 months'
      GROUP BY DATE_TRUNC('month', created_at)
      ORDER BY month DESC`,
      [companyId]
    );

    res.json({
      metrics: metricsResult.rows,
      by_status: statusStats.rows,
      by_department: departmentStats.rows,
      performance_by_month: performanceStats.rows
    });
  } catch (e) {
    console.error('Erro ao buscar métricas de vagas:', e);
    res.status(500).json({ erro: 'Falha ao buscar métricas de vagas' });
  }
});

// ============================================================================
// GET /api/dashboard/jobs/timeline - Timeline de vagas criadas
// ============================================================================
router.get('/jobs/timeline', async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const daysNum = Math.min(365, Math.max(1, parseInt(days) || 30));

    const result = await db.query(
      `SELECT 
        DATE(created_at) as date,
        COUNT(*)::int as jobs_created,
        COUNT(*) FILTER (WHERE status = 'draft')::int as draft_count,
        COUNT(*) FILTER (WHERE status = 'open')::int as open_count,
        COUNT(*) FILTER (WHERE published_at IS NOT NULL)::int as published_count
      FROM jobs
      WHERE company_id = $1
        AND created_at >= now() - interval '1 day' * $2
      GROUP BY DATE(created_at)
      ORDER BY date DESC`,
      [req.usuario.company_id, daysNum]
    );

    res.json(result.rows);
  } catch (e) {
    console.error('Erro ao buscar timeline de vagas:', e);
    res.status(500).json({ erro: 'Falha ao buscar timeline' });
  }
});

// ============================================================================
// MÉTRICAS DE QUESTION SETS (RF3)
// ============================================================================

router.get('/question-sets/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Chamar função de métricas
    const metricsResult = await db.query(
      `SELECT * FROM get_question_set_metrics($1)`,
      [companyId]
    );

    // Transformar em objeto
    const metrics = {};
    metricsResult.rows.forEach(row => {
      metrics[row.metric_name] = {
        value: parseFloat(row.metric_value) || 0,
        label: row.metric_label
      };
    });

    // Estatísticas por status
    const byTypeResult = await db.query(
      `SELECT * FROM question_type_distribution WHERE company_id = $1`,
      [companyId]
    );

    // Top question sets mais usados
    const topSetsResult = await db.query(
      `SELECT * FROM question_sets_usage WHERE company_id = $1 ORDER BY times_used DESC LIMIT 5`,
      [companyId]
    );

    res.json({
      success: true,
      data: {
        metrics,
        by_type: byTypeResult.rows,
        top_sets: topSetsResult.rows
      }
    });

  } catch (error) {
    console.error('Erro ao buscar métricas de question sets:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar métricas de conjuntos de perguntas',
      error: error.message
    });
  }
});

// Estatísticas de editing (IA vs Manual)
router.get('/question-sets/editing-stats', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT * FROM question_editing_stats WHERE company_id = $1`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows[0] || {
        ai_generated: 0,
        manual_created: 0,
        ai_edited: 0,
        ai_generated_percentage: 0,
        ai_edited_percentage: 0,
        total_questions: 0
      }
    });

  } catch (error) {
    console.error('Erro ao buscar estatísticas de edição:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar estatísticas de edição',
      error: error.message
    });
  }
});

// Conjuntos por vaga
router.get('/question-sets/by-job', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT * FROM question_sets_by_job WHERE company_id = $1 ORDER BY total_questions DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Erro ao buscar conjuntos por vaga:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar conjuntos por vaga',
      error: error.message
    });
  }
});

module.exports = router;

