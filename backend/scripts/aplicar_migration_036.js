/**
 * Script para aplicar a migration 036 - Renomear Tabelas Faltantes para PT-BR (Fase 2)
 * 
 * Tabelas renomeadas:
 *   - live_assessments → avaliacoes_tempo_real
 *   - interview_question_sets → conjuntos_perguntas_entrevista  
 *   - dashboard_presets → presets_dashboard
 * 
 * Views criadas:
 *   - entrevistas_por_status (substitui interviews_by_status)
 *   - entrevistas_por_resultado (substitui interviews_by_result)
 * 
 * Uso: node scripts/aplicar_migration_036.js
 */

require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'talentmatch'
});

async function aplicarMigration() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Iniciando migration 036 - Renomear Tabelas PT-BR (Fase 2)...\n');
    
    const sqlPath = path.join(__dirname, 'sql', '036_rename_tables_ptbr_fase2.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Executar o SQL
    await client.query(sql);
    
    console.log('\n✅ Migration 036 aplicada com sucesso!');
    
    // Verificar resultado
    console.log('\n📋 Verificando tabelas renomeadas...\n');
    
    const verificacao = await client.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      AND tablename IN (
        'avaliacoes_tempo_real',
        'conjuntos_perguntas_entrevista',
        'presets_dashboard',
        'entrevistas_por_status',
        'entrevistas_por_resultado'
      )
      ORDER BY tablename
    `);
    
    const viewsVerificacao = await client.query(`
      SELECT viewname 
      FROM pg_views 
      WHERE schemaname = 'public' 
      AND viewname IN (
        'entrevistas_por_status',
        'entrevistas_por_resultado'
      )
      ORDER BY viewname
    `);
    
    console.log('Tabelas PT-BR encontradas:');
    verificacao.rows.forEach(r => console.log(`  ✅ ${r.tablename}`));
    
    console.log('\nViews PT-BR encontradas:');
    viewsVerificacao.rows.forEach(r => console.log(`  ✅ ${r.viewname}`));
    
    // Verificar se tabelas antigas ainda existem
    const tabelasAntigas = await client.query(`
      SELECT tablename 
      FROM pg_tables 
      WHERE schemaname = 'public' 
      AND tablename IN (
        'live_assessments',
        'interview_question_sets',
        'dashboard_presets'
      )
      ORDER BY tablename
    `);
    
    if (tabelasAntigas.rows.length > 0) {
      console.log('\n⚠️  Tabelas antigas ainda existem (provavelmente já foram renomeadas):');
      tabelasAntigas.rows.forEach(r => console.log(`  - ${r.tablename}`));
    }
    
  } catch (error) {
    console.error('❌ Erro ao aplicar migration 036:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

aplicarMigration().catch(console.error);
