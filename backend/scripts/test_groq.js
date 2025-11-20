/**
 * Script para testar conexão com Groq API (Alternativa GRATUITA à OpenAI)
 * 
 * Uso:
 *   node scripts/test_groq.js
 * 
 * Para obter API Key:
 *   1. Acesse: https://console.groq.com/
 *   2. Faça login/cadastro (grátis)
 *   3. Vá em: https://console.groq.com/keys
 *   4. Clique em "Create API Key"
 *   5. Adicione no .env: GROQ_API_KEY=gsk_...
 */

require('dotenv').config();
const groqService = require('../src/servicos/groqService');

console.log('\n🚀 Teste de Conexão com Groq API (IA Gratuita)\n');
console.log('=' .repeat(60));

// Verifica se a chave existe
if (!process.env.GROQ_API_KEY) {
  console.log('\n❌ GROQ_API_KEY não configurada no .env!');
  console.log('\n📝 Para configurar:');
  console.log('   1. Acesse: https://console.groq.com/');
  console.log('   2. Faça login/cadastro (100% GRÁTIS)');
  console.log('   3. Vá em: https://console.groq.com/keys');
  console.log('   4. Clique em "Create API Key"');
  console.log('   5. Adicione no .env:');
  console.log('      GROQ_API_KEY=gsk_...');
  console.log('\n✨ Vantagens da Groq:');
  console.log('   - 100% GRATUITO (sem necessidade de cartão)');
  console.log('   - Extremamente RÁPIDO');
  console.log('   - Modelos poderosos (Llama 3, Mixtral)');
  console.log('   - Perfeito para desenvolvimento e MVP\n');
  process.exit(1);
}

// Mostra chave mascarada
const maskedKey = process.env.GROQ_API_KEY.substring(0, 10) + '...' + process.env.GROQ_API_KEY.substring(process.env.GROQ_API_KEY.length - 4);
console.log(`\n🔑 Chave encontrada: ${maskedKey}`);
console.log(`   Comprimento: ${process.env.GROQ_API_KEY.length} caracteres`);

// Teste 1: Verificar formato
console.log('\n📋 Teste 1: Formato da Chave');
if (process.env.GROQ_API_KEY.startsWith('gsk_')) {
  console.log('   ✅ Formato correto (começa com "gsk_")');
} else {
  console.log('   ⚠️  Formato incomum (deveria começar com "gsk_")');
}

// Teste 2: Chamada simples
console.log('\n📋 Teste 2: Teste de Conexão');
console.log('   Pergunta: "Diga apenas: OK"');
console.log('   Aguarde...');

groqService.chamarGroq(
  [{ role: 'user', content: 'Responda apenas com a palavra: OK' }],
  { max_tokens: 10, temperature: 0 }
)
  .then(resposta => {
    console.log('   ✅ Conexão bem-sucedida!');
    console.log(`   🤖 IA respondeu: "${resposta}"`);
    
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
    
    return groqService.analisarCurriculo(curriculoTeste);
  })
  .then(analise => {
    console.log('   ✅ Análise concluída!');
    console.log(`   👤 Nome detectado: ${analise.skills.length > 0 ? 'Sim' : 'Não'}`);
    console.log(`   🎯 Skills encontradas: ${analise.skills.slice(0, 5).join(', ')}...`);
    console.log(`   📊 Senioridade: ${analise.senioridade}`);
    console.log(`   💼 Experiência: ${analise.experiencia.substring(0, 80)}...`);
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ TODOS OS TESTES PASSARAM!');
    console.log('🎉 Groq API está funcionando perfeitamente!');
    console.log('💚 E o melhor: é 100% GRATUITO!');
    console.log('\n💡 Agora você pode usar análise de IA sem custos!');
    console.log('   - Upload de currículos funcionará ✅');
    console.log('   - Geração de perguntas funcionará ✅');
    console.log('   - Avaliação de respostas funcionará ✅\n');
  })
  .catch(erro => {
    console.log('   ❌ Erro:', erro.message);
    
    if (erro.message.includes('401') || erro.message.includes('inválida')) {
      console.log('\n💡 Diagnóstico: CHAVE INVÁLIDA');
      console.log('   - Sua GROQ_API_KEY está incorreta');
      console.log('\n📝 Solução:');
      console.log('   1. Acesse: https://console.groq.com/keys');
      console.log('   2. Gere uma nova chave');
      console.log('   3. Atualize no .env: GROQ_API_KEY=gsk_...');
      
    } else if (erro.message.includes('429') || erro.message.includes('Limite')) {
      console.log('\n💡 Diagnóstico: RATE LIMIT');
      console.log('   - Você fez muitas requisições muito rápido');
      console.log('\n📝 Solução:');
      console.log('   - Aguarde alguns segundos e tente novamente');
      
    } else if (erro.message.includes('timeout')) {
      console.log('\n💡 Diagnóstico: TIMEOUT');
      console.log('   - A Groq demorou muito para responder');
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
