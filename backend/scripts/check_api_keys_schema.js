const db = require('../src/config/database');

db.query(`
  SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
  FROM information_schema.columns 
  WHERE table_name = 'api_keys' 
  ORDER BY ordinal_position
`)
.then(r => { 
  console.log('📋 Estrutura da tabela api_keys:\n');
  console.table(r.rows);
  process.exit(0);
})
.catch(e => { 
  console.error('❌ Erro:', e.message); 
  process.exit(1); 
});
