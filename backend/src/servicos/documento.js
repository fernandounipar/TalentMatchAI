function somenteDigitos(str = '') {
  return String(str).replace(/\D+/g, '');
}

function validaCPF(cpf) {
  const s = somenteDigitos(cpf);
  if (!s || s.length !== 11) return false;
  if (/^(\d)\1{10}$/.test(s)) return false; // todos iguais

  let soma = 0;
  for (let i = 0; i < 9; i++) soma += parseInt(s.charAt(i)) * (10 - i);
  let resto = (soma * 10) % 11;
  if (resto === 10) resto = 0;
  if (resto !== parseInt(s.charAt(9))) return false;

  soma = 0;
  for (let i = 0; i < 10; i++) soma += parseInt(s.charAt(i)) * (11 - i);
  resto = (soma * 10) % 11;
  if (resto === 10) resto = 0;
  return resto === parseInt(s.charAt(10));
}

function validaCNPJ(cnpj) {
  const s = somenteDigitos(cnpj);
  if (!s || s.length !== 14) return false;
  if (/^(\d)\1{13}$/.test(s)) return false; // todos iguais

  const calcDV = (base, pesoInicial) => {
    let soma = 0, peso = pesoInicial;
    for (let i = 0; i < base.length; i++) {
      soma += parseInt(base.charAt(i)) * peso--;
      if (peso < 2) peso = 9;
    }
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };

  const dv1 = calcDV(s.slice(0, 12), 5);
  if (dv1 !== parseInt(s.charAt(12))) return false;
  const dv2 = calcDV(s.slice(0, 13), 6);
  return dv2 === parseInt(s.charAt(13));
}

function normalizaDocumento(doc) {
  return somenteDigitos(doc);
}

function validaDocumento(tipo, documento) {
  const t = String(tipo || '').toUpperCase();
  const d = normalizaDocumento(documento);
  if (t === 'CPF') return validaCPF(d);
  if (t === 'CNPJ') return validaCNPJ(d);
  return false;
}

module.exports = {
  somenteDigitos,
  validaCPF,
  validaCNPJ,
  normalizaDocumento,
  validaDocumento,
};

