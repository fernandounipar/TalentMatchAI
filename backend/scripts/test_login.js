/**
 * Script para testar o login via API
 * Uso: node scripts/test_login.js <email> <senha>
 */

const http = require('http');

const email = process.argv[2];
const senha = process.argv[3];

if (!email || !senha) {
  console.error('❌ Uso: node scripts/test_login.js <email> <senha>');
  process.exit(1);
}

const payload = JSON.stringify({ email, senha });

const options = {
  hostname: 'localhost',
  port: 4000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
};

console.log('\n🔐 Testando login...');
console.log(`📧 Email: ${email}`);
console.log(`🔑 Senha: ${senha} (${senha.length} caracteres)\n`);

const req = http.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`📊 Status: ${res.statusCode}`);
    
    if (res.statusCode === 200) {
      const response = JSON.parse(data);
      console.log('\n✅ ✅ ✅ LOGIN FUNCIONOU! ✅ ✅ ✅\n');
      console.log('Dados retornados:');
      console.log('- Usuário:', response.usuario?.nome || 'N/A');
      console.log('- Email:', response.usuario?.email || 'N/A');
      console.log('- Role:', response.usuario?.perfil || 'N/A');
      console.log('- Company ID:', response.usuario?.company_id || '(sem empresa)');
      console.log('- Access Token:', response.access_token ? `${response.access_token.substring(0, 20)}...` : 'N/A');
      console.log('- Refresh Token:', response.refresh_token ? `${response.refresh_token.substring(0, 20)}...` : 'N/A');
    } else {
      console.log('\n❌ LOGIN FALHOU\n');
      console.log('Resposta do servidor:');
      try {
        const error = JSON.parse(data);
        console.log(JSON.stringify(error, null, 2));
      } catch {
        console.log(data);
      }
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Erro na requisição:', error.message);
  console.error('O servidor está rodando na porta 4000?');
});

req.write(payload);
req.end();
