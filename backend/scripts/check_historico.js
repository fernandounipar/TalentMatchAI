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
    // Ver colunas da tabela entrevistas
    const cols = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'entrevistas'
      ORDER BY ordinal_position
    `);
    console.log('\n=== COLUNAS DE ENTREVISTAS ===');
    console.log(cols.rows.map(r => r.column_name).join(', '));

    // Ver colunas da tabela relatorios_entrevista
    const cols2 = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'relatorios_entrevista'
      ORDER BY ordinal_position
    `);
    console.log('\n=== COLUNAS DE RELATORIOS_ENTREVISTA ===');
    console.log(cols2.rows.map(r => r.column_name).join(', '));

    // Ver colunas de interview_reports
    const cols3 = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'interview_reports'
      ORDER BY ordinal_position
    `);
    console.log('\n=== COLUNAS DE INTERVIEW_REPORTS ===');
    console.log(cols3.rows.map(r => r.column_name).join(', '));

    // Buscar de interview_reports
    const result = await pool.query(`
      SELECT 
        id, 
        interview_id,
        recommendation,
        overall_score,
        created_at
      FROM interview_reports
      LIMIT 10
    `);
    
    console.log('\n=== INTERVIEW_REPORTS ===');
    console.table(result.rows);

    // Verificar quantos relatórios existem em cada tabela
    const reports1 = await pool.query(`SELECT COUNT(*) as count FROM relatorios_entrevista`);
    const reports2 = await pool.query(`SELECT COUNT(*) as count FROM interview_reports`);
    console.log('\n=== TOTAL DE RELATÓRIOS ===');
    console.log('relatorios_entrevista:', reports1.rows[0].count);
    console.log('interview_reports:', reports2.rows[0].count);

    process.exit(0);
  } catch (e) {
    console.error('Erro:', e.message);
    process.exit(1);
  }
}

main();
