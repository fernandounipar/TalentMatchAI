/**
 * Teste direto da API do OpenRouter
 */

require('dotenv').config();
const https = require('https');

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast';

console.log('🧪 Teste Direto do OpenRouter\n');
console.log('API Key:', OPENROUTER_API_KEY ? `${OPENROUTER_API_KEY.substring(0, 20)}...` : 'NÃO CONFIGURADA');
console.log('Modelo:', OPENROUTER_MODEL);
console.log('\n============================================================\n');

if (!OPENROUTER_API_KEY) {
  console.error('❌ OPENROUTER_API_KEY não configurada');
  process.exit(1);
}

const payload = JSON.stringify({
  model: OPENROUTER_MODEL,
  messages: [
    {
      role: 'user',
      content: 'Responda apenas: "Teste OK"'
    }
  ],
  temperature: 0.1,
  max_tokens: 50
});

const options = {
  hostname: 'openrouter.ai',
  path: '/api/v1/chat/completions',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://talentmatchia.app',
    'X-Title': 'TalentMatchIA',
    'Content-Length': Buffer.byteLength(payload)
  },
  timeout: 30000
};

console.log('📤 Enviando requisição para OpenRouter...\n');

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`📥 Status Code: ${res.statusCode}\n`);
    
    if (res.statusCode === 200) {
      try {
        const response = JSON.parse(data);
        console.log('✅ Sucesso!');
        console.log('\nResposta:', JSON.stringify(response, null, 2));
      } catch (error) {
        console.error('❌ Erro ao parsear resposta:', error.message);
        console.log('Dados recebidos:', data);
      }
    } else {
      console.error(`❌ Erro ${res.statusCode}`);
      console.log('Resposta:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Erro de conexão:', error.message);
});

req.on('timeout', () => {
  req.destroy();
  console.error('❌ Timeout após 30 segundos');
});

req.write(payload);
req.end();
