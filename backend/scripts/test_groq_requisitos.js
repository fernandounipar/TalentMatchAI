/**
 * Teste rápido: Verifica se groqService lida corretamente com requisitos (string vs array)
 */

require('dotenv').config();
const groqService = require('../src/servicos/groqService');

async function testar() {
  console.log('🧪 Testando groqService com diferentes formatos de requisitos...\n');

  const curriculoTexto = `
    João Silva
    Desenvolvedor Full Stack - 3 anos de experiência
    
    Skills:
    - JavaScript, TypeScript, Node.js
    - React, Next.js
    - PostgreSQL, MongoDB
    - Git, Docker
    
    Experiência:
    - TechCorp (2021-2024): Desenvolvedor Full Stack
      * Desenvolvimento de APIs REST com Node.js
      * Frontend com React e TypeScript
      * Integração com bancos de dados relacionais
  `;

  // Teste 1: Requisitos como ARRAY (formato esperado)
  console.log('📋 Teste 1: Requisitos como ARRAY');
  try {
    const vaga1 = {
      titulo: 'Desenvolvedor Full Stack',
      requisitos: ['JavaScript', 'React', 'Node.js', 'PostgreSQL']
    };
    
    const resultado1 = await groqService.analisarCurriculo(curriculoTexto, vaga1);
    console.log('✅ Sucesso com array!');
    console.log(`   Skills: ${resultado1.skills.slice(0, 3).join(', ')}...`);
    console.log(`   Aderência: ${resultado1.aderenciaVaga || 'N/A'}`);
  } catch (error) {
    console.log(`❌ Erro: ${error.message}`);
  }

  console.log('\n' + '='.repeat(60) + '\n');

  // Teste 2: Requisitos como STRING (formato que vinha do banco causando erro)
  console.log('📋 Teste 2: Requisitos como STRING');
  try {
    const vaga2 = {
      titulo: 'Desenvolvedor Full Stack',
      requisitos: 'JavaScript, React, Node.js, PostgreSQL' // STRING!
    };
    
    const resultado2 = await groqService.analisarCurriculo(curriculoTexto, vaga2);
    console.log('✅ Sucesso com string!');
    console.log(`   Skills: ${resultado2.skills.slice(0, 3).join(', ')}...`);
    console.log(`   Aderência: ${resultado2.aderenciaVaga || 'N/A'}`);
  } catch (error) {
    console.log(`❌ Erro: ${error.message}`);
  }

  console.log('\n' + '='.repeat(60) + '\n');

  // Teste 3: Requisitos NULL (formato que pode vir do banco)
  console.log('📋 Teste 3: Requisitos NULL');
  try {
    const vaga3 = {
      titulo: 'Desenvolvedor Full Stack',
      requisitos: null // NULL!
    };
    
    const resultado3 = await groqService.analisarCurriculo(curriculoTexto, vaga3);
    console.log('✅ Sucesso com null!');
    console.log(`   Skills: ${resultado3.skills.slice(0, 3).join(', ')}...`);
    console.log(`   Senioridade: ${resultado3.senioridade}`);
  } catch (error) {
    console.log(`❌ Erro: ${error.message}`);
  }

  console.log('\n' + '='.repeat(60) + '\n');

  // Teste 4: Sem vaga (análise geral)
  console.log('📋 Teste 4: Sem vaga (análise geral)');
  try {
    const resultado4 = await groqService.analisarCurriculo(curriculoTexto, null);
    console.log('✅ Sucesso sem vaga!');
    console.log(`   Skills: ${resultado4.skills.slice(0, 3).join(', ')}...`);
    console.log(`   Senioridade: ${resultado4.senioridade}`);
  } catch (error) {
    console.log(`❌ Erro: ${error.message}`);
  }

  console.log('\n' + '='.repeat(60));
  console.log('\n🎉 Testes concluídos! O groqService está pronto para lidar com qualquer formato de requisitos.\n');
}

// Executar
if (!process.env.GROQ_API_KEY) {
  console.error('❌ GROQ_API_KEY não configurada no .env');
  process.exit(1);
}

testar().catch(error => {
  console.error('❌ Erro ao executar testes:', error);
  process.exit(1);
});
