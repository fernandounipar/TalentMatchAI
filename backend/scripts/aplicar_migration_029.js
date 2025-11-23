const db = require('../src/config/database');
const fs = require('fs');
const path = require('path');

async function aplicarMigration029() {
  console.log('\n=== Aplicando Migration 029: GitHub Metrics Views ===\n');

  try {
    // Ler arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', '029_github_metrics_views.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executando migration...\n');
    await db.query(sql);
    console.log('✓ Migration 029 aplicada com sucesso!\n');

    // Validações
    console.log('=== Validando views criadas ===\n');

    const expectedViews = [
      'github_integration_stats',
      'github_sync_timeline',
      'github_top_languages',
      'github_top_candidates',
      'github_skills_distribution'
    ];

    for (const viewName of expectedViews) {
      const result = await db.query(`
        SELECT viewname
        FROM pg_views
        WHERE viewname = $1 AND schemaname = 'public'
      `, [viewName]);

      console.log(result.rows.length > 0 ? `  ✓ ${viewName}` : `  ✗ ${viewName} (AUSENTE)`);
    }

    // Verificar função
    console.log('\n=== Função ===\n');
    const func = await db.query(`
      SELECT proname, prokind
      FROM pg_proc
      WHERE proname = 'get_github_metrics'
        AND pronamespace = 'public'::regnamespace
    `);

    console.log(func.rows.length > 0 ? '  ✓ get_github_metrics (FUNCTION)' : '  ✗ Função não encontrada');

    // Verificar índices adicionais
    console.log('\n=== Índices Adicionais ===\n');
    const additionalIndexes = [
      'idx_github_sync_date',
      'idx_github_candidate_active',
      'idx_github_consent'
    ];

    for (const idxName of additionalIndexes) {
      const result = await db.query(`
        SELECT indexname
        FROM pg_indexes
        WHERE indexname = $1
          AND schemaname = 'public'
      `, [idxName]);

      console.log(result.rows.length > 0 ? `  ✓ ${idxName}` : `  ✗ ${idxName} (AUSENTE)`);
    }

    // Testar função get_github_metrics
    console.log('\n=== Testando get_github_metrics() ===\n');
    try {
      const testResult = await db.query(`
        SELECT get_github_metrics(NULL) as metrics
      `);
      console.log('  ✓ Função executada com sucesso\n');
      
      const metrics = testResult.rows[0]?.metrics || {};
      console.log('  Estrutura do metrics:');
      console.log(`    - stats: ${metrics.stats ? 'presente' : 'ausente'}`);
      console.log(`    - top_languages: ${metrics.top_languages ? 'presente' : 'ausente'}`);
      console.log(`    - top_candidates: ${metrics.top_candidates ? 'presente' : 'ausente'}`);
      console.log(`    - recent_success_rate: ${metrics.recent_success_rate !== undefined ? 'presente' : 'ausente'}`);
    } catch (err) {
      console.log('  ✗ Erro ao testar função:', err.message);
    }

    // Testar views com dados
    console.log('\n=== Testando views com dados ===\n');
    for (const viewName of expectedViews) {
      try {
        const count = await db.query(`SELECT COUNT(*) as total FROM ${viewName}`);
        console.log(`  ✓ ${viewName}: ${count.rows[0].total} registros`);
      } catch (err) {
        console.log(`  ✗ ${viewName}: ${err.message}`);
      }
    }

    console.log('\n=== Validação completa ===\n');

  } catch (error) {
    console.error('✗ Erro ao aplicar migration 029:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    await db.end();
  }
}

aplicarMigration029();
