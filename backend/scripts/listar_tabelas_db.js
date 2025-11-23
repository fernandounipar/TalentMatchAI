const db = require('../src/config/database');

async function listarTabelas() {
  console.log('\n=== Listando tabelas do banco de dados ===\n');

  try {
    // Listar todas as tabelas
    const result = await db.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      ORDER BY tablename
    `);

    console.log(`Total de tabelas: ${result.rows.length}\n`);
    
    // Classificar tabelas
    const tabelasMVP = [];
    const tabelasLegacy = [];
    const tabelasAuxiliares = [];

    result.rows.forEach(row => {
      const nome = row.tablename;
      
      // Tabelas MVP em inglês
      if ([
        'companies', 'users', 'sessions', 'refresh_tokens', 'password_resets',
        'audit_logs', 'files', 'jobs', 'job_revisions', 
        'candidates', 'skills', 'candidate_skills', 'candidate_github_profiles',
        'applications', 'application_stages', 'application_status_history', 'notes',
        'pipelines', 'pipeline_stages',
        'resumes', 'resume_analysis', 'resume_processing_stats',
        'interviews', 'interview_sessions', 'interview_questions', 
        'interview_answers', 'interview_messages', 'ai_feedback',
        'interview_reports',
        'calendar_events', 'ingestion_jobs', 'api_keys'
      ].includes(nome)) {
        tabelasMVP.push(nome);
      }
      // Tabelas legadas em português
      else if ([
        'vagas', 'candidatos', 'curriculos', 'entrevistas', 
        'perguntas', 'relatorios', 'mensagens'
      ].includes(nome)) {
        tabelasLegacy.push(nome);
      }
      // Outras
      else {
        tabelasAuxiliares.push(nome);
      }
    });

    console.log('=== TABELAS MVP (em uso) ===\n');
    tabelasMVP.forEach(t => console.log(`  ✓ ${t}`));

    console.log('\n=== TABELAS LEGACY (pt-BR, considerar remoção) ===\n');
    tabelasLegacy.forEach(t => console.log(`  ⚠ ${t}`));

    console.log('\n=== TABELAS AUXILIARES/OUTRAS ===\n');
    tabelasAuxiliares.forEach(t => console.log(`  ? ${t}`));

    console.log('\n=== Resumo ===\n');
    console.log(`  MVP: ${tabelasMVP.length} tabelas`);
    console.log(`  Legacy: ${tabelasLegacy.length} tabelas`);
    console.log(`  Outras: ${tabelasAuxiliares.length} tabelas`);
    console.log(`  Total: ${result.rows.length} tabelas\n`);

  } catch (error) {
    console.error('✗ Erro ao listar tabelas:', error.message);
    process.exit(1);
  } finally {
    if (db.pool) await db.pool.end();
    process.exit(0);
  }
}

listarTabelas();
