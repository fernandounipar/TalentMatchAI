// Script para testar endpoint GET /api/user/me após migration
const http = require('http');

async function testarEndpoint() {
  console.log('🔍 Testando endpoint GET /api/user/me...\n');

  // Primeiro, faz login para obter token
  const loginData = JSON.stringify({
    email: 'fernando@email.com',
    password: 'god0702'
  });

  const loginOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': loginData.length
    }
  };

  return new Promise((resolve, reject) => {
    const loginReq = http.request(loginOptions, (loginRes) => {
      let loginBody = '';
      
      loginRes.on('data', (chunk) => {
        loginBody += chunk;
      });

      loginRes.on('end', () => {
        if (loginRes.statusCode !== 200) {
          console.error('❌ Erro no login:', loginRes.statusCode);
          console.error(loginBody);
          reject(new Error('Login falhou'));
          return;
        }

        const loginResponse = JSON.parse(loginBody);
        const accessToken = loginResponse.accessToken;
        
        console.log('✅ Login bem-sucedido!');
        console.log('🔑 Token obtido\n');

        // Agora testa o endpoint /me
        const meOptions = {
          hostname: 'localhost',
          port: 3000,
          path: '/api/user/me',
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${accessToken}`
          }
        };

        const meReq = http.request(meOptions, (meRes) => {
          let meBody = '';

          meRes.on('data', (chunk) => {
            meBody += chunk;
          });

          meRes.on('end', () => {
            console.log(`📊 Status: ${meRes.statusCode}\n`);

            if (meRes.statusCode !== 200) {
              console.error('❌ Erro ao buscar /api/user/me');
              console.error('Resposta:', meBody);
              reject(new Error('Endpoint /me falhou'));
              return;
            }

            const userData = JSON.parse(meBody);
            
            console.log('✅ Dados do usuário obtidos com sucesso!\n');
            console.log('📋 Resposta completa:');
            console.log(JSON.stringify(userData, null, 2));
            
            console.log('\n🔍 Verificando campos específicos:');
            console.log(`   - user.cargo: ${userData.user?.cargo || 'NULL'}`);
            console.log(`   - user.foto_url: ${userData.user?.foto_url || 'NULL'}`);
            console.log(`   - usuario.cargo: ${userData.usuario?.cargo || 'NULL'}`);
            console.log(`   - usuario.foto_url: ${userData.usuario?.foto_url || 'NULL'}`);

            resolve(userData);
          });
        });

        meReq.on('error', (error) => {
          console.error('❌ Erro de rede:', error.message);
          reject(error);
        });

        meReq.end();
      });
    });

    loginReq.on('error', (error) => {
      console.error('❌ Erro de rede no login:', error.message);
      reject(error);
    });

    loginReq.write(loginData);
    loginReq.end();
  });
}

testarEndpoint()
  .then(() => {
    console.log('\n✅ Teste concluído com sucesso!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Teste falhou:', error.message);
    process.exit(1);
  });
