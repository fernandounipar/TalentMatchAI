/**
 * Script para aplicar Migration 027: Dashboard Metrics Views
 * RF9 - Dashboard de Acompanhamento
 * 
 * Cria 5 views + 1 função para métricas consolidadas de dashboard
 */

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function aplicarMigration027() {
  const client = await pool.connect();
  
  try {
    console.log('\n=== Aplicando Migration 027: Dashboard Metrics Views ===\n');
    
    const sqlPath = path.join(__dirname, 'sql', '027_dashboard_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('Executando migration...');
    await client.query(sql);
    
    console.log('\n✓ Migration 027 aplicada com sucesso!\n');
    
    // Validação: verificar views criadas
    console.log('=== Validando views criadas ===\n');
    
    const expectedViews = [
      'dashboard_global_overview',
      'dashboard_activity_timeline',
      'dashboard_preset_usage_stats',
      'dashboard_top_presets',
      'dashboard_conversion_funnel'
    ];
    
    const { rows: views } = await client.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name IN (${expectedViews.map((_, i) => `$${i + 1}`).join(', ')})
      ORDER BY table_name;
    `, expectedViews);
    
    const foundViews = views.map(v => v.table_name);
    expectedViews.forEach(viewName => {
      const found = foundViews.includes(viewName);
      console.log(`  ${found ? '✓' : '✗'} ${viewName}`);
    });
    
    // Verificar função get_dashboard_overview
    const { rows: functions } = await client.query(`
      SELECT routine_name, routine_type
      FROM information_schema.routines
      WHERE routine_schema = 'public'
        AND routine_name = 'get_dashboard_overview';
    `);
    
    console.log('\n=== Função ===\n');
    if (functions.length > 0) {
      console.log(`  ✓ get_dashboard_overview (${functions[0].routine_type})`);
    } else {
      console.log('  ✗ Função não encontrada');
    }
    
    // Verificar índices adicionais
    const { rows: indexes } = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE (
        indexname = 'idx_jobs_company_created_date'
        OR indexname = 'idx_resumes_company_created_date'
        OR indexname = 'idx_interviews_company_created_date'
      )
      ORDER BY indexname;
    `);
    
    console.log('\n=== Índices Adicionais ===\n');
    if (indexes.length > 0) {
      indexes.forEach(idx => {
        console.log(`  ✓ ${idx.indexname}`);
      });
    }
    
    // Testar função get_dashboard_overview
    console.log('\n=== Testando get_dashboard_overview() ===\n');
    
    try {
      const { rows: testResult } = await client.query(`
        SELECT get_dashboard_overview(NULL) as overview;
      `);
      
      if (testResult.length > 0 && testResult[0].overview) {
        const overview = testResult[0].overview;
        console.log('  ✓ Função executada com sucesso');
        console.log('\n  Estrutura do overview:');
        console.log(`    - global: ${overview.global ? 'presente' : 'ausente'}`);
        console.log(`    - presets: ${overview.presets ? 'presente' : 'ausente'}`);
        console.log(`    - conversion: ${overview.conversion ? 'presente' : 'ausente'}`);
        
        if (overview.global) {
          console.log('\n  Métricas globais:');
          const global = overview.global;
          console.log(`    - total_jobs: ${global.total_jobs}`);
          console.log(`    - total_resumes: ${global.total_resumes}`);
          console.log(`    - total_interviews: ${global.total_interviews}`);
        }
      }
    } catch (err) {
      console.log('  ⚠ Erro ao testar função:', err.message);
    }
    
    // Testar views com dados
    console.log('\n=== Testando views com dados ===\n');
    
    for (const viewName of expectedViews) {
      try {
        const { rows } = await client.query(`SELECT COUNT(*) as count FROM ${viewName};`);
        console.log(`  ✓ ${viewName}: ${rows[0].count} registros`);
      } catch (err) {
        console.log(`  ✗ ${viewName}: Erro - ${err.message}`);
      }
    }
    
    console.log('\n=== Validação completa ===\n');
    
  } catch (error) {
    console.error('\n✗ Erro ao aplicar migration 027:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration027().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
