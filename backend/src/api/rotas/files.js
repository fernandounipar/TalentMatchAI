const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

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

const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } });

router.use(exigirAutenticacao);

// Upload genérico de arquivo (currículos, áudios, etc.)
router.post('/', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ erro: 'Arquivo ausente' });
    const companyId = req.usuario.company_id;
    const relPath = path.posix.join(String(companyId), path.basename(req.file.path));
    const r = await db.query(
      `INSERT INTO files (company_id, storage_key, filename, mime, size, created_at)
       VALUES ($1,$2,$3,$4,$5, now()) RETURNING *`,
      [companyId, relPath, req.file.originalname, req.file.mimetype, req.file.size]
    );
    const file = r.rows[0];
    const url = `/uploads/${file.storage_key}`;
    res.status(201).json({ id: file.id, url, filename: file.filename, mime: file.mime, size: file.size, storage_key: file.storage_key });
  } catch (e) {
    res.status(500).json({ erro: 'Falha no upload' });
  }
});

// Metadados do arquivo
router.get('/:id', async (req, res) => {
  const r = await db.query('SELECT * FROM files WHERE id=$1 AND company_id=$2', [req.params.id, req.usuario.company_id]);
  const f = r.rows[0];
  if (!f) return res.status(404).json({ erro: 'Arquivo não encontrado' });
  res.json({ ...f, url: `/uploads/${f.storage_key}` });
});

module.exports = router;
