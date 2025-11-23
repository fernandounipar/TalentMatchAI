const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');
const { gerarPerguntasEntrevista, responderChatEntrevista, gerarRelatorioEntrevista } = require('../../servicos/iaService');

router.use(exigirAutenticacao);

function isoOrNull(v) {
  if (!v) return null;
  try { return new Date(v).toISOString(); } catch { return null; }
}

async function findOrCreateApplication(companyId, jobId, candidateId) {
  const exists = await db.query(
    'SELECT id FROM applications WHERE company_id=$1 AND job_id=$2 AND candidate_id=$3 LIMIT 1',
    [companyId, jobId, candidateId]
  );
  if (exists.rows[0]) return exists.rows[0].id;
  const ins = await db.query(
    `INSERT INTO applications (company_id, job_id, candidate_id, status, created_at)
     VALUES ($1,$2,$3,'open', now()) RETURNING id`,
    [companyId, jobId, candidateId]
  );
  return ins.rows[0].id;
}

async function createCalendarEvent(companyId, interviewId, startsAt, endsAt) {
  const ics = 'ics_' + Math.random().toString(36).slice(2) + Date.now().toString(36);
  const r = await db.query(
    `INSERT INTO calendar_events (company_id, interview_id, ics_uid, starts_at, ends_at, created_at)
     VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
    [companyId, interviewId, ics, startsAt, endsAt]
  );
  return r.rows[0];
}

// Listar entrevistas (agenda) - RF8 ENHANCED
router.get('/', async (req, res) => {
  try {
    const { status, job_id, candidate_id, from, to, result, interviewer_id, mode, page = 1, limit = 50 } = req.query;
    const params = [req.usuario.company_id];
    let sql = `SELECT i.*, a.job_id, a.candidate_id,
                  j.title AS job_title, c.full_name AS candidate_name,
                  u.full_name AS interviewer_name
               FROM interviews i
               JOIN applications a ON a.id = i.application_id
               JOIN jobs j ON j.id = a.job_id
               JOIN candidates c ON c.id = a.candidate_id
               LEFT JOIN users u ON u.id = i.interviewer_id
               WHERE i.company_id = $1 AND i.deleted_at IS NULL`;
    if (status) { params.push(String(status).toLowerCase()); sql += ` AND i.status = $${params.length}`; }
    if (job_id) { params.push(job_id); sql += ` AND a.job_id = $${params.length}`; }
    if (candidate_id) { params.push(candidate_id); sql += ` AND a.candidate_id = $${params.length}`; }
    if (result) { params.push(String(result).toLowerCase()); sql += ` AND i.result = $${params.length}`; }
    if (interviewer_id) { params.push(interviewer_id); sql += ` AND i.interviewer_id = $${params.length}`; }
    if (mode) { params.push(String(mode).toLowerCase()); sql += ` AND i.mode = $${params.length}`; }
    if (from) { params.push(new Date(from)); sql += ` AND i.scheduled_at >= $${params.length}`; }
    if (to) { params.push(new Date(to)); sql += ` AND i.scheduled_at <= $${params.length}`; }
    params.push(Number(limit));
    params.push((Number(page) - 1) * Number(limit));
    sql += ` ORDER BY i.scheduled_at ASC NULLS LAST, i.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;
    const r = await db.query(sql, params);
    res.json({
      data: r.rows,
      meta: {
        page: Number(page),
        limit: Number(limit)
      }
    });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao listar entrevistas' });
  }
});

// Agendar entrevista - RF8 ENHANCED
router.post('/', async (req, res) => {
  try {
    const { job_id, candidate_id, scheduled_at, ends_at, mode, interviewer_id, notes, metadata } = req.body || {};
    if (!job_id || !candidate_id || !scheduled_at) return res.status(400).json({ erro: 'Campos obrigatórios: job_id, candidate_id, scheduled_at' });
    const applicationId = await findOrCreateApplication(req.usuario.company_id, job_id, candidate_id);
    const st = isoOrNull(scheduled_at);
    const et = isoOrNull(ends_at) || new Date(new Date(st).getTime() + 60 * 60 * 1000).toISOString();
    const r = await db.query(
      `INSERT INTO interviews (company_id, application_id, scheduled_at, mode, status, interviewer_id, notes, metadata, created_at, updated_at)
       VALUES ($1,$2,$3,$4,'scheduled',$5,$6,$7::jsonb, now(), now()) RETURNING *`,
      [req.usuario.company_id, applicationId, st, (mode || 'online').toLowerCase(), interviewer_id || null, notes || null, JSON.stringify(metadata || {})]
    );
    const interview = r.rows[0];
    await createCalendarEvent(req.usuario.company_id, interview.id, st, et);
    await audit(req, 'create', 'interview', interview.id, { job_id, candidate_id, scheduled_at: st, mode, interviewer_id, notes });
    res.status(201).json({ data: interview });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao agendar entrevista' });
  }
});

