const fs = require('fs');
const path = require('path');
const db = require('../src/config/database');

async function aplicarMigration014() {
  try {
    console.log('📦 Aplicando Migration 014 - Colunas de vagas e job_revisions...\n');

    const sqlPath = path.join(__dirname, 'sql', '014_jobs_add_columns.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    await db.query(sql);

    console.log('✅ Migration 014 aplicada com sucesso!\n');

    // Validar estrutura
    console.log('🔍 Validando estrutura da tabela jobs...');
    const columnsResult = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'jobs'
      ORDER BY ordinal_position
    `);

    console.log(`\n📋 Colunas da tabela jobs (${columnsResult.rows.length} total):`);
    columnsResult.rows.forEach(col => {
      console.log(`   - ${col.column_name} (${col.data_type})`);
    });

    // Verificar tabela job_revisions
    const revisionsCheck = await db.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'job_revisions'
      ) as exists
    `);

    if (revisionsCheck.rows[0].exists) {
      console.log('\n✅ Tabela job_revisions criada com sucesso');
    } else {
      console.log('\n⚠️ Tabela job_revisions não foi criada');
    }

    // Verificar triggers
    const triggersResult = await db.query(`
      SELECT trigger_name 
      FROM information_schema.triggers
      WHERE event_object_table = 'jobs'
    `);

    console.log(`\n🎯 Triggers na tabela jobs (${triggersResult.rows.length}):`);
    triggersResult.rows.forEach(t => {
      console.log(`   - ${t.trigger_name}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao aplicar migration 014:', error.message);
    process.exit(1);
  }
}

aplicarMigration014();
