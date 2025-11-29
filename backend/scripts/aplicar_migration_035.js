/**
 * Script para aplicar Migration 035v2 - Limpeza de Tabelas em Inglês
 * Remove tabelas em inglês que não são mais utilizadas
 */

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

// Configuração do banco
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '1234',
    database: process.env.DB_NAME || 'talentmatch'
});

async function aplicarMigration() {
    const client = await pool.connect();
    
    try {
        console.log('='.repeat(60));
        console.log('MIGRATION 035v2: Limpeza de Tabelas em Inglês');
        console.log('='.repeat(60));
        
        // Listar tabelas antes
        console.log('\n📋 Tabelas ANTES da migração:');
        const tabelasAntes = await client.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
              AND table_type = 'BASE TABLE'
            ORDER BY table_name
        `);
        console.log(`Total: ${tabelasAntes.rows.length} tabelas`);
        tabelasAntes.rows.forEach(r => console.log(`  - ${r.table_name}`));
        
        // Ler o script SQL
        const sqlPath = path.join(__dirname, 'sql', '035_cleanup_english_tables_v2.sql');
        const sqlContent = fs.readFileSync(sqlPath, 'utf8');
        
        console.log('\n🚀 Executando script de limpeza...\n');
        
        // Executar o script
        await client.query(sqlContent);
        
        console.log('✅ Script executado com sucesso!\n');
        
        // Listar tabelas depois
        console.log('📋 Tabelas DEPOIS da migração:');
        const tabelasDepois = await client.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
              AND table_type = 'BASE TABLE'
            ORDER BY table_name
        `);
        console.log(`Total: ${tabelasDepois.rows.length} tabelas`);
        tabelasDepois.rows.forEach(r => console.log(`  - ${r.table_name}`));
        
        // Calcular diferença
        const removidas = tabelasAntes.rows.length - tabelasDepois.rows.length;
        console.log(`\n📊 Resumo: ${removidas} tabelas removidas`);
        
        console.log('\n' + '='.repeat(60));
        console.log('✅ MIGRATION 035v2 CONCLUÍDA COM SUCESSO!');
        console.log('='.repeat(60));
        
    } catch (error) {
        console.error('❌ Erro na migração:', error.message);
        throw error;
    } finally {
        client.release();
        await pool.end();
    }
}

// Executar
aplicarMigration().catch(err => {
    console.error('Falha na migração:', err);
    process.exit(1);
});
