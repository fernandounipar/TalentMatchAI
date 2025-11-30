const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { agora } = require('../../utils/dateUtils');

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
            FROM vagas j
           WHERE j.company_id = $1
             AND j.status = 'open'
             AND j.deleted_at IS NULL)                             AS vagas,

         -- Currículos/resumes cadastrados
         (SELECT COUNT(*)::int
            FROM curriculos r
           WHERE r.company_id = $1
             AND r.deleted_at IS NULL)                             AS curriculos,

         -- Entrevistas criadas nos últimos 30 dias
         (SELECT COUNT(*)::int
            FROM entrevistas i
           WHERE i.company_id = $1
             AND i.created_at >= now() - interval '30 days')       AS entrevistas,

         -- Relatórios de entrevistas gerados
         (SELECT COUNT(*)::int
            FROM relatorios_entrevista ir
           WHERE ir.company_id = $1)                               AS relatorios,

         -- Candidatos ativos (não deletados)
         (SELECT COUNT(*)::int
            FROM candidatos c
           WHERE c.company_id = $1
             AND c.deleted_at IS NULL)                             AS candidatos
      `,
      [companyId]
    );

    const row = r.rows[0] || {};

    res.json({
      data: {
        vagas: row.vagas || 0,
        curriculos: row.curriculos || 0,
        entrevistas: row.entrevistas || 0,
        relatorios: row.relatorios || 0,
        candidatos: row.candidatos || 0,
        tendencias: [],
      }
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
      `SELECT * FROM estatisticas_processamento_curriculo WHERE company_id = $1`,
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
      COUNT(*) FILTER(WHERE status = 'pending') as pending,
      COUNT(*) FILTER(WHERE status = 'reviewed') as reviewed,
      COUNT(*) FILTER(WHERE status = 'accepted') as accepted,
      COUNT(*) FILTER(WHERE status = 'rejected') as rejected
       FROM curriculos
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
      COUNT(*):: int as count,
      AVG(
        CASE 
            WHEN published_at IS NOT NULL AND created_at IS NOT NULL
            THEN EXTRACT(epoch FROM(published_at - created_at)) / 86400.0
            ELSE NULL
          END
      ):: numeric(10, 2) as avg_days_to_publish
      FROM vagas
      WHERE company_id = $1 AND deleted_at IS NULL
      GROUP BY status
      ORDER BY count DESC`,
      [companyId]
    );

    // Top departamentos
    const departmentStats = await db.query(
      `SELECT 
        COALESCE(department, 'Sem departamento') as department,
      COUNT(*):: int as total_jobs,
      COUNT(*) FILTER(WHERE status = 'open'):: int as open_jobs,
      AVG(salary_min):: numeric(10, 2) as avg_salary_min,
      AVG(salary_max):: numeric(10, 2) as avg_salary_max
      FROM vagas
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
      COUNT(*):: int as jobs_created,
      COUNT(*) FILTER(WHERE published_at IS NOT NULL):: int as jobs_published,
      COUNT(*) FILTER(WHERE closed_at IS NOT NULL):: int as jobs_closed
      FROM vagas
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
      COUNT(*):: int as jobs_created,
      COUNT(*) FILTER(WHERE status = 'draft'):: int as draft_count,
      COUNT(*) FILTER(WHERE status = 'open'):: int as open_count,
      COUNT(*) FILTER(WHERE published_at IS NOT NULL):: int as published_count
      FROM vagas
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

// ============================================================================
// MÉTRICAS DE ASSESSMENTS (RF6)
// ============================================================================

router.get('/assessments/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Chamar função de métricas
    const metricsResult = await db.query(
      `SELECT * FROM get_assessment_metrics($1)`,
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

    // Distribuição por tipo
    const byTypeResult = await db.query(
      `SELECT * FROM assessment_type_distribution WHERE company_id = $1`,
      [companyId]
    );

    // Concordância IA vs Humano
    const concordanceResult = await db.query(
      `SELECT * FROM assessment_concordance_stats WHERE company_id = $1`,
      [companyId]
    );

    res.json({
      success: true,
      data: {
        metrics,
        by_type: byTypeResult.rows,
        concordance: concordanceResult.rows[0] || {
          dual_scored_count: 0,
          avg_score_difference: 0,
          concordance_rate: 0,
          discordance_rate: 0
        }
      }
    });

  } catch (error) {
    console.error('Erro ao buscar métricas de assessments:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar métricas de avaliações',
      error: error.message
    });
  }
});

// Timeline de avaliações
router.get('/assessments/timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT * FROM assessment_performance_timeline 
       WHERE company_id = $1 
       AND assessment_date >= now() - interval '${parseInt(days)} days'
       ORDER BY assessment_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Erro ao buscar timeline de assessments:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline de avaliações',
      error: error.message
    });
  }
});

// Estatísticas por entrevista
router.get('/assessments/by-interview', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT * FROM assessment_by_interview WHERE company_id = $1 ORDER BY interview_date DESC LIMIT 50`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Erro ao buscar assessments por entrevista:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar avaliações por entrevista',
      error: error.message
    });
  }
});

