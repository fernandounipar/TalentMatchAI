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
    const r = await client.query(
      "SELECT 'usuarios' AS t, COUNT(*)::int AS c FROM usuarios UNION ALL " +
      "SELECT 'jobs', COUNT(*) FROM jobs UNION ALL " +
      "SELECT 'candidates', COUNT(*) FROM candidates UNION ALL " +
      "SELECT 'interviews', COUNT(*) FROM interviews"
    );
    console.log(JSON.stringify(r.rows, null, 2));
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Erro:', e.message);
  process.exit(1);
});

