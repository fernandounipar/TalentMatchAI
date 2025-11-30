const db = require('../src/config/database');

async function main() {
  try {
    // Verificar tabelas com 'revis' no nome
    const tables = await db.query(
      `SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename LIKE '%revis%'`
    );
    console.log('Tabelas com revis:', tables.rows);

    // Verificar triggers na tabela vagas
    const triggers = await db.query(
      `SELECT tgname, proname FROM pg_trigger t
       JOIN pg_proc p ON t.tgfoid = p.oid
       WHERE tgrelid = 'vagas'::regclass`
    );
    console.log('Triggers em vagas:', triggers.rows);

    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

main();
