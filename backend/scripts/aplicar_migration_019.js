const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'talentmatch_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres'
});

async function aplicarMigration019() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Aplicando Migration 019: assessment metrics views...\n');
    
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '019_assessment_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Aplicar migration
    await client.query(sql);
    console.log('✅ Migration 019 aplicada com sucesso!\n');
    
    // Validar views criadas
    console.log('📊 Validando views de métricas...');
    const views = await client.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
      AND table_name LIKE '%assessment%'
      ORDER BY table_name;
    `);
    
    console.log(`  ➜ Views criadas: ${views.rows.length}`);
    views.rows.forEach(v => {
      console.log(`    - ${v.table_name}`);
    });
    
    // Testar cada view com COUNT
    console.log('\n📊 Testando views com SELECT COUNT...');
    
    const viewsToTest = [
      'assessment_stats_overview',
      'assessment_by_interview',
      'assessment_type_distribution',
      'assessment_concordance_stats',
      'assessment_performance_timeline'
    ];
    
    for (const viewName of viewsToTest) {
      try {
        const result = await client.query(`SELECT COUNT(*) as count FROM ${viewName}`);
        console.log(`  ✅ ${viewName}: ${result.rows[0].count} registros`);
      } catch (err) {
        console.log(`  ❌ ${viewName}: Erro - ${err.message}`);
      }
    }
    
    // Testar função get_assessment_metrics
    console.log('\n📊 Testando função get_assessment_metrics...');
    
    // Pegar primeiro company_id disponível
    const companyResult = await client.query(`
      SELECT id FROM companies LIMIT 1
    `);
    
    if (companyResult.rows.length > 0) {
      const companyId = companyResult.rows[0].id;
      const metricsResult = await client.query(
        `SELECT * FROM get_assessment_metrics($1)`,
        [companyId]
      );
      
      console.log(`  ✅ Função retornou ${metricsResult.rows.length} métricas:`);
      metricsResult.rows.forEach(m => {
        console.log(`    - ${m.metric_label}: ${m.metric_value}`);
      });
    } else {
      console.log('  ⚠️  Nenhuma empresa encontrada para testar a função');
    }
    
    // Verificar índices adicionais
    console.log('\n📊 Verificando índices adicionais...');
    const indexes = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'live_assessments'
      AND indexname IN ('idx_live_assessments_scores', 'idx_live_assessments_date')
      ORDER BY indexname;
    `);
    
    console.log(`  ➜ Índices adicionais: ${indexes.rows.length}`);
    indexes.rows.forEach(idx => {
      console.log(`    - ${idx.indexname}`);
    });
    
    console.log('\n✅ Validação completa! Migration 019 aplicada com sucesso.');
    
  } catch (error) {
    console.error('❌ Erro ao aplicar migration 019:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration019();
