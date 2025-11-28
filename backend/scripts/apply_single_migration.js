const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const fs = require('fs');
const { Client } = require('pg');

async function main() {
  const fileToRun = process.argv[2];
  if (!fileToRun) {
    console.error('Please provide the migration filename (e.g. 034_resume_flow_updates.sql)');
    process.exit(1);
  }

  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432,
  });

  console.log('Connecting to Postgres...');
  await client.connect();

  try {
    const sqlDir = path.join(__dirname, 'sql');
    const fullPath = path.join(sqlDir, fileToRun);

    if (!fs.existsSync(fullPath)) {
      throw new Error(`File not found: ${fullPath}`);
    }

    const sql = fs.readFileSync(fullPath, 'utf8');
    console.log(`\n--- Executing ${fileToRun} ---`);
    await client.query(sql);
    console.log(`OK: ${fileToRun}`);
  } catch (e) {
    console.error(`Error executing ${fileToRun}:`, e.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main().catch(console.error);
