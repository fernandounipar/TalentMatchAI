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
    const nomeLower = (originalname || '').toLowerCase();
    const isPdf = mimetype === 'application/pdf' || nomeLower.endsWith('.pdf');
    const isTxt = mimetype === 'text/plain' || nomeLower.endsWith('.txt');
    const isDocx =
      mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      nomeLower.endsWith('.docx');

    if (isPdf) {
      const data = await pdfParse(dataBuffer);
      texto = data.text || '';
    } else if (isTxt) {
      texto = dataBuffer.toString('utf8');
    } else if (isDocx) {
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

    // Upsert candidato na tabela normalizada (candidates)
    const email = candidato.email || null;
    const github = candidato.github || null;
    
    let cand;
    if (email) {
      // Se tem email, tenta fazer upsert usando o índice único (company_id, lower(email))
      const cRes = await db.query(
        `INSERT INTO candidates (full_name, email, github_url, company_id, created_at)
         VALUES ($1, $2, $3, $4, now())
         ON CONFLICT (company_id, lower(email)) 
         DO UPDATE SET full_name = EXCLUDED.full_name, github_url = EXCLUDED.github_url, updated_at = now()
         RETURNING *`,
        [candidato.nome || 'Candidato', email, github, req.usuario.company_id]
      );
      cand = cRes.rows[0];
    } else {
      // Se não tem email, apenas insere (sem upsert)
      const cRes = await db.query(
        `INSERT INTO candidates (full_name, email, github_url, company_id, created_at)
         VALUES ($1, $2, $3, $4, now())
         RETURNING *`,
        [candidato.nome || 'Candidato', email, github, req.usuario.company_id]
      );
      cand = cRes.rows[0];
    }

    // Carregar vaga (job) para dar contexto à IA e retornar ao frontend
    let vaga = null;
    if (vagaId) {
      try {
        const vagaRes = await db.query(
          `SELECT id, title, description, requirements, seniority, location_type, slug, status
           FROM jobs
           WHERE id = $1 AND company_id = $2`,
          [vagaId, req.usuario.company_id]
        );
        vaga = vagaRes.rows[0] || null;
      } catch (e) {
        // Se der erro ao carregar a vaga, seguimos sem quebrar o fluxo
        console.error('Erro ao carregar vaga para análise de currículo:', e.message);
      }
    }

    // Análise IA – agora com contexto da vaga selecionada (quando existir)
    const analise = await gerarAnaliseCurriculo(texto, vaga ? {
      vagaId,
      titulo: vaga.title,
      descricao: vaga.description,
      requisitos: vaga.requirements,
      seniority: vaga.seniority,
      location_type: vaga.location_type,
    } : { vagaId });

    // Metadados do arquivo em files
    const relPath = path.posix.join(String(req.usuario.company_id), path.basename(filepath));
    const fileIns = await db.query(
      `INSERT INTO files (company_id, storage_key, filename, mime, size, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
      [req.usuario.company_id, relPath, originalname, mimetype, size]
    );
    const file = fileIns.rows[0];
    const fileUrl = `/uploads/${file.storage_key}`;

    // Inserir apenas na tabela normalizada (resumes)
    const resIns = await db.query(
      `INSERT INTO resumes (company_id, candidate_id, file_id, original_filename, parsed_text, parsed_json, created_at)
       VALUES ($1,$2,$3,$4,$5,$6::jsonb, now()) RETURNING *`,
      [req.usuario.company_id, cand.id, file.id, originalname, texto.substring(0, 15000), JSON.stringify(analise)]
    );
    const resume = resIns.rows[0];

    // Se houver vaga, cria application e interview
    let entrevista = null;
    let application = null;
    if (vagaId) {
      // Primeiro, cria a application (candidatura)
      const appRes = await db.query(
        `INSERT INTO applications (company_id, job_id, candidate_id, source, stage, status, created_at)
         VALUES ($1, $2, $3, 'UPLOAD', 'TRIAGEM', 'EM_ANALISE', now()) 
         RETURNING *`,
        [req.usuario.company_id, vagaId, cand.id]
      );
      application = appRes.rows[0];
      
      // Depois, cria a interview vinculada à application
      const intRes = await db.query(
        `INSERT INTO interviews (company_id, application_id, mode, status, created_at)
         VALUES ($1, $2, 'ASSISTIDA', 'PENDENTE', now()) 
         RETURNING *`,
        [req.usuario.company_id, application.id]
      );
      entrevista = intRes.rows[0];
    }

    // Finaliza job de ingestão
    await db.query(
      `UPDATE ingestion_jobs SET status=$1, progress=$2, entity_id=$3, metadata=$4::jsonb, updated_at=now() WHERE id=$5`,
      ['completed', 100, resume.id, JSON.stringify({ filename: originalname, file_id: file.id }), ingestion_job.id]
    );

    // Adaptação de campos para compatibilizar backend novo com frontend existente
    const candidatoCompat = {
      ...cand,
      // Alias para código legado
      nome: cand.full_name || cand.nome || candidato.nome || 'Candidato',
    };

    const curriculoCompat = {
      ...resume,
      // Alias de campos antigos
      nome_arquivo: resume.original_filename || originalname,
      analise_json: resume.parsed_json || analise,
    };

    const vagaCompat = vaga
      ? {
          ...vaga,
          // Campos usados pelo frontend antigo
          titulo: vaga.title,
          descricao: vaga.description,
          requisitos: vaga.requirements,
        }
      : null;

    res.json({
      candidato: candidatoCompat,
      curriculo: curriculoCompat, // Para compatibilidade com frontend, retorna resume como curriculo
      resume,
      application,
      ingestion_job,
      file: { id: file.id, url: fileUrl, filename: file.filename, mime: file.mime, size: file.size },
      entrevista,
      vaga: vagaCompat,
    });
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
