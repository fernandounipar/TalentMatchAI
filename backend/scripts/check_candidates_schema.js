const db = require('../src/config/database');

async function checkSchema() {
  console.log('📋 Estrutura da tabela candidates:\n');
  
  const columns = await db.query(`
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'candidates' 
    ORDER BY ordinal_position
  `);
  
  console.table(columns.rows);
  
  console.log('\n🔍 Constraints da tabela candidates:\n');
  
  const constraints = await db.query(`
    SELECT conname, contype, pg_get_constraintdef(oid) as definition 
    FROM pg_constraint 
    WHERE conrelid = 'candidates'::regclass 
    ORDER BY conname
  `);
  
  console.table(constraints.rows);
  
  console.log('\n📊 Índices da tabela candidates:\n');
  
  const indexes = await db.query(`
    SELECT indexname, indexdef 
    FROM pg_indexes 
    WHERE tablename = 'candidates' 
    ORDER BY indexname
  `);
  
  console.table(indexes.rows);
  
  process.exit(0);
}

checkSchema().catch(e => {
  console.error('❌ Erro:', e.message);
  process.exit(1);
});
