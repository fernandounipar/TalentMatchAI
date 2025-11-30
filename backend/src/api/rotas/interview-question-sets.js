/**
 * Rotas para gerenciamento de conjuntos de perguntas de entrevista (RF3)
 * CRUD completo + geração via IA
 */

const express = require('express');
const router = express.Router();
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
const authMiddleware = require('../../middlewares/authMiddleware');
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});

// Função auxiliar para mapear categoria/tipo da IA para o enum do banco
function mapKindToBanco(kind) {
  if (!kind) return 'TECNICA';
  const normalized = kind.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
  const map = {
    'tecnica': 'TECNICA',
    'technical': 'TECNICA',
    'comportamental': 'COMPORTAMENTAL',
    'behavioral': 'COMPORTAMENTAL',
    'situacional': 'SITUACIONAL',
    'situational': 'SITUACIONAL',
    'cultural': 'COMPORTAMENTAL',
    'general': 'TECNICA',
  };
  return map[normalized] || 'TECNICA';
}

// ============================================================================
// 1. LISTAR CONJUNTOS DE PERGUNTAS (com filtros e paginação)
// ============================================================================

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { company_id, user_id } = req.user;
    const {
      job_id,
      is_template,
      q,
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
    let conditions = ['qs.company_id = $1', 'qs.deleted_at IS NULL'];
    let params = [company_id];
    let paramCount = 1;

    if (job_id) {
      paramCount++;
      conditions.push(`qs.job_id = $${paramCount}`);
      params.push(job_id);
    }

    if (is_template !== undefined) {
      paramCount++;
      conditions.push(`qs.is_template = $${paramCount}`);
      params.push(is_template === 'true');
    }

    if (q) {
      paramCount++;
      conditions.push(`(
        qs.title ILIKE $${paramCount} OR 
        qs.description ILIKE $${paramCount}
      )`);
      params.push(`%${q}%`);
    }

    const whereClause = conditions.join(' AND ');

    // Validar sort_by
    const validSortFields = ['created_at', 'updated_at', 'title'];
    const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Query de contagem
    const countQuery = `
      SELECT COUNT(*)
      FROM conjuntos_perguntas_entrevista qs
      WHERE ${whereClause}
    `;
    const countResult = await pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    // Query principal
    const query = `
      SELECT 
        qs.id,
        qs.company_id,
        qs.job_id,
        qs.resume_id,
        qs.title,
        qs.description,
        qs.is_template,
        qs.created_by,
        qs.updated_by,
        qs.created_at,
        qs.updated_at,
        
        -- Informações do job
        j.title as job_title,
        j.seniority as job_seniority,
        
        -- Contadores
        (
          SELECT COUNT(*) 
          FROM perguntas_entrevista iq 
          WHERE iq.set_id = qs.id 
          AND iq.deleted_at IS NULL
        ) as question_count,
        
        (
          SELECT COUNT(DISTINCT iq.interview_id) 
          FROM perguntas_entrevista iq 
          WHERE iq.set_id = qs.id 
          AND iq.interview_id IS NOT NULL
        ) as usage_count,
        
        -- Criador
        u.full_name as created_by_name
        
      FROM conjuntos_perguntas_entrevista qs
      LEFT JOIN vagas j ON j.id = qs.job_id
      LEFT JOIN usuarios u ON u.id = qs.created_by
      WHERE ${whereClause}
      ORDER BY qs.${sortField} ${sortOrder}
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
    console.error('Erro ao listar question sets:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao listar conjuntos de perguntas',
      error: error.message
    });
  }
});

// ============================================================================
// 2. OBTER DETALHES DE UM CONJUNTO (com perguntas)
// ============================================================================

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const { company_id } = req.user;
    const { id } = req.params;

    // Query do conjunto
    const setQuery = `
      SELECT 
        qs.*,
        j.title as job_title,
        j.seniority as job_seniority,
        u_created.full_name as created_by_name,
        u_updated.full_name as updated_by_name
      FROM conjuntos_perguntas_entrevista qs
      LEFT JOIN vagas j ON j.id = qs.job_id
      LEFT JOIN usuarios u_created ON u_created.id = qs.created_by
      LEFT JOIN usuarios u_updated ON u_updated.id = qs.updated_by
      WHERE qs.id = $1 
      AND qs.company_id = $2 
      AND qs.deleted_at IS NULL
    `;

    const setResult = await pool.query(setQuery, [id, company_id]);

    if (setResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Conjunto de perguntas não encontrado'
      });
    }

    const questionSet = setResult.rows[0];

    // Query das perguntas
    const questionsQuery = `
      SELECT 
        id,
        set_id,
        kind as type,
        text,
        "order",
        origin,
        kind,
        prompt,
        created_at,
        updated_at
      FROM perguntas_entrevista
      WHERE set_id = $1
      AND deleted_at IS NULL
      ORDER BY "order" ASC NULLS LAST, created_at ASC
    `;

    const questionsResult = await pool.query(questionsQuery, [id]);

    res.json({
      success: true,
      data: {
        ...questionSet,
        questions: questionsResult.rows
      }
    });

  } catch (error) {
    console.error('Erro ao obter question set:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao obter conjunto de perguntas',
      error: error.message
    });
  }
});

// ============================================================================
// 3. CRIAR CONJUNTO DE PERGUNTAS (manual ou via IA)
// ============================================================================

router.post('/', authMiddleware, async (req, res) => {
  const client = await pool.connect();

  try {
    const { company_id, user_id, role } = req.user;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN', 'RECRUITER'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para criar conjuntos de perguntas'
      });
    }

    const {
      job_id,
      resume_id,
      title,
      description,
      is_template = false,
      questions = [],
      generate_via_ai = false
    } = req.body;

    // Validações
    if (!title || title.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Título é obrigatório'
      });
    }

    if (generate_via_ai && !job_id) {
      return res.status(400).json({
        success: false,
        message: 'job_id é obrigatório para geração via IA'
      });
    }

    await client.query('BEGIN');

    // Criar o conjunto
    const setId = uuidv4();
    const insertSetQuery = `
      INSERT INTO conjuntos_perguntas_entrevista (
        id, company_id, job_id, resume_id, title, description,
        is_template, created_by, updated_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `;

    const setResult = await client.query(insertSetQuery, [
      setId,
      company_id,
      job_id || null,
      resume_id || null,
      title.trim(),
      description || null,
      is_template,
      user_id,
      user_id
    ]);

    const createdSet = setResult.rows[0];
    let createdQuestions = [];

    // Se gerar via IA
    if (generate_via_ai) {
      const openRouterService = require('../../servicos/openRouterService');
      
      // Buscar dados da vaga
      const jobQuery = `SELECT * FROM vagas WHERE id = $1 AND company_id = $2`;
      const jobResult = await client.query(jobQuery, [job_id, company_id]);

      if (jobResult.rows.length === 0) {
        throw new Error('Vaga não encontrada');
      }

      const job = jobResult.rows[0];

      // Buscar dados do currículo (se fornecido)
      let resume = null;
      if (resume_id) {
        const resumeQuery = `SELECT * FROM curriculos WHERE id = $1 AND company_id = $2`;
        const resumeResult = await client.query(resumeQuery, [resume_id, company_id]);
        resume = resumeResult.rows[0] || null;
      }

      // Gerar perguntas via IA
      const aiQuestions = await openRouterService.gerarPerguntasEntrevista(job, resume);

      // Inserir perguntas geradas
      for (let i = 0; i < aiQuestions.length; i++) {
        const q = aiQuestions[i];
        const questionId = uuidv4();

        const insertQuestionQuery = `
          INSERT INTO perguntas_entrevista (
            id, company_id, set_id, kind, text, "order", origin, prompt
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          RETURNING *
        `;

        const questionResult = await client.query(insertQuestionQuery, [
          questionId,
          company_id,
          setId,
          mapKindToBanco(q.tipo || q.categoria),
          q.pergunta || q.texto,
          i + 1,
          'ai_generated',
          q.pergunta
        ]);

        createdQuestions.push(questionResult.rows[0]);
      }

    } else if (questions.length > 0) {
      // Inserir perguntas manuais
      for (let i = 0; i < questions.length; i++) {
        const q = questions[i];
        const questionId = uuidv4();

        if (!q.text || q.text.trim().length === 0) {
          throw new Error(`Pergunta ${i + 1} não pode estar vazia`);
        }

        const insertQuestionQuery = `
          INSERT INTO perguntas_entrevista (
            id, company_id, set_id, kind, text, "order", origin, prompt
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          RETURNING *
        `;

        const questionResult = await client.query(insertQuestionQuery, [
          questionId,
          company_id,
          setId,
          mapKindToBanco(q.type),
          q.text.trim(),
          q.order || i + 1,
          'manual',
          q.text.trim()
        ]);

        createdQuestions.push(questionResult.rows[0]);
      }
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Conjunto de perguntas criado com sucesso',
      data: {
        ...createdSet,
        questions: createdQuestions
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erro ao criar question set:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao criar conjunto de perguntas',
      error: error.message
    });
  } finally {
    client.release();
  }
});

// ============================================================================
// 4. ATUALIZAR CONJUNTO DE PERGUNTAS
// ============================================================================

router.put('/:id', authMiddleware, async (req, res) => {
  const client = await pool.connect();

  try {
    const { company_id, user_id, role } = req.user;
    const { id } = req.params;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN', 'RECRUITER'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para atualizar conjuntos de perguntas'
      });
    }

    const {
      title,
      description,
      is_template,
      questions
    } = req.body;

    // Verificar se o conjunto existe
    const checkQuery = `
      SELECT * FROM conjuntos_perguntas_entrevista
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await client.query(checkQuery, [id, company_id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Conjunto de perguntas não encontrado'
      });
    }

    await client.query('BEGIN');

    // Atualizar o conjunto (campos opcionais)
    let updateFields = [];
    let updateParams = [];
    let paramCount = 1;

    if (title !== undefined) {
      updateFields.push(`title = $${paramCount++}`);
      updateParams.push(title.trim());
    }

    if (description !== undefined) {
      updateFields.push(`description = $${paramCount++}`);
      updateParams.push(description);
    }

    if (is_template !== undefined) {
      updateFields.push(`is_template = $${paramCount++}`);
      updateParams.push(is_template);
    }

    updateFields.push(`updated_by = $${paramCount++}`);
    updateParams.push(user_id);

    updateParams.push(id, company_id);

    const updateSetQuery = `
      UPDATE conjuntos_perguntas_entrevista
      SET ${updateFields.join(', ')}
      WHERE id = $${paramCount++} AND company_id = $${paramCount++}
      RETURNING *
    `;

    const setResult = await client.query(updateSetQuery, updateParams);
    const updatedSet = setResult.rows[0];

    // Atualizar perguntas (se fornecidas)
    if (questions && Array.isArray(questions)) {
      for (const q of questions) {
        if (q.id) {
          // Atualizar pergunta existente
          const updateQuestionQuery = `
            UPDATE perguntas_entrevista
            SET 
              kind = COALESCE($1, kind),
              text = COALESCE($2, text),
              "order" = COALESCE($3, "order"),
              origin = 'ai_edited'
            WHERE id = $4 
            AND company_id = $5 
            AND set_id = $6
            AND deleted_at IS NULL
          `;

          await client.query(updateQuestionQuery, [
            q.type || null,
            q.text || null,
            q.order || null,
            q.id,
            company_id,
            id
          ]);
        } else {
          // Adicionar nova pergunta
          const questionId = uuidv4();
          const insertQuestionQuery = `
            INSERT INTO perguntas_entrevista (
              id, company_id, set_id, kind, text, "order", origin, prompt
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          `;

          await client.query(insertQuestionQuery, [
            questionId,
            company_id,
            id,
            mapKindToBanco(q.type),
            q.text,
            q.order || 999,
            'manual',
            q.text
          ]);
        }
      }
    }

    // Buscar perguntas atualizadas
    const questionsQuery = `
      SELECT * FROM perguntas_entrevista
      WHERE set_id = $1 AND deleted_at IS NULL
      ORDER BY "order" ASC NULLS LAST, created_at ASC
    `;
    const questionsResult = await client.query(questionsQuery, [id]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Conjunto de perguntas atualizado com sucesso',
      data: {
        ...updatedSet,
        questions: questionsResult.rows
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erro ao atualizar question set:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao atualizar conjunto de perguntas',
      error: error.message
    });
  } finally {
    client.release();
  }
});

