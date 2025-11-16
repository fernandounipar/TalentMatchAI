const db = require('../src/config/database');

async function checkInterviewsSchema() {
  console.log('📋 Foreign keys da tabela interviews:\n');
  
  const fks = await db.query(`
    SELECT 
      conname, 
      pg_get_constraintdef(oid) as definition 
    FROM pg_constraint 
    WHERE conrelid = 'interviews'::regclass 
      AND contype = 'f'
    ORDER BY conname
  `);
  
  console.table(fks.rows);
  
  console.log('\n📋 Estrutura da tabela interviews:\n');
  
  const columns = await db.query(`
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'interviews' 
    ORDER BY ordinal_position
  `);
  
  console.table(columns.rows);
  
  process.exit(0);
}

checkInterviewsSchema().catch(e => {
  console.error('❌ Erro:', e.message);
  process.exit(1);
});
