const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarPerguntasEntrevista } = require('../../servicos/iaService');

router.use(exigirAutenticacao);

router.get('/:id', async (req, res) => {
  const id = req.params.id;
  const r = await db.query(
    `SELECT e.*, v.titulo AS vaga_titulo, c.nome AS candidato_nome
     FROM entrevistas e
     JOIN vagas v ON v.id = e.vaga_id
     JOIN candidatos c ON c.id = e.candidato_id
     WHERE e.id=$1`, [id]
  );
  if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
  const perguntas = await db.query('SELECT * FROM perguntas WHERE entrevista_id=$1 ORDER BY criado_em ASC', [id]);
  const relatorio = await db.query('SELECT * FROM relatorios WHERE entrevista_id=$1', [id]);
  res.json({ entrevista: r.rows[0], perguntas: perguntas.rows, relatorio: relatorio.rows[0] || null });
});

router.post('/:id/perguntas', async (req, res) => {
  const id = req.params.id;
  const e = await db.query(
    `SELECT e.id, v.descricao AS vaga_desc, cu.analise_json
     FROM entrevistas e
     LEFT JOIN vagas v ON v.id = e.vaga_id
     LEFT JOIN curriculos cu ON cu.id = e.curriculo_id
     WHERE e.id=$1`, [id]
  );
  const row = e.rows[0];
  if (!row) return res.status(404).json({ erro: 'Entrevista não encontrada' });
  const analise = row.analise_json || {};
  const qs = await gerarPerguntasEntrevista({
    resumo: analise.summary || '',
    skills: analise.skills || [],
    vaga: row.vaga_desc || '',
    quantidade: Number(req.query.qtd || 8)
  });
  const inserts = await Promise.all(qs.map(q => db.query('INSERT INTO perguntas (entrevista_id, texto) VALUES ($1,$2) RETURNING *', [id, q])));
  res.json(inserts.map(i => i.rows[0]));
});

router.post('/:id/relatorio', async (req, res) => {
  const id = req.params.id;
  const perguntas = await db.query('SELECT texto FROM perguntas WHERE entrevista_id=$1 ORDER BY criado_em ASC', [id]);
  const html = `<html><head><meta charset="utf-8"></head><body>
  <h1>Relatório de Entrevista</h1>
  <h2>Perguntas</h2>
  <ol>${perguntas.rows.map(p=>`<li>${p.texto}</li>`).join('')}</ol>
  </body></html>`;
  const up = await db.query(
    `INSERT INTO relatorios (entrevista_id, html) VALUES ($1,$2)
     ON CONFLICT (entrevista_id) DO UPDATE SET html=EXCLUDED.html
     RETURNING *`, [id, html]
  );
  res.json(up.rows[0]);
});

module.exports = router;

