const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao, exigirRole } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');

router.use(exigirAutenticacao);

function slugify(text) {
  return String(text || '')
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '')
    .slice(0, 80);
}

// Listar jobs com filtros básicos
router.get('/', async (req, res) => {
  try {
    const { status, q, page = 1, limit = 50 } = req.query;
    const params = [req.usuario.company_id];
    let sql = 'SELECT * FROM jobs WHERE company_id = $1';
    if (status) {
      params.push(String(status).toLowerCase());
      sql += ` AND status = $${params.length}`;
    }
    if (q) {
      params.push(`%${String(q).toLowerCase()}%`);
      sql += ` AND lower(title) LIKE $${params.length}`;
    }
    params.push(Number(limit));
    params.push((Number(page) - 1) * Number(limit));
    sql += ` ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;
    const r = await db.query(sql, params);
    res.json(r.rows);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao listar vagas' });
  }
});

// Obter job por id
router.get('/:id', async (req, res) => {
  const r = await db.query('SELECT * FROM jobs WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
  if (!r.rows[0]) return res.status(404).json({ erro: 'Vaga não encontrada' });
  res.json(r.rows[0]);
});

// Criar job (ADMIN/SUPER_ADMIN)
router.post('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const { title, description, requirements, seniority, location_type, status, slug } = req.body || {};
    if (!title || !description || !requirements) {
      return res.status(400).json({ erro: 'Campos obrigatórios: title, description, requirements' });
    }
    const s = (status || 'open').toLowerCase();
    const sl = slug ? slugify(slug) : slugify(title);
    try {
      const r = await db.query(
        `INSERT INTO jobs (company_id, title, slug, description, requirements, seniority, location_type, status, created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8, now()) RETURNING *`,
        [req.usuario.company_id, title, sl, description, requirements, seniority || null, location_type || null, s]
      );
      const row = r.rows[0];
      await audit(req, 'create', 'job', row.id, { title: row.title, slug: row.slug });
      return res.status(201).json(row);
    } catch (e) {
      if (e && e.code === '23505') {
        return res.status(409).json({ erro: 'Slug já utilizado para esta empresa' });
      }
      throw e;
    }
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao criar vaga' });
  }
});

// Atualizar job (ADMIN/SUPER_ADMIN)
router.put('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const { title, description, requirements, seniority, location_type, status, slug } = req.body || {};
    const fields = [];
    const params = [];
    let idx = 1;
    function add(field, value) {
      fields.push(`${field}=COALESCE($${idx}, ${field})`);
      params.push(value);
      idx++;
    }
    if (title !== undefined) add('title', title);
    if (description !== undefined) add('description', description);
    if (requirements !== undefined) add('requirements', requirements);
    if (seniority !== undefined) add('seniority', seniority);
    if (location_type !== undefined) add('location_type', location_type);
    if (status !== undefined) add('status', String(status).toLowerCase());
    if (slug !== undefined) add('slug', slug ? slugify(slug) : null);
    params.push(req.params.id);
    params.push(req.usuario.company_id);
    const sql = `UPDATE jobs SET ${fields.join(', ')}, updated_at = now() WHERE id=$${idx} AND company_id=$${idx+1} RETURNING *`;
    const r = await db.query(sql, params);
    if (!r.rows[0]) return res.status(404).json({ erro: 'Vaga não encontrada' });
    await audit(req, 'update', 'job', req.params.id, { title, status });
    res.json(r.rows[0]);
  } catch (e) {
    if (e && e.code === '23505') return res.status(409).json({ erro: 'Slug já utilizado para esta empresa' });
    res.status(500).json({ erro: 'Falha ao atualizar vaga' });
  }
});

// Deletar job (ADMIN/SUPER_ADMIN)
router.delete('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const r = await db.query('DELETE FROM jobs WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    await audit(req, 'delete', 'job', req.params.id, {});
    return res.status(204).send();
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao deletar vaga' });
  }
});

module.exports = router;
