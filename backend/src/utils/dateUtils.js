/**
 * Utilitario para manipulacao de datas no fuso horario de Brasilia (America/Sao_Paulo)
 * UTC-3 (horario padrao) ou UTC-2 (horario de verao - atualmente nao usado no Brasil)
 */

const BRASILIA_OFFSET = -3; // UTC-3

/**
 * Retorna a data/hora atual no fuso horario de Brasilia
 * @returns {Date} Data atual em Brasilia
 */
function agora() {
  const now = new Date();
  const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
  return new Date(utc + (3600000 * BRASILIA_OFFSET));
}

/**
 * Retorna a data/hora atual como string ISO no fuso de Brasilia
 * @returns {string} String ISO com offset de Brasilia
 */
function agoraISO() {
  const brasilia = agora();
  return formatarParaISO(brasilia);
}

/**
 * Converte uma data UTC para o fuso de Brasilia
 * @param {Date|string} date - Data em UTC
 * @returns {Date} Data convertida para Brasilia
 */
function paraHorarioBrasilia(date) {
  if (!date) return null;
  const d = typeof date === 'string' ? new Date(date) : date;
  if (isNaN(d.getTime())) return null;
  
  const utc = d.getTime() + (d.getTimezoneOffset() * 60000);
  return new Date(utc + (3600000 * BRASILIA_OFFSET));
}

/**
 * Converte uma data de Brasilia para UTC
 * @param {Date|string} date - Data em horario de Brasilia
 * @returns {Date} Data convertida para UTC
 */
function paraUTC(date) {
  if (!date) return null;
  const d = typeof date === 'string' ? new Date(date) : date;
  if (isNaN(d.getTime())) return null;
  
  return new Date(d.getTime() - (3600000 * BRASILIA_OFFSET));
}

/**
 * Formata uma data para string ISO com offset de Brasilia (-03:00)
 * @param {Date} date - Data a formatar
 * @returns {string} String ISO com offset
 */
function formatarParaISO(date) {
  if (!date || isNaN(date.getTime())) return null;
  
  const ano = date.getFullYear();
  const mes = String(date.getMonth() + 1).padStart(2, '0');
  const dia = String(date.getDate()).padStart(2, '0');
  const hora = String(date.getHours()).padStart(2, '0');
  const minuto = String(date.getMinutes()).padStart(2, '0');
  const segundo = String(date.getSeconds()).padStart(2, '0');
  const ms = String(date.getMilliseconds()).padStart(3, '0');
  
  return `${ano}-${mes}-${dia}T${hora}:${minuto}:${segundo}.${ms}-03:00`;
}

/**
 * Formata uma data para exibicao no formato brasileiro
 * @param {Date|string} date - Data a formatar
 * @param {boolean} incluirHora - Se deve incluir a hora
 * @returns {string} Data formatada (ex: "30/11/2025 14:30")
 */
function formatarParaExibicao(date, incluirHora = true) {
  const d = paraHorarioBrasilia(date);
  if (!d) return '';
  
  const dia = String(d.getDate()).padStart(2, '0');
  const mes = String(d.getMonth() + 1).padStart(2, '0');
  const ano = d.getFullYear();
  
  if (!incluirHora) {
    return `${dia}/${mes}/${ano}`;
  }
  
  const hora = String(d.getHours()).padStart(2, '0');
  const minuto = String(d.getMinutes()).padStart(2, '0');
  
  return `${dia}/${mes}/${ano} ${hora}:${minuto}`;
}

/**
 * Retorna o inicio do dia atual em Brasilia (00:00:00)
 * @returns {Date}
 */
function inicioDoDia() {
  const hoje = agora();
  hoje.setHours(0, 0, 0, 0);
  return hoje;
}

/**
 * Retorna o fim do dia atual em Brasilia (23:59:59.999)
 * @returns {Date}
 */
function fimDoDia() {
  const hoje = agora();
  hoje.setHours(23, 59, 59, 999);
  return hoje;
}

/**
 * Calcula expiracao adicionando dias a partir de agora (em Brasilia)
 * @param {number} dias - Numero de dias a adicionar
 * @returns {Date}
 */
function expiracaoEmDias(dias) {
  const data = agora();
  data.setDate(data.getDate() + dias);
  return data;
}

/**
 * Calcula expiracao adicionando horas a partir de agora (em Brasilia)
 * @param {number} horas - Numero de horas a adicionar
 * @returns {Date}
 */
function expiracaoEmHoras(horas) {
  const data = agora();
  data.setHours(data.getHours() + horas);
  return data;
}

/**
 * Verifica se uma data ja expirou (comparando com agora em Brasilia)
 * @param {Date|string} dataExpiracao - Data de expiracao
 * @returns {boolean}
 */
function jaExpirou(dataExpiracao) {
  if (!dataExpiracao) return true;
  const expiracao = typeof dataExpiracao === 'string' ? new Date(dataExpiracao) : dataExpiracao;
  return agora() > expiracao;
}

module.exports = {
  BRASILIA_OFFSET,
  agora,
  agoraISO,
  paraHorarioBrasilia,
  paraUTC,
  formatarParaISO,
  formatarParaExibicao,
  inicioDoDia,
  fimDoDia,
  expiracaoEmDias,
  expiracaoEmHoras,
  jaExpirou
};
