const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Registrar novo usuário (cria empresa se informado CPF/CNPJ)
router.post('/registrar', async (req, res) => {
  try {
    const { nome, email, senha, aceitouLGPD, company } = req.body || {};
    if (!nome || !email || !senha) return res.status(400).json({ erro: 'Campos obrigatórios' });

    let companyId = null;
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
    const result = await db.query(
      'INSERT INTO usuarios (nome, email, senha_hash, aceitou_lgpd, perfil, company_id) VALUES ($1,$2,$3,$4,$5,COALESCE($6, (SELECT id FROM companies WHERE documento=$7 LIMIT 1))) RETURNING id,nome,email,perfil,company_id',
      [nome, email.toLowerCase(), hash, !!aceitouLGPD, 'RECRUTADOR', companyId, '00000000000000']
    );
    const usuario = result.rows[0];
    const token = jwt.sign({ id: usuario.id, email: usuario.email, perfil: usuario.perfil, companyId: usuario.company_id }, process.env.JWT_SECRET || 'dev', { expiresIn: '8h' });
    res.json({ token, usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email, perfil: usuario.perfil, company_id: usuario.company_id } });
  } catch (e) {
    if (String(e.message || '').includes('duplicate')) return res.status(409).json({ erro: 'Email já cadastrado' });
    res.status(500).json({ erro: 'Falha ao registrar' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, senha } = req.body || {};
    if (!email || !senha) return res.status(400).json({ erro: 'Credenciais obrigatórias' });
    const r = await db.query('SELECT * FROM usuarios WHERE email=$1', [email.toLowerCase()]);
    const u = r.rows[0];
    if (!u) return res.status(401).json({ erro: 'Credenciais inválidas' });
    const ok = await bcrypt.compare(senha, u.senha_hash);
    if (!ok) return res.status(401).json({ erro: 'Credenciais inválidas' });
    const token = jwt.sign({ id: u.id, email: u.email, perfil: u.perfil, companyId: u.company_id }, process.env.JWT_SECRET || 'dev', { expiresIn: '8h' });
    res.json({ token, usuario: { id: u.id, nome: u.nome, email: u.email, perfil: u.perfil, company_id: u.company_id } });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao autenticar' });
  }
});

module.exports = router;

