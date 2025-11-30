const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');
const { gerarPerguntasEntrevista, responderChatEntrevista, gerarRelatorioEntrevista } = require('../../servicos/iaService');
const { agora, agoraISO, formatarParaISO } = require('../../utils/dateUtils');

router.use(exigirAutenticacao);

function isoOrNull(v) {
  if (!v) return null;
  try {
    // Preservar o horario como foi enviado (interpretando como horario de Brasilia)
    const d = new Date(v);
    if (isNaN(d.getTime())) return null;
    
    // Se a string original nao tem indicador de timezone (Z ou +/-),
    // interpretar como horario de Brasilia e formatar com offset -03:00
    const str = v.toString();
    if (!str.includes('Z') && !str.match(/[+-]\d{2}:\d{2}$/)) {
      // Formato sem timezone - interpretar como Brasilia
      return formatarParaISO(d);
    }
    return d.toISOString();
  } catch {
    return null;
  }
}

function normalizeStringList(value) {
  if (value === null || value === undefined) return [];
  if (Array.isArray(value)) {
    return value.map((v) => v === null || v === undefined ? '' : String(v)).filter((v) => v.trim().length > 0);
  }
  if (typeof value === 'string') return value.trim().length > 0 ? [value] : [];
  return [];
}

async function findOrCreateApplication(companyId, jobId, candidateId) {
  const exists = await db.query(
    'SELECT id FROM candidaturas WHERE company_id=$1 AND job_id=$2 AND candidate_id=$3 LIMIT 1',
    [companyId, jobId, candidateId]
  );
  if (exists.rows[0]) return exists.rows[0].id;
  const ins = await db.query(
    `INSERT INTO candidaturas (company_id, job_id, candidate_id, status, created_at)
     VALUES ($1,$2,$3,'open', now()) RETURNING id`,
    [companyId, jobId, candidateId]
  );
  return ins.rows[0].id;
}

