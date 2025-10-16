const express = require('express');
const router = express.Router();
const multer = require('multer');
const pdfParse = require('pdf-parse');
let mammoth;
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarAnaliseCurriculo } = require('../../servicos/iaService');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

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
    } else if (mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' || (originalname || '').toLowerCase().endsWith('.docx')) {
      try {
        if (!mammoth) mammoth = require('mammoth');
        const result = await mammoth.extractRawText({ buffer });
        texto = (result && result.value) || '';
      } catch (e) {
        return res.status(400).json({ erro: 'Falha ao processar DOCX' });
      }
    } else {
      return res.status(400).json({ erro: 'Formatos aceitos: PDF, TXT ou DOCX' });
    }

    // Upsert candidato
    const email = candidato.email || null;
    const github = candidato.github || null;
    const cRes = await db.query(
      `INSERT INTO candidatos (nome, email, github, company_id)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (company_id, email) DO UPDATE SET nome=EXCLUDED.nome, github=EXCLUDED.github
       RETURNING *`,
      [candidato.nome || 'Candidato', email, github, req.usuario.companyId]
    );
    const cand = cRes.rows[0];

    // Análise IA
    const analise = await gerarAnaliseCurriculo(texto, vagaId);

    const curRes = await db.query(
      `INSERT INTO curriculos (candidato_id, nome_arquivo, mimetype, tamanho, texto, analise_json, company_id)
       VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7)
       RETURNING *`,
      [cand.id, originalname, mimetype, size, texto.substring(0, 15000), JSON.stringify(analise), req.usuario.companyId]
    );
    const curriculo = curRes.rows[0];

    // Se houver vaga, cria entrevista
    let entrevista = null;
    if (vagaId) {
      const eRes = await db.query(
        'INSERT INTO entrevistas (vaga_id, candidato_id, curriculo_id, company_id) VALUES ($1,$2,$3,$4) RETURNING *',
        [vagaId, cand.id, curriculo.id, req.usuario.companyId]
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
