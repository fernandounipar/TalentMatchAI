const pool = require('../src/config/database');

async function testReportQuery() {
  const interviewId = '696ec40d-691c-4047-a004-0726567b34a1';
  const companyId = 'c8550646-ec4e-4f7d-97d8-2207ed354a1c';
  
  try {
    console.log('=== Testando query de relatório ===\n');
    
    // Query igual à do interviews.js
    const respostasQuery = await pool.query(`
      SELECT 
        q.text as question_text,
        q.kind as question_type,
        a.raw_text as answer_text,
        la.score_final,
        la.feedback_auto,
        la.feedback_manual
      FROM respostas_entrevista a
      JOIN perguntas_entrevista q ON a.question_id = q.id
      LEFT JOIN avaliacoes_tempo_real la ON la.question_id = q.id AND la.interview_id = $1
      WHERE q.interview_id = $1
      ORDER BY a.created_at
    `, [interviewId]);

    console.log(`Respostas encontradas: ${respostasQuery.rows.length}`);
    
    if (respostasQuery.rows.length > 0) {
      respostasQuery.rows.forEach((r, i) => {
        console.log(`\n${i + 1}. ${r.question_type}: ${r.question_text?.substring(0, 40)}...`);
        console.log(`   Resposta: ${r.answer_text?.substring(0, 50) || '(vazia)'}...`);
        console.log(`   Score: ${r.score_final || 'N/A'}`);
      });
    }

    // Verificar mensagens
    const mensagensQuery = await pool.query(`
      SELECT sender, message, created_at
      FROM mensagens_entrevista
      WHERE interview_id = $1 AND company_id = $2
      ORDER BY created_at ASC
    `, [interviewId, companyId]);

    console.log(`\nMensagens encontradas: ${mensagensQuery.rows.length}`);

    // Simular o que seria enviado para IA
    const respostas = respostasQuery.rows.map(r => ({
      pergunta: r.question_text,
      tipo: r.question_type,
      resposta: r.answer_text,
      score: r.score_final
    }));

    const feedbacks = respostasQuery.rows
      .filter(r => r.feedback_auto || r.feedback_manual || r.score_final)
      .map(r => ({
        topic: r.question_type || 'Pergunta',
        score: r.score_final || 0
      }));

    console.log('\n=== Dados para IA ===');
    console.log(`Respostas: ${respostas.length}`);
    console.log(`Feedbacks: ${feedbacks.length}`);

    if (respostas.length === 0) {
      console.log('\n⚠️ PROBLEMA: Nenhuma resposta será enviada para IA!');
      console.log('   Isso fará o fallback ser usado (sem IA)');
    }

    process.exit(0);
  } catch (error) {
    console.error('Erro:', error);
    process.exit(1);
  }
}

testReportQuery();
