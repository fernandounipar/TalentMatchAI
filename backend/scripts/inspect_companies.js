const db = require('../src/config/database');

async function inspect() {
    try {
        const res = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'companies';
    `);
        console.log('Colunas da tabela companies:', res.rows);
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

inspect();
