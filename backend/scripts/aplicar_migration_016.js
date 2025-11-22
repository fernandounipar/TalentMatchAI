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

async function aplicarMigration016() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Aplicando Migration 016: interview_question_sets...\n');
    
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '016_interview_question_sets.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Aplicar migration
    await client.query(sql);
    console.log('✅ Migration 016 aplicada com sucesso!\n');
    
    // Validar estrutura interview_question_sets
    console.log('📊 Validando tabela interview_question_sets...');
    const setColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'interview_question_sets'
      ORDER BY ordinal_position;
    `);
    
    console.log(`  ➜ Colunas: ${setColumns.rows.length}`);
    setColumns.rows.forEach(col => {
      console.log(`    - ${col.column_name} (${col.data_type}, ${col.is_nullable === 'NO' ? 'NOT NULL' : 'nullable'})`);
    });
    
    // Validar colunas adicionadas em interview_questions
    console.log('\n📊 Validando colunas adicionadas em interview_questions...');
    const questionColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'interview_questions'
      AND column_name IN ('set_id', 'type', 'text', 'order', 'updated_at', 'deleted_at')
      ORDER BY ordinal_position;
    `);
    
    console.log(`  ➜ Novas colunas: ${questionColumns.rows.length}`);
    questionColumns.rows.forEach(col => {
      console.log(`    - ${col.column_name} (${col.data_type}, ${col.is_nullable === 'NO' ? 'NOT NULL' : 'nullable'})`);
    });
    
    // Verificar constraint de type
    console.log('\n📊 Verificando constraint de type...');
    const typeConstraint = await client.query(`
      SELECT constraint_name, check_clause
      FROM information_schema.check_constraints
      WHERE constraint_name LIKE '%type%'
      AND constraint_schema = 'public';
    `);
    
    if (typeConstraint.rows.length > 0) {
      console.log(`  ✅ Constraint encontrada: ${typeConstraint.rows[0].constraint_name}`);
    }
    
    // Verificar índices
    console.log('\n📊 Verificando índices criados...');
    const indexes = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename IN ('interview_question_sets', 'interview_questions')
      AND indexname LIKE 'idx_question%'
      ORDER BY indexname;
    `);
    
    console.log(`  ➜ Índices criados: ${indexes.rows.length}`);
    indexes.rows.forEach(idx => {
      console.log(`    - ${idx.indexname}`);
    });
    
    // Verificar triggers
    console.log('\n📊 Verificando triggers...');
    const triggers = await client.query(`
      SELECT trigger_name, event_object_table
      FROM information_schema.triggers
      WHERE event_object_table IN ('interview_question_sets', 'interview_questions')
      AND trigger_name LIKE '%updated_at%'
      ORDER BY event_object_table, trigger_name;
    `);
    
    console.log(`  ➜ Triggers criados: ${triggers.rows.length}`);
    triggers.rows.forEach(trg => {
      console.log(`    - ${trg.event_object_table}.${trg.trigger_name}`);
    });
    
    console.log('\n✅ Validação completa! Migration 016 aplicada com sucesso.');
    
  } catch (error) {
    console.error('❌ Erro ao aplicar migration 016:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration016();
