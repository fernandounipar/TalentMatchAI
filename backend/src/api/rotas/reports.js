/**
 * RF7 - Relatórios Detalhados de Entrevistas
 * CRUD completo de relatórios de entrevista
 */

const express = require('express');
const router = express.Router();
const { Pool } = require('pg');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { verificarPermissao } = require('../../middlewares/permissoes');
const { gerarRelatorioEntrevista } = require('../../servicos/iaService');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'talentmatch',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD
});

/**
 * POST /api/reports
 * Criar novo relatório (gerar via IA ou manual)
 */
router.post('/', exigirAutenticacao, verificarPermissao(['recruiter', 'admin']), async (req, res) => {
  const client = await pool.connect();

  try {
    const { companyId, userId } = req.usuario || {};
    const {
      interview_id,
      title,
      report_type = 'full', // full, summary, technical, behavioral
      format = 'json', // json, pdf, html, markdown
      generate_via_ai = true,
      is_final = false,
      // Dados para geração manual (se generate_via_ai = false)
      summary_text,
      candidate_name,
      job_title,
      overall_score,
      recommendation,
      strengths,
      weaknesses,
      risks,
      content
    } = req.body;

    if (!interview_id) {
      return res.status(400).json({
        success: false,
        message: 'interview_id é obrigatório'
      });
    }

    // Verificar se entrevista existe e pertence à company
    const interviewCheck = await client.query(`
      SELECT i.id, i.company_id, 
             c.full_name as candidate_name,
             j.title as job_title
      FROM entrevistas i
      LEFT JOIN candidaturas app ON i.application_id = app.id
      LEFT JOIN candidatos c ON app.candidate_id = c.id
      LEFT JOIN vagas j ON app.job_id = j.id
      WHERE i.id = $1 AND i.company_id = $2 AND i.deleted_at IS NULL
    `, [interview_id, companyId]);

    if (interviewCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Entrevista não encontrada'
      });
    }

    const interview = interviewCheck.rows[0];
    let reportContent = content || {};
    let reportSummary = summary_text;
    let reportScore = overall_score;
    let reportRecommendation = recommendation;
    let reportStrengths = strengths || [];
    let reportWeaknesses = weaknesses || [];
    let reportRisks = risks || [];

    // Gerar relatório via IA se solicitado
    if (generate_via_ai) {
      console.log(`[RF7] Gerando relatório via IA para entrevista ${interview_id}`);

      // Buscar respostas e avaliações da entrevista
      const answersQuery = await client.query(`
        SELECT 
          q.text as question_text,
          q.kind as question_type,
          a.raw_text as answer_text,
          la.score_final,
          la.feedback_auto,
          la.feedback_manual
        FROM respostas_entrevista a
        JOIN perguntas_entrevista q ON a.question_id = q.id
        LEFT JOIN avaliacoes_tempo_real la ON la.question_id = q.id AND la.interview_id = $1
        WHERE q.interview_id = $1
        ORDER BY a.created_at
      `, [interview_id]);

      const respostas = answersQuery.rows.map(r => ({
        pergunta: r.question_text,
        tipo: r.question_type,
        resposta: r.answer_text,
        score: r.score_final
      }));

      const feedbacks = answersQuery.rows
        .filter(r => r.feedback_auto || r.feedback_manual)
        .map(r => {
          const autoFeedback = r.feedback_auto || {};
          return {
            topic: r.question_type,
            score: r.score_final || autoFeedback.nota || 0,
            verdict: r.score_final >= 8 ? 'FORTE' : (r.score_final >= 6 ? 'OK' : 'FRACO'),
            comment: r.feedback_manual || autoFeedback.feedback || ''
          };
        });

      try {
        const aiReport = await gerarRelatorioEntrevista({
          candidato: interview.candidate_name || 'Candidato',
          vaga: interview.job_title || 'Vaga',
          respostas,
          feedbacks,
          companyId
        });

        reportContent = aiReport;
        reportSummary = aiReport.summary_text || reportSummary;
        reportStrengths = aiReport.strengths || reportStrengths;
        reportRisks = aiReport.risks || reportRisks;

        // Converter recomendação antiga para nova
        const oldToNew = {
          'APROVAR': 'APPROVE',
          'DÚVIDA': 'MAYBE',
          'REPROVAR': 'REJECT'
        };
        reportRecommendation = oldToNew[aiReport.recommendation] || 'PENDING';

        // Calcular score médio se não fornecido
        if (!reportScore && feedbacks.length > 0) {
          reportScore = feedbacks.reduce((acc, f) => acc + f.score, 0) / feedbacks.length;
        }

      } catch (aiError) {
        console.error('[RF7] Erro ao gerar relatório via IA:', aiError);
        // Continuar com dados manuais/defaults
      }
    }

    // Incrementar versão se já existir relatório para esta entrevista
    const versionQuery = await client.query(`
      SELECT COALESCE(MAX(version), 0) + 1 as next_version
      FROM relatorios_entrevista
      WHERE interview_id = $1 AND company_id = $2
    `, [interview_id, companyId]);

    const version = versionQuery.rows[0].next_version;

    // Inserir relatório
    const insertQuery = `
      INSERT INTO relatorios_entrevista (
        company_id,
        interview_id,
        title,
        report_type,
        content,
        summary_text,
        candidate_name,
        job_title,
        overall_score,
        recommendation,
        strengths,
        weaknesses,
        risks,
        format,
        generated_by,
        generated_at,
        is_final,
        version,
        created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, now(), $16, $17, $18)
      RETURNING id, created_at
    `;

    const result = await client.query(insertQuery, [
      companyId,
      interview_id,
      title || `Relatório de Entrevista v${version}`,
      report_type,
      JSON.stringify(reportContent),
      reportSummary,
      interview.candidate_name,
      interview.job_title,
      reportScore,
      reportRecommendation,
      JSON.stringify(reportStrengths),
      JSON.stringify(reportWeaknesses),
      JSON.stringify(reportRisks),
      format,
      userId,
      is_final,
      version,
      userId
    ]);

    console.log(`[RF7] Relatório ${result.rows[0].id} criado para entrevista ${interview_id}`);

    res.status(201).json({
      success: true,
      message: 'Relatório criado com sucesso',
      data: {
        id: result.rows[0].id,
        interview_id,
        version,
        title: title || `Relatório de Entrevista v${version}`,
        report_type,
        format,
        generated_via_ai: generate_via_ai,
        is_final,
        created_at: result.rows[0].created_at
      }
    });

  } catch (error) {
    console.error('[RF7] Erro ao criar relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar relatório',
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * GET /api/reports
 * Listar relatórios com filtros
 */
router.get('/', exigirAutenticacao, verificarPermissao(['recruiter', 'admin']), async (req, res) => {
  try {
    const { companyId } = req.usuario || {};
    const {
      interview_id,
      report_type,
      recommendation,
      is_final,
      format,
      date_from,
      date_to,
      search,
      sort_by = 'created_at',
      order = 'DESC',
      page = 1,
      limit = 20
    } = req.query;

    const pageNum = parseInt(page);
    const limitNum = Math.min(parseInt(limit), 100);
    const offset = (pageNum - 1) * limitNum;

    let whereConditions = ['company_id = $1', 'deleted_at IS NULL'];
    let params = [companyId];
    let paramCount = 1;

    if (interview_id) {
      paramCount++;
      whereConditions.push(`interview_id = $${paramCount}`);
      params.push(interview_id);
    }

    if (report_type) {
      paramCount++;
      whereConditions.push(`report_type = $${paramCount}`);
      params.push(report_type);
    }

    if (recommendation) {
      paramCount++;
      whereConditions.push(`recommendation = $${paramCount}`);
      params.push(recommendation);
    }

    if (is_final !== undefined) {
      paramCount++;
      whereConditions.push(`is_final = $${paramCount}`);
      params.push(is_final === 'true');
    }

    if (format) {
      paramCount++;
      whereConditions.push(`format = $${paramCount}`);
      params.push(format);
    }

    if (date_from) {
      paramCount++;
      whereConditions.push(`created_at >= $${paramCount}`);
      params.push(date_from);
    }

    if (date_to) {
      paramCount++;
      whereConditions.push(`created_at <= $${paramCount}`);
      params.push(date_to);
    }

    if (search) {
      paramCount++;
      whereConditions.push(`(
        title ILIKE $${paramCount} OR 
        summary_text ILIKE $${paramCount} OR 
        candidate_name ILIKE $${paramCount} OR 
        job_title ILIKE $${paramCount}
      )`);
      params.push(`%${search}%`);
    }

    const whereClause = whereConditions.join(' AND ');

    const validSortColumns = ['created_at', 'generated_at', 'overall_score', 'version', 'title'];
    const sortColumn = validSortColumns.includes(sort_by) ? sort_by : 'created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Contar total
    const countQuery = `SELECT COUNT(*) as total FROM relatorios_entrevista WHERE ${whereClause}`;
    const countResult = await pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].total);

    // Buscar relatórios
    paramCount++;
    const limitParam = paramCount;
    paramCount++;
    const offsetParam = paramCount;

    const dataQuery = `
      SELECT 
        id,
        interview_id,
        title,
        report_type,
        summary_text,
        candidate_name,
        job_title,
        overall_score,
        recommendation,
        format,
        is_final,
        version,
        generated_at,
        created_at,
        updated_at
      FROM relatorios_entrevista
      WHERE ${whereClause}
      ORDER BY ${sortColumn} ${sortOrder}
      LIMIT $${limitParam} OFFSET $${offsetParam}
    `;

    const result = await pool.query(dataQuery, [...params, limitNum, offset]);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum)
      }
    });

  } catch (error) {
    console.error('[RF7] Erro ao listar relatórios:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao listar relatórios',
      error: error.message
    });
  }
});

