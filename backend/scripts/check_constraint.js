const db = require('../src/config/database');

async function main() {
  try {
    const result = await db.query(`
      SELECT pg_get_constraintdef(oid) as def 
      FROM pg_constraint 
      WHERE conname = 'interview_reports_recommendation_check'
    `);
    console.log('Constraint definition:', result.rows);
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

main();