// ============================================
// RF7 - MÉTRICAS DE RELATÓRIOS
// ============================================

/**
 * GET /api/dashboard/reports/metrics
 * Métricas consolidadas de relatórios
 */
router.get('/reports/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Buscar métricas usando a função SQL
    const metricsResult = await db.query(
      `SELECT get_report_metrics($1) as metrics`,
      [companyId]
    );

    const metrics = metricsResult.rows[0].metrics;

    // Buscar distribuição por tipo
    const byTypeResult = await db.query(
      `SELECT * FROM reports_by_type WHERE company_id = $1 ORDER BY report_count DESC`,
      [companyId]
    );

    // Buscar distribuição por recomendação
    const byRecResult = await db.query(
      `SELECT * FROM reports_by_recommendation WHERE company_id = $1 ORDER BY report_count DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: {
        metrics,
        by_type: byTypeResult.rows,
        by_recommendation: byRecResult.rows
      }
    });

  } catch (error) {
    console.error('[RF7] Erro ao buscar métricas de relatórios:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar métricas de relatórios',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/reports/timeline
 * Timeline de geração de relatórios
 */
router.get('/reports/timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT *
    FROM report_generation_timeline 
       WHERE company_id = $1 
         AND generation_date >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'
       ORDER BY generation_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF7] Erro ao buscar timeline de relatórios:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/reports/by-interview
 * Relatórios agrupados por entrevista
 */
router.get('/reports/by-interview', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { limit = 50 } = req.query;

    const result = await db.query(
      `SELECT * FROM reports_by_interview WHERE company_id = $1 ORDER BY last_generated_at DESC LIMIT $2`,
      [companyId, parseInt(limit)]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF7] Erro ao buscar relatórios por entrevista:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar relatórios por entrevista',
      error: error.message
    });
  }
});

// =============================================
// RF8 - INTERVIEW HISTORY ENDPOINTS
// =============================================

/**
 * GET /api/dashboard/interviews/metrics
 * Métricas consolidadas de histórico de entrevistas
 */
router.get('/interviews/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Usar função get_interview_metrics() criada na migration 023
    const metricsResult = await db.query(
      `SELECT get_interview_metrics($1) as metrics`,
      [companyId]
    );

    const metrics = metricsResult.rows[0]?.metrics || {};

    // Buscar distribuição por status da view entrevistas_por_status
    const byStatusResult = await db.query(
      `SELECT status, interview_count, avg_score, avg_duration
       FROM entrevistas_por_status
       WHERE company_id = $1
       ORDER BY interview_count DESC`,
      [companyId]
    );

    // Buscar distribuição por resultado da view entrevistas_por_resultado
    const byResultResult = await db.query(
      `SELECT result, interview_count, avg_score, completed_count
       FROM entrevistas_por_resultado
       WHERE company_id = $1
       ORDER BY interview_count DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: {
        ...metrics,
        by_status: byStatusResult.rows,
        by_result: byResultResult.rows
      }
    });

  } catch (error) {
    console.error('[RF8] Erro ao buscar métricas de entrevistas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar métricas',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/interviews/timeline?days=30
 * Timeline de entrevistas criadas/concluídas/canceladas
 */
router.get('/interviews/timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT 
         interview_date,
      interviews_created,
      scheduled,
      completed,
      cancelled,
      approved,
      rejected,
      avg_score,
      avg_duration
       FROM interview_timeline
       WHERE company_id = $1
         AND interview_date >= current_date - interval '${parseInt(days)} days'
       ORDER BY interview_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF8] Erro ao buscar timeline de entrevistas:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/interviews/by-job?limit=20
 * Entrevistas agrupadas por vaga
 */
router.get('/interviews/by-job', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { limit = 20 } = req.query;

    const result = await db.query(
      `SELECT 
         job_id,
      job_title,
      total_interviews,
      completed_interviews,
      approved_count,
      rejected_count,
      avg_score,
      last_interview_date
       FROM interviews_by_job
       WHERE company_id = $1
       ORDER BY total_interviews DESC
       LIMIT $2`,
      [companyId, parseInt(limit)]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF8] Erro ao buscar entrevistas por vaga:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar entrevistas por vaga',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/interviews/by-interviewer?limit=20
 * Entrevistas agrupadas por entrevistador
 */
router.get('/interviews/by-interviewer', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { limit = 20 } = req.query;

    const result = await db.query(
      `SELECT 
         interviewer_id,
      interviewer_name,
      total_interviews,
      completed_count,
      approved_count,
      avg_score,
      avg_duration
       FROM interviews_by_interviewer
       WHERE company_id = $1
       ORDER BY total_interviews DESC
       LIMIT $2`,
      [companyId, parseInt(limit)]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF8] Erro ao buscar entrevistas por entrevistador:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar entrevistas por entrevistador',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/interviews/completion-rate?days=30
 * Taxa de conclusão de entrevistas ao longo do tempo
 */
router.get('/interviews/completion-rate', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT 
         scheduled_date,
      total_scheduled,
      completed,
      cancelled,
      no_show,
      completion_rate,
      no_show_rate
       FROM interview_completion_rate
       WHERE company_id = $1
         AND scheduled_date >= current_date - interval '${parseInt(days)} days'
       ORDER BY scheduled_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF8] Erro ao buscar taxa de conclusão:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar taxa de conclusão',
      error: error.message
    });
  }
});

