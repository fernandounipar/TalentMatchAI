const db = require('../config/database');

async function audit(req, action, entity, entityId, payload) {
  try {
    const userId = req.usuario?.id || null;
    const companyId = req.usuario?.company_id;
    await db.query(
      `INSERT INTO audit_logs (company_id, user_id, action, entity, entity_id, payload, created_at, ip, ua)
       VALUES ($1,$2,$3,$4,$5,$6::jsonb, now(), $7, $8)` ,
      [companyId, userId, action, entity, String(entityId || ''), JSON.stringify(payload || {}), req.ip, req.headers['user-agent']]
    );
  } catch (_) {
    // não interrompe fluxo
  }
}

module.exports = { audit };
