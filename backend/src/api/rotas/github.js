/**
 * Rotas de GitHub Integration (RF4)
 * CRUD de perfis GitHub vinculados a candidatos
 */

const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const githubService = require('../../servicos/githubService');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

// ============================================================================
// POST /api/candidates/:candidateId/github - Associar GitHub ao candidato
// ============================================================================

router.post('/:candidateId/github', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const userId = req.usuario.id;
    const { candidateId } = req.params;
    const { username, consent_given } = req.body;

    // Validações
    if (!username || username.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'GitHub username é obrigatório'
      });
    }

    if (!consent_given) {
      return res.status(400).json({
        success: false,
        message: 'Consentimento do candidato é obrigatório (LGPD)'
      });
    }

    // Verificar se candidato existe e pertence à company
    const candidate = await db.query(
      `SELECT id FROM candidatos 
       WHERE id = $1 AND company_id = $2 AND deleted_at IS NULL`,
      [candidateId, companyId]
    );

    if (candidate.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Candidato não encontrado'
      });
    }

    // Verificar se já existe integração para este candidato
    const existing = await db.query(
      `SELECT id FROM perfis_github_candidato 
       WHERE candidate_id = $1 AND company_id = $2 AND deleted_at IS NULL`,
      [candidateId, companyId]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Candidato já possui perfil GitHub vinculado. Use PUT para atualizar.'
      });
    }

    // Buscar dados do GitHub
    let githubData;
    try {
      githubData = await githubService.getCompleteProfile(username);
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: error.message,
        sync_status: 'error'
      });
    }

    // Salvar no banco
    const result = await db.query(
      `INSERT INTO perfis_github_candidato (
        candidate_id, company_id, username, github_id,
        avatar_url, profile_url, bio, location, blog,
        company, email, hireable, public_repos, public_gists,
        followers, following, summary, last_synced_at,
        sync_status, consent_given, consent_given_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
        $11, $12, $13, $14, $15, $16, $17, NOW(),
        'success', $18, NOW()
      ) RETURNING *`,
      [
        candidateId, companyId, githubData.username, githubData.github_id,
        githubData.avatar_url, githubData.profile_url, githubData.bio,
        githubData.location, githubData.blog, githubData.company,
        githubData.email, githubData.hireable, githubData.public_repos,
        githubData.public_gists, githubData.followers, githubData.following,
        githubData.summary, consent_given
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Perfil GitHub vinculado com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF4] Erro ao vincular GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao vincular perfil GitHub',
      error: error.message
    });
  }
});

// ============================================================================
// GET /api/candidates/:candidateId/github - Buscar perfil GitHub do candidato
// ============================================================================

router.get('/:candidateId/github', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { candidateId } = req.params;

    const result = await db.query(
      `SELECT * FROM visao_perfis_github_candidato
       WHERE candidate_id = $1 AND company_id = $2`,
      [candidateId, companyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Perfil GitHub não encontrado para este candidato'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF4] Erro ao buscar GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar perfil GitHub',
      error: error.message
    });
  }
});

// ============================================================================
// PUT /api/candidates/:candidateId/github - Re-sincronizar perfil GitHub
// ============================================================================

