const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');

router.use(exigirAutenticacao);

router.get('/', async (req, res) => {
  try {
  const r = await db.query('SELECT * FROM vagas WHERE company_id=$1 ORDER BY criado_em DESC', [req.usuario.company_id]);
    res.json(r.rows);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { titulo, descricao, requisitos, status, tecnologias, nivel } = req.body || {};
    if (!titulo || !descricao || !requisitos) {
      return res.status(400).json({ erro: 'Campos obrigatórios: titulo, descricao, requisitos' });
    }

    const r = await db.query(
      'INSERT INTO vagas (titulo, descricao, requisitos, status, tecnologias, nivel, company_id) VALUES ($1,$2,$3,COALESCE($4,\'aberta\'),$5,$6,$7) RETURNING *',
      [titulo, descricao, requisitos, status, tecnologias, nivel, req.usuario.company_id]
    );
    const row = r.rows[0];
    await audit(req, 'create', 'vaga', row.id, { titulo });
    res.status(201).json(row);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
  const r = await db.query('SELECT * FROM vagas WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    if (!r.rows[0]) return res.status(404).json({ erro: 'Vaga não encontrada' });
    await audit(req, 'update', 'vaga', req.params.id, { titulo, status });
    res.json(r.rows[0]);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { titulo, descricao, requisitos, status, tecnologias, nivel } = req.body || {};
    const r = await db.query(
      `UPDATE vagas SET
         titulo=COALESCE($2, titulo),
         descricao=COALESCE($3, descricao),
         requisitos=COALESCE($4, requisitos),
         status=COALESCE($5, status),
         tecnologias=COALESCE($6, tecnologias),
         nivel=COALESCE($7, nivel)
       WHERE id=$1 AND company_id=$8 RETURNING *`,
      [req.params.id, titulo, descricao, requisitos, status, tecnologias, nivel, req.usuario.company_id]
    );
    if (!r.rows[0]) return res.status(404).json({ erro: 'Vaga não encontrada' });
    res.json(r.rows[0]);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
  await db.query('DELETE FROM vagas WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
    await audit(req, 'delete', 'vaga', req.params.id, {});
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;
