/**
 * Script para aplicar Migration 022: Melhorias na tabela interviews
 * RF8 - Histórico de Entrevistas
 * 
 * Adiciona 11 colunas: notes, duration_minutes, completed_at, cancelled_at,
 * cancellation_reason, interviewer_id, result, overall_score, metadata,
 * updated_at, deleted_at
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

async function aplicarMigration022() {
  const client = await pool.connect();
  
  try {
    console.log('\n=== Aplicando Migration 022: Interview Improvements ===\n');
    
    // Ler o arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '022_interviews_improvements.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Executar a migration
    console.log('Executando migration...');
    await client.query(sql);
    
    console.log('\n✓ Migration 022 aplicada com sucesso!\n');
    
    // Validação: verificar colunas adicionadas
    console.log('=== Validando estrutura da tabela interviews ===\n');
    
    const { rows: columns } = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'interviews'
      ORDER BY ordinal_position;
    `);
    
    console.log('Colunas da tabela interviews:');
    columns.forEach(col => {
      console.log(`  - ${col.column_name} (${col.data_type}) ${col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}`);
    });
    
    // Verificar se as novas colunas foram criadas
    const newColumns = [
      'notes', 'duration_minutes', 'completed_at', 'cancelled_at',
      'cancellation_reason', 'interviewer_id', 'result', 'overall_score',
      'metadata', 'updated_at', 'deleted_at'
    ];
    
    console.log('\n=== Verificando novas colunas ===\n');
    const foundColumns = columns.map(c => c.column_name);
    newColumns.forEach(col => {
      const found = foundColumns.includes(col);
      console.log(`  ${found ? '✓' : '✗'} ${col}`);
    });
    
    // Verificar constraint de status
    const { rows: constraints } = await client.query(`
      SELECT constraint_name, check_clause
      FROM information_schema.check_constraints
      WHERE constraint_name LIKE '%interviews_status%';
    `);
    
    console.log('\n=== Constraints de status ===\n');
    if (constraints.length > 0) {
      constraints.forEach(c => {
        console.log(`  - ${c.constraint_name}`);
        console.log(`    ${c.check_clause}`);
      });
    }
    
    // Verificar foreign key interviewer_id
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
      WHERE tc.table_name = 'interviews'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'interviewer_id';
    `);
    
    console.log('\n=== Foreign Key interviewer_id ===\n');
    if (fkeys.length > 0) {
      fkeys.forEach(fk => {
        console.log(`  ✓ ${fk.constraint_name}: ${fk.column_name} → ${fk.foreign_table_name}(${fk.foreign_column_name})`);
      });
    } else {
      console.log('  ✗ Foreign key não encontrada');
    }
    
    // Verificar índices
    const { rows: indexes } = await client.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'interviews'
        AND indexname LIKE '%_022%'
      ORDER BY indexname;
    `);
    
    console.log('\n=== Índices criados pela migration 022 ===\n');
    if (indexes.length > 0) {
      indexes.forEach(idx => {
        console.log(`  ✓ ${idx.indexname}`);
      });
      console.log(`\nTotal: ${indexes.length} índices criados`);
    } else {
      console.log('  ⚠ Nenhum índice com sufixo _022 encontrado');
    }
    
    // Verificar trigger
    const { rows: triggers } = await client.query(`
      SELECT trigger_name, event_manipulation, action_statement
      FROM information_schema.triggers
      WHERE event_object_table = 'interviews'
        AND trigger_name = 'trigger_update_interviews_timestamps';
    `);
    
    console.log('\n=== Trigger update_interviews_timestamps ===\n');
    if (triggers.length > 0) {
      triggers.forEach(t => {
        console.log(`  ✓ ${t.trigger_name} (${t.event_manipulation})`);
      });
    } else {
      console.log('  ✗ Trigger não encontrado');
    }
    
    console.log('\n=== Validação completa ===\n');
    
  } catch (error) {
    console.error('\n✗ Erro ao aplicar migration 022:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Executar
aplicarMigration022().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