async function createCalendarEvent(companyId, interviewId, startsAt, endsAt) {
  const ics = 'ics_' + Math.random().toString(36).slice(2) + Date.now().toString(36);
  const r = await db.query(
    `INSERT INTO eventos_calendario (company_id, interview_id, ics_uid, starts_at, ends_at, created_at)
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
               FROM entrevistas i
               JOIN candidaturas a ON a.id = i.application_id
               JOIN vagas j ON j.id = a.job_id
               JOIN candidatos c ON c.id = a.candidate_id
               LEFT JOIN usuarios u ON u.id = i.interviewer_id
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
      `INSERT INTO entrevistas (company_id, application_id, scheduled_at, mode, status, interviewer_id, notes, metadata, created_at, updated_at)
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
    const r = await db.query('SELECT * FROM entrevistas WHERE id=$1 AND company_id=$2 AND deleted_at IS NULL', [req.params.id, req.usuario.company_id]);
    const current = r.rows[0];
    if (!current) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    const st = scheduled_at ? isoOrNull(scheduled_at) : null;
    const et = ends_at ? isoOrNull(ends_at) : null;
    const up = await db.query(
      `UPDATE entrevistas SET
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
        `UPDATE eventos_calendario SET starts_at = COALESCE($1, starts_at), ends_at = COALESCE($2, ends_at)
         WHERE interview_id = $3 AND company_id = $4`,
        [st, et, req.params.id, req.usuario.company_id]
      );
    }

    // RF7: Se status mudou para 'completed', garantir que existe relatório
    if (status && String(status).toLowerCase() === 'completed') {
      const checkReport = await db.query(
        'SELECT id FROM relatorios_entrevista WHERE interview_id = $1 AND company_id = $2 LIMIT 1',
        [req.params.id, req.usuario.company_id]
      );

      if (!checkReport.rows[0]) {
        // Buscar detalhes para gerar relatório
        const interviewDetails = await db.query(
          `SELECT i.id, j.title as job_title, c.full_name as candidate_name
             FROM entrevistas i
             JOIN candidaturas a ON a.id = i.application_id
             JOIN vagas j ON j.id = a.job_id
             JOIN candidatos c ON c.id = a.candidate_id
            WHERE i.id = $1 AND i.company_id = $2`,
          [req.params.id, req.usuario.company_id]
        );

        if (interviewDetails.rows[0]) {
          const det = interviewDetails.rows[0];
          
          // ===== MELHORIA: Buscar respostas da entrevista =====
          const respostasQuery = await db.query(`
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
          `, [req.params.id]);

          const respostas = respostasQuery.rows.map(r => ({
            pergunta: r.question_text,
            tipo: r.question_type,
            resposta: r.answer_text,
            score: r.score_final
          }));

          const feedbacks = respostasQuery.rows
            .filter(r => r.feedback_auto || r.feedback_manual || r.score_final)
            .map(r => {
              const autoFeedback = r.feedback_auto || {};
              return {
                topic: r.question_type || 'Pergunta',
                question: r.question_text,
                answer: r.answer_text,
                score: r.score_final || autoFeedback.nota || 0,
                verdict: r.score_final >= 8 ? 'FORTE' : (r.score_final >= 6 ? 'OK' : 'FRACO'),
                comment: r.feedback_manual || autoFeedback.feedback || ''
              };
            });

          // Buscar mensagens do chat se não houver respostas formais
          if (respostas.length === 0) {
            const mensagensQuery = await db.query(`
              SELECT sender, message, created_at
              FROM mensagens_entrevista
              WHERE interview_id = $1 AND company_id = $2
              ORDER BY created_at ASC
            `, [req.params.id, req.usuario.company_id]);

            const msgs = mensagensQuery.rows;
            for (let i = 0; i < msgs.length - 1; i++) {
              if (msgs[i].sender === 'assistant' && msgs[i + 1]?.sender === 'user') {
                respostas.push({
                  pergunta: msgs[i].message,
                  tipo: 'chat',
                  resposta: msgs[i + 1].message,
                  score: null
                });
              }
            }
          }

          console.log(`[RF7] Auto-gerando relatório para entrevista ${req.params.id} - ${respostas.length} respostas, ${feedbacks.length} feedbacks`);

          const aiReport = await gerarRelatorioEntrevista({
            candidato: det.candidate_name,
            vaga: det.job_title,
            respostas,
            feedbacks,
            companyId: req.usuario.company_id
          });

          const versionQuery = await db.query(
            `SELECT COALESCE(MAX(version), 0) + 1 as next_version
               FROM relatorios_entrevista
              WHERE interview_id = $1 AND company_id = $2`,
            [req.params.id, req.usuario.company_id]
          );
          const version = versionQuery.rows[0].next_version;

          await db.query(
            `INSERT INTO relatorios_entrevista (
               company_id, interview_id, title, report_type, content,
               summary_text, candidate_name, job_title, overall_score, recommendation,
               strengths, weaknesses, risks, format, generated_by, generated_at, is_final, version, created_by
             ) VALUES (
               $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15, now(), $16, $17, $18
             )`,
            [
              req.usuario.company_id,
              req.params.id,
              aiReport.title || `Relatório de Entrevista v${version}`,
              aiReport.report_type || 'full',
              JSON.stringify(aiReport),
              aiReport.summary_text || aiReport.summary || null,
              det.candidate_name,
              det.job_title,
              aiReport.overall_score || null,
              aiReport.recommendation || 'PENDING',
              aiReport.strengths || [],
              aiReport.weaknesses || [],
              aiReport.risks || [],
              aiReport.format || 'json',
              req.usuario.id,
              true, // is_final
              version,
              req.usuario.id
            ]
          );
        }
      }
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
       FROM entrevistas i
       JOIN candidaturas a ON a.id = i.application_id
       JOIN vagas j ON j.id = a.job_id
       JOIN candidatos c ON c.id = a.candidate_id
       LEFT JOIN usuarios u ON u.id = i.interviewer_id
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
    const r = await db.query('SELECT id FROM entrevistas WHERE id=$1 AND company_id=$2 AND deleted_at IS NULL', [req.params.id, req.usuario.company_id]);
    if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    await db.query('UPDATE entrevistas SET deleted_at = now(), updated_at = now() WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
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
    const r = await db.query('SELECT id FROM entrevistas WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
    const s = await db.query(
      `INSERT INTO sessoes_entrevista (company_id, interview_id, started_at, transcript_file_id)
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
         FROM entrevistas i
         JOIN candidaturas a ON a.id = i.application_id
         LEFT JOIN vagas j ON j.id = a.job_id
         LEFT JOIN LATERAL (
           SELECT res.parsed_text, res.id as resume_id
             FROM curriculos res
            WHERE res.candidate_id = a.candidate_id
              AND res.company_id = i.company_id
              AND res.deleted_at IS NULL
            ORDER BY res.created_at DESC
            LIMIT 1
         ) r ON TRUE
         LEFT JOIN LATERAL (
           SELECT ra.summary
             FROM analise_curriculos ra
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

    // Persistir perguntas na tabela perguntas_entrevista
    const perguntas = [];
    for (const pergunta of qs) {
      // Suporta tanto objeto { texto, kind } quanto string (retrocompatibilidade)
      const textoP = typeof pergunta === 'string' ? pergunta : (pergunta.texto || pergunta);
      const kindP = typeof pergunta === 'object' && pergunta.kind ? pergunta.kind : 'TECNICA';
      
      const insert = await db.query(
        `INSERT INTO perguntas_entrevista (company_id, interview_id, text, origin, kind, prompt, created_at)
           VALUES ($1,$2,$3,'AI',$4,$5, now())
           RETURNING id, text, text AS prompt, kind, created_at`,
        [req.usuario.company_id, id, textoP, kindP, textoP]
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
      `SELECT id, text, text AS prompt, kind, created_at
         FROM perguntas_entrevista
        WHERE interview_id = $1 AND company_id = $2
        ORDER BY created_at ASC`,
      [req.params.id, req.usuario.company_id]
    );
    res.json({ data: r.rows });
  } catch (error) {
    res.status(500).json({ erro: 'Falha ao listar perguntas' });
  }
});

// Listar respostas de uma entrevista
router.get('/:id/answers', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT ra.id, ra.question_id, ra.raw_text, ra.created_at
         FROM respostas_entrevista ra
         JOIN perguntas_entrevista pe ON pe.id = ra.question_id
        WHERE pe.interview_id = $1 AND ra.company_id = $2
        ORDER BY ra.created_at ASC`,
      [req.params.id, req.usuario.company_id]
    );
    res.json({ data: r.rows });
  } catch (error) {
    console.error('Erro ao listar respostas:', error);
    res.status(500).json({ erro: 'Falha ao listar respostas' });
  }
});

// Criar resposta para uma pergunta
router.post('/:id/answers', async (req, res) => {
  try {
    const { question_id, raw_text } = req.body || {};
    if (!question_id) {
      return res.status(400).json({ erro: 'question_id é obrigatório' });
    }
    if (!raw_text || String(raw_text).trim() === '') {
      return res.status(400).json({ erro: 'raw_text é obrigatório' });
    }

    // Verificar se a pergunta pertence à entrevista
    const perguntaCheck = await db.query(
      `SELECT id FROM perguntas_entrevista 
        WHERE id = $1 AND interview_id = $2 AND company_id = $3`,
      [question_id, req.params.id, req.usuario.company_id]
    );
    if (perguntaCheck.rows.length === 0) {
      return res.status(404).json({ erro: 'Pergunta não encontrada nesta entrevista' });
    }

    const insert = await db.query(
      `INSERT INTO respostas_entrevista (company_id, question_id, raw_text, created_at)
         VALUES ($1, $2, $3, now())
         RETURNING id, question_id, raw_text, created_at`,
      [req.usuario.company_id, question_id, raw_text.trim()]
    );
    res.status(201).json({ data: insert.rows[0] });
  } catch (error) {
    console.error('Erro ao criar resposta:', error);
    res.status(500).json({ erro: 'Falha ao criar resposta' });
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
         FROM entrevistas i
         JOIN candidaturas a ON a.id = i.application_id
         LEFT JOIN vagas j ON j.id = a.job_id
         LEFT JOIN LATERAL (
           SELECT res.parsed_text, res.id as resume_id
             FROM curriculos res
            WHERE res.candidate_id = a.candidate_id
              AND res.company_id = i.company_id
              AND res.deleted_at IS NULL
            ORDER BY res.created_at DESC
            LIMIT 1
         ) r ON TRUE
         LEFT JOIN LATERAL (
           SELECT ra.summary
             FROM analise_curriculos ra
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
      'SELECT sender as role, message as conteudo FROM mensagens_entrevista WHERE interview_id=$1 AND company_id=$2 ORDER BY created_at ASC LIMIT 50',
      [id, req.usuario.company_id]
    );

    // Persistir mensagem do usuário
    const insUser = await db.query(
      'INSERT INTO mensagens_entrevista (interview_id, sender, message, company_id, created_at) VALUES ($1,$2,$3,$4, now()) RETURNING id, sender as role, message as conteudo, created_at as criado_em',
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
      'INSERT INTO mensagens_entrevista (interview_id, sender, message, company_id, created_at) VALUES ($1,$2,$3,$4, now()) RETURNING id, sender as role, message as conteudo, created_at as criado_em',
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
      'SELECT id, sender as role, message as conteudo, created_at as criado_em FROM mensagens_entrevista WHERE interview_id=$1 AND company_id=$2 ORDER BY created_at ASC',
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
         FROM entrevistas i
         JOIN candidaturas a ON a.id = i.application_id
         JOIN vagas j ON j.id = a.job_id
         JOIN candidatos c ON c.id = a.candidate_id
        WHERE i.id = $1 AND i.company_id = $2`,
      [id, req.usuario.company_id]
    );
    if (!interview.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });

    // ===== MELHORIA: Buscar respostas da entrevista =====
    const respostasQuery = await db.query(`
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
    `, [id]);

    const respostas = respostasQuery.rows.map(r => ({
      pergunta: r.question_text,
      tipo: r.question_type,
      resposta: r.answer_text,
      score: r.score_final
    }));

    // ===== MELHORIA: Buscar feedbacks das avaliações =====
    const feedbacks = respostasQuery.rows
      .filter(r => r.feedback_auto || r.feedback_manual || r.score_final)
      .map(r => {
        const autoFeedback = r.feedback_auto || {};
        return {
          topic: r.question_type || 'Pergunta',
          question: r.question_text,
          answer: r.answer_text,
          score: r.score_final || autoFeedback.nota || 0,
          verdict: r.score_final >= 8 ? 'FORTE' : (r.score_final >= 6 ? 'OK' : 'FRACO'),
          comment: r.feedback_manual || autoFeedback.feedback || ''
        };
      });

    // ===== MELHORIA: Buscar mensagens do chat da entrevista =====
    const mensagensQuery = await db.query(`
      SELECT sender, message, created_at
      FROM mensagens_entrevista
      WHERE interview_id = $1 AND company_id = $2
      ORDER BY created_at ASC
    `, [id, req.usuario.company_id]);

    // Adicionar contexto do chat às respostas se não houver respostas formais
    if (respostas.length === 0 && mensagensQuery.rows.length > 0) {
      // Extrair perguntas e respostas do chat
      const msgs = mensagensQuery.rows;
      for (let i = 0; i < msgs.length - 1; i++) {
        if (msgs[i].sender === 'assistant' && msgs[i + 1]?.sender === 'user') {
          respostas.push({
            pergunta: msgs[i].message,
            tipo: 'chat',
            resposta: msgs[i + 1].message,
            score: null
          });
        }
      }
    }

    console.log(`[RF7] Gerando relatório para entrevista ${id} - ${respostas.length} respostas, ${feedbacks.length} feedbacks`);

    const aiReport = await gerarRelatorioEntrevista({
      candidato: interview.rows[0].candidate_name || 'Candidato',
      vaga: interview.rows[0].job_title || 'Vaga',
      respostas,
      feedbacks,
      companyId: req.usuario.company_id
    });

    const versionQuery = await db.query(
      `SELECT COALESCE(MAX(version), 0) + 1 as next_version
         FROM relatorios_entrevista
        WHERE interview_id = $1 AND company_id = $2`,
      [id, req.usuario.company_id]
    );
    const version = versionQuery.rows[0].next_version;

    const strengths = normalizeStringList(aiReport.strengths);
    const weaknesses = normalizeStringList(aiReport.weaknesses || aiReport.weak_points);
    const risks = normalizeStringList(aiReport.risks || aiReport.alerts);
    const overallScore =
      typeof aiReport.overall_score === 'number'
        ? aiReport.overall_score
        : Number.isFinite(Number(aiReport.overall_score))
            ? Number(aiReport.overall_score)
            : null;
    
    // Converter recomendação de PT para EN (padrão do frontend)
    const ptToEnRecommendation = {
      'APROVAR': 'APPROVE',
      'DÚVIDA': 'MAYBE',
      'DUVIDA': 'MAYBE',
      'REPROVAR': 'REJECT',
      // Já em inglês
      'APPROVE': 'APPROVE',
      'MAYBE': 'MAYBE',
      'REJECT': 'REJECT',
      'PENDING': 'PENDING'
    };
    const rawRecommendation = typeof aiReport.recommendation === 'string'
      ? aiReport.recommendation.toUpperCase()
      : 'PENDING';
    const recommendation = ptToEnRecommendation[rawRecommendation] || 'PENDING';
    const content = {
      ...aiReport,
      strengths,
      weaknesses,
      risks,
      overall_score: overallScore,
      recommendation,
    };

    const insert = await db.query(
      `INSERT INTO relatorios_entrevista (
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
        JSON.stringify(content),
        aiReport.summary_text || aiReport.summary || null,
        interview.rows[0].candidate_name,
        interview.rows[0].job_title,
        overallScore,
        recommendation,
        JSON.stringify(strengths),
        JSON.stringify(weaknesses),
        JSON.stringify(risks),
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
      `SELECT * FROM relatorios_entrevista WHERE interview_id = $1 AND company_id = $2 ORDER BY created_at DESC LIMIT 1`,
      [req.params.id, req.usuario.company_id]
    );
    if (!r.rows[0]) return res.status(404).json({ erro: 'Relatório não encontrado' });
    res.json({ data: r.rows[0] });
  } catch (error) {
    res.status(500).json({ erro: 'Falha ao obter relatório' });
  }
});

module.exports = router;
