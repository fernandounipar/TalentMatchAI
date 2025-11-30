require('dotenv').config({ path: __dirname + '/../.env' });
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function main() {
  const client = new Client({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: Number(process.env.DB_PORT) || 5432,
  });
  await client.connect();
  
  try {
    // Listar apenas tabelas (não views)
    const tablesRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    console.log('=== TABELAS BASE (sem views) ===\n');
    const tableNames = tablesRes.rows.map(r => r.table_name);
    tableNames.forEach(t => console.log(t));
    console.log(`\nTotal: ${tableNames.length} tabelas\n`);

    // Gerar DDL para cada tabela
    let ddl = `-- TalentMatchIA - Schema Unificado do Banco de Dados
-- Gerado em: ${new Date().toISOString()}
-- Total de tabelas: ${tableNames.length}

`;

    for (const tableName of tableNames) {
      // Obter colunas da tabela
      const columnsRes = await client.query(`
        SELECT 
          column_name,
          data_type,
          character_maximum_length,
          column_default,
          is_nullable,
          udt_name
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = $1
        ORDER BY ordinal_position
      `, [tableName]);

      // Obter constraints (PK, FK, UNIQUE)
      const constraintsRes = await client.query(`
        SELECT 
          tc.constraint_name,
          tc.constraint_type,
          kcu.column_name,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
          ON tc.constraint_name = kcu.constraint_name
        LEFT JOIN information_schema.constraint_column_usage ccu 
          ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_schema = 'public' 
        AND tc.table_name = $1
      `, [tableName]);

      ddl += `-- ============================================\n`;
      ddl += `-- Tabela: ${tableName}\n`;
      ddl += `-- ============================================\n`;
      ddl += `CREATE TABLE IF NOT EXISTS ${tableName} (\n`;

      const columnDefs = columnsRes.rows.map(col => {
        let def = `  ${col.column_name} `;
        
        // Tipo de dados
        if (col.data_type === 'character varying') {
          def += col.character_maximum_length ? `VARCHAR(${col.character_maximum_length})` : 'VARCHAR';
        } else if (col.data_type === 'ARRAY') {
          def += `${col.udt_name.replace('_', '')}[]`;
        } else if (col.data_type === 'USER-DEFINED') {
          def += col.udt_name;
        } else {
          def += col.data_type.toUpperCase();
        }
        
        // Nullable
        if (col.is_nullable === 'NO') {
          def += ' NOT NULL';
        }
        
        // Default
        if (col.column_default) {
          def += ` DEFAULT ${col.column_default}`;
        }
        
        return def;
      });

      ddl += columnDefs.join(',\n');

      // Adicionar constraints
      const pkCols = constraintsRes.rows
        .filter(c => c.constraint_type === 'PRIMARY KEY')
        .map(c => c.column_name);
      
      if (pkCols.length > 0) {
        ddl += `,\n  PRIMARY KEY (${pkCols.join(', ')})`;
      }

      ddl += `\n);\n\n`;
    }

    // Salvar arquivo
    const outputPath = path.join(__dirname, '..', 'database_schema.sql');
    fs.writeFileSync(outputPath, ddl);
    console.log(`Schema salvo em: ${outputPath}`);

  } finally {
    await client.end();
  }
}

main().catch((e) => { console.error(e.message); process.exit(1); });
