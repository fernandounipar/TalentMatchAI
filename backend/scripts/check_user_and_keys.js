const db = require('../src/config/database');

db.query(`
  SELECT 
    u.id, 
    u.full_name, 
    u.email, 
    u.role, 
    u.company_id, 
    c.nome as company_name 
  FROM users u 
  LEFT JOIN companies c ON u.company_id = c.id 
  WHERE u.email = 'fernando@email.com'
`)
.then(r => { 
  console.log('👤 Usuário:');
  console.table(r.rows);
  
  if (r.rows[0]?.company_id) {
    return db.query(`
      SELECT id, provider, label, is_active, company_id 
      FROM api_keys 
      WHERE company_id = $1 
      ORDER BY created_at DESC
    `, [r.rows[0].company_id]);
  }
})
.then(r => {
  if (r) {
    console.log('\n🔑 API Keys do company_id do usuário:');
    console.table(r.rows);
  }
  process.exit(0);
})
.catch(e => { 
  console.error(e.message); 
  process.exit(1); 
});
