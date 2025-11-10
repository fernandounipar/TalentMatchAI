const db = require('../src/config/database');

async function cleanup() {
  try {
    const email = process.argv[2] || 'fernando@email.com';
    
    console.log(`\n🔍 Procurando dados para: ${email}`);
    
    // Busca usuário
    const userResult = await db.query(
      `SELECT id, company_id, full_name, email FROM users WHERE email = $1`,
      [email]
    );
    
    if (userResult.rows.length === 0) {
      console.log('⚠️  Usuário não encontrado');
    } else {
      const user = userResult.rows[0];
      console.log(`📌 Usuário encontrado: ${user.full_name} (${user.id})`);
      
      // Remove refresh tokens
      await db.query(`DELETE FROM refresh_tokens WHERE user_id = $1`, [user.id]);
      console.log('✅ Refresh tokens removidos');
      
      // Remove password resets
      await db.query(`DELETE FROM password_resets WHERE user_id = $1`, [user.id]);
      console.log('✅ Password resets removidos');
      
      // Remove usuário
      await db.query(`DELETE FROM users WHERE id = $1`, [user.id]);
      console.log('✅ Usuário removido');
      
      // Remove empresa
      if (user.company_id) {
        await db.query(`DELETE FROM companies WHERE id = $1`, [user.company_id]);
        console.log('✅ Empresa removida');
      }
    }
    
    console.log('\n✅ Limpeza concluída!\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

cleanup();
