const db = require('../src/config/database');

db.query(`
  SELECT table_name 
  FROM information_schema.tables 
  WHERE table_schema = 'public' 
    AND (table_name = 'candidatos' OR table_name = 'candidates')
  ORDER BY table_name
`)
.then(r => { 
  console.log('📋 Tabelas de candidatos encontradas:\n');
  console.table(r.rows);
  
  if (r.rows.length === 0) {
    console.log('⚠️  Nenhuma tabela de candidatos encontrada!');
  }
  
  process.exit(0);
})
.catch(e => {
  console.error('❌ Erro:', e.message);
  process.exit(1);
});
