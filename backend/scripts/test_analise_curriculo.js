/**
 * Script para testar análise de currículo com IA
 * 
 * Uso:
 *   node scripts/test_analise_curriculo.js
 */

require('dotenv').config();
const iaService = require('../src/servicos/iaService');

console.log('\n🧪 Teste de Análise de Currículo com IA\n');
console.log('=' .repeat(60));

// Verifica se a chave existe
if (!process.env.OPENAI_API_KEY) {
  console.log('\n❌ OPENAI_API_KEY não configurada!');
  console.log('   Execute primeiro: node scripts/test_openai.js');
  process.exit(1);
}

// Texto de currículo de exemplo
const curriculoExemplo = `
FERNANDO SILVA
Desenvolvedor Full Stack

EXPERIÊNCIA:
- 3 anos como Desenvolvedor Full Stack na TechCorp
- Desenvolvimento de APIs REST com Node.js e Express
- Frontend com React e TypeScript
- Banco de dados PostgreSQL

HABILIDADES:
- JavaScript, Node.js, React, TypeScript
- PostgreSQL, MongoDB
- Git, Docker, CI/CD
- Metodologias Ágeis (Scrum)

FORMAÇÃO:
- Análise e Desenvolvimento de Sistemas - Universidade XYZ (2020-2023)
`;

// Requisitos da vaga de exemplo
const vagaExemplo = {
  titulo: 'Desenvolvedor Full Stack Sênior',
  requisitos: [
    'Node.js',
    'React',
    'PostgreSQL',
    'TypeScript',
    'Docker',
    'Experiência mínima de 3 anos'
  ]
};

console.log('\n📄 Currículo de Teste:');
console.log(curriculoExemplo);

console.log('\n💼 Vaga de Teste:');
console.log(`   Título: ${vagaExemplo.titulo}`);
console.log(`   Requisitos: ${vagaExemplo.requisitos.join(', ')}`);

console.log('\n🤖 Enviando para análise da IA...\n');

// Testa a análise (função correta é gerarAnaliseCurriculo)
iaService.gerarAnaliseCurriculo(curriculoExemplo, vagaExemplo)
  .then(resultado => {
    console.log('✅ Análise Concluída!\n');
    console.log('=' .repeat(60));
    console.log('📊 RESULTADO DA ANÁLISE:\n');
    console.log(JSON.stringify(resultado, null, 2));
    console.log('\n' + '=' .repeat(60));
    
    // Valida estrutura
    console.log('\n🔍 Validação da Estrutura:');
    const camposEsperados = ['skills', 'experiencia', 'aderenciaVaga', 'pontosFortesVaga', 'pontosFracosVaga'];
    let valido = true;
    
    camposEsperados.forEach(campo => {
      if (resultado.hasOwnProperty(campo)) {
        console.log(`   ✅ ${campo}: OK`);
      } else {
        console.log(`   ❌ ${campo}: AUSENTE`);
        valido = false;
      }
    });
    
    if (valido) {
      console.log('\n🎉 Estrutura da resposta está correta!');
    } else {
      console.log('\n⚠️  Estrutura da resposta incompleta.');
    }
    
    console.log('\n' + '=' .repeat(60) + '\n');
  })
  .catch(erro => {
    console.log('❌ Erro na Análise:\n');
    console.log(`   Tipo: ${erro.name}`);
    console.log(`   Mensagem: ${erro.message}`);
    
    if (erro.message.includes('429')) {
      console.log('\n💡 Diagnóstico: RATE LIMIT / CRÉDITO ESGOTADO');
      console.log('   - Seus créditos da OpenAI acabaram');
      console.log('   - Ou você excedeu o limite de requisições');
      console.log('\n📝 Solução:');
      console.log('   1. Verifique seu saldo: https://platform.openai.com/usage');
      console.log('   2. Adicione pagamento: https://platform.openai.com/account/billing');
      console.log('   3. A OpenAI cobra por token usado (~$0.002 por 1K tokens)');
      
    } else if (erro.message.includes('401')) {
      console.log('\n💡 Diagnóstico: CHAVE INVÁLIDA');
      console.log('   - Sua API Key está incorreta ou expirada');
      console.log('\n📝 Solução:');
      console.log('   1. Gere nova chave: https://platform.openai.com/api-keys');
      console.log('   2. Atualize no .env: OPENAI_API_KEY=sk-...');
      
    } else if (erro.message.includes('timeout')) {
      console.log('\n💡 Diagnóstico: TIMEOUT');
      console.log('   - A OpenAI demorou muito para responder');
      console.log('\n📝 Solução:');
      console.log('   - Tente novamente em alguns segundos');
      console.log('   - Verifique sua conexão com internet');
      
    } else {
      console.log('\n💡 Erro desconhecido. Stack trace:');
      console.log(erro.stack);
    }
    
    console.log('\n' + '=' .repeat(60) + '\n');
    process.exit(1);
  });
