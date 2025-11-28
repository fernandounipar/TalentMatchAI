const db = require('../src/config/database');
const bcrypt = require('bcryptjs');

async function seed() {
  console.log('🌱 Iniciando seed de dados de demonstração...');

  try {
    // 1. Criar Empresa Demo
    const companyDoc = '00000000000';
    let companyId;

    const companyRes = await db.query('SELECT id FROM companies WHERE document = $1', [companyDoc]);
    if (companyRes.rows.length > 0) {
      companyId = companyRes.rows[0].id;
      console.log('🏢 Empresa demo já existe:', companyId);
    } else {
      const newCompany = await db.query(
        `INSERT INTO companies (type, document, name, criado_em) 
         VALUES ('CPF', $1, 'TalentMatch Demo Corp', NOW()) RETURNING id`,
        [companyDoc]
      );
      companyId = newCompany.rows[0].id;
      console.log('🏢 Empresa demo criada:', companyId);
    }

    // 2. Criar Usuário Admin
    const email = 'admin@talentmatch.ai';
    const userRes = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (userRes.rows.length === 0) {
      const hash = await bcrypt.hash('123456', 10);
      await db.query(
        `INSERT INTO users (company_id, full_name, email, password_hash, role, is_active, created_at)
         VALUES ($1, 'Admin Demo', $2, $3, 'SUPER_ADMIN', true, NOW())`,
        [companyId, email, hash]
      );
      console.log('👤 Usuário admin criado:', email);
    } else {
      console.log('👤 Usuário admin já existe.');
    }

    // 3. Criar Vagas
    const jobs = [
      { title: 'Desenvolvedor Frontend Flutter', status: 'open' },
      { title: 'Backend Node.js Senior', status: 'open' },
      { title: 'Product Manager', status: 'closed' }
    ];

    const jobIds = [];
    for (const job of jobs) {
      let j = await db.query('SELECT id FROM jobs WHERE title = $1 AND company_id = $2', [job.title, companyId]);
      if (j.rows.length === 0) {
        j = await db.query(
          `INSERT INTO jobs (company_id, title, description, requirements, status, created_at)
           VALUES ($1, $2, 'Descrição da vaga de ' || $2, 'Requisitos para ' || $2, $3, NOW()) RETURNING id`,
          [companyId, job.title, job.status]
        );
        console.log('💼 Vaga criada:', job.title);
      }
      jobIds.push(j.rows[0].id);
    }

    // 4. Criar Candidatos
    const candidates = [
      { name: 'João Silva', email: 'joao@email.com' },
      { name: 'Maria Souza', email: 'maria@email.com' },
      { name: 'Carlos Pereira', email: 'carlos@email.com' }
    ];

    const candidateIds = [];
    for (const cand of candidates) {
      let c = await db.query('SELECT id FROM candidates WHERE email = $1 AND company_id = $2', [cand.email, companyId]);
      if (c.rows.length === 0) {
        c = await db.query(
          `INSERT INTO candidates (company_id, full_name, email, created_at)
           VALUES ($1, $2, $3, NOW()) RETURNING id`,
          [companyId, cand.name, cand.email]
        );
        console.log('👨‍💼 Candidato criado:', cand.name);
      }
      candidateIds.push(c.rows[0].id);
    }

    // 5. Criar Entrevistas e Relatórios (Simulação)
    // Entrevista 1: João para Flutter (Agendada)
    const app1 = await findOrCreateApp(companyId, jobIds[0], candidateIds[0]);
    await createInterview(companyId, app1, 'scheduled', null);

    // Entrevista 2: Maria para Node (Concluída com Relatório)
    const app2 = await findOrCreateApp(companyId, jobIds[1], candidateIds[1]);
    const int2 = await createInterview(companyId, app2, 'completed', 'approved');

    // Verificar se já tem relatório
    const repCheck = await db.query('SELECT id FROM interview_reports WHERE interview_id = $1', [int2]);
    if (repCheck.rows.length === 0) {
      await db.query(
        `INSERT INTO interview_reports (
           company_id, interview_id, title, report_type, 
           candidate_name, job_title, overall_score, recommendation, 
           summary_text, created_at, generated_at, version, created_by
         ) VALUES ($1, $2, 'Relatório Final', 'full', 'Maria Souza', 'Backend Node.js Senior', 9.5, 'APPROVE', 
           'Candidata excelente com forte domínio técnico.', NOW(), NOW(), 1, (SELECT id FROM users WHERE email=$3))`,
        [companyId, int2, email]
      );
      console.log('📝 Relatório criado para Maria Souza');
    }

    console.log('✅ Seed concluído com sucesso!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro no seed:', error);
    process.exit(1);
  }
}

async function findOrCreateApp(companyId, jobId, candidateId) {
  const res = await db.query(
    'SELECT id FROM applications WHERE company_id=$1 AND job_id=$2 AND candidate_id=$3',
    [companyId, jobId, candidateId]
  );
  if (res.rows.length > 0) return res.rows[0].id;

  const ins = await db.query(
    `INSERT INTO applications(company_id, job_id, candidate_id, status, created_at)
    VALUES($1, $2, $3, 'open', NOW()) RETURNING id`,
    [companyId, jobId, candidateId]
  );
  return ins.rows[0].id;
}

async function createInterview(companyId, appId, status, result) {
  // Check existing
  const check = await db.query('SELECT id FROM interviews WHERE application_id=$1', [appId]);
  if (check.rows.length > 0) return check.rows[0].id;

  const ins = await db.query(
    `INSERT INTO interviews(company_id, application_id, scheduled_at, mode, status, result, created_at)
    VALUES($1, $2, NOW() + interval '1 day', 'online', $3, $4, NOW()) RETURNING id`,
    [companyId, appId, status, result]
  );
  console.log(`📅 Entrevista criada(Status: ${status})`);
  return ins.rows[0].id;
}

seed();
