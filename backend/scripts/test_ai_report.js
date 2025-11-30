require('dotenv').config();
const { gerarRelatorioEntrevista } = require('../src/servicos/iaService');

async function testAIReport() {
  console.log('=== Testando geração de relatório com IA ===\n');
  
  const respostas = [
    {
      pergunta: 'Com sua experiência em Vue.js, quais são os principais desafios que você antecipa?',
      tipo: 'TECNICA',
      resposta: 'Vindo de Vue, eu antecipo como principais desafios a migração de conceitos de reatividade.',
      score: null
    },
    {
      pergunta: 'Descreva como você estruturaria uma API REST robusta.',
      tipo: 'TECNICA',
      resposta: 'Eu organizaria em camadas (routes → controllers → services) com validação.',
      score: null
    },
    {
      pergunta: 'Como você colabora com times de produto e design?',
      tipo: 'COMPORTAMENTAL',
      resposta: 'Eu colaboro bem em Scrum/Kanban participando de reuniões e revisões.',
      score: null
    }
  ];

  const feedbacks = [];

  try {
    console.log('📤 Enviando para IA...');
    console.log(`   Candidato: André Schonrock de Oliveira`);
    console.log(`   Vaga: Desenvolvedor Full Stack Senior`);
    console.log(`   Respostas: ${respostas.length}`);
    console.log(`   Feedbacks: ${feedbacks.length}`);
    console.log('');

    const result = await gerarRelatorioEntrevista({
      candidato: 'André Schonrock de Oliveira',
      vaga: 'Desenvolvedor Full Stack Senior',
      respostas,
      feedbacks,
      companyId: 'c8550646-ec4e-4f7d-97d8-2207ed354a1c'
    });

    console.log('\n=== Resultado ===');
    console.log('Summary:', result.summary_text?.substring(0, 100) + '...');
    console.log('Overall Score:', result.overall_score);
    console.log('Recommendation:', result.recommendation);
    console.log('Strengths:', result.strengths);
    console.log('Risks:', result.risks);

    if (result.summary_text?.includes('sem IA')) {
      console.log('\n⚠️ FALLBACK USADO! A IA não foi acionada corretamente.');
    } else {
      console.log('\n✅ IA gerou o relatório com sucesso!');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error);
    process.exit(1);
  }
}

testAIReport();
