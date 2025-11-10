const bcrypt = require('bcryptjs');
const db = require('../src/config/database');

async function testPassword() {
  const email = process.argv[2] || 'fernando@email.com';
  const senha = process.argv[3] || 'god0702';
  
  try {
    console.log(`\n🔍 Testando login para: ${email}`);
    console.log(`🔑 Senha fornecida: ${senha}`);
    console.log(`📏 Tamanho da senha: ${senha.length} caracteres`);
    console.log('');
    
    // Busca usuário
    const result = await db.query(
      'SELECT id, full_name, email, password_hash FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    
    if (result.rows.length === 0) {
      console.log('❌ Usuário não encontrado no banco');
      process.exit(1);
    }
    
    const user = result.rows[0];
    console.log(`✅ Usuário encontrado: ${user.full_name}`);
    console.log(`📧 Email no banco: ${user.email}`);
    console.log(`🔒 Hash armazenado: ${user.password_hash.substring(0, 20)}...`);
    console.log('');
    
    // Testa senha
    const senhaValida = await bcrypt.compare(senha, user.password_hash);
    
    if (senhaValida) {
      console.log('✅ ✅ ✅ SENHA CORRETA! ✅ ✅ ✅');
      console.log('O login deveria funcionar!');
    } else {
      console.log('❌ ❌ ❌ SENHA INCORRETA! ❌ ❌ ❌');
      console.log('A senha fornecida não corresponde ao hash armazenado.');
    }
    
    console.log('');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

testPassword();
