const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

async function updateConstraint() {
  try {
    // Remove a constraint antiga
    await pool.query('ALTER TABLE vagas DROP CONSTRAINT IF EXISTS jobs_status_check');
    console.log('✅ Constraint antiga removida');
    
    // Adiciona a nova constraint com 'filled'
    await pool.query(`
      ALTER TABLE vagas ADD CONSTRAINT jobs_status_check 
      CHECK (status IN ('draft', 'open', 'paused', 'closed', 'archived', 'filled'))
    `);
    console.log('✅ Nova constraint adicionada com status "filled"');
    
    // Verifica
    const result = await pool.query(`
      SELECT conname, pg_get_constraintdef(c.oid) as def 
      FROM pg_constraint c 
      WHERE conname = 'jobs_status_check'
    `);
    console.log('\nConstraint atualizada:');
    console.log(JSON.stringify(result.rows, null, 2));
    
    process.exit(0);
  } catch (e) {
    console.error('Erro:', e.message);
    process.exit(1);
  }
}

updateConstraint();
