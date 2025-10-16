require('dotenv').config({ path: __dirname + '/../.env' });
const { Client } = require('pg');

async function main() {
  const tables = process.argv.slice(2);
  if (!tables.length) {
    console.error('Informe ao menos um nome de tabela');
    process.exit(1);
  }
  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432,
  });
  await client.connect();
  try {
    for (const t of tables) {
      const r = await client.query(
        "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name=$1 ORDER BY ordinal_position",
        [t]
      );
      console.log(`== ${t} ==`);
      r.rows.forEach((row) => console.log(`${row.column_name}: ${row.data_type}`));
    }
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});

