/**
 * Rotas para gerenciamento de Live Assessments (RF6)
 * CRUD completo + avaliação automática via IA
 */

const express = require('express');
const router = express.Router();
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
const authMiddleware = require('../../middlewares/authMiddleware');
const { avaliarResposta } = require('../../servicos/openRouterService');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});

// ============================================================================
// 1. CRIAR AVALIAÇÃO (automática via IA ou manual)
// ============================================================================

router.post('/', authMiddleware, async (req, res) => {
  const client = await pool.connect();

  try {
    const { company_id, user_id, role } = req.user;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN', 'RECRUITER'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para criar avaliações'
      });
    }

    const {
      interview_id,
      question_id,
      answer_id,
      answer_text,          // Texto da resposta (se não tiver answer_id)
      question_text,        // Texto da pergunta (se não tiver question_id)
      assessment_type,
      response_time_seconds,
      auto_evaluate = true  // Se deve avaliar automaticamente via IA
    } = req.body;

    // Validações
    if (!interview_id) {
      return res.status(400).json({
        success: false,
        message: 'interview_id é obrigatório'
      });
    }

    await client.query('BEGIN');

    // Verificar se entrevista existe
    const interviewCheck = await client.query(
      `SELECT id FROM entrevistas WHERE id = $1 AND company_id = $2`,
      [interview_id, company_id]
    );

    if (interviewCheck.rows.length === 0) {
      throw new Error('Entrevista não encontrada');
    }

    let score_auto = null;
    let feedback_auto = null;
    let status = 'pending';

    // Se auto_evaluate = true, chamar IA
    if (auto_evaluate && (question_text || question_id) && (answer_text || answer_id)) {
      let questionForIA = question_text;
      let answerForIA = answer_text;

      // Buscar textos se IDs fornecidos
      if (question_id && !question_text) {
        const qResult = await client.query(
          `SELECT text, prompt FROM perguntas_entrevista WHERE id = $1`,
          [question_id]
        );
        questionForIA = qResult.rows[0]?.text || qResult.rows[0]?.prompt || '';
      }

      if (answer_id && !answer_text) {
        const aResult = await client.query(
          `SELECT raw_text FROM respostas_entrevista WHERE id = $1`,
          [answer_id]
        );
        answerForIA = aResult.rows[0]?.raw_text || '';
      }

      // Chamar IA para avaliação
      try {
        const avaliacao = await avaliarResposta(questionForIA, answerForIA);
        
        score_auto = avaliacao.nota || null;
        feedback_auto = {
          nota: avaliacao.nota,
          feedback: avaliacao.feedback,
          pontosFortesResposta: avaliacao.pontosFortesResposta || [],
          pontosMelhoria: avaliacao.pontosMelhoria || []
        };
        status = 'auto_evaluated';
      } catch (err) {
        console.error('Erro ao avaliar via IA:', err);
        // Continua sem avaliação automática
      }
    }

    // Criar assessment
    const assessmentId = uuidv4();
    const insertQuery = `
      INSERT INTO avaliacoes_tempo_real (
        id, company_id, interview_id, question_id, answer_id,
        score_auto, feedback_auto, assessment_type, status,
        response_time_seconds, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `;

    const result = await client.query(insertQuery, [
      assessmentId,
      company_id,
      interview_id,
      question_id || null,
      answer_id || null,
      score_auto,
      feedback_auto,
      assessment_type || 'general',
      status,
      response_time_seconds || null,
      user_id
    ]);

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Avaliação criada com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erro ao criar assessment:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar avaliação',
      error: error.message
    });
  } finally {
    client.release();
  }
});

// ============================================================================
// 2. LISTAR AVALIAÇÕES (com filtros e paginação)
// ============================================================================

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { company_id } = req.user;
    const {
      interview_id,
      status,
      assessment_type,
      sort_by = 'created_at',
      order = 'DESC',
      page = 1,
      limit = 20
    } = req.query;

    // Validar paginação
    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(100, Math.max(1, parseInt(limit)));
    const offset = (pageNum - 1) * limitNum;

    // Construir query
    let conditions = ['la.company_id = $1', 'la.deleted_at IS NULL'];
    let params = [company_id];
    let paramCount = 1;

    if (interview_id) {
      paramCount++;
      conditions.push(`la.interview_id = $${paramCount}`);
      params.push(interview_id);
    }

    if (status) {
      paramCount++;
      conditions.push(`la.status = $${paramCount}`);
      params.push(status);
    }

    if (assessment_type) {
      paramCount++;
      conditions.push(`la.assessment_type = $${paramCount}`);
      params.push(assessment_type);
    }

    const whereClause = conditions.join(' AND ');

    // Validar sort_by
    const validSortFields = ['created_at', 'updated_at', 'score_final', 'status'];
    const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Query de contagem
    const countQuery = `SELECT COUNT(*) FROM avaliacoes_tempo_real la WHERE ${whereClause}`;
    const countResult = await pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    // Query principal
    const query = `
      SELECT 
        la.*,
        iq.text as question_text,
        iq.kind as question_type,
        ia.raw_text as answer_text,
        u.full_name as evaluated_by_name
      FROM avaliacoes_tempo_real la
      LEFT JOIN perguntas_entrevista iq ON iq.id = la.question_id
      LEFT JOIN respostas_entrevista ia ON ia.id = la.answer_id
      LEFT JOIN usuarios u ON u.id = la.evaluated_by
      WHERE ${whereClause}
      ORDER BY la.${sortField} ${sortOrder}
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `;

    params.push(limitNum, offset);
    const result = await pool.query(query, params);

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
    console.error('Erro ao listar assessments:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao listar avaliações',
      error: error.message
    });
  }
});

