// Script para aplicar migration 009 (campos de perfil do usuário)
const db = require('../src/config/database');
const fs = require('fs');
const path = require('path');

async function aplicarMigration() {
  console.log('🔄 Aplicando migration 009: Campos de perfil do usuário...\n');

  try {
    const sqlPath = path.join(__dirname, 'sql', '009_user_profile_fields.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    await db.query(sql);

    console.log('✅ Migration 009 aplicada com sucesso!');
    console.log('📋 Campos adicionados:');
    console.log('   - users.cargo (VARCHAR 50)');
    console.log('   - users.foto_url (TEXT)');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao aplicar migration:', error.message);
    process.exit(1);
  }
}

aplicarMigration();
