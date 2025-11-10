const express = require('express');
const router = express.Router();
const multer = require('multer');
const pdfParse = require('pdf-parse');
let mammoth;
const path = require('path');
const fs = require('fs');
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { gerarAnaliseCurriculo } = require('../../servicos/iaService');

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '../../../uploads');
function ensureDirSync(p) { try { fs.mkdirSync(p, { recursive: true }); } catch {} }
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
  const dir = path.join(UPLOAD_DIR, String(req.usuario?.company_id || 'public'));
    ensureDirSync(dir);
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const safe = Date.now() + '_' + Math.random().toString(36).slice(2) + ext;
    cb(null, safe);
  }
});
const upload = multer({ storage, limits: { fileSize: 25 * 1024 * 1024 } });

router.post('/upload', exigirAutenticacao, upload.single('arquivo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ erro: 'Arquivo ausente' });
    const { originalname, mimetype, size, path: filepath } = req.file;
    const candidato = JSON.parse(String(req.body.candidato || '{}'));
    const vagaId = req.body.vagaId || null;
    let texto = '';
    // Cria job de ingestão (async/métricas)
    const jobIns = await db.query(
      `INSERT INTO ingestion_jobs (company_id, type, entity, status, progress, metadata, created_at)
       VALUES ($1,$2,$3,$4,$5,$6::jsonb, now()) RETURNING id, status, progress`,
      [req.usuario.company_id, 'resume_parse', 'resume', 'processing', 10, JSON.stringify({ filename: originalname })]
    );
    const ingestion_job = jobIns.rows[0];

    const dataBuffer = fs.readFileSync(filepath);
    if (mimetype === 'application/pdf') {
      const data = await pdfParse(dataBuffer);
      texto = data.text || '';
    } else if (mimetype === 'text/plain') {
      texto = dataBuffer.toString('utf8');
    } else if (mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' || (originalname || '').toLowerCase().endsWith('.docx')) {
      try {
        if (!mammoth) mammoth = require('mammoth');
        const result = await mammoth.extractRawText({ buffer: dataBuffer });
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
      [candidato.nome || 'Candidato', email, github, req.usuario.company_id]
    );
    const cand = cRes.rows[0];

    // Análise IA
    const analise = await gerarAnaliseCurriculo(texto, vagaId);

    // Metadados do arquivo em files
    const relPath = path.posix.join(String(req.usuario.company_id), path.basename(filepath));
    const fileIns = await db.query(
      `INSERT INTO files (company_id, storage_key, filename, mime, size, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
      [req.usuario.company_id, relPath, originalname, mimetype, size]
    );
    const file = fileIns.rows[0];
    const fileUrl = `/uploads/${file.storage_key}`;

    const curRes = await db.query(
      `INSERT INTO curriculos (candidato_id, nome_arquivo, mimetype, tamanho, texto, analise_json, company_id)
       VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7)
       RETURNING *`,
      [cand.id, originalname, mimetype, size, texto.substring(0, 15000), JSON.stringify(analise), req.usuario.company_id]
    );
    const curriculo = curRes.rows[0];

    // Resumes normalizado
    const resIns = await db.query(
      `INSERT INTO resumes (company_id, candidate_id, file_id, original_filename, parsed_text, parsed_json, created_at)
       VALUES ($1,$2,$3,$4,$5,$6::jsonb, now()) RETURNING *`,
      [req.usuario.company_id, cand.id, file.id, originalname, texto.substring(0, 15000), JSON.stringify(analise)]
    );
    const resume = resIns.rows[0];

    // Se houver vaga, cria entrevista
    let entrevista = null;
    if (vagaId) {
      const eRes = await db.query(
        'INSERT INTO entrevistas (vaga_id, candidato_id, curriculo_id, company_id) VALUES ($1,$2,$3,$4) RETURNING *',
        [vagaId, cand.id, curriculo.id, req.usuario.company_id]
      );
      entrevista = eRes.rows[0];
    }

    // Finaliza job de ingestão
    await db.query(
      `UPDATE ingestion_jobs SET status=$1, progress=$2, entity_id=$3, metadata=$4::jsonb, updated_at=now() WHERE id=$5`,
      ['completed', 100, resume.id, JSON.stringify({ filename: originalname, file_id: file.id }), ingestion_job.id]
    );

    res.json({ candidato: cand, curriculo, resume, ingestion_job, file: { id: file.id, url: fileUrl, filename: file.filename, mime: file.mime, size: file.size }, entrevista });
  } catch (e) {
    console.error(e);
    try {
      if (ingestion_job && ingestion_job.id) {
        await db.query('UPDATE ingestion_jobs SET status=$1, progress=$2, updated_at=now() WHERE id=$3', ['failed', 100, ingestion_job.id]);
      }
    } catch (_) {}
    res.status(500).json({ erro: 'Falha no upload/análise' });
  }
});

module.exports = router;
