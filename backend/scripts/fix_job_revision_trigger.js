const db = require('../src/config/database');

async function main() {
  try {
    console.log('Atualizando função create_job_revision para usar revisoes_vagas...');
    
    await db.query(`
      CREATE OR REPLACE FUNCTION create_job_revision()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Só cria revisão se houver mudança em campos importantes
        IF (OLD.title IS DISTINCT FROM NEW.title
            OR OLD.description IS DISTINCT FROM NEW.description
            OR OLD.requirements IS DISTINCT FROM NEW.requirements
            OR OLD.seniority IS DISTINCT FROM NEW.seniority
            OR OLD.salary_min IS DISTINCT FROM NEW.salary_min
            OR OLD.salary_max IS DISTINCT FROM NEW.salary_max
            OR OLD.status IS DISTINCT FROM NEW.status) THEN
          
          -- Incrementar versão
          NEW.version = COALESCE(OLD.version, 1) + 1;
          
          -- Inserir revisão na tabela correta (revisoes_vagas)
          INSERT INTO revisoes_vagas (
            job_id, company_id, version, title, description, requirements,
            seniority, location_type, status, salary_min, salary_max,
            contract_type, department, unit, benefits, skills_required,
            is_remote, changed_by, changed_at
          ) VALUES (
            NEW.id, NEW.company_id, OLD.version, OLD.title, OLD.description, OLD.requirements,
            OLD.seniority, OLD.location_type, OLD.status, OLD.salary_min, OLD.salary_max,
            OLD.contract_type, OLD.department, OLD.unit, OLD.benefits, OLD.skills_required,
            OLD.is_remote, NEW.updated_by, now()
          );
        END IF;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
    
    console.log('✅ Função create_job_revision atualizada com sucesso!');
    process.exit(0);
  } catch (e) {
    console.error('Erro:', e);
    process.exit(1);
  }
}

main();
