const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

router.post('/registrar', async (req, res) => {
  try {
    const { nome, email, senha, aceitouLGPD } = req.body || {};
    if (!nome || !email || !senha) return res.status(400).json({ erro: 'Campos obrigatórios' });
    const hash = await bcrypt.hash(senha, 10);
    const result = await db.query(
      'INSERT INTO usuarios (nome, email, senha_hash, aceitou_lgpd) VALUES ($1,$2,$3,$4) RETURNING id,nome,email,perfil',
      [nome, email.toLowerCase(), hash, !!aceitouLGPD]
    );
    const usuario = result.rows[0];
    const token = jwt.sign({ id: usuario.id, email: usuario.email, perfil: usuario.perfil }, process.env.JWT_SECRET || 'dev', { expiresIn: '8h' });
    res.json({ token, usuario });
  } catch (e) {
    if (String(e.message || '').includes('duplicate')) return res.status(409).json({ erro: 'Email já cadastrado' });
    res.status(500).json({ erro: 'Falha ao registrar' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, senha } = req.body || {};
    if (!email || !senha) return res.status(400).json({ erro: 'Credenciais obrigatórias' });
    const r = await db.query('SELECT * FROM usuarios WHERE email=$1', [email.toLowerCase()]);
    const u = r.rows[0];
    if (!u) return res.status(401).json({ erro: 'Credenciais inválidas' });
    const ok = await bcrypt.compare(senha, u.senha_hash);
    if (!ok) return res.status(401).json({ erro: 'Credenciais inválidas' });
    const token = jwt.sign({ id: u.id, email: u.email, perfil: u.perfil }, process.env.JWT_SECRET || 'dev', { expiresIn: '8h' });
    res.json({ token, usuario: { id: u.id, nome: u.nome, email: u.email, perfil: u.perfil } });
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao autenticar' });
  }
});

module.exports = router;

