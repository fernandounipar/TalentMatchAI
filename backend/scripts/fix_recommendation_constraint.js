const db = require('../src/config/database');

async function main() {
  try {
    console.log('Atualizando constraint para aceitar valores em PT-BR...');
    
    // Remove constraint antiga
    await db.query(`
      ALTER TABLE relatorios_entrevista 
      DROP CONSTRAINT IF EXISTS interview_reports_recommendation_check
    `);
    
    // Adiciona nova constraint com valores em PT-BR e EN
    await db.query(`
      ALTER TABLE relatorios_entrevista 
      ADD CONSTRAINT interview_reports_recommendation_check 
      CHECK (recommendation IN ('APPROVE', 'MAYBE', 'REJECT', 'PENDING', 'APROVAR', 'DÚVIDA', 'REPROVAR', 'PENDENTE'))
    `);
    
    console.log('✅ Constraint atualizada com sucesso!');
    process.exit(0);
  } catch (e) {
    console.error('Erro:', e);
    process.exit(1);
  }
}

main();
