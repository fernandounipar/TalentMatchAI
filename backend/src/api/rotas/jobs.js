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

// ============================================================================
// GET /api/jobs - Listar vagas com filtros avançados e paginação
// ============================================================================
router.get('/', async (req, res) => {
  try {
    const {
      status,
      department,
      seniority,
      is_remote,
      location_type,
      q,
      date_from,
      date_to,
      sort_by = 'created_at',
      order = 'desc',
      page = 1,
      limit = 20
    } = req.query;

    // Validação de paginação
    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 20));
    const offset = (pageNum - 1) * limitNum;

    // Validação de ordenação
    const allowedSortFields = ['created_at', 'updated_at', 'title', 'status', 'published_at', 'closed_at'];
    const sortField = allowedSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortOrder = order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    // Construir query dinâmica
    const params = [req.usuario.company_id];
    const conditions = ['j.company_id = $1', 'j.deleted_at IS NULL'];

    // Filtros opcionais
    if (status) {
      params.push(String(status).toLowerCase());
      conditions.push(`j.status = $${params.length}`);
    }

    if (department) {
      params.push(String(department));
      conditions.push(`j.department = $${params.length}`);
    }

    if (seniority) {
      params.push(String(seniority).toLowerCase());
      conditions.push(`j.seniority = $${params.length}`);
    }

    if (is_remote !== undefined) {
      params.push(is_remote === 'true' || is_remote === '1');
      conditions.push(`j.is_remote = $${params.length}`);
    }

    if (location_type) {
      params.push(String(location_type).toLowerCase());
      conditions.push(`j.location_type = $${params.length}`);
    }

    if (q) {
      params.push(`%${String(q).toLowerCase()}%`);
      conditions.push(`(LOWER(j.title) LIKE $${params.length} OR LOWER(j.description) LIKE $${params.length})`);
    }

    if (date_from) {
      params.push(date_from);
      conditions.push(`j.created_at >= $${params.length}::timestamp`);
    }

    if (date_to) {
      params.push(date_to);
      conditions.push(`j.created_at <= $${params.length}::timestamp`);
    }

    // Query de contagem total
    const countSql = `SELECT COUNT(*) as total FROM vagas j WHERE ${conditions.join(' AND ')}`;
    const countResult = await db.query(countSql, params);
    const total = parseInt(countResult.rows[0]?.total || 0);

    // Query principal com dados
    params.push(limitNum);
    params.push(offset);

    const sql = `
      SELECT
        j.id,
        j.company_id,
        j.title,
        j.slug,
        j.description,
        j.requirements,
        j.seniority,
        j.location_type,
        j.status,
        j.salary_min,
        j.salary_max,
        j.contract_type,
        j.department,
        j.unit,
        j.benefits,
        j.skills_required,
        j.is_remote,
        j.published_at,
        j.closed_at,
        j.version,
        j.created_at,
        j.updated_at,
        COALESCE(apps.cnt, 0)::int AS candidates_count
      FROM vagas j
      LEFT JOIN (
        SELECT job_id, COUNT(*)::int AS cnt
          FROM candidaturas
         WHERE company_id = $1
           AND deleted_at IS NULL
         GROUP BY job_id
      ) apps ON apps.job_id = j.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY j.${sortField} ${sortOrder}
      LIMIT $${params.length - 1} OFFSET $${params.length}
    `;

    const result = await db.query(sql, params);

    // Resposta com paginação
    res.json({
      data: result.rows,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: total,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (e) {
    console.error('Erro ao listar vagas:', e);
    res.status(500).json({ erro: 'Falha ao listar vagas' });
  }
});


// ============================================================================
// GET /api/jobs/:id - Obter vaga por ID com histórico de revisões
// ============================================================================
router.get('/:id', async (req, res) => {
  try {
    // Buscar vaga principal
    const jobResult = await db.query(
      `SELECT 
        j.*,
        COALESCE(apps.cnt, 0)::int AS candidates_count,
        creator.full_name as created_by_name,
        creator.email as created_by_email,
        updater.full_name as updated_by_name,
        updater.email as updated_by_email
      FROM vagas j
      LEFT JOIN (
        SELECT job_id, COUNT(*)::int AS cnt
        FROM candidaturas
        WHERE company_id = $2 AND deleted_at IS NULL
        GROUP BY job_id
      ) apps ON apps.job_id = j.id
      LEFT JOIN usuarios creator ON creator.id = j.created_by
      LEFT JOIN usuarios updater ON updater.id = j.updated_by
      WHERE j.id = $1 AND j.company_id = $2 AND j.deleted_at IS NULL`,
      [req.params.id, req.usuario.company_id]
    );

    if (!jobResult.rows[0]) {
      return res.status(404).json({ erro: 'Vaga não encontrada' });
    }

    // Buscar histórico de revisões
    const revisionsResult = await db.query(
      `SELECT 
        jr.*,
        u.full_name as changed_by_name,
        u.email as changed_by_email
      FROM revisoes_vagas jr
      LEFT JOIN usuarios u ON u.id = jr.changed_by
      WHERE jr.job_id = $1 AND jr.company_id = $2
      ORDER BY jr.version DESC
      LIMIT 10`,
      [req.params.id, req.usuario.company_id]
    );

    res.json({
      ...jobResult.rows[0],
      revisions: revisionsResult.rows
    });
  } catch (e) {
    console.error('Erro ao buscar vaga:', e);
    res.status(500).json({ erro: 'Falha ao buscar vaga' });
  }
});


// ============================================================================
// POST /api/jobs - Criar nova vaga (ADMIN/SUPER_ADMIN)
// ============================================================================
router.post('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const {
      title,
      description,
      requirements,
      seniority,
      location_type,
      status,
      slug,
      salary_min,
      salary_max,
      contract_type,
      department,
      unit,
      benefits,
      skills_required,
      is_remote
    } = req.body || {};

    // Validação de campos obrigatórios
    if (!title || !description || !requirements) {
      return res.status(400).json({
        erro: 'Campos obrigatórios: title, description, requirements'
      });
    }

    // Valores padrão e processamento
    const finalStatus = (status || 'draft').toLowerCase();
    const finalSlug = slug ? slugify(slug) : slugify(title);
    const finalIsRemote = is_remote === true || is_remote === 'true';

    // Auto-publicar se status for 'open'
    const publishedAt = finalStatus === 'open' ? new Date() : null;

    try {
      const result = await db.query(
        `INSERT INTO vagas (
          company_id, title, slug, description, requirements, seniority,
          location_type, status, salary_min, salary_max, contract_type,
          department, unit, benefits, skills_required, is_remote,
          published_at, created_by, created_at, updated_at, version
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, now(), now(), 1
        ) RETURNING *`,
        [
          req.usuario.company_id,
          title,
          finalSlug,
          description,
          requirements,
          seniority || null,
          location_type || null,
          finalStatus,
          salary_min || null,
          salary_max || null,
          contract_type || null,
          department || null,
          unit || null,
          JSON.stringify(benefits || []),
          JSON.stringify(skills_required || []),
          finalIsRemote,
          publishedAt,
          req.usuario.user_id
        ]
      );

      const row = result.rows[0];
      await audit(req, 'create', 'job', row.id, {
        title: row.title,
        slug: row.slug,
        status: row.status
      });

      return res.status(201).json(row);
    } catch (e) {
      if (e && e.code === '23505') {
        return res.status(409).json({
          erro: 'Slug já utilizado para esta empresa'
        });
      }
      throw e;
    }
  } catch (e) {
    console.error('Erro ao criar vaga:', e);
    res.status(500).json({ erro: 'Falha ao criar vaga' });
  }
});


