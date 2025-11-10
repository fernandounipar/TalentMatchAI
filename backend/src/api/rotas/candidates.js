const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

function normalizeSkillsInput(skills) {
  if (!skills) return [];
  if (Array.isArray(skills)) {
    return skills.map((s) => {
      if (typeof s === 'string') return { name: s, level: null };
      if (s && typeof s === 'object') return { name: String(s.name || s.nome || ''), level: s.level || null };
      return null;
    }).filter(Boolean).filter((s) => s.name.trim() !== '');
  }
  if (typeof skills === 'string') {
    return skills.split(',').map((x) => ({ name: x.trim(), level: null })).filter((s) => s.name);
  }
  return [];
}

async function upsertSkills(companyId, skillsArr) {
  const result = [];
  for (const s of skillsArr) {
    const name = s.name.trim();
    const q = await db.query(
      `INSERT INTO skills (company_id, name)
       VALUES ($1, $2)
       ON CONFLICT (company_id, lower(name)) DO UPDATE SET name = EXCLUDED.name
       RETURNING id`,
      [companyId, name]
    );
    result.push({ id: q.rows[0].id, name, level: s.level || null });
  }
  return result;
}

// Listar candidatos com skills e contagens
router.get('/', async (req, res) => {
  try {
    const { skill, q, page = 1, limit = 50 } = req.query;
    const params = [req.usuario.company_id];
    let sql = `SELECT c.id, c.company_id, c.full_name, c.email, c.phone, c.linkedin, c.github_url, c.created_at,
      COALESCE((SELECT json_agg(s.name ORDER BY s.name)
                FROM candidate_skills cs JOIN skills s ON s.id = cs.skill_id
                WHERE cs.candidate_id = c.id), '[]') AS skills,
      (SELECT COUNT(*)::int FROM resumes r WHERE r.candidate_id = c.id AND r.company_id = $1) AS qtd_curriculos,
      (SELECT COUNT(*)::int FROM interviews i JOIN applications a ON a.id = i.application_id
        WHERE a.candidate_id = c.id AND i.company_id = $1) AS qtd_entrevistas
      FROM candidates c
      WHERE c.company_id = $1`;
    if (q) {
      params.push(`%${String(q).toLowerCase()}%`);
      sql += ` AND (lower(c.full_name) LIKE $${params.length} OR lower(c.email) LIKE $${params.length})`;
    }
    if (skill) {
      params.push(String(skill).toLowerCase());
      sql += ` AND EXISTS (
         SELECT 1 FROM candidate_skills cs
         JOIN skills s ON s.id = cs.skill_id
         WHERE cs.candidate_id = c.id AND s.company_id = $1 AND lower(s.name) = $${params.length}
      )`;
    }
    params.push(Number(limit));
    params.push((Number(page) - 1) * Number(limit));
    sql += ` ORDER BY c.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;
    const r = await db.query(sql, params);
    res.json(r.rows.map((row) => ({
      id: row.id,
      nome: row.full_name,
      email: row.email,
      telefone: row.phone,
      linkedin_url: row.linkedin,
      github_url: row.github_url,
      skills: row.skills || [],
      qtd_curriculos: row.qtd_curriculos,
      qtd_entrevistas: row.qtd_entrevistas,
      criado_em: row.created_at,
    })));
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao listar candidatos' });
  }
});

// Obter candidato com skills
router.get('/:id', async (req, res) => {
  const r = await db.query(
    `SELECT c.*, COALESCE((SELECT json_agg(json_build_object('name', s.name, 'level', cs.level))
      FROM candidate_skills cs JOIN skills s ON s.id = cs.skill_id WHERE cs.candidate_id = c.id), '[]') AS skills
     FROM candidates c WHERE c.id=$1 AND c.company_id=$2`,
    [req.params.id, req.usuario.company_id]
  );
  if (!r.rows[0]) return res.status(404).json({ erro: 'Candidato não encontrado' });
  const u = r.rows[0];
  res.json({
    id: u.id,
    nome: u.full_name,
    email: u.email,
    telefone: u.phone,
    linkedin_url: u.linkedin,
    github_url: u.github_url,
    skills: (u.skills || []).map((x) => x.name),
    criado_em: u.created_at,
  });
});

// Criar candidato
router.post('/', async (req, res) => {
  try {
    const { full_name, email, phone, linkedin, github_url, skills } = req.body || {};
    if (!full_name || !email) return res.status(400).json({ erro: 'Campos obrigatórios: full_name, email' });
    const r = await db.query(
      `INSERT INTO candidates (company_id, full_name, email, phone, linkedin, github_url, created_at)
       VALUES ($1,$2,$3,$4,$5,$6, now()) RETURNING *`,
      [req.usuario.company_id, full_name, email.toLowerCase(), phone || null, linkedin || null, github_url || null]
    );
    const cand = r.rows[0];
    const norm = normalizeSkillsInput(skills);
    if (norm.length > 0) {
      const up = await upsertSkills(req.usuario.company_id, norm);
      for (const s of up) {
        await db.query(
          `INSERT INTO candidate_skills (candidate_id, skill_id, level)
           VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
          [cand.id, s.id, s.level]
        );
      }
    }
    res.status(201).json({ id: cand.id });
  } catch (e) {
    if (e && e.code === '23505') return res.status(409).json({ erro: 'Email já cadastrado' });
    res.status(500).json({ erro: 'Falha ao criar candidato' });
  }
});

// Atualizar candidato
router.put('/:id', async (req, res) => {
  try {
    const { full_name, email, phone, linkedin, github_url, skills } = req.body || {};
    const r = await db.query(
      `UPDATE candidates SET
         full_name = COALESCE($1, full_name),
         email = COALESCE($2, email),
         phone = COALESCE($3, phone),
         linkedin = COALESCE($4, linkedin),
         github_url = COALESCE($5, github_url),
         updated_at = now()
       WHERE id=$6 AND company_id=$7 RETURNING *`,
      [full_name || null, email ? email.toLowerCase() : null, phone || null, linkedin || null, github_url || null, req.params.id, req.usuario.company_id]
    );
    const cand = r.rows[0];
    if (!cand) return res.status(404).json({ erro: 'Candidato não encontrado' });
    if (skills !== undefined) {
      await db.query('DELETE FROM candidate_skills WHERE candidate_id=$1', [cand.id]);
      const norm = normalizeSkillsInput(skills);
      if (norm.length > 0) {
        const up = await upsertSkills(req.usuario.company_id, norm);
        for (const s of up) {
          await db.query(
            `INSERT INTO candidate_skills (candidate_id, skill_id, level)
             VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
            [cand.id, s.id, s.level]
          );
        }
      }
    }
    res.json({ ok: true });
  } catch (e) {
    if (e && e.code === '23505') return res.status(409).json({ erro: 'Email já cadastrado' });
    res.status(500).json({ erro: 'Falha ao atualizar candidato' });
  }
});

// Deletar candidato
router.delete('/:id', async (req, res) => {
  await db.query('DELETE FROM candidates WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
  res.status(204).send();
});

module.exports = router;
