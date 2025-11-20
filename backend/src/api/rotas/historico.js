const express = require('express');
const router = express.Router();
const db = require('../../config/database');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

router.use(exigirAutenticacao);

// Timeline de eventos (histórico) por tenant
// Combina uploads de currículo, entrevistas (legado e novo domínio) e gera um payload comum
router.get('/', async (req, res) => {
  try {
    const companyId = req.usuario.company_id;

    // Uploads de currículo (ingestion_jobs + resumes/candidates)
    const uploads = await db.query(
      `SELECT j.id,
              j.created_at,
              j.metadata->>'filename' AS filename,
              cand.full_name AS candidato,
              r.id AS resume_id
         FROM ingestion_jobs j
         LEFT JOIN resumes r
           ON r.id = j.entity_id
          AND r.company_id = j.company_id
         LEFT JOIN candidates cand
           ON cand.id = r.candidate_id
          AND cand.company_id = j.company_id
        WHERE j.company_id = $1
          AND j.type = 'resume_parse'
        ORDER BY j.created_at DESC
        LIMIT 50`,
      [companyId]
    );

    // Entrevistas (tabelas legadas)
    const legacy = await db.query(
      `SELECT e.id,
              e.criado_em,
              v.titulo AS vaga,
              c.nome AS candidato,
              EXISTS(SELECT 1 FROM relatorios r2 WHERE r2.entrevista_id = e.id) AS tem_relatorio
         FROM entrevistas e
         JOIN vagas v ON v.id = e.vaga_id
         JOIN candidatos c ON c.id = e.candidato_id
        WHERE e.company_id = $1
        ORDER BY e.criado_em DESC
        LIMIT 50`,
      [companyId]
    );

    // Entrevistas (domínio novo)
    const modern = await db.query(
      `SELECT i.id,
              i.created_at AS criado_em,
              j.title AS vaga,
              cand.full_name AS candidato,
              EXISTS(SELECT 1 FROM interview_reports ir WHERE ir.interview_id = i.id AND ir.company_id = i.company_id) AS tem_relatorio
         FROM interviews i
         JOIN applications a ON a.id = i.application_id
         JOIN jobs j ON j.id = a.job_id
         JOIN candidates cand ON cand.id = a.candidate_id
        WHERE i.company_id = $1
        ORDER BY i.created_at DESC
        LIMIT 50`,
      [companyId]
    );

    const eventos = [];

    // Normaliza uploads de currículo
    for (const row of uploads.rows) {
      eventos.push({
        id: String(row.id),
        criado_em: row.created_at,
        tipo: 'Upload',
        descricao: `Upload de currículo ${row.filename || ''}`.trim(),
        usuario: row.candidato || '',
        entidade: 'Currículo',
        entidade_id: row.resume_id ? String(row.resume_id) : String(row.id),
        // Campos de compatibilidade com frontend existente
        vaga: null,
        candidato: row.candidato || null,
        tem_relatorio: false,
      });
    }

    // Normaliza entrevistas legadas
    for (const row of legacy.rows) {
      eventos.push({
        id: String(row.id),
        criado_em: row.criado_em,
        tipo: 'Entrevista',
        descricao: `Entrevista ${row.tem_relatorio ? 'com relatório' : 'registrada'} para ${row.vaga}`,
        usuario: row.candidato || '',
        entidade: 'Entrevista',
        entidade_id: String(row.id),
        vaga: row.vaga,
        candidato: row.candidato,
        tem_relatorio: row.tem_relatorio,
      });
    }

    // Normaliza entrevistas do domínio novo
    for (const row of modern.rows) {
      eventos.push({
        id: String(row.id),
        criado_em: row.criado_em,
        tipo: 'Entrevista',
        descricao: `Entrevista ${row.tem_relatorio ? 'com relatório' : 'registrada'} para ${row.vaga}`,
        usuario: row.candidato || '',
        entidade: 'Entrevista',
        entidade_id: String(row.id),
        vaga: row.vaga,
        candidato: row.candidato,
        tem_relatorio: row.tem_relatorio,
      });
    }

    eventos.sort((a, b) => new Date(b.criado_em).getTime() - new Date(a.criado_em).getTime());

    res.json(eventos);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;
