/**
 * Script para aplicar a migration 013_resume_metrics_views.sql
 * Views de métricas para RF1 - Triagem de Currículos
 */

const fs = require('fs');
const path = require('path');
const db = require('../src/config/database');

async function aplicarMigration013() {
  console.log('\n🔄 Aplicando migration 013: Views de métricas de currículos\n');

  try {
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '013_resume_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Executar SQL
    await db.query(sql);

    console.log('✅ Migration 013 aplicada com sucesso!\n');
    console.log('📊 Views criadas:');
    console.log('   - resume_processing_stats');
    console.log('   - resume_crud_stats');
    console.log('   - resume_analysis_performance');
    console.log('   - resume_by_job_stats');
    console.log('   - candidate_resume_history');
    console.log('\n📈 Função criada:');
    console.log('   - get_resume_metrics(company_id UUID)');
    console.log('\n🎯 Índices criados para performance das queries');
    
    // Testar se as views foram criadas
    console.log('\n🧪 Testando views...\n');
    
    const testQueries = [
      { name: 'resume_processing_stats', query: 'SELECT COUNT(*) FROM resume_processing_stats' },
      { name: 'resume_crud_stats', query: 'SELECT COUNT(*) FROM resume_crud_stats' },
      { name: 'resume_analysis_performance', query: 'SELECT COUNT(*) FROM resume_analysis_performance' },
      { name: 'resume_by_job_stats', query: 'SELECT COUNT(*) FROM resume_by_job_stats' },
      { name: 'candidate_resume_history', query: 'SELECT COUNT(*) FROM candidate_resume_history' }
    ];

    for (const test of testQueries) {
      try {
        const result = await db.query(test.query);
        console.log(`   ✅ ${test.name}: ${result.rows[0].count} registros`);
      } catch (err) {
        console.log(`   ❌ ${test.name}: ERRO - ${err.message}`);
      }
    }

    console.log('\n✨ Migration concluída com sucesso!\n');
    process.exit(0);

  } catch (error) {
    console.error('\n❌ Erro ao aplicar migration 013:');
    console.error(error.message);
    console.error('\nStack trace:');
    console.error(error.stack);
    process.exit(1);
  }
}

// Executar
aplicarMigration013();
