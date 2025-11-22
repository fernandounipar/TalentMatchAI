/**
 * Script para aplicar Migration 025: User Management Metrics Views
 * RF10 - Gerenciamento de Usuários
 * 
 * Cria 7 views e 1 função para métricas de usuários:
 * - user_stats_overview, users_by_role, users_by_department
 * - user_login_timeline, user_registration_timeline
 * - user_security_stats, user_invitation_stats
 * - get_user_metrics()
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

async function aplicarMigration025() {
  const client = await pool.connect();
  
  try {
    console.log('\n=== Aplicando Migration 025: User Management Metrics Views ===\n');
    
    // Ler o arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '025_user_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Executar a migration
    console.log('Executando migration...');
    await client.query(sql);
    
    console.log('\n✓ Migration 025 aplicada com sucesso!\n');
    
    // Validação: verificar views criadas
    console.log('=== Validando views criadas ===\n');
    
    const expectedViews = [
      'user_stats_overview',
      'users_by_role',
      'users_by_department',
      'user_login_timeline',
      'user_registration_timeline',
      'user_security_stats',
      'user_invitation_stats'
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
    
    // Verificar função get_user_metrics
    const { rows: functions } = await client.query(`
      SELECT routine_name, routine_type
      FROM information_schema.routines
      WHERE routine_schema = 'public'
        AND routine_name = 'get_user_metrics';
    `);
    
    console.log('\n=== Função get_user_metrics ===\n');
    if (functions.length > 0) {
      console.log(`  ✓ Função criada (${functions[0].routine_type})`);
    } else {
      console.log('  ✗ Função não encontrada');
    }
    
    // Verificar índices adicionais
    const { rows: indexes } = await client.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'users'
        AND (
          indexname = 'idx_users_company_role'
          OR indexname = 'idx_users_company_active'
          OR indexname = 'idx_users_registration_date'
        )
      ORDER BY indexname;
    `);
    
    console.log('\n=== Índices adicionais ===\n');
    if (indexes.length > 0) {
      indexes.forEach(idx => {
        console.log(`  ✓ ${idx.indexname}`);
      });
    } else {
      console.log('  ⚠ Nenhum índice adicional encontrado');
    }
    
    // Testar função get_user_metrics (sem company_id específico)
    console.log('\n=== Testando get_user_metrics() ===\n');
    
    try {
      const { rows: metricsTest } = await client.query(`
        SELECT get_user_metrics(NULL) as metrics;
      `);
      
      if (metricsTest.length > 0 && metricsTest[0].metrics) {
        const metrics = metricsTest[0].metrics;
        console.log('  ✓ Função executada com sucesso');
        console.log(`  Métricas retornadas: ${Object.keys(metrics).length} campos`);
        console.log('\n  Exemplo de métricas:');
        console.log(`    - total_users: ${metrics.total_users}`);
        console.log(`    - active_users: ${metrics.active_users}`);
        console.log(`    - verified_users: ${metrics.verified_users}`);
        console.log(`    - active_rate: ${metrics.active_rate}%`);
        console.log(`    - verification_rate: ${metrics.verification_rate}%`);
      }
    } catch (err) {
      console.log('  ⚠ Erro ao testar função:', err.message);
    }
    
    // Verificar se views retornam dados
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
    console.error('\n✗ Erro ao aplicar migration 025:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Executar
aplicarMigration025().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
