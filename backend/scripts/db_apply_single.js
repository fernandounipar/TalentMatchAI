const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const fs = require('fs');
const { Client } = require('pg');

async function main() {
    const file = process.argv[2];
    if (!file) {
        console.error('Uso: node db_apply_single.js <arquivo.sql>');
        process.exit(1);
    }

    const client = new Client({
        user: process.env.DB_USER,
        host: process.env.DB_HOST,
        database: process.env.DB_NAME,
        password: process.env.DB_PASSWORD,
        port: Number(process.env.DB_PORT) || 5432,
    });

    console.log('Conectando ao Postgres...', client.connectionParameters);
    await client.connect();

    try {
        const fullPath = path.resolve(process.cwd(), file);
        if (!fs.existsSync(fullPath)) {
            console.error(`Arquivo não encontrado: ${fullPath}`);
            process.exit(1);
        }
        const sql = fs.readFileSync(fullPath, 'utf8');
        console.log(`\n--- Executando ${path.basename(fullPath)} ---`);
        await client.query(sql);
        console.log(`OK: ${path.basename(fullPath)}`);
    } catch (e) {
        console.error(`Erro ao executar ${file}:`, e.message);
        process.exit(1);
    } finally {
        await client.end();
    }
}

main().catch((e) => {
    console.error('Falha fatal:', e.message);
    process.exit(1);
});
