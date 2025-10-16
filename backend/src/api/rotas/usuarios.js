const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const bcrypt = require('bcryptjs');
const { exigirAutenticacao, exigirAdmin } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

// Criar novo usuário (somente admin)
router.post('/', exigirAdmin, async (req, res) => {
  try {
    const { nome, email, senha, perfil = 'RECRUTADOR', aceitouLGPD = true, company } = req.body || {};
    if (!nome || !email || !senha) return res.status(400).json({ erro: 'Campos obrigatórios: nome, email, senha' });
    if (!['ADMIN', 'RECRUTADOR', 'GESTOR'].includes(perfil)) return res.status(400).json({ erro: 'Perfil inválido' });
    // Resolver company_id: usa a mesma do admin por padrão, ou cria/pega pela combinação tipo/documento
    let companyId = req.usuario.companyId;
    if (company && company.documento && company.tipo) {
      const up = await db.query(
        `INSERT INTO companies (tipo, documento, nome)
         VALUES ($1,$2,$3)
         ON CONFLICT (documento) DO UPDATE SET tipo=EXCLUDED.tipo, nome=EXCLUDED.nome
         RETURNING id`, [company.tipo, String(company.documento), company.nome || null]
      );
      companyId = up.rows[0].id;
    }
    const hash = await bcrypt.hash(senha, 10);
    const r = await db.query(
      'INSERT INTO usuarios (nome, email, senha_hash, perfil, aceitou_lgpd, company_id) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id,nome,email,perfil,criado_em',
      [nome, email.toLowerCase(), hash, perfil, !!aceitouLGPD, companyId]
    );
    res.status(201).json(r.rows[0]);
  } catch (e) {
    if (String(e.message || '').includes('duplicate')) return res.status(409).json({ erro: 'Email já cadastrado' });
    res.status(500).json({ erro: 'Falha ao criar usuário' });
  }
});

// Listar usuários (somente admin)
router.get('/', exigirAdmin, async (req, res) => {
  const r = await db.query('SELECT id,nome,email,perfil,criado_em FROM usuarios WHERE company_id=$1 ORDER BY criado_em DESC', [req.usuario.companyId]);
  res.json(r.rows);
});

module.exports = router;
