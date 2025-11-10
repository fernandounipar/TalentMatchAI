/**
 * Utilitários de Validação de Documentos Brasileiros
 * Validadores para CPF e CNPJ com verificação de dígito
 */

/**
 * Remove caracteres não numéricos de um documento
 * @param {string} doc - Documento com ou sem máscara
 * @returns {string} - Apenas dígitos
 */
function normalizarDocumento(doc) {
  if (!doc) return '';
  return doc.replace(/\D/g, '');
}

/**
 * Valida CPF brasileiro
 * @param {string} cpf - CPF com ou sem máscara
 * @returns {boolean} - true se válido
 */
function validarCPF(cpf) {
  const cleaned = normalizarDocumento(cpf);
  
  // CPF deve ter exatamente 11 dígitos
  if (cleaned.length !== 11) return false;
  
  // Rejeita CPFs com todos os dígitos iguais
  if (/^(\d)\1{10}$/.test(cleaned)) return false;
  
  // Valida primeiro dígito verificador
  let soma = 0;
  for (let i = 0; i < 9; i++) {
    soma += parseInt(cleaned[i]) * (10 - i);
  }
  let digito1 = 11 - (soma % 11);
  if (digito1 > 9) digito1 = 0;
  if (parseInt(cleaned[9]) !== digito1) return false;
  
  // Valida segundo dígito verificador
  soma = 0;
  for (let i = 0; i < 10; i++) {
    soma += parseInt(cleaned[i]) * (11 - i);
  }
  let digito2 = 11 - (soma % 11);
  if (digito2 > 9) digito2 = 0;
  if (parseInt(cleaned[10]) !== digito2) return false;
  
  return true;
}

/**
 * Valida CNPJ brasileiro
 * @param {string} cnpj - CNPJ com ou sem máscara
 * @returns {boolean} - true se válido
 */
function validarCNPJ(cnpj) {
  const cleaned = normalizarDocumento(cnpj);
  
  // CNPJ deve ter exatamente 14 dígitos
  if (cleaned.length !== 14) return false;
  
  // Rejeita CNPJs com todos os dígitos iguais
  if (/^(\d)\1{13}$/.test(cleaned)) return false;
  
  // Valida primeiro dígito verificador
  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  let soma = 0;
  for (let i = 0; i < 12; i++) {
    soma += parseInt(cleaned[i]) * pesos1[i];
  }
  let digito1 = soma % 11;
  digito1 = digito1 < 2 ? 0 : 11 - digito1;
  if (parseInt(cleaned[12]) !== digito1) return false;
  
  // Valida segundo dígito verificador
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  soma = 0;
  for (let i = 0; i < 13; i++) {
    soma += parseInt(cleaned[i]) * pesos2[i];
  }
  let digito2 = soma % 11;
  digito2 = digito2 < 2 ? 0 : 11 - digito2;
  if (parseInt(cleaned[13]) !== digito2) return false;
  
  return true;
}

/**
 * Valida documento CPF ou CNPJ automaticamente
 * @param {string} doc - Documento a validar
 * @param {string} type - 'CPF' ou 'CNPJ' (opcional, detecta automaticamente)
 * @returns {object} - {valid: boolean, type: 'CPF'|'CNPJ', normalized: string}
 */
function validarDocumento(doc, type = null) {
  const normalized = normalizarDocumento(doc);
  
  // Se o tipo foi especificado, valida apenas aquele tipo
  if (type === 'CPF') {
    return {
      valid: validarCPF(normalized),
      type: 'CPF',
      normalized
    };
  }
  
  if (type === 'CNPJ') {
    return {
      valid: validarCNPJ(normalized),
      type: 'CNPJ',
      normalized
    };
  }
  
  // Detecta automaticamente pelo tamanho
  if (normalized.length === 11) {
    return {
      valid: validarCPF(normalized),
      type: 'CPF',
      normalized
    };
  }
  
  if (normalized.length === 14) {
    return {
      valid: validarCNPJ(normalized),
      type: 'CNPJ',
      normalized
    };
  }
  
  return {
    valid: false,
    type: null,
    normalized
  };
}

/**
 * Formata CPF para exibição: 000.000.000-00
 * @param {string} cpf - CPF sem máscara
 * @returns {string} - CPF formatado
 */
function formatarCPF(cpf) {
  const cleaned = normalizarDocumento(cpf);
  if (cleaned.length !== 11) return cpf;
  return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
}

/**
 * Formata CNPJ para exibição: 00.000.000/0000-00
 * @param {string} cnpj - CNPJ sem máscara
 * @returns {string} - CNPJ formatado
 */
function formatarCNPJ(cnpj) {
  const cleaned = normalizarDocumento(cnpj);
  if (cleaned.length !== 14) return cnpj;
  return cleaned.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
}

/**
 * Formata documento automaticamente
 * @param {string} doc - Documento a formatar
 * @returns {string} - Documento formatado
 */
function formatarDocumento(doc) {
  const normalized = normalizarDocumento(doc);
  if (normalized.length === 11) return formatarCPF(normalized);
  if (normalized.length === 14) return formatarCNPJ(normalized);
  return doc;
}

module.exports = {
  normalizarDocumento,
  validarCPF,
  validarCNPJ,
  validarDocumento,
  formatarCPF,
  formatarCNPJ,
  formatarDocumento
};
