/**
 * Script para testar DELETE /api/api-keys/:id
 */

const http = require('http');

// Configurações
const API_BASE = 'http://localhost:3000';
const EMAIL = 'fernando@email.com';
const PASSWORD = 'god0702';

async function request(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(API_BASE + path);
    const options = {
      method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        const response = {
          statusCode: res.statusCode,
          headers: res.headers,
          body: data ? (data.startsWith('{') || data.startsWith('[') ? JSON.parse(data) : data) : null,
        };
        resolve(response);
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

async function main() {
  try {
    console.log('📝 Testando DELETE /api/api-keys/:id\n');

    // 1. Login
    console.log('1️⃣ Fazendo login...');
    const loginRes = await request('POST', '/api/auth/login', { email: EMAIL, senha: PASSWORD });
    
    if (loginRes.statusCode !== 200) {
      console.error('❌ Erro no login:', loginRes.statusCode, loginRes.body);
      process.exit(1);
    }

    const token = loginRes.body.token;
    console.log('✅ Login bem-sucedido\n');

    // 2. Listar API Keys
    console.log('2️⃣ Listando API Keys...');
    const listRes = await request('GET', '/api/api-keys', null, token);
    
    if (listRes.statusCode !== 200) {
      console.error('❌ Erro ao listar API Keys:', listRes.statusCode, listRes.body);
      process.exit(1);
    }

    console.log('✅ API Keys encontradas:', listRes.body.length);
    
    if (listRes.body.length === 0) {
      console.log('⚠️  Nenhuma API Key encontrada. Crie uma primeiro.');
      process.exit(0);
    }

    // Pegar a primeira API Key
    const apiKeyId = listRes.body[0].id;
    console.log('📋 API Key para deletar:', apiKeyId);
    console.log('   Provider:', listRes.body[0].provider);
    console.log('   Label:', listRes.body[0].label);
    console.log('   Active:', listRes.body[0].is_active);
    console.log('');

    // 3. Deletar API Key
    console.log('3️⃣ Deletando API Key...');
    const deleteRes = await request('DELETE', `/api/api-keys/${apiKeyId}`, null, token);
    
    console.log('📊 Status Code:', deleteRes.statusCode);
    console.log('📊 Response Body:', deleteRes.body);

    if (deleteRes.statusCode === 204) {
      console.log('✅ API Key deletada com sucesso (204 No Content)');
    } else if (deleteRes.statusCode === 404) {
      console.error('❌ Rota não encontrada (404)');
      console.error('   Isso pode indicar que:');
      console.error('   - A rota DELETE não está registrada corretamente');
      console.error('   - Algum middleware está bloqueando a requisição');
      console.error('   - O servidor não está rodando corretamente');
    } else {
      console.error('❌ Erro ao deletar:', deleteRes.statusCode, deleteRes.body);
    }

    console.log('');

    // 4. Verificar se foi deletada (listar novamente)
    console.log('4️⃣ Verificando se foi deletada...');
    const listRes2 = await request('GET', '/api/api-keys', null, token);
    console.log('✅ API Keys restantes:', listRes2.body.length);

    const encontrada = listRes2.body.find(k => k.id === apiKeyId);
    if (encontrada) {
      if (encontrada.is_active === false) {
        console.log('✅ API Key marcada como inativa (soft delete)');
      } else {
        console.log('⚠️  API Key ainda está ativa!');
      }
    } else {
      console.log('✅ API Key não aparece mais na listagem');
    }

  } catch (e) {
    console.error('❌ Erro:', e.message);
    process.exit(1);
  }
}

main();
