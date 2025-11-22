/**
 * Script para aplicar migration 012: Adicionar colunas à tabela resumes
 */

const fs = require('fs');
const path = require('path');
const db = require('../src/config/database');

async function aplicarMigration012() {
  console.log('\n🔄 Aplicando migration 012: Adicionar colunas à tabela resumes\n');

  try {
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '012_resumes_add_columns.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Executar SQL
    await db.query(sql);

    console.log('✅ Migration 012 aplicada com sucesso!\n');
    console.log('📝 Colunas adicionadas:');
    console.log('   - job_id (UUID)');
    console.log('   - file_size (BIGINT)');
    console.log('   - mime_type (TEXT)');
    console.log('   - status (TEXT) [pending, reviewed, accepted, rejected]');
    console.log('   - notes (TEXT)');
    console.log('   - is_favorite (BOOLEAN)');
    console.log('   - updated_at (TIMESTAMP)');
    console.log('   - updated_by (UUID)');
    console.log('   - deleted_at (TIMESTAMP)');
    console.log('\n📋 Tabela criada:');
    console.log('   - resume_analysis');
    console.log('\n🎯 Índices criados para performance');
    console.log('\n🔄 Trigger criado: update_resumes_updated_at');
    
    // Verificar estrutura
    console.log('\n🧪 Verificando estrutura...\n');
    
    const columns = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'resumes' 
      ORDER BY ordinal_position
    `);

    console.log('   Colunas da tabela resumes:');
    columns.rows.forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type}`);
    });

    console.log('\n✨ Migration 012 concluída com sucesso!\n');
    console.log('🎯 Próximo passo: Executar migration 013 (views de métricas)\n');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ Erro ao aplicar migration 012:');
    console.error(error.message);
    console.error('\nStack trace:');
    console.error(error.stack);
    process.exit(1);
  }
}

// Executar
aplicarMigration012();
