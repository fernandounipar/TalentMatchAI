const db = require('../src/config/database');

async function checkColumns() {
  try {
    const result = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'password_resets'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Colunas da tabela password_resets:');
    result.rows.forEach(col => {
      console.log(`  - ${col.column_name} (${col.data_type})`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

checkColumns();