router.put('/:candidateId/github', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { candidateId } = req.params;

    // Buscar integração existente
    const existing = await db.query(
      `SELECT * FROM perfis_github_candidato
       WHERE candidate_id = $1 AND company_id = $2 AND deleted_at IS NULL`,
      [candidateId, companyId]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Perfil GitHub não encontrado para este candidato'
      });
    }

    const profile = existing.rows[0];

    // Re-sincronizar dados
    let githubData;
    try {
      await db.query(
        `UPDATE perfis_github_candidato 
         SET sync_status = 'syncing' 
         WHERE id = $1`,
        [profile.id]
      );

      githubData = await githubService.getCompleteProfile(profile.username);

      // Atualizar no banco
      const result = await db.query(
        `UPDATE perfis_github_candidato SET
          github_id = $1, avatar_url = $2, profile_url = $3,
          bio = $4, location = $5, blog = $6, company = $7,
          email = $8, hireable = $9, public_repos = $10,
          public_gists = $11, followers = $12, following = $13,
          summary = $14, last_synced_at = NOW(),
          sync_status = 'success', sync_error = NULL
         WHERE id = $15
         RETURNING *`,
        [
          githubData.github_id, githubData.avatar_url, githubData.profile_url,
          githubData.bio, githubData.location, githubData.blog,
          githubData.company, githubData.email, githubData.hireable,
          githubData.public_repos, githubData.public_gists,
          githubData.followers, githubData.following, githubData.summary,
          profile.id
        ]
      );

      res.json({
        success: true,
        message: 'Perfil GitHub re-sincronizado com sucesso',
        data: result.rows[0]
      });

    } catch (error) {
      // Marcar erro
      await db.query(
        `UPDATE perfis_github_candidato 
         SET sync_status = 'error', sync_error = $1, last_synced_at = NOW()
         WHERE id = $2`,
        [error.message, profile.id]
      );

      return res.status(400).json({
        success: false,
        message: error.message,
        sync_status: 'error'
      });
    }

  } catch (error) {
    console.error('[RF4] Erro ao re-sincronizar GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao re-sincronizar perfil GitHub',
      error: error.message
    });
  }
});

// ============================================================================
// DELETE /api/candidates/:candidateId/github - Remover integração GitHub
// ============================================================================

router.delete('/:candidateId/github', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const { candidateId } = req.params;

    const result = await db.query(
      `UPDATE perfis_github_candidato 
       SET deleted_at = NOW()
       WHERE candidate_id = $1 AND company_id = $2 AND deleted_at IS NULL
       RETURNING id, username`,
      [candidateId, companyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Perfil GitHub não encontrado para este candidato'
      });
    }

    res.json({
      success: true,
      message: 'Integração GitHub removida com sucesso',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('[RF4] Erro ao remover GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao remover integração GitHub',
      error: error.message
    });
  }
});

// ============================================================================
// GET /api/candidates/github - Listar todos os perfis GitHub da company
// ============================================================================

router.get('/github', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;
    const {
      search,
      sync_status,
      sort = 'last_synced_at',
      order = 'DESC',
      page = 1,
      limit = 20
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const maxLimit = Math.min(parseInt(limit), 100);

    // Construir query
    let whereClauses = ['company_id = $1'];
    let params = [companyId];
    let paramIndex = 2;

    if (search) {
      whereClauses.push(`(
        username ILIKE $${paramIndex} OR
        candidate_name ILIKE $${paramIndex} OR
        bio ILIKE $${paramIndex}
      )`);
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (sync_status) {
      whereClauses.push(`sync_status = $${paramIndex}`);
      params.push(sync_status);
      paramIndex++;
    }

    const whereClause = whereClauses.join(' AND ');

    // Validar sort
    const allowedSorts = ['username', 'last_synced_at', 'public_repos', 'followers', 'created_at'];
    const sortColumn = allowedSorts.includes(sort) ? sort : 'last_synced_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    // Query principal
    const result = await db.query(
      `SELECT * FROM visao_perfis_github_candidato
       WHERE ${whereClause}
       ORDER BY ${sortColumn} ${sortOrder}
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...params, maxLimit, offset]
    );

    // Contar total
    const countResult = await db.query(
      `SELECT COUNT(*)::int as total
       FROM visao_perfis_github_candidato
       WHERE ${whereClause}`,
      params
    );

    const total = countResult.rows[0]?.total || 0;

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: maxLimit,
        total,
        totalPages: Math.ceil(total / maxLimit)
      }
    });

  } catch (error) {
    console.error('[RF4] Erro ao listar perfis GitHub:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao listar perfis GitHub',
      error: error.message
    });
  }
});

module.exports = router;
