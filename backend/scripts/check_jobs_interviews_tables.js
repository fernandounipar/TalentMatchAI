const db = require('../src/config/database');

async function checkTables() {
  console.log('📋 Verificando tabelas de vagas:\n');
  
  const vagas = await db.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND (table_name = 'vagas' OR table_name = 'jobs')
    ORDER BY table_name
  `);
  
  console.table(vagas.rows);
  
  console.log('\n📋 Verificando tabelas de entrevistas:\n');
  
  const entrevistas = await db.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND (table_name = 'entrevistas' OR table_name = 'interviews')
    ORDER BY table_name
  `);
  
  console.table(entrevistas.rows);
  
  console.log('\n🔍 Foreign keys da tabela entrevistas:\n');
  
  const fks = await db.query(`
    SELECT 
      conname, 
      pg_get_constraintdef(oid) as definition 
    FROM pg_constraint 
    WHERE conrelid = 'entrevistas'::regclass 
      AND contype = 'f'
    ORDER BY conname
  `);
  
  console.table(fks.rows);
  
  process.exit(0);
}

checkTables().catch(e => {
  console.error('❌ Erro:', e.message);
  process.exit(1);
});
