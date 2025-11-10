const db = require('../src/config/database');

async function listUsers() {
  try {
    const result = await db.query(`
      SELECT id, full_name, email, role, company_id, is_active, created_at
      FROM users
      WHERE deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT 10
    `);
    
    console.log(`\n📋 Últimos ${result.rows.length} usuários cadastrados:\n`);
    
    result.rows.forEach(user => {
      console.log(`👤 ${user.full_name} (${user.email})`);
      console.log(`   ID: ${user.id}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Empresa: ${user.company_id || 'Não cadastrada'}`);
      console.log(`   Ativo: ${user.is_active ? 'Sim' : 'Não'}`);
      console.log(`   Criado: ${user.created_at}`);
      console.log('');
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

listUsers();
