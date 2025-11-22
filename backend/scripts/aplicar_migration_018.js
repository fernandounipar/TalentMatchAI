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

async function aplicarMigration018() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Aplicando Migration 018: live_assessments...\n');
    
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '018_live_assessments.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Aplicar migration
    await client.query(sql);
    console.log('✅ Migration 018 aplicada com sucesso!\n');
    
    // Validar estrutura live_assessments
    console.log('📊 Validando tabela live_assessments...');
    const columns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'live_assessments'
      ORDER BY ordinal_position;
    `);
    
    console.log(`  ➜ Colunas: ${columns.rows.length}`);
    columns.rows.forEach(col => {
      console.log(`    - ${col.column_name} (${col.data_type}, ${col.is_nullable === 'NO' ? 'NOT NULL' : 'nullable'})`);
    });
    
    // Verificar constraints
    console.log('\n📊 Verificando constraints...');
    const constraints = await client.query(`
      SELECT constraint_name, constraint_type
      FROM information_schema.table_constraints
      WHERE table_name = 'live_assessments'
      AND constraint_type IN ('CHECK', 'FOREIGN KEY')
      ORDER BY constraint_name;
    `);
    
    console.log(`  ➜ Constraints: ${constraints.rows.length}`);
    constraints.rows.forEach(c => {
      console.log(`    - ${c.constraint_name} (${c.constraint_type})`);
    });
    
    // Verificar índices
    console.log('\n📊 Verificando índices criados...');
    const indexes = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'live_assessments'
      AND indexname LIKE 'idx_%'
      ORDER BY indexname;
    `);
    
    console.log(`  ➜ Índices criados: ${indexes.rows.length}`);
    indexes.rows.forEach(idx => {
      console.log(`    - ${idx.indexname}`);
    });
    
    // Verificar triggers
    console.log('\n📊 Verificando triggers...');
    const triggers = await client.query(`
      SELECT trigger_name, event_manipulation
      FROM information_schema.triggers
      WHERE event_object_table = 'live_assessments'
      ORDER BY trigger_name;
    `);
    
    console.log(`  ➜ Triggers criados: ${triggers.rows.length}`);
    triggers.rows.forEach(trg => {
      console.log(`    - ${trg.trigger_name} (${trg.event_manipulation})`);
    });
    
    // Verificar função
    console.log('\n📊 Verificando funções...');
    const functions = await client.query(`
      SELECT proname
      FROM pg_proc
      WHERE proname = 'update_live_assessments_timestamps';
    `);
    
    console.log(`  ➜ Funções: ${functions.rows.length}`);
    functions.rows.forEach(f => {
      console.log(`    - ${f.proname}()`);
    });
    
    console.log('\n✅ Validação completa! Migration 018 aplicada com sucesso.');
    
  } catch (error) {
    console.error('❌ Erro ao aplicar migration 018:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration018();