// Atualizar entrevista (horário/modo/status/result/score/notes/duration/cancellation) - RF8 ENHANCED
router.put('/:id', async (req, res) => {
  try {
    const { scheduled_at, ends_at, mode, status, result, overall_score, notes, duration_minutes, cancellation_reason, interviewer_id, metadata } = req.body || {};
    const r = await db.query('SELECT * FROM interviews WHERE id=$1 AND company_id=$2 AND deleted_at IS NULL', [req.params.id, req.usuario.company_id]);
    const current = r.rows[0];
    if (!current) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    const st = scheduled_at ? isoOrNull(scheduled_at) : null;
    const et = ends_at ? isoOrNull(ends_at) : null;
    const up = await db.query(
      `UPDATE interviews SET
         scheduled_at = COALESCE($1, scheduled_at),
         mode = COALESCE($2, mode),
         status = COALESCE($3, status),
         result = COALESCE($4, result),
         overall_score = COALESCE($5, overall_score),
         notes = COALESCE($6, notes),
         duration_minutes = COALESCE($7, duration_minutes),
         cancellation_reason = COALESCE($8, cancellation_reason),
         interviewer_id = COALESCE($9, interviewer_id),
         metadata = COALESCE($10::jsonb, metadata),
         updated_at = now()
       WHERE id=$11 AND company_id=$12 RETURNING *`,
      [
        st,
        mode ? String(mode).toLowerCase() : null,
        status ? String(status).toLowerCase() : null,
        result ? String(result).toLowerCase() : null,
        overall_score !== undefined ? Number(overall_score) : null,
        notes !== undefined ? notes : null,
        duration_minutes !== undefined ? Number(duration_minutes) : null,
        cancellation_reason !== undefined ? cancellation_reason : null,
        interviewer_id !== undefined ? interviewer_id : null,
        metadata ? JSON.stringify(metadata) : null,
        req.params.id,
        req.usuario.company_id
      ]
    );
    if (st || et) {
      // Atualiza calendar_events vinculado
      await db.query(
        `UPDATE calendar_events SET starts_at = COALESCE($1, starts_at), ends_at = COALESCE($2, ends_at)
         WHERE interview_id = $3 AND company_id = $4`,
        [st, et, req.params.id, req.usuario.company_id]
      );
    }
    await audit(req, 'update', 'interview', req.params.id, { scheduled_at: st, mode, status, result, overall_score, notes, duration_minutes, cancellation_reason });
    res.json({ data: up.rows[0] });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao atualizar entrevista' });
  }
});

