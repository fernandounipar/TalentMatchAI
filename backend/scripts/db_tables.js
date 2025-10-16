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
  await client.connect();
  try {
    const r = await client.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name");
    console.log(r.rows.map(x => x.table_name).join('\n'));
  } finally {
    await client.end();
  }
}

main().catch((e) => { console.error(e.message); process.exit(1); });

