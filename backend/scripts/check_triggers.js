const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

pool.query(`
  SELECT trigger_name, event_manipulation
  FROM information_schema.triggers
  WHERE event_object_table = 'interviews'
`).then(r => {
  console.log('Triggers encontrados:', r.rowCount);
  r.rows.forEach(row => console.log(' -', row.trigger_name, '(', row.event_manipulation, ')'));
  pool.end();
}).catch(err => {
  console.error('Erro:', err.message);
  pool.end();
});
