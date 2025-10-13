const OpenAI = require('openai');
const { openaiApiKey } = require('../config');

const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

async function gerarAnaliseCurriculo(texto, vagaId) {
  if (!openai) {
    return { summary: 'OPENAI não configurado', skills: [], keywords: [], experiences: [] };
  }
  const prompt = `Analise o currículo abaixo e retorne JSON com summary, skills[], keywords[] e experiences[]. Currículo:\n${texto.slice(0, 8000)}`;
  const resp = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Você é um especialista em análise de currículos. Responda apenas JSON válido.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.2,
  });
  const content = resp.choices?.[0]?.message?.content || '{}';
  try { return JSON.parse(content); } catch { return { summary: content, skills: [], keywords: [], experiences: [] }; }
}

async function gerarPerguntasEntrevista({ resumo, skills = [], vaga = '', quantidade = 8 }) {
  if (!openai) return ['OPENAI não configurado'];
  const prompt = `Gere ${quantidade} perguntas (técnicas e comportamentais) em português, como JSON array de strings. Resumo:${resumo}\nSkills:${skills.join(', ')}\nVaga:${vaga}`;
  const resp = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Você é um entrevistador técnico sênior.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.3,
  });
  const content = resp.choices?.[0]?.message?.content || '[]';
  try { const arr = JSON.parse(content); return Array.isArray(arr) ? arr : [String(content)]; } catch { return [content]; }
}

module.exports = { gerarAnaliseCurriculo, gerarPerguntasEntrevista };

