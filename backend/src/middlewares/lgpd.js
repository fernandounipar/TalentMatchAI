// Middleware simples para registrar consentimento e garantir política de retenção.
// Para MVP, apenas registra header opcional 'x-lgpd-consent: true'.

function verificarConsentimentoLGPD(req, _res, next) {
  req.consentiuLGPD = String(req.headers['x-lgpd-consent'] || '').toLowerCase() === 'true';
  next();
}

module.exports = { verificarConsentimentoLGPD };