// Buscar detalhes de uma entrevista específica - RF8 NEW
router.get('/:id', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT i.*, a.job_id, a.candidate_id,
              j.title AS job_title, c.full_name AS candidate_name,
              u.full_name AS interviewer_name
       FROM interviews i
       JOIN applications a ON a.id = i.application_id
       JOIN jobs j ON j.id = a.job_id
       JOIN candidates c ON c.id = a.candidate_id
       LEFT JOIN users u ON u.id = i.interviewer_id
       WHERE i.id = $1 AND i.company_id = $2 AND i.deleted_at IS NULL`,
      [req.params.id, req.usuario.company_id]
    );
    if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    res.json({ data: r.rows[0] });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao buscar entrevista' });
  }
});

// Deletar entrevista (soft delete) - RF8 NEW
router.delete('/:id', async (req, res) => {
  try {
    const r = await db.query('SELECT id FROM interviews WHERE id=$1 AND company_id=$2 AND deleted_at IS NULL', [req.params.id, req.usuario.company_id]);
    if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    await db.query('UPDATE interviews SET deleted_at = now(), updated_at = now() WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    await audit(req, 'delete', 'interview', req.params.id, {});
    res.json({ data: { mensagem: 'Entrevista removida com sucesso' } });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao remover entrevista' });
  }
});

// Criar sessão de entrevista (opcional) com transcript_file_id
router.post('/:id/session', async (req, res) => {
  try {
    const { transcript_file_id } = req.body || {};
    // Ensure interview exists
    const r = await db.query('SELECT id FROM interviews WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    const s = await db.query(
      `INSERT INTO interview_sessions (company_id, interview_id, started_at, transcript_file_id)
       VALUES ($1,$2, now(), $3) RETURNING *`,
      [req.usuario.company_id, req.params.id, transcript_file_id || null]
    );
    res.status(201).json({ data: s.rows[0] });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao criar sessão' });
  }
});

// Gerar perguntas de entrevista com IA (migrado do legado)
const perguntasHandler = async (req, res) => {
  try {
    const id = req.params.id;
    const e = await db.query(
      `SELECT i.id, j.description AS vaga_desc, r.parsed_text AS texto_curriculo, ra.summary AS analise_json
         FROM interviews i
         JOIN applications a ON a.id = i.application_id
         LEFT JOIN jobs j ON j.id = a.job_id
         LEFT JOIN LATERAL (
           SELECT res.parsed_text, res.id as resume_id
             FROM resumes res
            WHERE res.candidate_id = a.candidate_id
              AND res.company_id = i.company_id
              AND res.deleted_at IS NULL
            ORDER BY res.created_at DESC
            LIMIT 1
         ) r ON TRUE
         LEFT JOIN LATERAL (
           SELECT ra.summary
             FROM resume_analysis ra
            WHERE ra.resume_id = r.resume_id
            ORDER BY ra.created_at DESC
            LIMIT 1
         ) ra ON TRUE
        WHERE i.id=$1 AND i.company_id=$2`,
      [id, req.usuario.company_id]
    );
    const row = e.rows[0];
    if (!row) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    const analise = row.analise_json || {};
    const qs = await gerarPerguntasEntrevista({
      resumo: analise.summary || '',
      skills: analise.skills || [],
      vaga: row.vaga_desc || '',
      quantidade: Number(req.query.qtd || 8),
      companyId: req.usuario.company_id,
    });
    // Persistir perguntas em tabela interview_questions se existir
    const perguntas = [];
    for (const texto of qs) {
      const insert = await db.query(
        `INSERT INTO interview_questions (company_id, interview_id, text, created_at)
           VALUES ($1,$2,$3, now())
           RETURNING id, text, created_at`,
        [req.usuario.company_id, id, texto]
      );
      perguntas.push(insert.rows[0]);
    }
    res.json({ data: perguntas });
  } catch (error) {
    console.error('Erro ao gerar perguntas:', error);
    res.status(500).json({ erro: 'Falha ao gerar perguntas' });
  }
};

router.post('/:id/perguntas', perguntasHandler);
router.post('/:id/questions', perguntasHandler);

// Listar perguntas existentes
router.get('/:id/questions', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT id, text, created_at
         FROM interview_questions
        WHERE interview_id = $1 AND company_id = $2
        ORDER BY created_at ASC`,
      [req.params.id, req.usuario.company_id]
    );
    res.json({ data: r.rows });
  } catch (error) {
    res.status(500).json({ erro: 'Falha ao listar perguntas' });
  }
});

