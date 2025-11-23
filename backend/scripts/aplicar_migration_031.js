const db = require('../src/config/database');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

async function confirmarRemocao() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    console.log('\n⚠️  ATENÇÃO: Esta migration irá REMOVER permanentemente as seguintes tabelas:\n');
    console.log('  - mensagens');
    console.log('  - perguntas');
    console.log('  - relatorios');
    console.log('  - entrevistas');
    console.log('  - curriculos');
    console.log('  - candidatos');
    console.log('  - vagas\n');
    console.log('Certifique-se de ter feito backup dos dados, se necessário.\n');

    rl.question('Deseja continuar? (sim/não): ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'sim' || answer.toLowerCase() === 's');
    });
  });
}

async function aplicarMigration031() {
  console.log('\n=== Migration 031: Remoção de Tabelas Legacy ===\n');

  try {
    // Confirmar antes de executar
    const confirmado = await confirmarRemocao();
    
    if (!confirmado) {
      console.log('\n❌ Operação cancelada pelo usuário.\n');
      process.exit(0);
    }

    console.log('\n✅ Confirmado. Executando remoção...\n');

    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '031_remove_legacy_tables.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executando migration...\n');
    await db.query(sql);
    console.log('✓ Migration 031 aplicada com sucesso!\n');

    // Validações
    console.log('=== Verificando tabelas removidas ===\n');

    const legacyTables = [
      'mensagens',
      'perguntas', 
      'relatorios',
      'entrevistas',
      'curriculos',
      'candidatos',
      'vagas'
    ];

    let allRemoved = true;

    for (const tableName of legacyTables) {
      const result = await db.query(`
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
      `, [tableName]);

      if (result.rows.length === 0) {
        console.log(`  ✓ ${tableName} - REMOVIDA`);
      } else {
        console.log(`  ✗ ${tableName} - AINDA EXISTE`);
        allRemoved = false;
      }
    }

    console.log('\n=== Contagem final de tabelas ===\n');
    const totalTables = await db.query(`
      SELECT COUNT(*) as total
      FROM information_schema.tables
      WHERE table_schema = 'public'
    `);

    console.log(`  Total de tabelas no banco: ${totalTables.rows[0].total}\n`);

    if (allRemoved) {
      console.log('✅ Todas as tabelas legacy foram removidas com sucesso!\n');
    } else {
      console.log('⚠️  Algumas tabelas legacy ainda existem. Verifique manualmente.\n');
    }

  } catch (error) {
    console.error('✗ Erro ao aplicar migration 031:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    if (db.pool) await db.pool.end();
    process.exit(0);
  }
}

aplicarMigration031();
