/**
 * Script para corrigir a constraint de overall_score na tabela relatorios_entrevista
 * O score deve aceitar valores de 0 a 100, não apenas 0 a 5
 */

const db = require('../src/config/database');

async function fixConstraint() {
  try {
    console.log('🔍 Verificando constraints existentes...');
    
    // Listar constraints da tabela
    const constraints = await db.query(`
      SELECT conname, pg_get_constraintdef(oid) as definition 
      FROM pg_constraint 
      WHERE conrelid = 'relatorios_entrevista'::regclass 
      AND contype = 'c'
    `);
    
    console.log('Constraints encontradas:');
    constraints.rows.forEach(c => {
      console.log(`  - ${c.conname}: ${c.definition}`);
    });

    // Procurar constraint de overall_score
    const scoreConstraint = constraints.rows.find(c => 
      c.conname.includes('overall_score') || c.definition.includes('overall_score')
    );

    if (scoreConstraint) {
      console.log(`\n🔧 Removendo constraint: ${scoreConstraint.conname}`);
      await db.query(`ALTER TABLE relatorios_entrevista DROP CONSTRAINT "${scoreConstraint.conname}"`);
      console.log('✅ Constraint removida com sucesso!');
      
      // Adicionar nova constraint com range 0-100
      console.log('\n📝 Adicionando nova constraint (0-100)...');
      await db.query(`
        ALTER TABLE relatorios_entrevista 
        ADD CONSTRAINT interview_reports_overall_score_check 
        CHECK (overall_score IS NULL OR (overall_score >= 0 AND overall_score <= 100))
      `);
      console.log('✅ Nova constraint adicionada!');
    } else {
      console.log('\n⚠️ Constraint de overall_score não encontrada. Criando nova...');
      
      // Tenta criar a constraint correta
      try {
        await db.query(`
          ALTER TABLE relatorios_entrevista 
          ADD CONSTRAINT interview_reports_overall_score_check 
          CHECK (overall_score IS NULL OR (overall_score >= 0 AND overall_score <= 100))
        `);
        console.log('✅ Constraint criada com sucesso!');
      } catch (e) {
        if (e.message.includes('already exists')) {
          console.log('Constraint já existe, tentando remover e recriar...');
          await db.query(`ALTER TABLE relatorios_entrevista DROP CONSTRAINT IF EXISTS interview_reports_overall_score_check`);
          await db.query(`
            ALTER TABLE relatorios_entrevista 
            ADD CONSTRAINT interview_reports_overall_score_check 
            CHECK (overall_score IS NULL OR (overall_score >= 0 AND overall_score <= 100))
          `);
          console.log('✅ Constraint recriada com sucesso!');
        } else {
          throw e;
        }
      }
    }

    // Verificar resultado
    console.log('\n🔍 Verificando constraints após correção...');
    const newConstraints = await db.query(`
      SELECT conname, pg_get_constraintdef(oid) as definition 
      FROM pg_constraint 
      WHERE conrelid = 'relatorios_entrevista'::regclass 
      AND contype = 'c'
    `);
    
    console.log('Constraints atuais:');
    newConstraints.rows.forEach(c => {
      console.log(`  - ${c.conname}: ${c.definition}`);
    });

    console.log('\n✅ Correção concluída!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }
}

fixConstraint();
