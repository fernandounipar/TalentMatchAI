const db = require('../src/config/database');

async function checkConstraints() {
  console.log('📋 Verificando constraints da tabela candidatos:\n');
  
  const constraints = await db.query(`
    SELECT 
      conname, 
      contype,
      pg_get_constraintdef(oid) as definition 
    FROM pg_constraint 
    WHERE conrelid = 'candidatos'::regclass 
    ORDER BY conname
  `);
  
  console.table(constraints.rows);
  
  console.log('\n📋 Verificando índices da tabela candidatos:\n');
  
  const indexes = await db.query(`
    SELECT 
      indexname, 
      indexdef 
    FROM pg_indexes 
    WHERE tablename = 'candidatos' 
    ORDER BY indexname
  `);
  
  console.table(indexes.rows);
  
  console.log('\n📋 Estrutura da tabela candidatos:\n');
  
  const columns = await db.query(`
    SELECT 
      column_name, 
      data_type, 
      is_nullable 
    FROM information_schema.columns 
    WHERE table_name = 'candidatos' 
    ORDER BY ordinal_position
  `);
  
  console.table(columns.rows);
  
  process.exit(0);
}

checkConstraints().catch(e => {
  console.error('❌ Erro:', e.message);
  process.exit(1);
});
