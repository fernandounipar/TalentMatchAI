/**
 * Teste completo da análise de currículo com OpenRouter
 */

require('dotenv').config();
const openRouterService = require('../src/servicos/openRouterService');

console.log('\n🧪 Teste COMPLETO de Análise de Currículo (OpenRouter)\n');
console.log('=' .repeat(60));

const curriculoExemplo = `
FERNANDO SILVA
Desenvolvedor Full Stack Sênior

EXPERIÊNCIA PROFISSIONAL:
• TechCorp (2020-2023) - Desenvolvedor Full Stack Sênior
  - Desenvolvimento de APIs REST com Node.js e Express
  - Frontend com React e TypeScript
  - Implementação de CI/CD com Docker e GitHub Actions
  - Liderança técnica de equipe de 3 desenvolvedores
  - Banco de dados PostgreSQL e MongoDB

• StartupXYZ (2018-2020) - Desenvolvedor JavaScript
  - Desenvolvimento de aplicações web com React
  - Integração com APIs REST
  - Testes automatizados com Jest

HABILIDADES TÉCNICAS:
• Backend: Node.js, Express, NestJS, GraphQL
• Frontend: React, TypeScript, Next.js, Flutter
• Banco de Dados: PostgreSQL, MongoDB, Redis
• DevOps: Docker, CI/CD, AWS, Git
• Metodologias: Scrum, Kanban, TDD

FORMAÇÃO:
• Análise e Desenvolvimento de Sistemas - Universidade XYZ (2016-2019)
• Curso de Especialização em Arquitetura de Software (2021)

IDIOMAS:
• Português (Nativo)
• Inglês (Avançado)
`;

const vagaExemplo = {
  titulo: 'Desenvolvedor Full Stack Sênior',
  requisitos: 'Node.js, React, TypeScript, PostgreSQL, Docker, Experiência com CI/CD, Mínimo 3 anos de experiência'
};

console.log('📄 Currículo:', curriculoExemplo.substring(0, 200) + '...');
console.log('\n💼 Vaga:', vagaExemplo.titulo);
console.log('📋 Requisitos:', vagaExemplo.requisitos);
console.log('\n🤖 Analisando com OpenRouter (Grok-4.1-fast)...\n');

openRouterService.analisarCurriculo(curriculoExemplo, vagaExemplo)
  .then(resultado => {
    console.log('✅ ANÁLISE CONCLUÍDA!\n');
    console.log('=' .repeat(60));
    console.log('📊 RESULTADO COMPLETO:\n');
    console.log(JSON.stringify(resultado, null, 2));
    console.log('\n' + '=' .repeat(60));
    
    console.log('\n🔍 Resumo da Análise:');
    console.log(`   Skills encontradas: ${resultado.skills?.length || 0}`);
    console.log(`   Senioridade detectada: ${resultado.senioridade || 'N/A'}`);
    console.log(`   Aderência à vaga: ${resultado.aderenciaVaga || 'N/A'}%`);
    console.log(`   Pontos fortes: ${resultado.pontosFortesVaga?.length || 0}`);
    console.log(`   Pontos fracos: ${resultado.pontosFracosVaga?.length || 0}`);
    
    if (resultado.skills && resultado.skills.length > 0) {
      console.log(`\n💡 Top Skills: ${resultado.skills.slice(0, 5).join(', ')}`);
    }
    
    console.log('\n🎉 Teste concluído com sucesso!\n');
  })
  .catch(erro => {
    console.log('❌ ERRO:', erro.message);
    console.log('\n' + '=' .repeat(60));
    console.log('\n💡 Possíveis causas:');
    console.log('   1. OPENROUTER_API_KEY não configurada ou inválida');
    console.log('   2. Créditos insuficientes no OpenRouter');
    console.log('   3. Problema de conexão');
    console.log('\n📝 Verifique:');
    console.log('   - .env tem OPENROUTER_API_KEY configurada');
    console.log('   - Chave é válida em https://openrouter.ai/keys');
    console.log('   - Tem créditos em https://openrouter.ai/credits\n');
    process.exit(1);
  });
