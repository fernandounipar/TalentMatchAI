const db = require('../src/config/database');

async function inspect() {
    try {
        const tables = ['users', 'jobs', 'candidates', 'resumes', 'interviews'];
        for (const t of tables) {
            const res = await db.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = '${t}';
      `);
            console.log(`Colunas da tabela ${t}:`, res.rows.map(r => r.column_name));
        }
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

inspect();
