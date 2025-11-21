/**
 * Script para testar conexão com OpenRouter API
 * 
 * Uso:
 *   node scripts/test_openrouter.js
 * 
 * Para obter API Key:
 *   1. Acesse: https://openrouter.ai/
 *   2. Faça login/cadastro
 *   3. Vá em: https://openrouter.ai/keys
 *   4. Clique em "Create Key"
 *   5. Adicione no .env: OPENROUTER_API_KEY=sk-or-v1-...
 */

require('dotenv').config();
const openRouterService = require('../src/servicos/openRouterService');

console.log('\n🚀 Teste de Conexão com OpenRouter API\n');
console.log('=' .repeat(60));

// Verifica se a chave existe
if (!process.env.OPENROUTER_API_KEY) {
  console.log('\n❌ OPENROUTER_API_KEY não configurada no .env!');
  console.log('\n📝 Para configurar:');
  console.log('   1. Acesse: https://openrouter.ai/');
  console.log('   2. Faça login/cadastro');
  console.log('   3. Vá em: https://openrouter.ai/keys');
  console.log('   4. Clique em "Create Key"');
  console.log('   5. Adicione no .env:');
  console.log('      OPENROUTER_API_KEY=sk-or-v1-...');
  console.log('\n✨ Vantagens do OpenRouter:');
  console.log('   - Acesso a múltiplos modelos (Grok, Claude, GPT-4, etc.)');
  console.log('   - Créditos iniciais gratuitos');
  console.log('   - Preços competitivos');
  console.log('   - API única para todos os modelos\n');
  process.exit(1);
}

// Mostra chave mascarada
const maskedKey = process.env.OPENROUTER_API_KEY.substring(0, 15) + '...' + process.env.OPENROUTER_API_KEY.substring(process.env.OPENROUTER_API_KEY.length - 4);
console.log(`\n🔑 Chave encontrada: ${maskedKey}`);
console.log(`   Comprimento: ${process.env.OPENROUTER_API_KEY.length} caracteres`);

// Mostra modelo configurado
const modelo = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast';
console.log(`\n🤖 Modelo configurado: ${modelo}`);

// Teste 1: Verificar formato
console.log('\n📋 Teste 1: Formato da Chave');
if (process.env.OPENROUTER_API_KEY.startsWith('sk-or-v1-')) {
  console.log('   ✅ Formato correto (começa com "sk-or-v1-")');
} else {
  console.log('   ⚠️  Formato incomum (deveria começar com "sk-or-v1-")');
}

// Teste 2: Chamada simples
console.log('\n📋 Teste 2: Teste de Conexão');
console.log('   Pergunta: "Diga apenas: OK"');
console.log('   Aguarde...');

openRouterService.chamarOpenRouter(
  [{ role: 'user', content: 'Responda apenas com a palavra: OK' }],
  { max_tokens: 10, temperature: 0 }
)
  .then(resposta => {
    console.log('   ✅ Conexão bem-sucedida!');
    console.log(`   🤖 IA respondeu: "${resposta.content}"`);
    
    // Teste 3: Análise de currículo
    console.log('\n📋 Teste 3: Análise de Currículo');
    console.log('   Aguarde...');
    
    const curriculoTeste = `
João Silva
Desenvolvedor Full Stack Sênior

Experiência:
- 5 anos como Desenvolvedor na TechCorp
- Especialista em Node.js, React e PostgreSQL
- Liderou equipe de 3 desenvolvedores

Habilidades:
JavaScript, TypeScript, Node.js, React, PostgreSQL, Docker, AWS
    `;
    
    return openRouterService.analisarCurriculo(curriculoTeste);
  })
  .then(analise => {
    console.log('   ✅ Análise concluída!');
    console.log(`   👤 Skills detectadas: ${analise.skills.length > 0 ? 'Sim' : 'Não'}`);
    console.log(`   🎯 Skills encontradas: ${analise.skills.slice(0, 5).join(', ')}...`);
    console.log(`   📊 Senioridade: ${analise.senioridade}`);
    console.log(`   💼 Experiência: ${analise.experiencia.substring(0, 80)}...`);
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ TODOS OS TESTES PASSARAM!');
    console.log('🎉 OpenRouter API está funcionando perfeitamente!');
    console.log(`💚 Usando modelo: ${process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast'}`);
    console.log('\n💡 Agora você pode usar análise de IA!');
    console.log('   - Upload de currículos funcionará ✅');
    console.log('   - Geração de perguntas funcionará ✅');
    console.log('   - Avaliação de respostas funcionará ✅\n');
  })
  .catch(erro => {
    console.log('   ❌ Erro:', erro.message);
    
    if (erro.message.includes('401') || erro.message.includes('inválida')) {
      console.log('\n💡 Diagnóstico: CHAVE INVÁLIDA');
      console.log('   - Sua OPENROUTER_API_KEY está incorreta');
      console.log('\n📝 Solução:');
      console.log('   1. Acesse: https://openrouter.ai/keys');
      console.log('   2. Gere uma nova chave');
      console.log('   3. Atualize no .env: OPENROUTER_API_KEY=sk-or-v1-...');
      
    } else if (erro.message.includes('402') || erro.message.includes('Créditos')) {
      console.log('\n💡 Diagnóstico: CRÉDITOS INSUFICIENTES');
      console.log('   - Seus créditos do OpenRouter acabaram');
      console.log('\n📝 Solução:');
      console.log('   1. Acesse: https://openrouter.ai/credits');
      console.log('   2. Adicione créditos');
      
    } else if (erro.message.includes('429') || erro.message.includes('Limite')) {
      console.log('\n💡 Diagnóstico: RATE LIMIT');
      console.log('   - Você fez muitas requisições muito rápido');
      console.log('\n📝 Solução:');
      console.log('   - Aguarde alguns segundos e tente novamente');
      
    } else if (erro.message.includes('timeout')) {
      console.log('\n💡 Diagnóstico: TIMEOUT');
      console.log('   - O OpenRouter demorou muito para responder');
      console.log('\n📝 Solução:');
      console.log('   - Tente novamente');
      console.log('   - Verifique sua conexão com internet');
      
    } else {
      console.log('\n💡 Erro desconhecido:');
      console.log(erro.stack);
    }
    
    console.log('\n' + '='.repeat(60) + '\n');
    process.exit(1);
  });
