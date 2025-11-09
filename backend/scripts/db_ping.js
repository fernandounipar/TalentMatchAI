require('dotenv').config({ path: __dirname + '/../.env' });
const { Client } = require('pg');

async function main() {
  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432,
  });
  console.log('Tentando conectar ao Postgres...', client.connectionParameters);
  await client.connect();
  try {
    const r = await client.query("select version(), current_database() as db, current_user as usr");
    console.log(r.rows[0]);
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Falha na conexão:', e.message);
  process.exit(1);
});

