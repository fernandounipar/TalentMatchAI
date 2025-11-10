const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');

router.use(exigirAutenticacao);

async function getStageNameById(companyId, stageId) {
  const r = await db.query('SELECT name FROM pipeline_stages WHERE id=$1 AND company_id=$2', [stageId, companyId]);
  return r.rows[0]?.name || null;
}

// Listar applications com joins básicos
router.get('/', async (req, res) => {
  const { job_id, candidate_id, page = 1, limit = 50 } = req.query;
  const params = [req.usuario.company_id];
  let sql = `SELECT a.*, j.title AS job_title, c.full_name AS candidate_name
             FROM applications a
             JOIN jobs j ON j.id = a.job_id
             JOIN candidates c ON c.id = a.candidate_id
             WHERE a.company_id = $1`;
  if (job_id) { params.push(job_id); sql += ` AND a.job_id = $${params.length}`; }
  if (candidate_id) { params.push(candidate_id); sql += ` AND a.candidate_id = $${params.length}`; }
  params.push(Number(limit));
  params.push((Number(page) - 1) * Number(limit));
  sql += ` ORDER BY a.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;
  const r = await db.query(sql, params);
  res.json(r.rows);
});

// Criar application; se já existir para par (job_id, candidate_id), retorna existente
router.post('/', async (req, res) => {
  try {
    const { job_id, candidate_id, stage_id } = req.body || {};
    if (!job_id || !candidate_id) return res.status(400).json({ erro: 'Campos obrigatórios: job_id, candidate_id' });
    // Verifica existente
    const exists = await db.query(
      'SELECT id FROM applications WHERE company_id=$1 AND job_id=$2 AND candidate_id=$3 LIMIT 1',
      [req.usuario.company_id, job_id, candidate_id]
    );
    if (exists.rows[0]) {
      return res.json({ id: exists.rows[0].id, existed: true });
    }
    // Pega pipeline e primeiro stage se não enviado
    let toStageId = stage_id;
    if (!toStageId) {
      const p = await db.query('SELECT id FROM pipelines WHERE company_id=$1 AND job_id=$2 LIMIT 1', [req.usuario.company_id, job_id]);
      let pipelineId;
      if (!p.rows[0]) {
        // cria padrão através da rota pipelines; mas aqui cria no escopo direto
        const created = await db.query('INSERT INTO pipelines (company_id, job_id, name) VALUES ($1,$2,$3) RETURNING id', [req.usuario.company_id, job_id, 'Padrão']);
        pipelineId = created.rows[0].id;
        const defaults = ['Triagem', 'Entrevista', 'Proposta', 'Fechado'];
        let pos = 1;
        for (const n of defaults) await db.query('INSERT INTO pipeline_stages (company_id, pipeline_id, name, position) VALUES ($1,$2,$3,$4)', [req.usuario.company_id, pipelineId, n, pos++]);
      } else {
        pipelineId = p.rows[0].id;
      }
      const fst = await db.query('SELECT id FROM pipeline_stages WHERE pipeline_id=$1 AND company_id=$2 ORDER BY position LIMIT 1', [pipelineId, req.usuario.company_id]);
      toStageId = fst.rows[0]?.id || null;
    }
    const stageName = toStageId ? await getStageNameById(req.usuario.company_id, toStageId) : null;
    const ins = await db.query(
      `INSERT INTO applications (company_id, job_id, candidate_id, stage, status, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
      [req.usuario.company_id, job_id, candidate_id, stageName, 'open']
    );
    const app = ins.rows[0];
    if (toStageId) {
      await db.query('INSERT INTO application_stages (company_id, application_id, stage_id, entered_at) VALUES ($1,$2,$3, now())', [req.usuario.company_id, app.id, toStageId]);
      await db.query('INSERT INTO application_status_history (company_id, application_id, from_status, to_status, note, created_at) VALUES ($1,$2,$3,$4,$5, now())', [req.usuario.company_id, app.id, null, stageName, 'criação']);
    }
    await audit(req, 'create', 'application', app.id, { job_id, candidate_id, stage: stageName });
    res.status(201).json(app);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao criar candidatura' });
  }
});

// Mover estágio
router.post('/:id/move', async (req, res) => {
  try {
    const { to_stage_id, note } = req.body || {};
    if (!to_stage_id) return res.status(400).json({ erro: 'to_stage_id é obrigatório' });
    const appq = await db.query('SELECT * FROM applications WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    const app = appq.rows[0];
    if (!app) return res.status(404).json({ erro: 'Candidatura não encontrada' });
    const newName = await getStageNameById(req.usuario.company_id, to_stage_id);
    if (!newName) return res.status(400).json({ erro: 'Estágio inválido' });
    const fromName = app.stage || null;
    await db.query('INSERT INTO application_stages (company_id, application_id, stage_id, entered_at) VALUES ($1,$2,$3, now())', [req.usuario.company_id, app.id, to_stage_id]);
    await db.query('UPDATE applications SET stage=$1, updated_at = now() WHERE id=$2', [newName, app.id]);
    await db.query('INSERT INTO application_status_history (company_id, application_id, from_status, to_status, note, created_at) VALUES ($1,$2,$3,$4,$5, now())', [req.usuario.company_id, app.id, fromName, newName, note || null]);
    await audit(req, 'move_stage', 'application', app.id, { from: fromName, to: newName });
    res.json({ ok: true, from: fromName, to: newName });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao mover estágio' });
  }
});

// Histórico da aplicação
router.get('/:id/history', async (req, res) => {
  try {
    const stages = await db.query(
      `SELECT asg.entered_at, ps.name AS stage
         FROM application_stages asg JOIN pipeline_stages ps ON ps.id = asg.stage_id
        WHERE asg.application_id = $1 AND asg.company_id = $2
        ORDER BY asg.entered_at ASC`,
      [req.params.id, req.usuario.company_id]
    );
    const notes = await db.query(
      `SELECT created_at, from_status, to_status, note
         FROM application_status_history
        WHERE application_id = $1 AND company_id = $2
        ORDER BY created_at ASC`,
      [req.params.id, req.usuario.company_id]
    );
    res.json({ stages: stages.rows, transitions: notes.rows });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao obter histórico' });
  }
});

// Nota na aplicação
router.post('/:id/notes', async (req, res) => {
  const { text } = req.body || {};
  await db.query(
    `INSERT INTO notes (company_id, entity, entity_id, user_id, text, created_at)
     VALUES ($1,$2,$3,$4,$5, now())`,
      [req.usuario.company_id, 'application', req.params.id, req.usuario.id || null, text || null]
  );
  res.json({ ok: true });
});

module.exports = router;
