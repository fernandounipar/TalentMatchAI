const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const dadosMockados = require('../../servicos/dadosMockados');

router.use(exigirAutenticacao);

router.get('/', async (_req, res) => {
  try {
    // Tentar buscar do banco, se falhar, usar dados mockados
    try {
      const r = await db.query('SELECT * FROM vagas ORDER BY criado_em DESC');
      res.json(r.rows);
    } catch (dbError) {
      console.log('Usando dados mockados para vagas:', dbError.message);
      res.json(dadosMockados.vagas);
    }
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

    try {
      const r = await db.query(
        'INSERT INTO vagas (titulo, descricao, requisitos, status, tecnologias, nivel) VALUES ($1,$2,$3,COALESCE($4,\'aberta\'),$5,$6) RETURNING *',
        [titulo, descricao, requisitos, status, tecnologias, nivel]
      );
      res.status(201).json(r.rows[0]);
    } catch (dbError) {
      console.log('Usando dados mockados para criar vaga:', dbError.message);
      const novaVaga = {
        id: String(dadosMockados.vagas.length + 1),
        titulo,
        descricao,
        requisitos,
        status: status || 'aberta',
        tecnologias,
        nivel,
        criado_em: new Date().toISOString(),
      };
      dadosMockados.vagas.push(novaVaga);
      res.status(201).json(novaVaga);
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    try {
      const r = await db.query('SELECT * FROM vagas WHERE id=$1', [req.params.id]);
      if (!r.rows[0]) return res.status(404).json({ erro: 'Vaga não encontrada' });
      res.json(r.rows[0]);
    } catch (dbError) {
      console.log('Usando dados mockados para buscar vaga:', dbError.message);
      const vaga = dadosMockados.vagas.find(v => v.id === req.params.id);
      if (!vaga) return res.status(404).json({ erro: 'Vaga não encontrada' });
      res.json(vaga);
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { titulo, descricao, requisitos, status, tecnologias, nivel } = req.body || {};
    try {
      const r = await db.query(
        `UPDATE vagas SET
         titulo=COALESCE($2, titulo),
         descricao=COALESCE($3, descricao),
         requisitos=COALESCE($4, requisitos),
         status=COALESCE($5, status),
         tecnologias=COALESCE($6, tecnologias),
         nivel=COALESCE($7, nivel)
       WHERE id=$1 RETURNING *`,
        [req.params.id, titulo, descricao, requisitos, status, tecnologias, nivel]
      );
      if (!r.rows[0]) return res.status(404).json({ erro: 'Vaga não encontrada' });
      res.json(r.rows[0]);
    } catch (dbError) {
      console.log('Usando dados mockados para atualizar vaga:', dbError.message);
      const index = dadosMockados.vagas.findIndex(v => v.id === req.params.id);
      if (index === -1) return res.status(404).json({ erro: 'Vaga não encontrada' });
      dadosMockados.vagas[index] = { ...dadosMockados.vagas[index], titulo, descricao, requisitos, status, tecnologias, nivel };
      res.json(dadosMockados.vagas[index]);
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    try {
      await db.query('DELETE FROM vagas WHERE id=$1', [req.params.id]);
      res.status(204).send();
    } catch (dbError) {
      console.log('Usando dados mockados para deletar vaga:', dbError.message);
      const index = dadosMockados.vagas.findIndex(v => v.id === req.params.id);
      if (index !== -1) dadosMockados.vagas.splice(index, 1);
      res.status(204).send();
    }
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;
