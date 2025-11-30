const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

async function checkConstraint() {
  try {
    const result = await pool.query(`
      SELECT conname, pg_get_constraintdef(c.oid) as def 
      FROM pg_constraint c 
      WHERE conname = 'jobs_status_check'
    `);
    console.log('Constraint atual:');
    console.log(JSON.stringify(result.rows, null, 2));
    process.exit(0);
  } catch (e) {
    console.error('Erro:', e.message);
    process.exit(1);
  }
}

checkConstraint();