/**
 * GET /api/reports/:id
 * Obter detalhes de um relatório
 */
router.get('/:id', exigirAutenticacao, verificarPermissao(['recruiter', 'admin']), async (req, res) => {
  try {
    const { companyId } = req.usuario || {};
    const { id } = req.params;

    const query = `
      SELECT 
        r.*,
        u_gen.full_name as generated_by_name,
        u_created.full_name as created_by_name
      FROM relatorios_entrevista r
      LEFT JOIN usuarios u_gen ON r.generated_by = u_gen.id
      LEFT JOIN usuarios u_created ON r.created_by = u_created.id
      WHERE r.id = $1 AND r.company_id = $2 AND r.deleted_at IS NULL
    `;

    const result = await pool.query(query, [id, companyId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF7] Erro ao buscar relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar relatório',
      error: error.message
    });
  }
});

/**
 * PUT /api/reports/:id
 * Atualizar relatório (regenerar ou editar campos)
 */
router.put('/:id', exigirAutenticacao, verificarPermissao(['recruiter', 'admin']), async (req, res) => {
  const client = await pool.connect();

  try {
    const { companyId, userId } = req.usuario || {};
    const { id } = req.params;
    const {
      title,
      summary_text,
      overall_score,
      recommendation,
      strengths,
      weaknesses,
      risks,
      is_final,
      regenerate = false
    } = req.body;

    // Verificar se relatório existe
    const reportCheck = await client.query(`
      SELECT * FROM relatorios_entrevista
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `, [id, companyId]);

    if (reportCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    const currentReport = reportCheck.rows[0];

    // Se regenerate = true, criar nova versão
    if (regenerate) {
      // Criar novo relatório com mesma interview_id (incrementa versão)
      const newReportReq = {
        body: {
          interview_id: currentReport.interview_id,
          title: title || currentReport.title,
          report_type: currentReport.report_type,
          format: currentReport.format,
          generate_via_ai: true,
          is_final: is_final !== undefined ? is_final : currentReport.is_final
        },
        user: { companyId, userId }
      };

      // Redirecionar para POST (criar nova versão)
      return router.handle(
        { ...newReportReq, method: 'POST', url: '/api/reports' },
        res
      );
    }

    // Update normal de campos
    const updates = [];
    const values = [];
    let paramCount = 0;

    if (title !== undefined) {
      paramCount++;
      updates.push(`title = $${paramCount}`);
      values.push(title);
    }

    if (summary_text !== undefined) {
      paramCount++;
      updates.push(`summary_text = $${paramCount}`);
      values.push(summary_text);
    }

    if (overall_score !== undefined) {
      paramCount++;
      updates.push(`overall_score = $${paramCount}`);
      values.push(overall_score);
    }

    if (recommendation !== undefined) {
      paramCount++;
      updates.push(`recommendation = $${paramCount}`);
      values.push(recommendation);
    }

    if (strengths !== undefined) {
      paramCount++;
      updates.push(`strengths = $${paramCount}`);
      values.push(JSON.stringify(strengths));
    }

    if (weaknesses !== undefined) {
      paramCount++;
      updates.push(`weaknesses = $${paramCount}`);
      values.push(JSON.stringify(weaknesses));
    }

    if (risks !== undefined) {
      paramCount++;
      updates.push(`risks = $${paramCount}`);
      values.push(JSON.stringify(risks));
    }

    if (is_final !== undefined) {
      paramCount++;
      updates.push(`is_final = $${paramCount}`);
      values.push(is_final);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nenhum campo para atualizar'
      });
    }

    paramCount++;
    values.push(id);
    paramCount++;
    values.push(companyId);

    const updateQuery = `
      UPDATE relatorios_entrevista
      SET ${updates.join(', ')}
      WHERE id = $${paramCount - 1} AND company_id = $${paramCount}
      RETURNING *
    `;

    const result = await client.query(updateQuery, values);

    console.log(`[RF7] Relatório ${id} atualizado`);

    res.json({
      success: true,
      message: 'Relatório atualizado com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF7] Erro ao atualizar relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar relatório',
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * DELETE /api/reports/:id
 * Arquivar/excluir relatório (soft delete)
 */
router.delete('/:id', exigirAutenticacao, verificarPermissao(['recruiter', 'admin']), async (req, res) => {
  try {
    const { companyId } = req.usuario || {};
    const { id } = req.params;

    const result = await pool.query(`
      UPDATE relatorios_entrevista
      SET deleted_at = now()
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
      RETURNING id
    `, [id, companyId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Relatório não encontrado'
      });
    }

    console.log(`[RF7] Relatório ${id} arquivado`);

    res.json({
      success: true,
      message: 'Relatório arquivado com sucesso'
    });

  } catch (error) {
    console.error('[RF7] Erro ao arquivar relatório:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao arquivar relatório',
      error: error.message
    });
  }
});

/**
 * GET /api/reports/interview/:interview_id
 * Buscar todos os relatórios de uma entrevista
 */
router.get('/interview/:interview_id', exigirAutenticacao, verificarPermissao(['recruiter', 'admin']), async (req, res) => {
  try {
    const { companyId } = req.usuario || {};
    const { interview_id } = req.params;

    const query = `
      SELECT 
        id,
        title,
        report_type,
        version,
        overall_score,
        recommendation,
        is_final,
        format,
        generated_at,
        created_at
      FROM relatorios_entrevista
      WHERE interview_id = $1 AND company_id = $2 AND deleted_at IS NULL
      ORDER BY version DESC, created_at DESC
    `;

    const result = await pool.query(query, [interview_id, companyId]);

    // Estatísticas
    const stats = {
      total_versions: result.rows.length,
      latest_version: result.rows.length > 0 ? result.rows[0].version : 0,
      final_reports: result.rows.filter(r => r.is_final).length,
      draft_reports: result.rows.filter(r => !r.is_final).length
    };

    res.json({
      success: true,
      data: result.rows,
      stats
    });

  } catch (error) {
    console.error('[RF7] Erro ao buscar relatórios da entrevista:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar relatórios',
      error: error.message
    });
  }
});

module.exports = router;
