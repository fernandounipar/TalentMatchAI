const db = require('../src/config/database');
const fs = require('fs');
const path = require('path');

async function aplicarMigration030() {
  console.log('\n=== Aplicando Migration 030: Interview Chat and Dashboard ===\n');

  try {
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '030_interview_chat_and_dashboard.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executando migration...\n');
    await db.query(sql);
    console.log('✓ Migration 030 aplicada com sucesso!\n');

    // Validações
    console.log('=== Validando estrutura de interview_questions ===\n');

    const expectedColumns = [
      'text',
      'order',
      'updated_at',
      'deleted_at'
    ];

    for (const colName of expectedColumns) {
      const result = await db.query(`
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'interview_questions' AND column_name = $1
      `, [colName]);

      console.log(result.rows.length > 0 
        ? `  ✓ interview_questions.${colName} (${result.rows[0].data_type})`
        : `  ✗ interview_questions.${colName} (AUSENTE)`);
    }

    // Verificar índices de interview_questions
    console.log('\n=== Índices de interview_questions ===\n');
    const idxResult = await db.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'interview_questions'
        AND indexname = 'idx_interview_questions_interview_order'
    `);
    console.log(idxResult.rows.length > 0 
      ? '  ✓ idx_interview_questions_interview_order'
      : '  ✗ Índice não encontrado');

    // Verificar tabela interview_messages
    console.log('\n=== Validando tabela interview_messages ===\n');
    const messagesTable = await db.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_name = 'interview_messages'
    `);

    if (messagesTable.rows.length > 0) {
      console.log('  ✓ Tabela interview_messages criada');

      const messageCols = ['id', 'company_id', 'interview_id', 'sender', 'message', 'metadata', 'created_at'];
      for (const col of messageCols) {
        const result = await db.query(`
          SELECT column_name, data_type
          FROM information_schema.columns
          WHERE table_name = 'interview_messages' AND column_name = $1
        `, [col]);

        console.log(result.rows.length > 0 
          ? `  ✓ interview_messages.${col} (${result.rows[0].data_type})`
          : `  ✗ interview_messages.${col} (AUSENTE)`);
      }

      // Verificar índice
      const msgIdx = await db.query(`
        SELECT indexname
        FROM pg_indexes
        WHERE tablename = 'interview_messages'
          AND indexname = 'idx_interview_messages_company'
      `);
      console.log(msgIdx.rows.length > 0 
        ? '  ✓ idx_interview_messages_company'
        : '  ✗ Índice não encontrado');
    } else {
      console.log('  ✗ Tabela interview_messages não encontrada');
    }

    // Verificar colunas de interview_reports
    console.log('\n=== Validando colunas de interview_reports ===\n');
    const reportCols = [
      'content',
      'summary_text',
      'candidate_name',
      'job_title',
      'overall_score',
      'recommendation',
      'strengths',
      'weaknesses',
      'risks',
      'format',
      'version',
      'generated_by',
      'generated_at',
      'is_final',
      'deleted_at'
    ];

    for (const col of reportCols) {
      const result = await db.query(`
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'interview_reports' AND column_name = $1
      `, [col]);

      console.log(result.rows.length > 0 
        ? `  ✓ interview_reports.${col} (${result.rows[0].data_type})`
        : `  ✗ interview_reports.${col} (AUSENTE)`);
    }

    // Verificar índice de interview_reports
    console.log('\n=== Índices de interview_reports ===\n');
    const reportIdx = await db.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'interview_reports'
        AND indexname = 'idx_interview_reports_company_interview'
    `);
    console.log(reportIdx.rows.length > 0 
      ? '  ✓ idx_interview_reports_company_interview'
      : '  ✗ Índice não encontrado');

    // Verificar função get_dashboard_overview
    console.log('\n=== Função de Dashboard ===\n');
    const func = await db.query(`
      SELECT proname, prokind
      FROM pg_proc
      WHERE proname = 'get_dashboard_overview'
        AND pronamespace = 'public'::regnamespace
    `);

    console.log(func.rows.length > 0 
      ? '  ✓ get_dashboard_overview (FUNCTION)'
      : '  ✗ Função não encontrada');

    // Testar função get_dashboard_overview
    if (func.rows.length > 0) {
      console.log('\n=== Testando get_dashboard_overview() ===\n');
      try {
        // Primeiro, verificar se existe alguma empresa
        const companies = await db.query('SELECT id FROM companies LIMIT 1');
        
        if (companies.rows.length > 0) {
          const companyId = companies.rows[0].id;
          const testResult = await db.query(`
            SELECT * FROM get_dashboard_overview($1)
          `, [companyId]);
          
          console.log('  ✓ Função executada com sucesso\n');
          
          const overview = testResult.rows[0] || {};
          console.log('  KPIs retornados:');
          console.log(`    - vagas: ${overview.vagas || 0}`);
          console.log(`    - curriculos: ${overview.curriculos || 0}`);
          console.log(`    - entrevistas: ${overview.entrevistas || 0}`);
          console.log(`    - relatorios: ${overview.relatorios || 0}`);
          console.log(`    - candidatos: ${overview.candidatos || 0}`);
        } else {
          console.log('  ⚠ Nenhuma empresa encontrada para teste. Função criada mas não testada.');
        }
      } catch (err) {
        console.log('  ✗ Erro ao testar função:', err.message);
      }
    }

    console.log('\n=== Validação completa ===\n');

  } catch (error) {
    console.error('✗ Erro ao aplicar migration 030:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    // Fechar pool de conexões
    if (db && db.pool && typeof db.pool.end === 'function') {
      await db.pool.end();
    }
    process.exit(0);
  }
}

aplicarMigration030();