// Chat de entrevista com IA (migrado do legado)
router.post('/:id/chat', async (req, res) => {
  try {
    const id = req.params.id;
    const { mensagem } = req.body || {};
    if (!mensagem || String(mensagem).trim() === '') {
      return res.status(400).json({ erro: 'Mensagem obrigatória' });
    }

    // Carregar contexto da entrevista
    const e = await db.query(
      `SELECT i.id, j.description AS vaga_desc, r.parsed_text AS texto, ra.summary AS analise_json
         FROM interviews i
         JOIN applications a ON a.id = i.application_id
         LEFT JOIN jobs j ON j.id = a.job_id
         LEFT JOIN LATERAL (
           SELECT res.parsed_text, res.id as resume_id
             FROM resumes res
            WHERE res.candidate_id = a.candidate_id
              AND res.company_id = i.company_id
              AND res.deleted_at IS NULL
            ORDER BY res.created_at DESC
            LIMIT 1
         ) r ON TRUE
         LEFT JOIN LATERAL (
           SELECT ra.summary
             FROM resume_analysis ra
            WHERE ra.resume_id = r.resume_id
            ORDER BY ra.created_at DESC
            LIMIT 1
         ) ra ON TRUE
        WHERE i.id=$1 AND i.company_id=$2`,
      [id, req.usuario.company_id]
    );
    const row = e.rows[0];
    if (!row) return res.status(404).json({ erro: 'Entrevista não encontrada' });

    // Buscar histórico recente
    const hist = await db.query(
      'SELECT role, conteudo FROM mensagens WHERE entrevista_id=$1 AND company_id=$2 ORDER BY criado_em ASC LIMIT 50',
      [id, req.usuario.company_id]
    );

    // Persistir mensagem do usuário
    const insUser = await db.query(
      'INSERT INTO mensagens (entrevista_id, role, conteudo, company_id, criado_em) VALUES ($1,$2,$3,$4, now()) RETURNING id, role, conteudo, criado_em',
      [id, 'user', String(mensagem), req.usuario.company_id]
    );

    // Gerar resposta via IA
    const resposta = await responderChatEntrevista({
      historico: hist.rows,
      mensagemAtual: String(mensagem),
      analise: row.analise_json || {},
      vagaDesc: row.vaga_desc || '',
      textoCurriculo: row.texto ? String(row.texto).slice(0, 5000) : '',
      companyId: req.usuario.company_id,
    });

    const conteudoResposta = Array.isArray(resposta) ? resposta.join('\n') : String(resposta);

    // Persistir resposta do assistant
    const insIA = await db.query(
      'INSERT INTO mensagens (entrevista_id, role, conteudo, company_id, criado_em) VALUES ($1,$2,$3,$4, now()) RETURNING id, role, conteudo, criado_em',
      [id, 'assistant', conteudoResposta, req.usuario.company_id]
    );

    res.json({
      data: {
        enviada: insUser.rows[0],
        resposta: insIA.rows[0],
      }
    });
  } catch (error) {
    console.error('Erro no chat da entrevista:', error);
    res.status(500).json({ erro: 'Falha no chat da entrevista' });
  }
});

// Histórico de mensagens do chat
router.get('/:id/messages', async (req, res) => {
  try {
    const msgs = await db.query(
      'SELECT id, role, conteudo, criado_em FROM mensagens WHERE entrevista_id=$1 AND company_id=$2 ORDER BY criado_em ASC',
      [req.params.id, req.usuario.company_id]
    );
    res.json({ data: msgs.rows });
  } catch (error) {
    res.status(500).json({ erro: 'Falha ao listar mensagens' });
  }
});

// Relatório de entrevista (RF7) - gerar e obter
router.post('/:id/report', async (req, res) => {
  try {
    const id = req.params.id;
    // Verifica se entrevista existe
    const interview = await db.query(
      `SELECT i.id, i.company_id, a.job_id, a.candidate_id, j.title as job_title, c.full_name as candidate_name
         FROM interviews i
         JOIN applications a ON a.id = i.application_id
         JOIN jobs j ON j.id = a.job_id
         JOIN candidates c ON c.id = a.candidate_id
        WHERE i.id = $1 AND i.company_id = $2`,
      [id, req.usuario.company_id]
    );
    if (!interview.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });

    // Coletar respostas/feedback simplificados
    const respostas = []; // placeholder se necessário
    const feedbacks = [];

    const aiReport = await gerarRelatorioEntrevista({
      candidato: interview.rows[0].candidate_name || 'Candidato',
      vaga: interview.rows[0].job_title || 'Vaga',
      respostas,
      feedbacks,
      companyId: req.usuario.company_id
    });

    const versionQuery = await db.query(
      `SELECT COALESCE(MAX(version), 0) + 1 as next_version
         FROM interview_reports
        WHERE interview_id = $1 AND company_id = $2`,
      [id, req.usuario.company_id]
    );
    const version = versionQuery.rows[0].next_version;

    const insert = await db.query(
      `INSERT INTO interview_reports (
         company_id, interview_id, title, report_type, content,
         summary_text, candidate_name, job_title, overall_score, recommendation,
         strengths, weaknesses, risks, format, generated_by, generated_at, is_final, version, created_by
       ) VALUES (
         $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15, now(), $16, $17, $18
       ) RETURNING *`,
      [
        req.usuario.company_id,
        id,
        aiReport.title || `Relatório de Entrevista v${version}`,
        aiReport.report_type || 'full',
        JSON.stringify(aiReport),
        aiReport.summary_text || aiReport.summary || null,
        interview.rows[0].candidate_name,
        interview.rows[0].job_title,
        aiReport.overall_score || null,
        aiReport.recommendation || 'PENDING',
        aiReport.strengths || [],
        aiReport.weaknesses || [],
        aiReport.risks || [],
        aiReport.format || 'json',
        req.usuario.id,
        req.body?.is_final ?? false,
        version,
        req.usuario.id
      ]
    );

    res.status(201).json({ data: insert.rows[0] });
  } catch (error) {
    console.error('Erro ao gerar relatório:', error);
    res.status(500).json({ erro: 'Falha ao gerar relatório' });
  }
});