// ============================================================================
// PUT /api/jobs/:id - Atualizar vaga (ADMIN/SUPER_ADMIN)
// ============================================================================
router.put('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const {
      title,
      description,
      requirements,
      seniority,
      location_type,
      status,
      slug,
      salary_min,
      salary_max,
      contract_type,
      department,
      unit,
      benefits,
      skills_required,
      is_remote
    } = req.body || {};

    // Construir campos dinâmicos para update
    const fields = [];
    const params = [];
    let idx = 1;

    function addField(fieldName, value) {
      if (value !== undefined) {
        params.push(value);
        fields.push(`${fieldName} = $${idx}`);
        idx++;
      }
    }

    addField('title', title);
    addField('description', description);
    addField('requirements', requirements);
    addField('seniority', seniority);
    addField('location_type', location_type);
    addField('salary_min', salary_min);
    addField('salary_max', salary_max);
    addField('contract_type', contract_type);
    addField('department', department);
    addField('unit', unit);
    addField('is_remote', is_remote);

    if (benefits !== undefined) {
      params.push(JSON.stringify(benefits));
      fields.push(`benefits = $${idx}`);
      idx++;
    }

    if (skills_required !== undefined) {
      params.push(JSON.stringify(skills_required));
      fields.push(`skills_required = $${idx}`);
      idx++;
    }

    if (slug !== undefined) {
      params.push(slug ? slugify(slug) : null);
      fields.push(`slug = $${idx}`);
      idx++;
    }

    // Gerenciar mudanças de status e timestamps
    if (status !== undefined) {
      const newStatus = String(status).toLowerCase();
      params.push(newStatus);
      fields.push(`status = $${idx}`);
      idx++;

      // Se mudar para 'open' e ainda não foi publicado, marcar published_at
      if (newStatus === 'open') {
        fields.push(`published_at = COALESCE(published_at, now())`);
      }

      // Se fechar a vaga, marcar closed_at
      if (newStatus === 'closed') {
        fields.push(`closed_at = COALESCE(closed_at, now())`);
      }
    }

    // Adicionar updated_by
    params.push(req.usuario.user_id);
    fields.push(`updated_by = $${idx}`);
    idx++;

    if (fields.length === 0) {
      return res.status(400).json({ erro: 'Nenhum campo para atualizar' });
    }

    // Parâmetros finais: job_id e company_id
    params.push(req.params.id);
    params.push(req.usuario.company_id);

    const sql = `
      UPDATE vagas 
      SET ${fields.join(', ')}, updated_at = now()
      WHERE id = $${idx} AND company_id = $${idx + 1} AND deleted_at IS NULL
      RETURNING *
    `;

    const result = await db.query(sql, params);

    if (!result.rows[0]) {
      return res.status(404).json({ erro: 'Vaga não encontrada' });
    }

    await audit(req, 'update', 'job', req.params.id, {
      title: result.rows[0].title,
      status: result.rows[0].status
    });

    res.json(result.rows[0]);
  } catch (e) {
    console.error('Erro ao atualizar vaga:', e);
    if (e && e.code === '23505') {
      return res.status(409).json({ erro: 'Slug já utilizado para esta empresa' });
    }
    res.status(500).json({ erro: 'Falha ao atualizar vaga' });
  }
});


