const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarAnaliseCurriculo } = require('../../servicos/iaService');

router.use(exigirAutenticacao);

/**
 * POST /api/resumes - Criar novo currículo (já implementado via /curriculos/upload)
 * Redireciona para a rota de upload de currículos
 */

/**
 * GET /api/resumes - Listar currículos com paginação e filtros (Read)
 */
router.get('/', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const {
      page = 1,
      limit = 20,
      job_id,
      status,
      candidate_name,
      date_from,
      date_to,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    
    // Construir filtros dinâmicos
    let whereConditions = ['r.company_id = $1', 'r.deleted_at IS NULL'];
    let params = [companyId];
    let paramIndex = 2;

    if (job_id) {
      whereConditions.push(`r.job_id = $${paramIndex}`);
      params.push(job_id);
      paramIndex++;
    }

    if (status) {
      whereConditions.push(`r.status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    if (candidate_name) {
      whereConditions.push(`c.full_name ILIKE $${paramIndex}`);
      params.push(`%${candidate_name}%`);
      paramIndex++;
    }

    if (date_from) {
      whereConditions.push(`r.created_at >= $${paramIndex}`);
      params.push(date_from);
      paramIndex++;
    }

    if (date_to) {
      whereConditions.push(`r.created_at <= $${paramIndex}`);
      params.push(date_to);
      paramIndex++;
    }

    const whereClause = whereConditions.join(' AND ');
    
    // Validar sort_by para prevenir SQL injection
    const allowedSortFields = ['created_at', 'updated_at', 'candidate_name', 'status'];
    const sortField = allowedSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortDir = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Query principal
    const query = `
      SELECT 
        r.id,
        r.candidate_id,
        r.job_id,
        r.original_filename,
        r.file_size,
        r.mime_type,
        r.status,
        r.notes,
        r.is_favorite,
        r.created_at,
        r.updated_at,
        c.full_name AS candidate_name,
        CASE 
          WHEN c.email LIKE '%@%' THEN 
            SUBSTRING(c.email FROM 1 FOR 3) || '***@' || SUBSTRING(c.email FROM POSITION('@' IN c.email) + 1)
          ELSE NULL
        END AS email_masked,
        c.phone,
        j.title AS job_title,
        (SELECT COUNT(*) FROM resume_analysis ra WHERE ra.resume_id = r.id) AS analysis_count,
        (SELECT score FROM resume_analysis ra WHERE ra.resume_id = r.id ORDER BY created_at DESC LIMIT 1) AS latest_score
      FROM resumes r
      INNER JOIN candidates c ON c.id = r.candidate_id
      LEFT JOIN jobs j ON j.id = r.job_id
      WHERE ${whereClause}
      ORDER BY r.${sortField} ${sortDir}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    params.push(parseInt(limit), offset);

    const result = await db.query(query, params);

    // Count total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM resumes r
      INNER JOIN candidates c ON c.id = r.candidate_id
      WHERE ${whereClause}
    `;
    const countResult = await db.query(countQuery, params.slice(0, paramIndex - 1));
    const total = parseInt(countResult.rows[0].total);

    res.json({
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('❌ Erro ao listar currículos:', error);
    res.status(500).json({ erro: 'Erro ao listar currículos', detalhes: error.message });
  }
});

/**
 * GET /api/resumes/:id - Obter detalhes de um currículo específico (Read)
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.usuario.company_id;

    const query = `
      SELECT 
        r.*,
        c.full_name,
        c.email,
        c.phone,
        c.github_url,
        c.linkedin_url,
        j.title AS job_title,
        j.description AS job_description,
        j.requirements AS job_requirements,
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'id', ra.id,
              'summary', ra.summary,
              'score', ra.score,
              'questions', ra.questions,
              'created_at', ra.created_at
            ) ORDER BY ra.created_at DESC
          )
          FROM resume_analysis ra
          WHERE ra.resume_id = r.id
        ) AS analyses
      FROM resumes r
      INNER JOIN candidates c ON c.id = r.candidate_id
      LEFT JOIN jobs j ON j.id = r.job_id
      WHERE r.id = $1 AND r.company_id = $2 AND r.deleted_at IS NULL
    `;

    const result = await db.query(query, [id, companyId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Currículo não encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('❌ Erro ao obter currículo:', error);
    res.status(500).json({ erro: 'Erro ao obter currículo', detalhes: error.message });
  }
});

/**
 * PUT /api/resumes/:id - Atualizar metadados do currículo (Update)
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.usuario.company_id;
    const { status, notes, is_favorite, job_id } = req.body;

    // Verificar se o currículo pertence à empresa
    const checkQuery = `
      SELECT id FROM resumes 
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await db.query(checkQuery, [id, companyId]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ erro: 'Currículo não encontrado' });
    }

    // Construir update dinâmico
    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    if (notes !== undefined) {
      updates.push(`notes = $${paramIndex}`);
      params.push(notes);
      paramIndex++;
    }

    if (is_favorite !== undefined) {
      updates.push(`is_favorite = $${paramIndex}`);
      params.push(is_favorite);
      paramIndex++;
    }

    if (job_id !== undefined) {
      updates.push(`job_id = $${paramIndex}`);
      params.push(job_id);
      paramIndex++;
    }

    if (updates.length === 0) {
      return res.status(400).json({ erro: 'Nenhum campo para atualizar' });
    }

    updates.push(`updated_at = NOW()`);
    updates.push(`updated_by = $${paramIndex}`);
    params.push(req.usuario.id);
    paramIndex++;

    params.push(id, companyId);

    const updateQuery = `
      UPDATE resumes
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex - 1} AND company_id = $${paramIndex}
      RETURNING *
    `;

    const result = await db.query(updateQuery, params);

    res.json({
      mensagem: 'Currículo atualizado com sucesso',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Erro ao atualizar currículo:', error);
    res.status(500).json({ erro: 'Erro ao atualizar currículo', detalhes: error.message });
  }
});