router.get('/:id/report', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT * FROM interview_reports WHERE interview_id = $1 AND company_id = $2 ORDER BY created_at DESC LIMIT 1`,
      [req.params.id, req.usuario.company_id]
    );
    if (!r.rows[0]) return res.status(404).json({ erro: 'Relatório não encontrado' });
    res.json({ data: r.rows[0] });
  } catch (error) {
    res.status(500).json({ erro: 'Falha ao obter relatório' });
  }
});

module.exports = router;

// ===== Perguntas (AI/MANUAL) e Respostas =====

// Listar perguntas
router.get('/:id/questions', async (req, res) => {
  const r = await db.query(
    `SELECT q.* FROM interview_questions q
      WHERE q.company_id=$1 AND q.interview_id=$2
      ORDER BY q.created_at ASC`,
    [req.usuario.company_id, req.params.id]
  );
  res.json(r.rows);
});

// Criar perguntas (manual ou gerar via IA)
router.post('/:id/questions', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const interviewId = req.params.id;
    const { origin, kind, prompt, generate_ai } = req.body || {};

    if (generate_ai) {
      // carrega contexto (vaga/analise) para IA
      const ctx = await db.query(
        `SELECT a.id as app_id, j.description AS vaga_desc, COALESCE(r.parsed_json,'{}'::jsonb) AS analise
           FROM interviews i
           JOIN applications a ON a.id = i.application_id
           LEFT JOIN resumes r ON r.company_id=i.company_id AND r.candidate_id=a.candidate_id
          WHERE i.id=$1 AND i.company_id=$2
          LIMIT 1`,
        [interviewId, companyId]
      );
      const row = ctx.rows[0] || {};
      const analise = row.analise || {};
      const qs = await gerarPerguntasEntrevista({
        resumo: analise.summary || '',
        skills: analise.skills || [],
        vaga: row.vaga_desc || '',
        quantidade: Number(req.query.qtd || 8),
        companyId,
      });
      const inserted = [];
      for (const text of qs) {
        const ins = await db.query(
          `INSERT INTO interview_questions (company_id, interview_id, origin, kind, prompt, created_at)
           VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
          [companyId, interviewId, 'AI', kind || 'TECNICA', String(text)]
        );
        inserted.push(ins.rows[0]);
      }
      return res.json(inserted);
    }

    if (!prompt) return res.status(400).json({ erro: 'prompt obrigatório' });
    const ins = await db.query(
      `INSERT INTO interview_questions (company_id, interview_id, origin, kind, prompt, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
      [companyId, interviewId, (origin || 'MANUAL'), (kind || 'TECNICA'), String(prompt)]
    );
    res.status(201).json(ins.rows[0]);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao criar perguntas' });
  }
});

// Listar respostas
router.get('/:id/answers', async (req, res) => {
  const r = await db.query(
    `SELECT a.*, q.prompt AS question_prompt
       FROM interview_answers a
       LEFT JOIN interview_questions q ON q.id = a.question_id AND q.company_id = a.company_id
      WHERE a.company_id=$1 AND (a.session_id IS NULL OR a.session_id IS NOT NULL) AND q.interview_id = $2
      ORDER BY a.created_at ASC`,
    [req.usuario.company_id, req.params.id]
  );
  res.json(r.rows);
});

// Registrar resposta
router.post('/:id/answers', async (req, res) => {
  try {
    const { question_id, session_id, raw_text, audio_file_id } = req.body || {};
    if (!question_id || !raw_text) return res.status(400).json({ erro: 'question_id e raw_text são obrigatórios' });
    // valida question pertence à entrevista e tenant
    const q = await db.query('SELECT id FROM interview_questions WHERE id=$1 AND company_id=$2 AND interview_id=$3', [question_id, req.usuario.company_id, req.params.id]);
    if (!q.rows[0]) return res.status(400).json({ erro: 'Pergunta inválida' });
    const ins = await db.query(
      `INSERT INTO interview_answers (company_id, question_id, session_id, raw_text, audio_file_id, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
      [req.usuario.company_id, question_id, session_id || null, String(raw_text), audio_file_id || null]
    );
    res.status(201).json(ins.rows[0]);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao registrar resposta' });
  }
});

