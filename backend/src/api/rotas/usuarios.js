const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const bcrypt = require('bcryptjs');
const { exigirAutenticacao, exigirAdmin, exigirRole } = require('../../middlewares/autenticacao');
const { audit } = require('../../middlewares/audit');
const { validaDocumento, normalizaDocumento } = require('../../servicos/documento');

router.use(exigirAutenticacao);

// Criar novo usuário (somente admin)
router.post('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  try {
    const { nome, email, senha, perfil = 'USER', aceitouLGPD = true, company, is_active = true } = req.body || {};
    if (!nome || !email || !senha) return res.status(400).json({ erro: 'Campos obrigatórios: nome, email, senha' });
    if (!['USER', 'ADMIN', 'SUPER_ADMIN'].includes(perfil)) return res.status(400).json({ erro: 'Perfil inválido' });
    // Resolver company_id: usa a mesma do admin por padrão, ou cria/pega pela combinação tipo/documento
    let companyId = req.usuario.company_id;
    if (company && company.documento && company.tipo) {
      const tipo = String(company.tipo).toUpperCase();
      const documento = normalizaDocumento(company.documento);
      if (!['CPF', 'CNPJ'].includes(tipo) || !validaDocumento(tipo, documento)) {
        return res.status(400).json({ erro: 'Company inválida (tipo/documento)' });
      }
      const up = await db.query(
        `INSERT INTO companies (type, document, name)
         VALUES ($1,$2,$3)
         ON CONFLICT (document) DO UPDATE SET type = EXCLUDED.type, name = EXCLUDED.name
         RETURNING id`,
        [tipo, documento, company.nome || null]
      );
      companyId = up.rows[0].id;
    }
    const hash = await bcrypt.hash(senha, 10);
    const r = await db.query(
      'INSERT INTO usuarios (nome, email, senha_hash, perfil, aceitou_lgpd, company_id, is_active) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id,nome,email,perfil,criado_em',
      [nome, email.toLowerCase(), hash, perfil, !!aceitouLGPD, companyId, !!is_active]
    );
    const row = r.rows[0];
    await audit(req, 'create', 'usuario', row.id, { email: row.email, perfil: row.perfil });
    res.status(201).json(row);
  } catch (e) {
    if (String(e.message || '').includes('duplicate')) return res.status(409).json({ erro: 'Email já cadastrado' });
    res.status(500).json({ erro: 'Falha ao criar usuário' });
  }
});

// Listar usuários (somente admin)
router.get('/', exigirRole('ADMIN', 'SUPER_ADMIN'), async (req, res) => {
  const r = await db.query('SELECT id,nome,email,perfil,criado_em FROM usuarios WHERE company_id=$1 ORDER BY criado_em DESC', [req.usuario.company_id]);
  res.json(r.rows);
});

module.exports = router;