// ============================================================================
// DELETE /api/jobs/:id - Soft delete de vaga (ADMIN/SUPER_ADMIN)
// ============================================================================
router.delete('/:id', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE vagas 
       SET deleted_at = now(), updated_by = $3
       WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL
       RETURNING id, title`,
      [req.params.id, req.usuario.company_id, req.usuario.user_id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ erro: 'Vaga não encontrada' });
    }

    await audit(req, 'delete', 'job', req.params.id, {
      title: result.rows[0].title
    });

    return res.status(204).send();
  } catch (e) {
    console.error('Erro ao deletar vaga:', e);
    res.status(500).json({ erro: 'Falha ao deletar vaga' });
  }
});

// ============================================================================
// GET /api/jobs/search/text - Busca textual em vagas
// ============================================================================
router.get('/search/text', async (req, res) => {
  try {
    const { q, limit = 10 } = req.query;

    if (!q || q.trim().length < 3) {
      return res.status(400).json({
        erro: 'Parâmetro "q" deve ter pelo menos 3 caracteres'
      });
    }

    const result = await db.query(
      `SELECT 
        id, title, slug, description, status, department, 
        seniority, location_type, created_at, published_at
      FROM vagas
      WHERE company_id = $1
        AND deleted_at IS NULL
        AND (
          title ILIKE $2
          OR description ILIKE $2
          OR requirements ILIKE $2
        )
      ORDER BY 
        CASE WHEN title ILIKE $2 THEN 1 ELSE 2 END,
        created_at DESC
      LIMIT $3`,
      [req.usuario.company_id, `%${q}%`, Math.min(50, parseInt(limit) || 10)]
    );

    res.json(result.rows);
  } catch (e) {
    console.error('Erro na busca textual:', e);
    res.status(500).json({ erro: 'Falha na busca' });
  }
});

module.exports = router;