/**
 * DELETE /api/resumes/:id - Excluir currículo (soft delete)
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.usuario.company_id;

    // Verificar se o currículo existe e pertence à empresa
    const checkQuery = `
      SELECT id FROM resumes 
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await db.query(checkQuery, [id, companyId]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ erro: 'Currículo não encontrado' });
    }

    // Soft delete
    const deleteQuery = `
      UPDATE resumes
      SET deleted_at = NOW(), updated_at = NOW(), updated_by = $1
      WHERE id = $2 AND company_id = $3
      RETURNING id
    `;

    await db.query(deleteQuery, [req.usuario.id, id, companyId]);

    res.json({
      mensagem: 'Currículo excluído com sucesso',
      id
    });
  } catch (error) {
    console.error('❌ Erro ao excluir currículo:', error);
    res.status(500).json({ erro: 'Erro ao excluir currículo', detalhes: error.message });
  }
});

/**
 * POST /api/resumes/:id/analyze - Reanalisar currículo
 */
router.post('/:id/analyze', async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.usuario.company_id;

    // Buscar currículo com dados do candidato e vaga
    const query = `
      SELECT 
        r.id,
        r.parsed_text,
        r.candidate_id,
        r.job_id,
        c.full_name,
        c.email,
        c.phone,
        j.title AS job_title,
        j.description AS job_description,
        j.requirements AS job_requirements
      FROM resumes r
      INNER JOIN candidates c ON c.id = r.candidate_id
      LEFT JOIN jobs j ON j.id = r.job_id
      WHERE r.id = $1 AND r.company_id = $2 AND r.deleted_at IS NULL
    `;

    const result = await db.query(query, [id, companyId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Currículo não encontrado' });
    }

    const resume = result.rows[0];

    // Gerar análise com IA
    const analysis = await gerarAnaliseCurriculo(
      resume.parsed_text,
      resume.job_title,
      resume.job_description,
      resume.job_requirements
    );

    // Salvar análise no banco
    const insertQuery = `
      INSERT INTO resume_analysis (
        resume_id,
        summary,
        score,
        questions,
        provider,
        model,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING *
    `;

    const analysisResult = await db.query(insertQuery, [
      id,
      JSON.stringify(analysis),
      analysis.matchingScore || 0,
      JSON.stringify(analysis.questions || []),
      analysis.provider,
      analysis.model
    ]);

    res.json({
      mensagem: 'Análise realizada com sucesso',
      analysis: analysisResult.rows[0]
    });
  } catch (error) {
    console.error('❌ Erro ao reanalisar currículo:', error);
    res.status(500).json({ erro: 'Erro ao reanalisar currículo', detalhes: error.message });
  }
});

/**
 * GET /api/resumes/search - Busca simples por termos em resumes.parsed_text
 */
router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || String(q).trim() === '') return res.json([]);
    const term = `%${String(q).toLowerCase()}%`;
    const r = await db.query(
      `SELECT r.id, r.candidate_id, r.file_id, r.original_filename, r.created_at,
              c.full_name, c.email
         FROM resumes r
         JOIN candidates c ON c.id = r.candidate_id
        WHERE r.company_id=$1 AND lower(r.parsed_text) LIKE $2 AND r.deleted_at IS NULL
        ORDER BY r.created_at DESC LIMIT 50`,
      [req.usuario.company_id, term]
    );
    res.json(r.rows);
  } catch (e) {
    res.status(500).json({ erro: 'Falha na busca' });
  }
});

module.exports = router;