// ============================================================================
// 5. DELETAR CONJUNTO DE PERGUNTAS (soft delete)
// ============================================================================

router.delete('/:id', authMiddleware, async (req, res) => {
  const client = await pool.connect();

  try {
    const { company_id, user_id, role } = req.user;
    const { id } = req.params;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para deletar conjuntos de perguntas'
      });
    }

    // Verificar se o conjunto existe
    const checkQuery = `
      SELECT * FROM conjuntos_perguntas_entrevista
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await client.query(checkQuery, [id, company_id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Conjunto de perguntas não encontrado'
      });
    }

    await client.query('BEGIN');

    // Soft delete do conjunto
    const deleteSetQuery = `
      UPDATE conjuntos_perguntas_entrevista
      SET deleted_at = now(), updated_by = $1
      WHERE id = $2 AND company_id = $3
    `;
    await client.query(deleteSetQuery, [user_id, id, company_id]);

    // Soft delete das perguntas (apenas aquelas NÃO usadas em entrevistas)
    const deleteQuestionsQuery = `
      UPDATE perguntas_entrevista
      SET deleted_at = now()
      WHERE set_id = $1 
      AND company_id = $2
      AND interview_id IS NULL
      AND deleted_at IS NULL
    `;
    await client.query(deleteQuestionsQuery, [id, company_id]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Conjunto de perguntas deletado com sucesso'
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erro ao deletar question set:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao deletar conjunto de perguntas',
      error: error.message
    });
  } finally {
    client.release();
  }
});

// ============================================================================
// 6. DELETAR UMA PERGUNTA ESPECÍFICA (soft delete)
// ============================================================================

router.delete('/:setId/questions/:questionId', authMiddleware, async (req, res) => {
  try {
    const { company_id, user_id, role } = req.user;
    const { setId, questionId } = req.params;

    // Validar permissões
    if (!['ADMIN', 'SUPER_ADMIN', 'RECRUITER'].includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Sem permissão para deletar perguntas'
      });
    }

    // Verificar se a pergunta existe e NÃO está vinculada a entrevista
    const checkQuery = `
      SELECT * FROM perguntas_entrevista
      WHERE id = $1 
      AND set_id = $2 
      AND company_id = $3 
      AND deleted_at IS NULL
    `;
    const checkResult = await pool.query(checkQuery, [questionId, setId, company_id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pergunta não encontrada'
      });
    }

    const question = checkResult.rows[0];

    if (question.interview_id) {
      return res.status(400).json({
        success: false,
        message: 'Não é possível deletar perguntas já usadas em entrevistas'
      });
    }

    // Soft delete
    const deleteQuery = `
      UPDATE perguntas_entrevista
      SET deleted_at = now()
      WHERE id = $1 AND company_id = $2
    `;
    await pool.query(deleteQuery, [questionId, company_id]);

    res.json({
      success: true,
      message: 'Pergunta deletada com sucesso'
    });

  } catch (error) {
    console.error('Erro ao deletar pergunta:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao deletar pergunta',
      error: error.message
    });
  }
});

module.exports = router;
