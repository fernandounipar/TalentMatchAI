/**
 * Script para testar conexão com OpenAI API
 * 
 * Uso:
 *   node scripts/test_openai.js
 * 
 * Ou com chave direta:
 *   OPENAI_API_KEY=sk-... node scripts/test_openai.js
 */

require('dotenv').config();
const https = require('https');

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

console.log('\n🧪 Teste de Conexão com OpenAI API\n');
console.log('=' .repeat(60));

// Verifica se a chave existe
if (!OPENAI_API_KEY) {
  console.log('\n❌ OPENAI_API_KEY não configurada no .env!');
  console.log('\n📝 Para configurar:');
  console.log('   1. Crie uma conta em: https://platform.openai.com/');
  console.log('   2. Gere uma API Key em: https://platform.openai.com/api-keys');
  console.log('   3. Adicione no arquivo .env:');
  console.log('      OPENAI_API_KEY=sk-proj-...');
  console.log('\n💡 Dica: A OpenAI oferece $5 de crédito grátis para novos usuários!');
  process.exit(1);
}

// Mostra apenas os primeiros e últimos caracteres da chave (por segurança)
const maskedKey = OPENAI_API_KEY.substring(0, 10) + '...' + OPENAI_API_KEY.substring(OPENAI_API_KEY.length - 4);
console.log(`\n🔑 Chave encontrada: ${maskedKey}`);
console.log(`   Comprimento: ${OPENAI_API_KEY.length} caracteres`);

// Teste 1: Verificar formato da chave
console.log('\n📋 Teste 1: Formato da Chave');
if (OPENAI_API_KEY.startsWith('sk-')) {
  console.log('   ✅ Formato correto (começa com "sk-")');
} else {
  console.log('   ⚠️  Formato incomum (deveria começar com "sk-")');
}

// Teste 2: Listar modelos disponíveis
console.log('\n📋 Teste 2: Testando Autenticação (GET /v1/models)');
console.log('   Aguarde...');

const options = {
  hostname: 'api.openai.com',
  path: '/v1/models',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${OPENAI_API_KEY}`,
    'Content-Type': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log(`   Status: ${res.statusCode}`);
    
    if (res.statusCode === 200) {
      const parsed = JSON.parse(data);
      const modelCount = parsed.data ? parsed.data.length : 0;
      console.log('   ✅ Autenticação bem-sucedida!');
      console.log(`   📦 Modelos disponíveis: ${modelCount}`);
      
      // Verifica se tem GPT-4
      const hasGPT4 = parsed.data.some(m => m.id.includes('gpt-4'));
      const hasGPT35 = parsed.data.some(m => m.id.includes('gpt-3.5'));
      
      if (hasGPT4) {
        console.log('   ✅ GPT-4 disponível');
      }
      if (hasGPT35) {
        console.log('   ✅ GPT-3.5 disponível');
      }
      
      // Teste 3: Fazer uma chamada simples
      testCompletion();
      
    } else if (res.statusCode === 401) {
      console.log('   ❌ Erro de Autenticação (401 Unauthorized)');
      console.log('   💡 Sua chave API está inválida ou expirada.');
      console.log('   📝 Gere uma nova em: https://platform.openai.com/api-keys');
      process.exit(1);
      
    } else if (res.statusCode === 429) {
      console.log('   ⚠️  Rate Limit (429 Too Many Requests)');
      console.log('   💡 Você excedeu o limite de requisições ou créditos.');
      console.log('   📊 Verifique seu uso em: https://platform.openai.com/usage');
      process.exit(1);
      
    } else {
      console.log('   ❌ Erro inesperado');
      console.log(`   Resposta: ${data}`);
      process.exit(1);
    }
  });
});

req.on('error', (error) => {
  console.log('   ❌ Erro de conexão:', error.message);
  console.log('   💡 Verifique sua conexão com a internet.');
  process.exit(1);
});

req.end();

// Teste 3: Completion simples
function testCompletion() {
  console.log('\n📋 Teste 3: Chat Completion (gpt-3.5-turbo)');
  console.log('   Pergunta: "Diga apenas: OK"');
  console.log('   Aguarde...');
  
  const payload = JSON.stringify({
    model: 'gpt-3.5-turbo',
    messages: [
      { role: 'user', content: 'Responda apenas com a palavra: OK' }
    ],
    max_tokens: 10,
    temperature: 0
  });
  
  const options = {
    hostname: 'api.openai.com',
    path: '/v1/chat/completions',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload)
    }
  };
  
  const req = https.request(options, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      if (res.statusCode === 200) {
        const parsed = JSON.parse(data);
        const resposta = parsed.choices[0].message.content;
        const tokens = parsed.usage.total_tokens;
        
        console.log('   ✅ Resposta recebida!');
        console.log(`   🤖 IA respondeu: "${resposta}"`);
        console.log(`   📊 Tokens usados: ${tokens}`);
        console.log('\n' + '='.repeat(60));
        console.log('✅ TODOS OS TESTES PASSARAM!');
        console.log('🎉 Sua API Key da OpenAI está funcionando perfeitamente!\n');
        
      } else if (res.statusCode === 429) {
        const parsed = JSON.parse(data);
        console.log('   ⚠️  Rate Limit ou Limite de Crédito');
        console.log(`   Mensagem: ${parsed.error?.message || 'Sem detalhes'}`);
        console.log('\n💡 Possíveis causas:');
        console.log('   - Seus créditos gratuitos acabaram');
        console.log('   - Você precisa adicionar um método de pagamento');
        console.log('   📊 Verifique: https://platform.openai.com/usage');
        console.log('   💳 Adicionar pagamento: https://platform.openai.com/account/billing');
        
      } else if (res.statusCode === 400) {
        const parsed = JSON.parse(data);
        console.log('   ❌ Erro na Requisição (400 Bad Request)');
        console.log(`   Mensagem: ${parsed.error?.message || data}`);
        
      } else {
        console.log(`   ❌ Erro: Status ${res.statusCode}`);
        console.log(`   Resposta: ${data}`);
      }
      
      console.log('\n' + '='.repeat(60) + '\n');
    });
  });
  
  req.on('error', (error) => {
    console.log('   ❌ Erro de conexão:', error.message);
  });
  
  req.write(payload);
  req.end();
}
