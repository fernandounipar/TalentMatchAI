const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarPerguntasEntrevista, responderChatEntrevista } = require('../../servicos/iaService');

router.use(exigirAutenticacao);

router.get('/:id', async (req, res) => {
  const id = req.params.id;
  const r = await db.query(
    `SELECT e.*, v.titulo AS vaga_titulo, c.nome AS candidato_nome
     FROM entrevistas e
     JOIN vagas v ON v.id = e.vaga_id
     JOIN candidatos c ON c.id = e.candidato_id
     WHERE e.id=$1 AND e.company_id=$2`, [id, req.usuario.company_id]
  );
  if (!r.rows[0]) return res.status(404).json({ erro: 'Entrevista não encontrada' });
  const perguntas = await db.query('SELECT * FROM perguntas WHERE entrevista_id=$1 AND company_id=$2 ORDER BY criado_em ASC', [id, req.usuario.company_id]);
  const relatorio = await db.query('SELECT * FROM relatorios WHERE entrevista_id=$1 AND company_id=$2', [id, req.usuario.company_id]);
  res.json({ entrevista: r.rows[0], perguntas: perguntas.rows, relatorio: relatorio.rows[0] || null });
});

router.post('/:id/perguntas', async (req, res) => {
  const id = req.params.id;
  const e = await db.query(
    `SELECT e.id, v.descricao AS vaga_desc, cu.analise_json
     FROM entrevistas e
     LEFT JOIN vagas v ON v.id = e.vaga_id
     LEFT JOIN curriculos cu ON cu.id = e.curriculo_id
     WHERE e.id=$1 AND e.company_id=$2`, [id, req.usuario.company_id]
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
  const inserts = await Promise.all(qs.map(q => db.query('INSERT INTO perguntas (entrevista_id, texto, company_id) VALUES ($1,$2,$3) RETURNING *', [id, q, req.usuario.company_id])));
  res.json(inserts.map(i => i.rows[0]));
});

router.post('/:id/relatorio', async (req, res) => {
  const id = req.params.id;
  const perguntas = await db.query('SELECT texto FROM perguntas WHERE entrevista_id=$1 AND company_id=$2 ORDER BY criado_em ASC', [id, req.usuario.company_id]);
  const html = `<html><head><meta charset="utf-8"></head><body>
  <h1>Relatório de Entrevista</h1>
  <h2>Perguntas</h2>
  <ol>${perguntas.rows.map(p=>`<li>${p.texto}</li>`).join('')}</ol>
  </body></html>`;
  const up = await db.query(
    `INSERT INTO relatorios (entrevista_id, html, company_id) VALUES ($1,$2,$3)
     ON CONFLICT (entrevista_id) DO UPDATE SET html=EXCLUDED.html, company_id=EXCLUDED.company_id
     RETURNING *`, [id, html, req.usuario.company_id]
  );
  res.json(up.rows[0]);
});

// Histórico de mensagens do chat da entrevista
router.get('/:id/mensagens', async (req, res) => {
  const id = req.params.id;
  const msgs = await db.query(
    'SELECT id, role, conteudo, criado_em FROM mensagens WHERE entrevista_id=$1 AND company_id=$2 ORDER BY criado_em ASC',
    [id, req.usuario.company_id]
  );
  res.json(msgs.rows);
});

// Enviar mensagem ao chat e obter resposta da IA
router.post('/:id/chat', async (req, res) => {
  const id = req.params.id;
  const { mensagem } = req.body || {};
  if (!mensagem || String(mensagem).trim() === '') {
    return res.status(400).json({ erro: 'Mensagem obrigatória' });
  }

  // Carregar contexto da entrevista
  const e = await db.query(
    `SELECT e.id, v.descricao AS vaga_desc, cu.texto, cu.analise_json
     FROM entrevistas e
     LEFT JOIN vagas v ON v.id = e.vaga_id
     LEFT JOIN curriculos cu ON cu.id = e.curriculo_id
     WHERE e.id=$1 AND e.company_id=$2`,
    [id, req.usuario.company_id]
  );
  const row = e.rows[0];
  if (!row) return res.status(404).json({ erro: 'Entrevista não encontrada' });

  // Buscar histórico recente
  const hist = await db.query(
    'SELECT role, conteudo FROM mensagens WHERE entrevista_id=$1 AND company_id=$2 ORDER BY criado_em ASC LIMIT 50',
    [id, req.usuario.company_id]
  );

  // Persistir mensagem do usuário
  const insUser = await db.query(
    'INSERT INTO mensagens (entrevista_id, role, conteudo, company_id) VALUES ($1,$2,$3,$4) RETURNING id, role, conteudo, criado_em',
    [id, 'user', String(mensagem), req.usuario.company_id]
  );

  // Gerar resposta via IA (ou mock)
  const resposta = await responderChatEntrevista({
    historico: hist.rows,
    mensagemAtual: String(mensagem),
    analise: row.analise_json || {},
    vagaDesc: row.vaga_desc || '',
    textoCurriculo: row.texto ? String(row.texto).slice(0, 5000) : '',
    companyId: req.usuario.company_id,
  });

  // Persistir resposta do assistant
  const insIA = await db.query(
    'INSERT INTO mensagens (entrevista_id, role, conteudo, company_id) VALUES ($1,$2,$3,$4) RETURNING id, role, conteudo, criado_em',
    [id, 'assistant', String(resposta), req.usuario.company_id]
  );

  res.json({
    enviada: insUser.rows[0],
    resposta: insIA.rows[0],
  });
});

module.exports = router;