// Gerar feedback de IA para respostas sem avaliação
router.post('/:id/ai-feedback', async (req, res) => {
  try {
    const interviewId = req.params.id;
    const ans = await db.query(
      `SELECT a.id as answer_id, a.raw_text, q.prompt
         FROM interview_answers a
         JOIN interview_questions q ON q.id = a.question_id
        WHERE a.company_id=$1 AND q.interview_id=$2
          AND NOT EXISTS (SELECT 1 FROM ai_feedback f WHERE f.answer_id = a.id AND f.company_id=$1)`,
      [req.usuario.company_id, interviewId]
    );
    const inserted = [];
    for (const row of ans.rows) {
      const fb = await avaliarResposta({
        pergunta: row.prompt,
        resposta: row.raw_text,
        companyId: req.usuario.company_id,
      });
      const ins = await db.query(
        `INSERT INTO ai_feedback (company_id, answer_id, score, verdict, rationale_text, suggested_followups, created_at)
         VALUES ($1,$2,$3,$4,$5,$6::jsonb, now()) RETURNING *`,
        [req.usuario.company_id, row.answer_id, fb.score || 0, (fb.verdict || 'ADEQUADO'), fb.rationale_text || '', JSON.stringify(fb.suggested_followups || [])]
      );
      inserted.push(ins.rows[0]);
    }
    res.json(inserted);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao gerar feedback' });
  }
});

// Listar feedback
router.get('/:id/ai-feedback', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT f.* FROM ai_feedback f
         JOIN interview_answers a ON a.id = f.answer_id
         JOIN interview_questions q ON q.id = a.question_id
        WHERE f.company_id=$1 AND q.interview_id=$2
        ORDER BY f.created_at ASC`,
      [req.usuario.company_id, req.params.id]
    );
    res.json(r.rows);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao listar feedback' });
  }
});

// Gerar relatório de entrevista (composto)
router.post('/:id/report', async (req, res) => {
  try {
    const interviewId = req.params.id;
    const base = await db.query(
      `SELECT i.id, c.full_name AS candidato, j.title AS vaga
         FROM interviews i
         JOIN applications a ON a.id = i.application_id
         JOIN candidates c ON c.id = a.candidate_id
         JOIN jobs j ON j.id = a.job_id
        WHERE i.id=$1 AND i.company_id=$2`,
      [interviewId, req.usuario.company_id]
    );
    if (!base.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    // coleta respostas e feedbacks
    const respostas = await db.query(
      `SELECT a.id, q.prompt, a.raw_text FROM interview_answers a
        JOIN interview_questions q ON q.id = a.question_id
       WHERE a.company_id=$1 AND q.interview_id=$2
       ORDER BY a.created_at ASC`,
      [req.usuario.company_id, interviewId]
    );
    const feedbacks = await db.query(
      `SELECT f.* FROM ai_feedback f
        JOIN interview_answers a ON a.id = f.answer_id
        JOIN interview_questions q ON q.id = a.question_id
       WHERE f.company_id=$1 AND q.interview_id=$2
       ORDER BY f.created_at ASC`,
      [req.usuario.company_id, interviewId]
    );
    // Se não houver feedback, gera agora
    if (feedbacks.rows.length === 0) {
      await db.query('SELECT 1'); // noop
      await (await fetch('http://localhost/')).catch(()=>{});
    }
    const report = await gerarRelatorioEntrevista({
      candidato: base.rows[0].candidato,
      vaga: base.rows[0].vaga,
      respostas: respostas.rows,
      feedbacks: feedbacks.rows,
      companyId: req.usuario.company_id,
    });
    // Persistir em interview_reports
    const ins = await db.query(
      `INSERT INTO interview_reports (company_id, interview_id, summary_text, strengths, risks, recommendation, created_at)
       VALUES ($1,$2,$3,$4::jsonb,$5::jsonb,$6, now())
       ON CONFLICT (interview_id) DO UPDATE SET summary_text=EXCLUDED.summary_text, strengths=EXCLUDED.strengths, risks=EXCLUDED.risks, recommendation=EXCLUDED.recommendation, created_at=EXCLUDED.created_at
       RETURNING *`,
      [req.usuario.company_id, interviewId, report.summary_text || '', JSON.stringify(report.strengths || []), JSON.stringify(report.risks || []), report.recommendation || 'DÚVIDA']
    );
    res.json(ins.rows[0]);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao gerar relatório' });
  }
});

// Obter relatório
router.get('/:id/report', async (req, res) => {
  const r = await db.query('SELECT * FROM interview_reports WHERE interview_id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
  res.json(r.rows[0] || null);
});
