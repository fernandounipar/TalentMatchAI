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

// Chat da entrevista: gera resposta baseada no histórico e no contexto
async function responderChatEntrevista({ historico = [], mensagemAtual = '', analise = {}, vagaDesc = '', textoCurriculo = '' }) {
  if (!openai) {
    // fallback simples
    return 'OPENAI não configurado. (Resposta mock) Sugestão: aprofunde pedindo exemplos específicos e resultados mensuráveis.';
  }

  const system = [
    'Você é um assistente de entrevistas técnicas que ajuda o recrutador.',
    'Responda em português, de forma objetiva e prática.',
    'Use o contexto do currículo e da vaga quando relevante.',
    'Evite respostas longas; proponha follow-ups quando fizer sentido.',
  ].join(' ');

  const contexto = `Resumo: ${(analise.summary || '').slice(0, 800)}\nSkills: ${(analise.skills || []).join(', ')}\nKeywords: ${(analise.keywords || []).join(', ')}\nVaga: ${String(vagaDesc || '').slice(0, 1000)}\n`;
  const extra = textoCurriculo ? `Trechos do currículo:\n${String(textoCurriculo).slice(0, 1500)}` : '';

  const msgs = [
    { role: 'system', content: system },
    { role: 'system', content: contexto + extra },
    ...historico.map((m) => ({ role: m.role === 'assistant' ? 'assistant' : 'user', content: String(m.conteudo || '') })),
    { role: 'user', content: String(mensagemAtual) },
  ];

  const resp = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: msgs,
    temperature: 0.3,
  });
  const content = resp.choices?.[0]?.message?.content || '';
  return content.trim();
}

module.exports = { gerarAnaliseCurriculo, gerarPerguntasEntrevista, responderChatEntrevista };
