/*
  Aplica todas as migrações SQL em backend/scripts/sql na ordem do nome do arquivo
*/
require('dotenv').config({ path: __dirname + '/../.env' });
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function main() {
  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432,
  });

  const sqlDir = path.join(__dirname, 'sql');
  const files = fs
    .readdirSync(sqlDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  console.log('Conectando ao Postgres...', client.connectionParameters);
  await client.connect();

  try {
    for (const file of files) {
      const full = path.join(sqlDir, file);
      const sql = fs.readFileSync(full, 'utf8');
      console.log(`\n--- Executando ${file} ---`);
      await client.query(sql);
      console.log(`OK: ${file}`);
    }
  } finally {
    await client.end();
    console.log('\nMigrações aplicadas com sucesso.');
  }
}

main().catch((e) => {
  console.error('Falha ao aplicar migrações:', e.message);
  process.exit(1);
});

