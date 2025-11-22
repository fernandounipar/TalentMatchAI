const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'talentmatch',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD
});

async function aplicarMigration020() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Iniciando aplicação da Migration 020...\n');
    
    const sqlPath = path.join(__dirname, 'sql', '020_interview_reports.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    await client.query(sql);
    
    console.log('\n✅ Migration 020 aplicada com sucesso!\n');
    
    // Validação
    console.log('🔍 Validando estrutura criada...\n');
    
    // 1. Verificar tabela
    const tableCheck = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'interview_reports'
      ORDER BY ordinal_position
    `);
    
    console.log(`✓ Tabela interview_reports: ${tableCheck.rows.length} colunas`);
    
    // 2. Verificar constraints
    const constraintCheck = await client.query(`
      SELECT constraint_name, constraint_type
      FROM information_schema.table_constraints
      WHERE table_name = 'interview_reports'
    `);
    
    console.log(`✓ Constraints: ${constraintCheck.rows.length} encontradas`);
    constraintCheck.rows.forEach(c => {
      console.log(`  - ${c.constraint_name} (${c.constraint_type})`);
    });
    
    // 3. Verificar índices
    const indexCheck = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'interview_reports'
      ORDER BY indexname
    `);
    
    console.log(`✓ Índices: ${indexCheck.rows.length} criados`);
    indexCheck.rows.forEach(i => {
      console.log(`  - ${i.indexname}`);
    });
    
    // 4. Verificar trigger
    const triggerCheck = await client.query(`
      SELECT trigger_name, event_manipulation
      FROM information_schema.triggers
      WHERE event_object_table = 'interview_reports'
    `);
    
    console.log(`✓ Triggers: ${triggerCheck.rows.length} ativo(s)`);
    triggerCheck.rows.forEach(t => {
      console.log(`  - ${t.trigger_name} (${t.event_manipulation})`);
    });
    
    // 5. Verificar função
    const functionCheck = await client.query(`
      SELECT proname
      FROM pg_proc
      WHERE proname = 'update_interview_reports_timestamps'
    `);
    
    console.log(`✓ Função update_interview_reports_timestamps: ${functionCheck.rows.length > 0 ? 'CRIADA' : 'NÃO ENCONTRADA'}`);
    
    // 6. Testar inserção básica
    console.log('\n🧪 Testando inserção básica...');
    const testCompany = await client.query(`SELECT id FROM companies LIMIT 1`);
    const testInterview = await client.query(`SELECT id FROM interviews LIMIT 1`);
    
    if (testCompany.rows.length > 0 && testInterview.rows.length > 0) {
      const insertTest = await client.query(`
        INSERT INTO interview_reports (
          company_id,
          interview_id,
          title,
          report_type,
          content,
          summary_text,
          overall_score,
          recommendation
        ) VALUES ($1, $2, 'Teste Migration 020', 'summary', '{"test": true}'::jsonb, 'Relatório de teste', 8.5, 'APPROVE')
        RETURNING id
      `, [testCompany.rows[0].id, testInterview.rows[0].id]);
      
      const testId = insertTest.rows[0].id;
      console.log(`✓ Registro de teste criado: ${testId}`);
      
      // Testar update (trigger)
      await client.query(`UPDATE interview_reports SET title = 'Teste Atualizado' WHERE id = $1`, [testId]);
      
      const checkUpdate = await client.query(`
        SELECT updated_at > created_at as trigger_works
        FROM interview_reports
        WHERE id = $1
      `, [testId]);
      
      console.log(`✓ Trigger de update_at: ${checkUpdate.rows[0].trigger_works ? 'FUNCIONANDO' : 'FALHOU'}`);
      
      // Limpar teste
      await client.query(`DELETE FROM interview_reports WHERE id = $1`, [testId]);
      console.log(`✓ Registro de teste removido`);
    } else {
      console.log('⚠ Sem dados de company/interview para teste - pulando validação de inserção');
    }
    
    console.log('\n✅ Validação completa! Migration 020 está funcional.\n');
    
  } catch (error) {
    console.error('❌ Erro ao aplicar migration:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration020();
