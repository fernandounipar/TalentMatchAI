/**
 * Script para aplicar Migration 026: Dashboard Presets
 * RF9 - Dashboard de Acompanhamento
 * 
 * Cria tabela dashboard_presets para salvar configurações personalizadas
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

async function aplicarMigration026() {
  const client = await pool.connect();
  
  try {
    console.log('\n=== Aplicando Migration 026: Dashboard Presets ===\n');
    
    const sqlPath = path.join(__dirname, 'sql', '026_dashboard_presets.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('Executando migration...');
    await client.query(sql);
    
    console.log('\n✓ Migration 026 aplicada com sucesso!\n');
    
    // Validação: verificar tabela criada
    console.log('=== Validando tabela dashboard_presets ===\n');
    
    const { rows: columns } = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'dashboard_presets'
      ORDER BY ordinal_position;
    `);
    
    console.log(`Total de colunas: ${columns.length}`);
    
    const expectedColumns = [
      'id', 'user_id', 'company_id', 'name', 'description',
      'filters', 'layout', 'preferences',
      'is_default', 'is_shared', 'shared_with_roles',
      'usage_count', 'last_used_at',
      'created_at', 'updated_at', 'deleted_at'
    ];
    
    console.log('\n=== Verificando colunas ===\n');
    const foundColumns = columns.map(c => c.column_name);
    expectedColumns.forEach(col => {
      const found = foundColumns.includes(col);
      console.log(`  ${found ? '✓' : '✗'} ${col}`);
    });
    
    // Verificar foreign keys
    const { rows: fkeys } = await client.query(`
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
      WHERE tc.table_name = 'dashboard_presets'
        AND tc.constraint_type = 'FOREIGN KEY';
    `);
    
    console.log('\n=== Foreign Keys ===\n');
    if (fkeys.length > 0) {
      fkeys.forEach(fk => {
        console.log(`  ✓ ${fk.constraint_name}: ${fk.column_name} → ${fk.foreign_table_name}(${fk.foreign_column_name})`);
      });
    }
    
    // Verificar índices
    const { rows: indexes } = await client.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'dashboard_presets'
        AND indexname LIKE 'idx_dashboard%'
      ORDER BY indexname;
    `);
    
    console.log('\n=== Índices ===\n');
    if (indexes.length > 0) {
      indexes.forEach(idx => {
        console.log(`  ✓ ${idx.indexname}`);
      });
      console.log(`\nTotal: ${indexes.length} índices`);
    }
    
    // Verificar triggers
    const { rows: triggers } = await client.query(`
      SELECT trigger_name, event_manipulation, action_statement
      FROM information_schema.triggers
      WHERE event_object_table = 'dashboard_presets'
      ORDER BY trigger_name;
    `);
    
    console.log('\n=== Triggers ===\n');
    if (triggers.length > 0) {
      triggers.forEach(t => {
        console.log(`  ✓ ${t.trigger_name} (${t.event_manipulation})`);
      });
    }
    
    // Verificar view
    const { rows: views } = await client.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name = 'dashboard_presets_overview';
    `);
    
    console.log('\n=== View ===\n');
    if (views.length > 0) {
      console.log('  ✓ dashboard_presets_overview criada');
    }
    
    console.log('\n=== Validação completa ===\n');
    
  } catch (error) {
    console.error('\n✗ Erro ao aplicar migration 026:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration026().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
