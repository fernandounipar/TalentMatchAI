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

    // Uploads de currículo (processos_ingestao + curriculos/candidatos)
    const uploads = await db.query(
      `SELECT j.id,
              j.created_at,
              j.metadata->>'filename' AS filename,
              cand.full_name AS candidato,
              r.id AS resume_id
         FROM processos_ingestao j
         LEFT JOIN curriculos r
           ON r.id = j.entity_id
          AND r.company_id = j.company_id
         LEFT JOIN candidatos cand
           ON cand.id = r.candidate_id
          AND cand.company_id = j.company_id
        WHERE j.company_id = $1
          AND j.type = 'resume_parse'
        ORDER BY j.created_at DESC
        LIMIT 50`,
      [companyId]
    );

    // Entrevistas - usando tabelas em português (entrevistas, candidaturas, vagas, candidatos)
    const entrevistas = await db.query(
      `SELECT i.id,
              i.created_at AS criado_em,
              i.status,
              i.result,
              i.overall_score,
              i.scheduled_at,
              i.completed_at,
              i.duration_minutes,
              j.title AS vaga,
              cand.full_name AS candidato,
              u.full_name AS entrevistador,
              EXISTS(SELECT 1 FROM relatorios_entrevista re WHERE re.interview_id = i.id AND re.company_id = i.company_id) AS tem_relatorio,
              (SELECT re.recommendation FROM relatorios_entrevista re WHERE re.interview_id = i.id AND re.company_id = i.company_id ORDER BY re.generated_at DESC LIMIT 1) AS relatorio_recomendacao
         FROM entrevistas i
         JOIN candidaturas a ON a.id = i.application_id
         JOIN vagas j ON j.id = a.job_id
         JOIN candidatos cand ON cand.id = a.candidate_id
         LEFT JOIN usuarios u ON u.id = i.interviewer_id
        WHERE i.company_id = $1
          AND i.deleted_at IS NULL
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

    // Normaliza entrevistas
    const statusLabels = {
      'scheduled': 'Agendada',
      'in_progress': 'Em andamento',
      'completed': 'Finalizada',
      'cancelled': 'Cancelada',
      'no_show': 'Não compareceu'
    };
    for (const row of entrevistas.rows) {
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
        // Campos RF7/RF8 adicionais
        status: row.status,
        status_label: statusLabels[row.status] || row.status,
        result: row.result,
        overall_score: row.overall_score,
        relatorio_recomendacao: row.relatorio_recomendacao,
        scheduled_at: row.scheduled_at,
        completed_at: row.completed_at,
        duration_minutes: row.duration_minutes,
        entrevistador: row.entrevistador,
      });
    }

    eventos.sort((a, b) => new Date(b.criado_em).getTime() - new Date(a.criado_em).getTime());

    res.json(eventos);
  } catch (error) {
    res.status(500).json({ erro: error.message });
  }
});

module.exports = router;
