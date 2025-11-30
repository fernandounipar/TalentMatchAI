const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarAnaliseCurriculo } = require('../../servicos/iaService');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const pdf = require('pdf-parse');
const mammoth = require('mammoth');

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '../../../uploads');

function ensureDirSync(p) { try { fs.mkdirSync(p, { recursive: true }); } catch { } }

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = path.join(UPLOAD_DIR, String(req.usuario?.company_id || 'public'));
    ensureDirSync(dir);
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const safe = Date.now() + '_' + Math.random().toString(36).slice(2) + ext;
    cb(null, safe);
  }
});

const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } });

router.use(exigirAutenticacao);

/**
 * POST /api/resumes - Criar novo currículo (já implementado via /curriculos/upload)
 * Redireciona para a rota de upload de currículos
 */

/**
 * POST /api/resumes/upload - Upload de currículo (RF1)
 * Aceita multipart field "file" e, opcionalmente, candidate_id ou dados do candidato
 */
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    if (!req.file) return res.status(400).json({ erro: 'Arquivo ausente' });

    const {
      candidate_id,
      job_id,
      full_name,
      email,
      phone,
      linkedin,
      github_url
    } = req.body || {};

    // Resolve candidato
    let candidateId = candidate_id;
    if (!candidateId) {
      if (!full_name || !email) {
        return res.status(400).json({ erro: 'Informe candidate_id ou full_name e email para criar candidato' });
      }
      const cand = await db.query(
        `INSERT INTO candidatos (company_id, full_name, email, phone, linkedin, github_url, created_at)
         VALUES ($1,$2,$3,$4,$5,$6, now()) RETURNING id`,
        [companyId, full_name, email.toLowerCase(), phone || null, linkedin || null, github_url || null]
      );
      candidateId = cand.rows[0].id;
    } else {
      const check = await db.query(
        'SELECT id FROM candidatos WHERE id=$1 AND company_id=$2 AND deleted_at IS NULL',
        [candidateId, companyId]
      );
      if (!check.rows[0]) return res.status(404).json({ erro: 'Candidato não encontrado' });
    }

    // Salva metadata do arquivo
    const relPath = path.posix.join(String(companyId), path.basename(req.file.path));
    const fileIns = await db.query(
      `INSERT INTO arquivos (company_id, storage_key, filename, mime, size, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING id`,
      [companyId, relPath, req.file.originalname, req.file.mimetype, req.file.size]
    );
    const fileId = fileIns.rows[0].id;

    // Cria registro de resume
    const resumeIns = await db.query(
      `INSERT INTO curriculos (
         company_id, candidate_id, job_id, file_id,
         original_filename, file_size, mime_type, status, created_at, updated_at
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,'pending', now(), now())
       RETURNING *`,
      [
        companyId,
        candidateId,
        job_id || null,
        fileId,
        req.file.originalname,
        req.file.size,
        req.file.mimetype
      ]
    );

    const resume = resumeIns.rows[0];
    // Extrair texto do arquivo
    let parsedText = '';
    const filePath = req.file.path;
    let mimeType = req.file.mimetype;
    const ext = path.extname(req.file.originalname).toLowerCase();

    // Fallback de mime type baseado na extensão se for genérico
    if (mimeType === 'application/octet-stream') {
      if (ext === '.pdf') mimeType = 'application/pdf';
      else if (ext === '.docx') mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      else if (ext === '.txt') mimeType = 'text/plain';
    }

    try {
      if (mimeType === 'application/pdf') {
        const dataBuffer = fs.readFileSync(filePath);
        const pdfData = await pdf(dataBuffer);
        parsedText = pdfData.text;
      } else if (mimeType === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
        const result = await mammoth.extractRawText({ path: filePath });
        parsedText = result.value;
      } else if (mimeType === 'text/plain') {
        parsedText = fs.readFileSync(filePath, 'utf8');
      }
    } catch (err) {
      console.error('Erro na extração de texto:', err);
      parsedText = 'Erro ao extrair texto do arquivo.';
    }

    // Atualiza texto extraído no currículo
    await db.query(
      `UPDATE curriculos SET parsed_text = $1 WHERE id = $2`,
      [parsedText, resume.id]
    );

    // Buscar dados da vaga para contexto da IA
    let vagaCtx = {};
    if (job_id) {
      const vagaRes = await db.query('SELECT title, description, requirements FROM vagas WHERE id = $1', [job_id]);
      if (vagaRes.rows.length > 0) {
        vagaCtx = vagaRes.rows[0];
      }
    }

    // Gerar análise com IA
    const analysis = await gerarAnaliseCurriculo(parsedText, vagaCtx, { companyId });

    // Salvar análise no banco
    const insertAnalysis = await db.query(
      `INSERT INTO analise_curriculos (
         resume_id, summary, score, questions, provider, model, created_at
       ) VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING *`,
      [
        resume.id,
        JSON.stringify(analysis),
        analysis.matchingScore || 0,
        JSON.stringify(analysis.questions || []),
        analysis.provider,
        analysis.model
      ]
    );

    // Atualizar dados do candidato com informações extraídas pela IA
    if (analysis.candidato) {
      const c = analysis.candidato;
      // Tenta atualizar dados se a IA extraiu algo relevante
      if (c.nome || c.email) {
        await db.query(
          `UPDATE candidatos 
           SET full_name = COALESCE($1, full_name),
               email = COALESCE($2, email),
               phone = COALESCE($3, phone),
               linkedin = COALESCE($4, linkedin),
               github_url = COALESCE($5, github_url),
               updated_at = NOW()
           WHERE id = $6`,
          [
            c.nome || null,
            c.email ? c.email.toLowerCase() : null,
            c.telefone || null,
            c.linkedin || null,
            c.github || null,
            candidateId
          ]
        );
      }
    }

    // Atualizar status do currículo
    await db.query(
      `UPDATE curriculos SET status = 'reviewed', updated_at = NOW() WHERE id = $1`,
      [resume.id]
    );

    const url = `/uploads/${relPath}`;

    res.status(201).json({
      data: {
        ...resume,
        file_url: url,
        parsed_text: parsedText,
        analise_json: analysis, // Envia JSON estruturado para o frontend
        provider: analysis.provider,
        model: analysis.model
      }
    });
  } catch (error) {
    console.error('❌ Erro no upload de currículo:', error);
    res.status(500).json({ erro: 'Erro ao fazer upload de currículo', detalhes: error.message });
  }
});

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
        (SELECT COUNT(*) FROM analise_curriculos ra WHERE ra.resume_id = r.id) AS analysis_count,
        (SELECT score FROM analise_curriculos ra WHERE ra.resume_id = r.id ORDER BY created_at DESC LIMIT 1) AS latest_score
      FROM curriculos r
      INNER JOIN candidatos c ON c.id = r.candidate_id
      LEFT JOIN vagas j ON j.id = r.job_id
      WHERE ${whereClause}
      ORDER BY r.${sortField} ${sortDir}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    params.push(parseInt(limit), offset);

    const result = await db.query(query, params);

    // Count total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM curriculos r
      INNER JOIN candidatos c ON c.id = r.candidate_id
      WHERE ${whereClause}
    `;
    const countResult = await db.query(countQuery, params.slice(0, paramIndex - 1));
    const total = parseInt(countResult.rows[0].total);

    res.json({
      data: result.rows,
      meta: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        total_pages: Math.ceil(total / parseInt(limit))
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
          FROM analise_curriculos ra
          WHERE ra.resume_id = r.id
        ) AS analyses
      FROM curriculos r
      INNER JOIN candidatos c ON c.id = r.candidate_id
      LEFT JOIN vagas j ON j.id = r.job_id
      WHERE r.id = $1 AND r.company_id = $2 AND r.deleted_at IS NULL
    `;

    const result = await db.query(query, [id, companyId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Currículo não encontrado' });
    }

    res.json({ data: result.rows[0] });
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
      SELECT id FROM curriculos 
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
      UPDATE curriculos
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex - 1} AND company_id = $${paramIndex}
      RETURNING *
    `;

    const result = await db.query(updateQuery, params);

    res.json({ data: result.rows[0] });
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
      SELECT id FROM curriculos 
      WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
    `;
    const checkResult = await db.query(checkQuery, [id, companyId]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ erro: 'Currículo não encontrado' });
    }

    // Soft delete
    const deleteQuery = `
      UPDATE curriculos
      SET deleted_at = NOW(), updated_at = NOW(), updated_by = $1
      WHERE id = $2 AND company_id = $3
      RETURNING id
    `;

    await db.query(deleteQuery, [req.usuario.id, id, companyId]);

    res.status(204).send();
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
      FROM curriculos r
      INNER JOIN candidatos c ON c.id = r.candidate_id
      LEFT JOIN vagas j ON j.id = r.job_id
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
      INSERT INTO analise_curriculos (
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
      data: {
        mensagem: 'Análise realizada com sucesso',
        analysis: analysisResult.rows[0]
      }
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
         FROM curriculos r
         JOIN candidatos c ON c.id = r.candidate_id
        WHERE r.company_id=$1 AND lower(r.parsed_text) LIKE $2 AND r.deleted_at IS NULL
        ORDER BY r.created_at DESC LIMIT 50`,
      [req.usuario.company_id, term]
    );
    res.json({ data: r.rows });
  } catch (e) {
    res.status(500).json({ erro: 'Falha na busca' });
  }
});

/**
 * POST /api/resumes/:id/decision - Registrar decisão (Aprovar/Reprovar/Agendar)
 */
router.post('/:id/decision', async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.usuario.company_id;
    const { decision, job_id, schedule } = req.body; // decision: 'APROVADO' | 'REPROVADO' | 'ENTREVISTA_AGENDADA'

    if (!['APROVADO', 'REPROVADO', 'ENTREVISTA_AGENDADA'].includes(decision)) {
      return res.status(400).json({ erro: 'Decisão inválida' });
    }

    // 1. Buscar currículo para garantir que existe e pegar candidate_id
    const resumeRes = await db.query(
      'SELECT candidate_id, job_id FROM curriculos WHERE id=$1 AND company_id=$2',
      [id, companyId]
    );
    if (!resumeRes.rows[0]) return res.status(404).json({ erro: 'Currículo não encontrado' });

    const resume = resumeRes.rows[0];
    const candidateId = resume.candidate_id;
    const jobId = job_id || resume.job_id;

    if (!jobId) return res.status(400).json({ erro: 'Vaga não identificada para esta decisão' });

    // 2. Buscar ou Criar Candidatura (Application)
    let applicationId;
    const appRes = await db.query(
      'SELECT id FROM candidaturas WHERE company_id=$1 AND job_id=$2 AND candidate_id=$3 LIMIT 1',
      [companyId, jobId, candidateId]
    );

    if (appRes.rows[0]) {
      applicationId = appRes.rows[0].id;
      // Atualizar status
      await db.query(
        'UPDATE candidaturas SET status=$1, updated_at=now() WHERE id=$2',
        [decision, applicationId]
      );
    } else {
      const ins = await db.query(
        `INSERT INTO candidaturas (company_id, job_id, candidate_id, status, created_at)
         VALUES ($1,$2,$3,$4, now()) RETURNING id`,
        [companyId, jobId, candidateId, decision]
      );
      applicationId = ins.rows[0].id;
    }

    // 3. Se for Entrevista, criar registro em 'entrevistas'
    let interviewId = null;
    if (decision === 'ENTREVISTA_AGENDADA') {
      // Verificar se já existe entrevista aberta para não duplicar
      const existingInterview = await db.query(
        `SELECT id FROM entrevistas 
         WHERE application_id=$1 AND status NOT IN ('cancelled', 'completed', 'missed') 
         LIMIT 1`,
        [applicationId]
      );

      if (existingInterview.rows[0]) {
        interviewId = existingInterview.rows[0].id;
      } else {
        const scheduledAt = schedule?.dataHora ? new Date(schedule.dataHora).toISOString() : null;
        const insInterview = await db.query(
          `INSERT INTO entrevistas (
             company_id, application_id, status, scheduled_at, created_at
           ) VALUES ($1, $2, 'scheduled', $3, now()) RETURNING id`,
          [companyId, applicationId, scheduledAt]
        );
        interviewId = insInterview.rows[0].id;
      }
    }

    res.json({
      data: {
        message: 'Decisão registrada com sucesso',
        application_id: applicationId,
        interview_id: interviewId,
        status: decision
      }
    });

  } catch (error) {
    console.error('❌ Erro ao registrar decisão:', error);
    res.status(500).json({ erro: 'Falha ao registrar decisão', detalhes: error.message });
  }
});

module.exports = router;
