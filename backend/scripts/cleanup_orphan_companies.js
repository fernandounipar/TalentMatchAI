const db = require('../src/config/database');

async function cleanupOrphans() {
  try {
    console.log('\n🔍 Procurando empresas órfãs...');
    
    // Busca empresas sem usuários
    const result = await db.query(`
      SELECT c.id, c.tipo, c.documento, c.nome 
      FROM companies c
      LEFT JOIN users u ON u.company_id = c.id
      WHERE u.id IS NULL
    `);
    
    if (result.rows.length === 0) {
      console.log('✅ Nenhuma empresa órfã encontrada\n');
    } else {
      console.log(`📌 Encontradas ${result.rows.length} empresa(s) órfã(s):\n`);
      
      for (const company of result.rows) {
        console.log(`  - ${company.nome} (${company.documento})`);
        await db.query(`DELETE FROM companies WHERE id = $1`, [company.id]);
      }
      
      console.log(`\n✅ ${result.rows.length} empresa(s) removida(s)!\n`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

cleanupOrphans();
