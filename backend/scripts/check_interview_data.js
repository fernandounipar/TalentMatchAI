const pool = require('../src/config/database');

async function checkInterviewData() {
  const interviewId = '696ec40d-691c-4047-a004-0726567b34a1';
  
  try {
    console.log('=== Verificando dados da entrevista ===\n');
    
    // 1. Perguntas
    const perguntas = await pool.query(
      'SELECT id, text, kind FROM perguntas_entrevista WHERE interview_id = $1',
      [interviewId]
    );
    console.log(`Perguntas: ${perguntas.rows.length}`);
    perguntas.rows.forEach((p, i) => {
      console.log(`  ${i + 1}. [${p.kind}] ${p.text?.substring(0, 50)}...`);
    });

    // 2. Respostas
    const respostas = await pool.query(
      `SELECT r.id, r.raw_text, q.text as pergunta 
       FROM respostas_entrevista r
       JOIN perguntas_entrevista q ON r.question_id = q.id
       WHERE q.interview_id = $1`,
      [interviewId]
    );
    console.log(`\nRespostas: ${respostas.rows.length}`);
    respostas.rows.forEach((r, i) => {
      console.log(`  ${i + 1}. Pergunta: ${r.pergunta?.substring(0, 30)}...`);
      console.log(`     Resposta: ${r.raw_text?.substring(0, 50) || '(vazio)'}...`);
    });

    // 3. Mensagens do chat
    const mensagens = await pool.query(
      'SELECT sender, LEFT(message, 100) as msg FROM mensagens_entrevista WHERE interview_id = $1 ORDER BY created_at',
      [interviewId]
    );
    console.log(`\nMensagens do chat: ${mensagens.rows.length}`);
    mensagens.rows.forEach((m, i) => {
      console.log(`  ${i + 1}. [${m.sender}] ${m.msg}...`);
    });

    // 4. Status da entrevista
    const entrevista = await pool.query(
      'SELECT id, status, result FROM entrevistas WHERE id = $1',
      [interviewId]
    );
    console.log(`\nStatus da entrevista: ${entrevista.rows[0]?.status}`);
    console.log(`Resultado: ${entrevista.rows[0]?.result || '(nenhum)'}`);

    process.exit(0);
  } catch (error) {
    console.error('Erro:', error);
    process.exit(1);
  }
}

checkInterviewData();
