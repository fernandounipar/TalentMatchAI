const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

async function main() {
  try {
    const hash = await bcrypt.hash('admin123', 10);
    const r = await pool.query('UPDATE usuarios SET password_hash = $1 WHERE email = $2', [hash, 'fernando@email.com']);
    console.log('Senha resetada:', r.rowCount);
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

main();
