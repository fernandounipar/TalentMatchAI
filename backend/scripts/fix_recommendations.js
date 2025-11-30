const pool = require('../src/config/database');

async function fixRecommendations() {
  try {
    console.log('=== Corrigindo recomendações de PT para EN ===\n');

    // Mapeamento PT -> EN
    const ptToEn = {
      'APROVAR': 'APPROVE',
      'DÚVIDA': 'MAYBE',
      'DUVIDA': 'MAYBE',
      'REPROVAR': 'REJECT'
    };

    // Buscar relatórios com recomendação em PT
    const reports = await pool.query(`
      SELECT id, recommendation 
      FROM relatorios_entrevista 
      WHERE recommendation IN ('APROVAR', 'DÚVIDA', 'DUVIDA', 'REPROVAR')
    `);

    console.log(`Encontrados ${reports.rows.length} relatórios com recomendação em português.\n`);

    for (const r of reports.rows) {
      const newRec = ptToEn[r.recommendation] || 'PENDING';
      console.log(`  ID ${r.id}: ${r.recommendation} -> ${newRec}`);
      
      await pool.query(
        `UPDATE relatorios_entrevista SET recommendation = $1 WHERE id = $2`,
        [newRec, r.id]
      );
    }

    console.log('\n✅ Recomendações atualizadas com sucesso!');

    // Verificar resultado
    const after = await pool.query(`
      SELECT recommendation, COUNT(*) as total 
      FROM relatorios_entrevista 
      GROUP BY recommendation
    `);
    console.log('\n=== Recomendações após correção ===');
    after.rows.forEach(r => console.log(`  ${r.recommendation}: ${r.total}`));

    process.exit(0);
  } catch (error) {
    console.error('Erro:', error);
    process.exit(1);
  }
}

fixRecommendations();
