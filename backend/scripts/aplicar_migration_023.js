/**
 * Script para aplicar Migration 023: Views de métricas de entrevistas
 * RF8 - Histórico de Entrevistas
 * 
 * Cria 7 views e 1 função para métricas e KPIs de histórico de entrevistas
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

async function aplicarMigration023() {
  const client = await pool.connect();
  
  try {
    console.log('\n=== Aplicando Migration 023: Interview Metrics Views ===\n');
    
    // Ler o arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '023_interview_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Executar a migration
    console.log('Executando migration...');
    await client.query(sql);
    
    console.log('\n✓ Migration 023 aplicada com sucesso!\n');
    
    // Validação: verificar views criadas
    console.log('=== Validando views criadas ===\n');
    
    const { rows: views } = await client.query(`
      SELECT table_name, view_definition
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name IN (
          'interview_stats_overview',
          'interviews_by_status',
          'interviews_by_result',
          'interview_timeline',
          'interviews_by_job',
          'interviews_by_interviewer',
          'interview_completion_rate'
        )
      ORDER BY table_name;
    `);
    
    console.log('Views criadas:');
    views.forEach(v => {
      console.log(`  ✓ ${v.table_name}`);
    });
    
    if (views.length !== 7) {
      console.warn(`\n⚠ Esperado 7 views, encontrado ${views.length}`);
    }
    
    // Verificar função get_interview_metrics
    const { rows: functions } = await client.query(`
      SELECT routine_name, routine_type, data_type
      FROM information_schema.routines
      WHERE routine_schema = 'public'
        AND routine_name = 'get_interview_metrics';
    `);
    
    console.log('\n=== Função get_interview_metrics ===\n');
    if (functions.length > 0) {
      functions.forEach(f => {
        console.log(`  ✓ ${f.routine_name} (${f.routine_type}) → retorna ${f.data_type}`);
      });
    } else {
      console.log('  ✗ Função não encontrada');
    }
    
    // Verificar índices adicionais
    const { rows: indexes } = await client.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'interviews'
        AND (
          indexname = 'idx_interviews_company_status'
          OR indexname = 'idx_interviews_company_result'
          OR indexname = 'idx_interviews_scheduled_date'
        )
      ORDER BY indexname;
    `);
    
    console.log('\n=== Índices adicionais para métricas ===\n');
    if (indexes.length > 0) {
      indexes.forEach(idx => {
        console.log(`  ✓ ${idx.indexname}`);
      });
    } else {
      console.log('  ⚠ Nenhum índice adicional encontrado');
    }
    
    // Testar a função get_interview_metrics
    console.log('\n=== Testando get_interview_metrics ===\n');
    
    // Pegar uma company_id existente
    const { rows: companies } = await client.query(`
      SELECT id FROM companies LIMIT 1;
    `);
    
    if (companies.length > 0) {
      const companyId = companies[0].id;
      console.log(`Testando com company_id: ${companyId}`);
      
      const { rows: metricsResult } = await client.query(`
        SELECT get_interview_metrics($1) as metrics;
      `, [companyId]);
      
      if (metricsResult.length > 0) {
        console.log('\n  Resultado:');
        console.log('  ', JSON.stringify(metricsResult[0].metrics, null, 4));
      }
    } else {
      console.log('  ⚠ Nenhuma empresa encontrada para teste');
    }
    
    // Testar views vazias
    console.log('\n=== Testando views (sem dados) ===\n');
    
    const testViews = [
      'interview_stats_overview',
      'interviews_by_status',
      'interviews_by_result'
    ];
    
    for (const viewName of testViews) {
      const { rows } = await client.query(`SELECT COUNT(*) as count FROM ${viewName};`);
      console.log(`  ${viewName}: ${rows[0].count} registros`);
    }
    
    console.log('\n=== Validação completa ===\n');
    
  } catch (error) {
    console.error('\n✗ Erro ao aplicar migration 023:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Executar
aplicarMigration023().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
