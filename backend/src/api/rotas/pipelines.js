const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

async function ensureDefaultPipeline(companyId, jobId) {
  // Verifica se existe pipeline para a vaga; se não, cria um padrão
  const p = await db.query('SELECT * FROM pipelines WHERE job_id=$1 AND company_id=$2 LIMIT 1', [jobId, companyId]);
  if (p.rows[0]) return p.rows[0];
  const created = await db.query(
    'INSERT INTO pipelines (company_id, job_id, name) VALUES ($1,$2,$3) RETURNING *',
    [companyId, jobId, 'Padrão']
  );
  const pipeline = created.rows[0];
  const stages = ['Triagem', 'Entrevista', 'Proposta', 'Fechado'];
  let pos = 1;
  for (const name of stages) {
    await db.query(
      'INSERT INTO pipeline_stages (company_id, pipeline_id, name, position) VALUES ($1,$2,$3,$4)',
      [companyId, pipeline.id, name, pos++]
    );
  }
  return pipeline;
}

// Retorna pipeline e estágios da vaga; cria padrão se não existir
router.get('/jobs/:jobId/pipeline', async (req, res) => {
  const jobId = req.params.jobId;
  const companyId = req.usuario.company_id;
  try {
    const pipeline = await ensureDefaultPipeline(companyId, jobId);
    const stages = await db.query(
      'SELECT id, name, position FROM pipeline_stages WHERE pipeline_id=$1 AND company_id=$2 ORDER BY position',
      [pipeline.id, companyId]
    );
    res.json({ pipeline, stages: stages.rows });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao obter pipeline' });
  }
});

module.exports = router;