// ============================================================================
// RF10 - USER MANAGEMENT DASHBOARD ENDPOINTS
// ============================================================================

/**
 * GET /api/dashboard/users/metrics
 * Métricas consolidadas de usuários
 * Retorna: 17 KPIs incluindo counts, activity, rates
 */
router.get('/users/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      'SELECT get_user_metrics($1) as metrics',
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows[0].metrics
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar métricas de usuários:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar métricas de usuários',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/users/by-role
 * Distribuição de usuários por role
 */
router.get('/users/by-role', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT
         role,
      user_count,
      active_count,
      verified_count,
      most_recent_login
       FROM users_by_role
       WHERE company_id = $1
       ORDER BY 
         CASE role
           WHEN 'SUPER_ADMIN' THEN 1
           WHEN 'ADMIN' THEN 2
           WHEN 'RECRUITER' THEN 3
           WHEN 'USER' THEN 4
           ELSE 5
         END`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar usuários por role:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar usuários por role',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/users/by-department
 * Distribuição de usuários por departamento
 */
router.get('/users/by-department', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT
         department,
      user_count,
      active_count
       FROM users_by_department
       WHERE company_id = $1
       ORDER BY user_count DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar usuários por departamento:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar usuários por departamento',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/users/login-timeline?days=30
 * Timeline de atividade de login
 */
router.get('/users/login-timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT
         login_date,
      unique_users_logged,
      total_logins
       FROM user_login_timeline
       WHERE company_id = $1
         AND login_date >= current_date - interval '${parseInt(days)} days'
       ORDER BY login_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar timeline de login:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline de login',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/users/registration-timeline?days=90
 * Timeline de novos registros
 */
router.get('/users/registration-timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 90 } = req.query;

    const result = await db.query(
      `SELECT
         registration_date,
      users_registered,
      active_registered,
      verified_registered
       FROM user_registration_timeline
       WHERE company_id = $1
         AND registration_date >= current_date - interval '${parseInt(days)} days'
       ORDER BY registration_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar timeline de registro:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline de registro',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/users/security-stats
 * Estatísticas de segurança (failed attempts, locked accounts, etc)
 */
router.get('/users/security-stats', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT
         total_users,
      users_with_failed_attempts,
      currently_locked,
      avg_failed_attempts,
      max_failed_attempts,
      unverified_emails,
      unverified_percentage
       FROM user_security_stats
       WHERE company_id = $1`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows[0] || {
        total_users: 0,
        users_with_failed_attempts: 0,
        currently_locked: 0,
        avg_failed_attempts: 0,
        max_failed_attempts: 0,
        unverified_emails: 0,
        unverified_percentage: 0
      }
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar estatísticas de segurança:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar estatísticas de segurança',
      error: error.message
    });
  }
});

/**
 * GET /api/dashboard/users/invitation-stats
 * Estatísticas de convites (pending, expired, accepted)
 */
router.get('/users/invitation-stats', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT
         total_invitations,
      pending_invitations,
      expired_invitations,
      accepted_invitations
       FROM user_invitation_stats
       WHERE company_id = $1`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows[0] || {
        total_invitations: 0,
        pending_invitations: 0,
        expired_invitations: 0,
        accepted_invitations: 0
      }
    });

  } catch (error) {
    console.error('[RF10] Erro ao buscar estatísticas de convites:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar estatísticas de convites',
      error: error.message
    });
  }
});

