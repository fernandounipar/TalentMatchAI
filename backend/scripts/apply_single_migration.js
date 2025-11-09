/*
  Aplica uma única migração SQL informada por nome de arquivo (em scripts/sql)
  Uso: node scripts/apply_single_migration.js 007_users_multitenant.sql
*/
require('dotenv').config({ path: __dirname + '/../.env' });
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function main() {
  const file = process.argv[2];
  if (!file) {
    console.error('Informe o nome do arquivo SQL em scripts/sql');
    process.exit(1);
  }
  const sqlPath = path.join(__dirname, 'sql', file);
  if (!fs.existsSync(sqlPath)) {
    console.error('Arquivo não encontrado:', sqlPath);
    process.exit(1);
  }
  const sql = fs.readFileSync(sqlPath, 'utf8');

  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432,
  });

  console.log('Conectando ao Postgres...', client.connectionParameters);
  await client.connect();
  try {
    console.log(`Executando ${file}...`);
    await client.query(sql);
    console.log('OK');
  } finally {
    await client.end();
  }
}

main().catch((e) => { console.error('Falha:', e.message); process.exit(1); });

