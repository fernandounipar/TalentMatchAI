const db = require('../src/config/database');
const fs = require('fs');
const path = require('path');

async function aplicarMigration028() {
  console.log('\n=== Aplicando Migration 028: GitHub Integration ===\n');

  try {
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '028_github_integration.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executando migration...\n');
    await db.query(sql);
    console.log('✓ Migration 028 aplicada com sucesso!\n');

    // Validações
    console.log('=== Validando tabela candidate_github_profiles ===\n');

    // 1. Verificar colunas
    const columns = await db.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'candidate_github_profiles'
      ORDER BY ordinal_position
    `);

    console.log(`Total de colunas: ${columns.rows.length}\n`);

    const expectedColumns = [
      'id', 'candidate_id', 'company_id', 'username', 'github_id',
      'avatar_url', 'profile_url', 'bio', 'location', 'blog',
      'company', 'email', 'hireable', 'public_repos', 'public_gists',
      'followers', 'following', 'summary', 'last_synced_at', 'sync_status',
      'sync_error', 'consent_given', 'consent_given_at', 'created_at',
      'updated_at', 'deleted_at'
    ];

    console.log('=== Verificando colunas ===\n');
    expectedColumns.forEach(col => {
      const found = columns.rows.find(r => r.column_name === col);
      console.log(found ? `  ✓ ${col}` : `  ✗ ${col} (AUSENTE)`);
    });

    // 2. Verificar foreign keys
    console.log('\n=== Foreign Keys ===\n');
    const fks = await db.query(`
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
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'candidate_github_profiles'
    `);

    fks.rows.forEach(fk => {
      console.log(`  ✓ ${fk.constraint_name}: ${fk.column_name} → ${fk.foreign_table_name}(${fk.foreign_column_name})`);
    });

    // 3. Verificar índices
    console.log('\n=== Índices ===\n');
    const indexes = await db.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'candidate_github_profiles'
        AND schemaname = 'public'
      ORDER BY indexname
    `);

    indexes.rows.forEach(idx => {
      console.log(`  ✓ ${idx.indexname}`);
    });
    console.log(`\nTotal: ${indexes.rows.length} índices`);

    // 4. Verificar trigger
    console.log('\n=== Triggers ===\n');
    const triggers = await db.query(`
      SELECT trigger_name, event_manipulation
      FROM information_schema.triggers
      WHERE event_object_table = 'candidate_github_profiles'
    `);

    triggers.rows.forEach(trg => {
      console.log(`  ✓ ${trg.trigger_name} (${trg.event_manipulation})`);
    });

    // 5. Verificar view
    console.log('\n=== View ===\n');
    const views = await db.query(`
      SELECT viewname
      FROM pg_views
      WHERE viewname = 'candidate_github_profiles_overview'
        AND schemaname = 'public'
    `);

    if (views.rows.length > 0) {
      console.log('  ✓ candidate_github_profiles_overview criada');
    } else {
      console.log('  ✗ View não encontrada');
    }

    console.log('\n=== Validação completa ===\n');

  } catch (error) {
    console.error('✗ Erro ao aplicar migration 028:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    await db.end();
  }
}

aplicarMigration028();