// ============================================================================
// RF9 - Dashboard Overview Consolidado
// ============================================================================

// GET /api/dashboard/overview - Overview consolidado (26+ métricas)
router.get('/overview', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      `SELECT get_dashboard_overview($1) as overview`,
      [companyId]
    );

    const overview = result.rows[0]?.overview || {};

    res.json({
      success: true,
      data: overview
    });

  } catch (error) {
    console.error('[RF9] Erro ao buscar overview consolidado:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar overview consolidado',
      error: error.message
    });
  }
});

// GET /api/dashboard/activity-timeline - Timeline de atividades
router.get('/activity-timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT 
        activity_date,
      jobs_created,
      resumes_uploaded,
      interviews_scheduled,
      reports_generated,
      users_registered,
      total_activities
       FROM dashboard_activity_timeline
       WHERE company_id = $1
         AND activity_date >= CURRENT_DATE - INTERVAL '1 day' * $2
       ORDER BY activity_date DESC`,
      [companyId, parseInt(days)]
    );

    res.json({
      success: true,
      data: result.rows,
      period: {
        days: parseInt(days),
        from: result.rows[result.rows.length - 1]?.activity_date,
        to: result.rows[0]?.activity_date
      }
    });

  } catch (error) {
    console.error('[RF9] Erro ao buscar timeline de atividades:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline de atividades',
      error: error.message
    });
  }
});

// GET /api/dashboard/conversion-funnel - Funil de conversão
router.get('/conversion-funnel', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const {
      status,
      limit = 20,
      sort = 'resume_to_interview_rate',
      order = 'DESC'
    } = req.query;

    let whereClauses = ['company_id = $1'];
    let params = [companyId];
    let paramIndex = 2;

    if (status) {
      whereClauses.push(`job_status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    const whereClause = whereClauses.join(' AND ');

    // Validar sort
    const allowedSorts = [
      'total_resumes',
      'total_interviews',
      'approved_candidates',
      'resume_to_interview_rate',
      'interview_to_approval_rate'
    ];
    const sortColumn = allowedSorts.includes(sort) ? sort : 'resume_to_interview_rate';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    const result = await db.query(
      `SELECT 
        job_id,
      job_title,
      job_status,
      job_created_at,
      total_resumes,
      total_interviews,
      completed_interviews,
      approved_candidates,
      resume_to_interview_rate,
      interview_to_approval_rate
       FROM dashboard_conversion_funnel
       WHERE ${whereClause}
       ORDER BY ${sortColumn} ${sortOrder}
       LIMIT $${paramIndex}`,
      [...params, parseInt(limit)]
    );

    // Calcular agregados gerais
    const statsResult = await db.query(
      `SELECT 
        COUNT(*):: int as total_jobs,
      SUM(total_resumes):: int as total_resumes,
      SUM(total_interviews):: int as total_interviews,
      SUM(approved_candidates):: int as total_approved,
      ROUND(AVG(resume_to_interview_rate), 2) as avg_resume_to_interview_rate,
      ROUND(AVG(interview_to_approval_rate), 2) as avg_interview_to_approval_rate
       FROM dashboard_conversion_funnel
       WHERE ${whereClause}`,
      params
    );

    res.json({
      success: true,
      data: result.rows,
      stats: statsResult.rows[0] || {}
    });

  } catch (error) {
    console.error('[RF9] Erro ao buscar funil de conversão:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar funil de conversão',
      error: error.message
    });
  }
});

