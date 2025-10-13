const express = require('express');
const router = express.Router();
const multer = require('multer');
const pdfParse = require('pdf-parse');
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarAnaliseCurriculo } = require('../../servicos/iaService');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

router.post('/upload', exigirAutenticacao, upload.single('arquivo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ erro: 'Arquivo ausente' });
    const { originalname, mimetype, size, buffer } = req.file;
    const candidato = JSON.parse(String(req.body.candidato || '{}'));
    const vagaId = req.body.vagaId || null;
    let texto = '';
    if (mimetype === 'application/pdf') {
      const data = await pdfParse(buffer);
      texto = data.text || '';
    } else if (mimetype === 'text/plain') {
      texto = buffer.toString('utf8');
    } else {
      return res.status(400).json({ erro: 'Formatos aceitos: PDF ou TXT' });
    }

    // Upsert candidato
    const email = candidato.email || null;
    const github = candidato.github || null;
    const cRes = await db.query(
      `INSERT INTO candidatos (nome, email, github)
       VALUES ($1,$2,$3)
       ON CONFLICT (email) DO UPDATE SET nome=EXCLUDED.nome, github=EXCLUDED.github
       RETURNING *`,
      [candidato.nome || 'Candidato', email, github]
    );
    const cand = cRes.rows[0];

    // Análise IA
    const analise = await gerarAnaliseCurriculo(texto, vagaId);

    const curRes = await db.query(
      `INSERT INTO curriculos (candidato_id, nome_arquivo, mimetype, tamanho, texto, analise_json)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [cand.id, originalname, mimetype, size, texto.substring(0, 15000), analise]
    );
    const curriculo = curRes.rows[0];

    // Se houver vaga, cria entrevista
    let entrevista = null;
    if (vagaId) {
      const eRes = await db.query(
        'INSERT INTO entrevistas (vaga_id, candidato_id, curriculo_id) VALUES ($1,$2,$3) RETURNING *',
        [vagaId, cand.id, curriculo.id]
      );
      entrevista = eRes.rows[0];
    }

    res.json({ candidato: cand, curriculo, entrevista });
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Falha no upload/análise' });
  }
});

module.exports = router;