// ============================================================================
// 3. OBTER DETALHES DE UMA AVALIAÇÃO
// ============================================================================

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const { company_id } = req.user;
    const { id } = req.params;

    const query = `
      SELECT 
        la.*,
        iq.text as question_text,
        iq.kind as question_type,
        iq.prompt as question_prompt,
        ia.raw_text as answer_text,
        i.scheduled_at as interview_date,
        i.status as interview_status,
        u_created.full_name as created_by_name,
        u_evaluated.full_name as evaluated_by_name
      FROM avaliacoes_tempo_real la
      LEFT JOIN perguntas_entrevista iq ON iq.id = la.question_id
      LEFT JOIN respostas_entrevista ia ON ia.id = la.answer_id
      LEFT JOIN entrevistas i ON i.id = la.interview_id
      LEFT JOIN usuarios u_created ON u_created.id = la.created_by
      LEFT JOIN usuarios u_evaluated ON u_evaluated.id = la.evaluated_by
      WHERE la.id = $1 
      AND la.company_id = $2 
      AND la.deleted_at IS NULL
    `;

    const result = await pool.query(query, [id, company_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Avaliação não encontrada'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Erro ao obter assessment:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao obter avaliação',
      error: error.message
    });
  }
});

// ============================================================================
// 4. ATUALIZAR AVALIAÇÃO (ajuste manual)
// ============================================================================

router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const { company_id, user_id, role } = req.user;
    const { id } = req.params;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN', 'RECRUITER'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para atualizar avaliações'
      });
    }

    const {
      score_manual,
      feedback_manual,
      status
    } = req.body;

    // Verificar se existe
    const checkQuery = `
      SELECT * FROM avaliacoes_tempo_real
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await pool.query(checkQuery, [id, company_id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Avaliação não encontrada'
      });
    }

    // Atualizar
    let updateFields = [];
    let updateParams = [];
    let paramCount = 1;

    if (score_manual !== undefined) {
      updateFields.push(`score_manual = $${paramCount++}`);
      updateParams.push(score_manual);
      updateFields.push(`evaluated_by = $${paramCount++}`);
      updateParams.push(user_id);
    }

    if (feedback_manual !== undefined) {
      updateFields.push(`feedback_manual = $${paramCount++}`);
      updateParams.push(feedback_manual);
    }

    if (status !== undefined) {
      updateFields.push(`status = $${paramCount++}`);
      updateParams.push(status);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Nenhum campo para atualizar'
      });
    }

    updateParams.push(id, company_id);

    const updateQuery = `
      UPDATE avaliacoes_tempo_real
      SET ${updateFields.join(', ')}
      WHERE id = $${paramCount++} AND company_id = $${paramCount++}
      RETURNING *
    `;

    const result = await pool.query(updateQuery, updateParams);

    res.json({
      success: true,
      message: 'Avaliação atualizada com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Erro ao atualizar assessment:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar avaliação',
      error: error.message
    });
  }
});

// ============================================================================
// 5. INVALIDAR/DELETAR AVALIAÇÃO (soft delete)
// ============================================================================

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { company_id, user_id, role } = req.user;
    const { id } = req.params;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para deletar avaliações'
      });
    }

    // Verificar se existe
    const checkQuery = `
      SELECT * FROM avaliacoes_tempo_real
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await pool.query(checkQuery, [id, company_id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Avaliação não encontrada'
      });
    }

    // Soft delete
    const deleteQuery = `
      UPDATE avaliacoes_tempo_real
      SET deleted_at = now(), status = 'invalidated'
      WHERE id = $1 AND company_id = $2
      RETURNING *
    `;
    const result = await pool.query(deleteQuery, [id, company_id]);

    res.json({
      success: true,
      message: 'Avaliação invalidada com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Erro ao deletar assessment:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao deletar avaliação',
      error: error.message
    });
  }
});

// ============================================================================
// 6. AVALIAÇÕES POR ENTREVISTA (listagem específica)
// ============================================================================

router.get('/interview/:interview_id', authMiddleware, async (req, res) => {
  try {
    const { company_id } = req.user;
    const { interview_id } = req.params;

    const query = `
      SELECT 
        la.*,
        iq.text as question_text,
        iq.kind as question_type,
        ia.raw_text as answer_text,
        u.full_name as evaluated_by_name
      FROM avaliacoes_tempo_real la
      LEFT JOIN perguntas_entrevista iq ON iq.id = la.question_id
      LEFT JOIN respostas_entrevista ia ON ia.id = la.answer_id
      LEFT JOIN usuarios u ON u.id = la.evaluated_by
      WHERE la.interview_id = $1 
      AND la.company_id = $2 
      AND la.deleted_at IS NULL
      ORDER BY la.created_at ASC
    `;

    const result = await pool.query(query, [interview_id, company_id]);

    // Calcular estatísticas
    const stats = {
      total_assessments: result.rows.length,
      avg_score: result.rows.length > 0 
        ? (result.rows.reduce((sum, a) => sum + (parseFloat(a.score_final) || 0), 0) / result.rows.length).toFixed(2)
        : 0,
      auto_evaluated: result.rows.filter(a => a.status === 'auto_evaluated').length,
      manually_adjusted: result.rows.filter(a => a.status === 'manually_adjusted').length
    };

    res.json({
      success: true,
      data: result.rows,
      stats
    });

  } catch (error) {
    console.error('Erro ao listar assessments por entrevista:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao listar avaliações da entrevista',
      error: error.message
    });
  }
});

module.exports = router;