// ============================================================================
// RF9 - Dashboard Presets (CRUD de configurações salvas)
// ============================================================================

// POST /api/dashboard/presets - Criar novo preset
router.post('/presets', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;
    const {
      name,
      description,
      filters,
      layout,
      preferences,
      is_default,
      is_shared,
      shared_with_roles
    } = req.body;

    // Validações básicas
    if (!name || name.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nome do preset é obrigatório'
      });
    }

    // Se marcar como default, desmarcar outros defaults do usuário
    if (is_default) {
      await db.query(
        `UPDATE presets_dashboard 
         SET is_default = FALSE 
         WHERE user_id = $1 AND company_id = $2 AND deleted_at IS NULL`,
        [userId, companyId]
      );
    }

    const result = await db.query(
      `INSERT INTO presets_dashboard(
        user_id, company_id, name, description,
        filters, layout, preferences,
        is_default, is_shared, shared_with_roles
      ) VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING * `,
      [
        userId,
        companyId,
        name.trim(),
        description || null,
        filters || {},
        layout || {},
        preferences || {},
        is_default || false,
        is_shared || false,
        shared_with_roles || []
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Preset criado com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF9] Erro ao criar preset:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar preset',
      error: error.message
    });
  }
});

// GET /api/dashboard/presets - Listar presets do usuário
router.get('/presets', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;
    const userRole = req.usuario.role;

    const {
      search,
      is_shared,
      is_default,
      sort = 'usage_count',
      order = 'DESC',
      page = 1,
      limit = 20
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const maxLimit = Math.min(parseInt(limit), 100);

    // Construir query dinamicamente
    let whereClauses = ['dp.deleted_at IS NULL', 'dp.company_id = $1'];
    let params = [companyId];
    let paramIndex = 2;

    // Filtro: presets próprios OU compartilhados com seu role
    whereClauses.push(`(dp.user_id = $${paramIndex} OR(dp.is_shared = TRUE AND $${paramIndex + 1} = ANY(dp.shared_with_roles)))`);
    params.push(userId, userRole);
    paramIndex += 2;

    if (search) {
      whereClauses.push(`(dp.name ILIKE $${paramIndex} OR dp.description ILIKE $${paramIndex})`);
      params.push(`% ${search}% `);
      paramIndex++;
    }

    if (is_shared !== undefined) {
      whereClauses.push(`dp.is_shared = $${paramIndex} `);
      params.push(is_shared === 'true');
      paramIndex++;
    }

    if (is_default !== undefined) {
      whereClauses.push(`dp.is_default = $${paramIndex} `);
      params.push(is_default === 'true');
      paramIndex++;
    }

    const whereClause = whereClauses.join(' AND ');

    // Validar sort
    const allowedSorts = ['usage_count', 'last_used_at', 'created_at', 'name'];
    const sortColumn = allowedSorts.includes(sort) ? sort : 'usage_count';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Query principal
    const result = await db.query(
      `SELECT
dp.id,
  dp.user_id,
  dp.company_id,
  dp.name,
  dp.description,
  dp.filters,
  dp.layout,
  dp.preferences,
  dp.is_default,
  dp.is_shared,
  dp.shared_with_roles,
  dp.usage_count,
  dp.last_used_at,
  dp.created_at,
  dp.updated_at,
  u.nome as user_name,
  c.name as company_name
       FROM presets_dashboard dp
       LEFT JOIN usuarios u ON u.id = dp.user_id
       LEFT JOIN empresas c ON c.id = dp.company_id
       WHERE ${whereClause}
       ORDER BY dp.${sortColumn} ${sortOrder}
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1} `,
      [...params, maxLimit, offset]
    );

    // Contar total
    const countResult = await db.query(
      `SELECT COUNT(*):: int as total
       FROM presets_dashboard dp
       WHERE ${whereClause} `,
      params
    );

    const total = countResult.rows[0]?.total || 0;

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: maxLimit,
        total,
        totalPages: Math.ceil(total / maxLimit)
      }
    });

  } catch (error) {
    console.error('[RF9] Erro ao listar presets:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao listar presets',
      error: error.message
    });
  }
});

