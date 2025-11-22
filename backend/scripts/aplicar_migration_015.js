const fs = require('fs');
const path = require('path');
const db = require('../src/config/database');

async function aplicarMigration015() {
  try {
    console.log('📊 Aplicando Migration 015 - Views de métricas de vagas...\n');

    const sqlPath = path.join(__dirname, 'sql', '015_job_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    await db.query(sql);

    console.log('✅ Migration 015 aplicada com sucesso!\n');

    // Testar views criadas
    const views = [
      'job_stats_overview',
      'job_crud_stats',
      'job_by_department_stats',
      'job_revision_history',
      'job_performance_by_period'
    ];

    console.log('🧪 Testando views criadas...\n');

    for (const viewName of views) {
      try {
        const result = await db.query(`SELECT COUNT(*) as count FROM ${viewName}`);
        console.log(`   ✅ ${viewName}: ${result.rows[0].count} registros`);
      } catch (e) {
        console.log(`   ❌ ${viewName}: erro ao consultar (${e.message})`);
      }
    }

    // Testar função get_job_metrics
    console.log('\n🧪 Testando função get_job_metrics...');
    try {
      const testCompanyId = await db.query(`
        SELECT company_id FROM jobs LIMIT 1
      `);
      
      if (testCompanyId.rows.length > 0) {
        const metricsResult = await db.query(
          'SELECT * FROM get_job_metrics($1)',
          [testCompanyId.rows[0].company_id]
        );
        console.log(`   ✅ get_job_metrics: ${metricsResult.rows.length} métricas retornadas`);
      } else {
        console.log('   ⚠️ Sem dados de jobs para testar a função');
      }
    } catch (e) {
      console.log(`   ❌ get_job_metrics: erro (${e.message})`);
    }

    // Verificar índices criados
    const indexesResult = await db.query(`
      SELECT indexname 
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename IN ('jobs', 'job_revisions')
        AND indexname LIKE 'idx_job%'
      ORDER BY indexname
    `);

    console.log(`\n🎯 Índices criados (${indexesResult.rows.length}):`);
    indexesResult.rows.forEach(idx => {
      console.log(`   - ${idx.indexname}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao aplicar migration 015:', error.message);
    console.error(error);
    process.exit(1);
  }
}

aplicarMigration015();
