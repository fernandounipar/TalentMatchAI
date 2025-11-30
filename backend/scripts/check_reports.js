const pool = require('../src/config/database');

async function checkReports() {
  try {
    // 1. Verificar relatórios na tabela
    console.log('=== RELATÓRIOS NA TABELA ===');
    const reports = await pool.query(
      `SELECT id, interview_id, company_id, candidate_name, overall_score, recommendation, created_at 
       FROM relatorios_entrevista 
       ORDER BY created_at DESC 
       LIMIT 5`
    );
    console.log('Total encontrados:', reports.rows.length);
    reports.rows.forEach((r, i) => {
      console.log(`\n[${i + 1}] ID: ${r.id}`);
      console.log(`    interview_id: ${r.interview_id}`);
      console.log(`    company_id: ${r.company_id}`);
      console.log(`    candidate_name: ${r.candidate_name}`);
      console.log(`    overall_score: ${r.overall_score}`);
      console.log(`    recommendation: ${r.recommendation}`);
      console.log(`    created_at: ${r.created_at}`);
    });

    // 2. Verificar a entrevista correspondente
    if (reports.rows.length > 0) {
      const interviewId = reports.rows[0].interview_id;
      console.log('\n=== ENTREVISTA CORRESPONDENTE ===');
      const interview = await pool.query(
        `SELECT id, company_id, status FROM entrevistas WHERE id = $1`,
        [interviewId]
      );
      if (interview.rows.length > 0) {
        console.log('Entrevista encontrada:');
        console.log('  ID:', interview.rows[0].id);
        console.log('  company_id:', interview.rows[0].company_id);
        console.log('  status:', interview.rows[0].status);
        
        // Comparar company_ids
        const reportCompanyId = reports.rows[0].company_id;
        const interviewCompanyId = interview.rows[0].company_id;
        if (reportCompanyId === interviewCompanyId) {
          console.log('\n✅ company_ids coincidem!');
        } else {
          console.log('\n❌ company_ids NÃO coincidem!');
          console.log('  Relatório company_id:', reportCompanyId);
          console.log('  Entrevista company_id:', interviewCompanyId);
        }
      } else {
        console.log('❌ Entrevista não encontrada!');
      }
    }

    // 3. Verificar query que o histórico usa
    console.log('\n=== QUERY DO HISTÓRICO (tem_relatorio) ===');
    const historico = await pool.query(
      `SELECT i.id, cand.full_name AS candidato,
              EXISTS(SELECT 1 FROM relatorios_entrevista re WHERE re.interview_id = i.id AND re.company_id = i.company_id) AS tem_relatorio
       FROM entrevistas i
       JOIN candidaturas a ON a.id = i.application_id
       JOIN candidatos cand ON cand.id = a.candidate_id
       WHERE i.deleted_at IS NULL
       ORDER BY i.created_at DESC
       LIMIT 5`
    );
    historico.rows.forEach((h, i) => {
      console.log(`[${i + 1}] ${h.candidato}: tem_relatorio = ${h.tem_relatorio}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Erro:', error);
    process.exit(1);
  }
}

checkReports();