// GET /api/dashboard/presets/:id - Buscar preset específico
router.get('/presets/:id', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;
    const userRole = req.usuario.role;
    const { id } = req.params;

    const result = await db.query(
      `SELECT
dp.*,
  u.nome as user_name,
  c.name as company_name
       FROM presets_dashboard dp
       LEFT JOIN usuarios u ON u.id = dp.user_id
       LEFT JOIN empresas c ON c.id = dp.company_id
       WHERE dp.id = $1 
         AND dp.company_id = $2
         AND dp.deleted_at IS NULL
AND(dp.user_id = $3 OR(dp.is_shared = TRUE AND $4 = ANY(dp.shared_with_roles)))`,
      [id, companyId, userId, userRole]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Preset não encontrado'
      });
    }

    // Incrementar usage_count e atualizar last_used_at
    await db.query(
      `UPDATE presets_dashboard 
       SET usage_count = usage_count + 1,
  last_used_at = NOW()
       WHERE id = $1`,
      [id]
    );

    const preset = result.rows[0];
    preset.usage_count = (preset.usage_count || 0) + 1;
    preset.last_used_at = agora(); // Horario de Brasilia

    res.json({
      success: true,
      data: preset
    });

  } catch (error) {
    console.error('[RF9] Erro ao buscar preset:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar preset',
      error: error.message
    });
  }
});

// PUT /api/dashboard/presets/:id - Atualizar preset
router.put('/presets/:id', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;
    const { id } = req.params;
    const {
      name,
      description,
      filters,
      layout,
      preferences,
      is_default,
      is_shared,
      shared_with_roles
    } = req.body;

    // Verificar se preset existe e pertence ao usuário
    const checkResult = await db.query(
      `SELECT * FROM presets_dashboard 
       WHERE id = $1 AND company_id = $2 AND user_id = $3 AND deleted_at IS NULL`,
      [id, companyId, userId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Preset não encontrado ou você não tem permissão para editá-lo'
      });
    }

    // Se marcar como default, desmarcar outros defaults do usuário
    if (is_default) {
      await db.query(
        `UPDATE presets_dashboard 
         SET is_default = FALSE 
         WHERE user_id = $1 AND company_id = $2 AND id != $3 AND deleted_at IS NULL`,
        [userId, companyId, id]
      );
    }

    // Construir update dinâmico
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex} `);
      values.push(name.trim());
      paramIndex++;
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex} `);
      values.push(description);
      paramIndex++;
    }
    if (filters !== undefined) {
      updates.push(`filters = $${paramIndex} `);
      values.push(filters);
      paramIndex++;
    }
    if (layout !== undefined) {
      updates.push(`layout = $${paramIndex} `);
      values.push(layout);
      paramIndex++;
    }
    if (preferences !== undefined) {
      updates.push(`preferences = $${paramIndex} `);
      values.push(preferences);
      paramIndex++;
    }
    if (is_default !== undefined) {
      updates.push(`is_default = $${paramIndex} `);
      values.push(is_default);
      paramIndex++;
    }
    if (is_shared !== undefined) {
      updates.push(`is_shared = $${paramIndex} `);
      values.push(is_shared);
      paramIndex++;
    }
    if (shared_with_roles !== undefined) {
      updates.push(`shared_with_roles = $${paramIndex} `);
      values.push(shared_with_roles);
      paramIndex++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nenhum campo para atualizar'
      });
    }

    values.push(id);
    const result = await db.query(
      `UPDATE presets_dashboard 
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
RETURNING * `,
      values
    );

    res.json({
      success: true,
      message: 'Preset atualizado com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF9] Erro ao atualizar preset:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar preset',
      error: error.message
    });
  }
});

