/*
  Seed inicial do banco: cria usuário admin, algumas vagas e um candidato exemplo
*/
require('dotenv').config({ path: __dirname + '/../.env' });
const { Client } = require('pg');
const bcrypt = require('bcryptjs');

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
    console.log('Seeding usuários...');
    const senhaHash = await bcrypt.hash('123456', 10);
    const def = await client.query(`SELECT id FROM companies WHERE documento='00000000000000' LIMIT 1`);
    const companyId = def.rows[0]?.id;
    await client.query(
      `INSERT INTO usuarios (nome, email, senha_hash, perfil, aceitou_lgpd, company_id)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (email) DO UPDATE SET perfil=EXCLUDED.perfil, senha_hash=EXCLUDED.senha_hash, aceitou_lgpd=EXCLUDED.aceitou_lgpd`,
      ['Admin', 'admin@talentmatch.local', senhaHash, 'ADMIN', true, companyId]
    );

    console.log('Seeding vagas...');
    const vagas = [
      {
        titulo: 'Desenvolvedor Full Stack',
        descricao: 'Desenvolvimento de funcionalidades web com Flutter Web e Node.js',
        requisitos: 'Experiência com Flutter, Node.js e PostgreSQL',
        status: 'aberta',
        tecnologias: 'Flutter, Node.js, PostgreSQL',
        nivel: 'Pleno',
      },
      {
        titulo: 'UX/UI Designer',
        descricao: 'Design de interfaces e pesquisa com usuários',
        requisitos: 'Figma, boas práticas de UX, design system',
        status: 'aberta',
        tecnologias: 'Figma',
        nivel: 'Pleno',
      },
    ];
    for (const v of vagas) {
      await client.query(
        `INSERT INTO vagas (titulo, descricao, requisitos, status, tecnologias, nivel)
         VALUES ($1,$2,$3,$4,$5,$6)
         ON CONFLICT DO NOTHING`,
        [v.titulo, v.descricao, v.requisitos, v.status, v.tecnologias, v.nivel]
      );
    }

    console.log('Seeding candidato exemplo...');
    await client.query(
      `INSERT INTO candidatos (nome, email, github)
       VALUES ($1,$2,$3)
       ON CONFLICT (email) DO NOTHING`,
      ['João Silva', 'joao@exemplo.com', 'joaodev']
    );

    console.log('Seed concluído.');
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Falha no seed:', e.message);
  process.exit(1);
});
