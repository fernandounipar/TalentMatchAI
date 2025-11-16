/*
  Testa uma API Key cadastrada na tabela api_keys.
  Uso:
    node scripts/test_api_key_from_db.js <company_id>

  - Busca a API Key mais recente e ativa para o provider 'OPENAI' do company_id informado.
  - Faz uma chamada simples à OpenAI (chat.completions) e imprime a resposta.
*/

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { Client } = require('pg');
const OpenAI = require('openai');

async function main() {
  const companyId = process.argv[2];
  if (!companyId) {
    console.error('Informe o company_id:');
    console.error('  node scripts/test_api_key_from_db.js <company_id>');
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
    console.log(`Buscando API Key para company_id=${companyId} e provider='OPENAI'...`);
    const r = await client.query(
      `SELECT token, provider, label, created_at
       FROM api_keys
       WHERE company_id = $1 AND provider = 'OPENAI' AND is_active = true
       ORDER BY created_at DESC
       LIMIT 1`,
      [companyId]
    );

    if (!r.rows[0]) {
      console.error('Nenhuma API Key ativa encontrada para este tenant.');
      process.exit(1);
    }

    const row = r.rows[0];
    console.log(`Encontrada API Key (${row.provider}) criada em ${row.created_at} (label="${row.label || ''}")`);

    const openai = new OpenAI({ apiKey: row.token });
    console.log('Chamando OpenAI (gpt-4o-mini) para teste rápido...');

    const resp = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: 'Responda apenas "OK" se esta chave estiver funcionando.',
        },
      ],
      max_tokens: 5,
      temperature: 0,
    });

    const content = resp.choices?.[0]?.message?.content || '';
    console.log('\nResposta da OpenAI:');
    console.log('--------------------');
    console.log(content.trim());
    console.log('--------------------');
    console.log('\n✅ Teste concluído.');
  } catch (e) {
    console.error('❌ Erro ao testar API Key:', e.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Falha:', e.message);
  process.exit(1);
});

