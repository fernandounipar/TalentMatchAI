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

async function aplicarMigration021() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Iniciando aplicação da Migration 021...\n');
    
    const sqlPath = path.join(__dirname, 'sql', '021_report_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    await client.query(sql);
    
    console.log('\n✅ Migration 021 aplicada com sucesso!\n');
    
    // Validação
    console.log('🔍 Validando views e função criadas...\n');
    
    // 1. Verificar views
    const viewsToCheck = [
      'report_stats_overview',
      'reports_by_recommendation',
      'reports_by_type',
      'report_generation_timeline',
      'reports_by_interview'
    ];
    
    for (const viewName of viewsToCheck) {
      const viewCheck = await client.query(`
        SELECT COUNT(*) as count
        FROM information_schema.views
        WHERE table_name = $1
      `, [viewName]);
      
      if (viewCheck.rows[0].count > 0) {
        console.log(`✓ View ${viewName}: CRIADA`);
        
        // Testar query da view
        const testQuery = await client.query(`SELECT * FROM ${viewName} LIMIT 1`);
        console.log(`  - Query test: ${testQuery.rows.length} registro(s) retornado(s)`);
      } else {
        console.log(`✗ View ${viewName}: NÃO ENCONTRADA`);
      }
    }
    
    // 2. Verificar função
    const functionCheck = await client.query(`
      SELECT proname, pronargs
      FROM pg_proc
      WHERE proname = 'get_report_metrics'
    `);
    
    console.log(`\n✓ Função get_report_metrics: ${functionCheck.rows.length > 0 ? 'CRIADA' : 'NÃO ENCONTRADA'}`);
    
    if (functionCheck.rows.length > 0) {
      // Testar função
      const testCompany = await client.query(`SELECT id FROM companies LIMIT 1`);
      
      if (testCompany.rows.length > 0) {
        const functionTest = await client.query(`
          SELECT get_report_metrics($1) as metrics
        `, [testCompany.rows[0].id]);
        
        const metrics = functionTest.rows[0].metrics;
        console.log('  - Teste da função:');
        console.log(`    total_reports: ${metrics.total_reports}`);
        console.log(`    final_reports: ${metrics.final_reports}`);
        console.log(`    draft_reports: ${metrics.draft_reports}`);
        console.log(`    approval_rate: ${metrics.approval_rate}%`);
        console.log(`    rejection_rate: ${metrics.rejection_rate}%`);
        console.log(`    avg_overall_score: ${metrics.avg_overall_score}`);
        console.log(`    reports_last_7_days: ${metrics.reports_last_7_days}`);
        console.log(`    reports_last_30_days: ${metrics.reports_last_30_days}`);
        console.log(`    pdf_reports: ${metrics.pdf_reports}`);
        console.log(`    json_reports: ${metrics.json_reports}`);
      } else {
        console.log('  ⚠ Sem dados de company para teste da função');
      }
    }
    
    // 3. Verificar índices adicionais
    const additionalIndexes = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'interview_reports'
        AND (indexname LIKE '%_score%' OR indexname LIKE '%_recommendation%')
      ORDER BY indexname
    `);
    
    console.log(`\n✓ Índices adicionais: ${additionalIndexes.rows.length} criado(s)`);
    additionalIndexes.rows.forEach(i => {
      console.log(`  - ${i.indexname}`);
    });
    
    // 4. Testar queries de dashboard típicas
    console.log('\n🧪 Testando queries típicas de dashboard...\n');
    
    const testCompany = await client.query(`SELECT id FROM companies LIMIT 1`);
    if (testCompany.rows.length > 0) {
      const companyId = testCompany.rows[0].id;
      
      // Overview
      const overview = await client.query(`
        SELECT * FROM report_stats_overview WHERE company_id = $1
      `, [companyId]);
      console.log(`✓ report_stats_overview: ${overview.rows.length} linha(s)`);
      
      // By recommendation
      const byRec = await client.query(`
        SELECT * FROM reports_by_recommendation WHERE company_id = $1
      `, [companyId]);
      console.log(`✓ reports_by_recommendation: ${byRec.rows.length} linha(s)`);
      
      // By type
      const byType = await client.query(`
        SELECT * FROM reports_by_type WHERE company_id = $1
      `, [companyId]);
      console.log(`✓ reports_by_type: ${byType.rows.length} linha(s)`);
      
      // Timeline (últimos 7 dias)
      const timeline = await client.query(`
        SELECT * FROM report_generation_timeline 
        WHERE company_id = $1 
          AND generation_date >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY generation_date DESC
      `, [companyId]);
      console.log(`✓ report_generation_timeline (7 dias): ${timeline.rows.length} linha(s)`);
      
      // By interview
      const byInterview = await client.query(`
        SELECT * FROM reports_by_interview 
        WHERE company_id = $1 
        LIMIT 10
      `, [companyId]);
      console.log(`✓ reports_by_interview (top 10): ${byInterview.rows.length} linha(s)`);
    }
    
    console.log('\n✅ Validação completa! Migration 021 está funcional.\n');
    
  } catch (error) {
    console.error('❌ Erro ao aplicar migration:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration021();
