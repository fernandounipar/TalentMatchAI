const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');
const { validaDocumento, normalizaDocumento } = require('../../servicos/documento');

// Criar company (CPF/CNPJ) — pode ser usado por admins ou no onboarding
router.post('/', exigirAutenticacao, async (req, res) => {
  try {
    const { type, document, name } = req.body || {};
    const tipo = String(type || '').toUpperCase();
    const documento = normalizaDocumento(document || '');
    if (!['CPF', 'CNPJ'].includes(tipo)) {
      return res.status(400).json({ erro: 'Tipo inválido. Use CPF ou CNPJ.' });
    }
    if (!validaDocumento(tipo, documento)) {
      return res.status(400).json({ erro: 'Documento inválido.' });
    }
    const up = await db.query(
      `INSERT INTO companies (tipo, documento, nome)
       VALUES ($1,$2,$3)
       ON CONFLICT (documento) DO UPDATE SET tipo=EXCLUDED.tipo, nome=EXCLUDED.nome
       RETURNING id, tipo, documento, nome, criado_em`,
      [tipo, documento, name || null]
    );
    res.status(201).json(up.rows[0]);
  } catch (e) {
    res.status(500).json({ erro: 'Falha ao criar empresa' });
  }
});

module.exports = router;

