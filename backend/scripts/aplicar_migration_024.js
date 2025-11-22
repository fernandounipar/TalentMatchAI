/**
 * Script para aplicar Migration 024: User Management Improvements
 * RF10 - Gerenciamento de Usuários
 * 
 * Adiciona 14 colunas: phone, department, job_title, last_login_at, last_login_ip,
 * failed_login_attempts, locked_until, email_verified, email_verified_at,
 * invitation_token, invitation_expires_at, invited_by, bio, preferences
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

async function aplicarMigration024() {
  const client = await pool.connect();
  
  try {
    console.log('\n=== Aplicando Migration 024: User Management Improvements ===\n');
    
    // Ler o arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '024_users_improvements.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Executar a migration
    console.log('Executando migration...');
    await client.query(sql);
    
    console.log('\n✓ Migration 024 aplicada com sucesso!\n');
    
    // Validação: verificar colunas adicionadas
    console.log('=== Validando estrutura da tabela users ===\n');
    
    const { rows: columns } = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position;
    `);
    
    console.log(`Total de colunas: ${columns.length}`);
    
    // Verificar se as novas colunas foram criadas
    const newColumns = [
      'phone', 'department', 'job_title', 'last_login_at', 'last_login_ip',
      'failed_login_attempts', 'locked_until', 'email_verified', 'email_verified_at',
      'invitation_token', 'invitation_expires_at', 'invited_by', 'bio', 'preferences',
      'updated_at', 'deleted_at'
    ];
    
    console.log('\n=== Verificando colunas RF10 ===\n');
    const foundColumns = columns.map(c => c.column_name);
    newColumns.forEach(col => {
      const found = foundColumns.includes(col);
      console.log(`  ${found ? '✓' : '✗'} ${col}`);
    });
    
    // Verificar constraint de role
    const { rows: constraints } = await client.query(`
      SELECT constraint_name, check_clause
      FROM information_schema.check_constraints
      WHERE constraint_name LIKE '%users_role%';
    `);
    
    console.log('\n=== Constraints de role ===\n');
    if (constraints.length > 0) {
      constraints.forEach(c => {
        console.log(`  - ${c.constraint_name}`);
        console.log(`    ${c.check_clause}`);
      });
    }
    
    // Verificar foreign key invited_by
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
      WHERE tc.table_name = 'users'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'invited_by';
    `);
    
    console.log('\n=== Foreign Key invited_by ===\n');
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
      WHERE tablename = 'users'
        AND indexname LIKE 'idx_users%'
      ORDER BY indexname;
    `);
    
    console.log('\n=== Índices da tabela users ===\n');
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
      WHERE event_object_table = 'users'
      ORDER BY trigger_name;
    `);
    
    console.log('\n=== Triggers da tabela users ===\n');
    if (triggers.length > 0) {
      triggers.forEach(t => {
        console.log(`  ✓ ${t.trigger_name} (${t.event_manipulation})`);
      });
    } else {
      console.log('  ⚠ Nenhum trigger encontrado');
    }
    
    // Verificar view active_users_overview
    const { rows: views } = await client.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_schema = 'public'
        AND table_name = 'active_users_overview';
    `);
    
    console.log('\n=== View active_users_overview ===\n');
    if (views.length > 0) {
      console.log('  ✓ View criada com sucesso');
    } else {
      console.log('  ✗ View não encontrada');
    }
    
    console.log('\n=== Validação completa ===\n');
    
  } catch (error) {
    console.error('\n✗ Erro ao aplicar migration 024:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Executar
aplicarMigration024().catch(err => {
  console.error('Erro fatal:', err);
  process.exit(1);
});