// DELETE /api/dashboard/presets/:id - Deletar preset (soft delete)
router.delete('/presets/:id', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;
    const { id } = req.params;

    const result = await db.query(
      `UPDATE presets_dashboard 
       SET deleted_at = NOW()
       WHERE id = $1 AND company_id = $2 AND user_id = $3 AND deleted_at IS NULL
       RETURNING id, name`,
      [id, companyId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Preset não encontrado ou você não tem permissão para deletá-lo'
      });
    }

    res.json({
      success: true,
      message: 'Preset deletado com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF9] Erro ao deletar preset:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao deletar preset',
      error: error.message
    });
  }
});

// ============================================================================
// RF4 - GitHub Integration Endpoints
// ============================================================================

// GET /api/dashboard/github/metrics - Métricas consolidadas de GitHub
router.get('/github/metrics', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    const result = await db.query(
      'SELECT get_github_metrics($1) as metrics',
      [companyId]
    );

    const metrics = result.rows[0]?.metrics || {
      stats: {},
      top_languages: [],
      top_candidates: [],
      recent_success_rate: null
    };

    res.json({
      success: true,
      data: metrics
    });

  } catch (error) {
    console.error('[RF4] Erro ao buscar métricas GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar métricas GitHub',
      error: error.message
    });
  }
});

// GET /api/dashboard/github/sync-timeline - Timeline de sincronizações
router.get('/github/sync-timeline', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { days = 30 } = req.query;

    const result = await db.query(
      `SELECT * FROM github_sync_timeline
       WHERE company_id = $1 
       AND sync_date >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'
       ORDER BY sync_date DESC`,
      [companyId]
    );

    res.json({
      success: true,
      data: result.rows,
      period: {
        days: parseInt(days),
        from: result.rows[result.rows.length - 1]?.sync_date,
        to: result.rows[0]?.sync_date
      }
    });

  } catch (error) {
    console.error('[RF4] Erro ao buscar timeline GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar timeline de sincronizações GitHub',
      error: error.message
    });
  }
});

// GET /api/dashboard/github/top-languages - Top linguagens mais usadas
router.get('/github/top-languages', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { limit = 10 } = req.query;

    const result = await db.query(
      `SELECT * FROM github_top_languages
       WHERE company_id = $1
       ORDER BY developers_count DESC, avg_percentage DESC
       LIMIT $2`,
      [companyId, parseInt(limit)]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF4] Erro ao buscar top languages GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar linguagens mais usadas',
      error: error.message
    });
  }
});

// GET /api/dashboard/github/top-candidates - Top candidatos por popularidade
router.get('/github/top-candidates', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { limit = 10 } = req.query;

    const result = await db.query(
      `SELECT * FROM github_top_candidates
       WHERE company_id = $1
       ORDER BY popularity_rank
       LIMIT $2`,
      [companyId, parseInt(limit)]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF4] Erro ao buscar top candidates GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar candidatos mais populares',
      error: error.message
    });
  }
});

// GET /api/dashboard/github/skills-distribution - Distribuição de skills
router.get('/github/skills-distribution', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { limit = 20 } = req.query;

    const result = await db.query(
      `SELECT * FROM github_skills_distribution
       WHERE company_id = $1
       ORDER BY candidates_count DESC
       LIMIT $2`,
      [companyId, parseInt(limit)]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('[RF4] Erro ao buscar skills distribution GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar distribuição de skills',
      error: error.message
    });
  }
});

module.exports = router;
