const OpenAI = require('openai');
const { openaiApiKey } = require('../config');

const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

/**
 * Analisa o texto de um currículo com contexto opcional da vaga.
 *
 * Segundo parâmetro (vagaCtx) pode ser:
 *  - um objeto com { titulo, descricao, requisitos, ... }
 *  - ou qualquer outro valor legacy (ex.: apenas vagaId), que será ignorado
 */
async function gerarAnaliseCurriculo(texto, vagaCtx) {
  // Normaliza contexto da vaga recebido do caller (curriculos.js)
  let vagaTitulo = '';
  let vagaDescricao = '';
  let vagaRequisitos = '';

  if (vagaCtx && typeof vagaCtx === 'object') {
    vagaTitulo =
      vagaCtx.titulo ||
      vagaCtx.title ||
      vagaCtx.vagaTitulo ||
      '';
    vagaDescricao =
      vagaCtx.descricao ||
      vagaCtx.description ||
      vagaCtx.vagaDescricao ||
      '';
    vagaRequisitos =
      vagaCtx.requisitos ||
      vagaCtx.requirements ||
      vagaCtx.vagaRequisitos ||
      '';
  }

  // Fallback seguro quando a API não está configurada
  if (!openai) {
    return {
      summary: 'OPENAI não configurado. Análise automática indisponível.',
      skills: [],
      keywords: [],
      experiences: [],
      matchingScore: 0,
      recomendacao: 'Análise indisponível',
      pontosFortes: [],
      pontosAtencao: [],
      aderenciaRequisitos: [],
      error: 'OPENAI_UNAVAILABLE',
    };
  }

  const prompt = `
Analise o currículo e a vaga abaixo e responda APENAS com um JSON válido no seguinte formato:
{
  "summary": string,
  "skills": string[],
  "keywords": string[],
  "experiences": string[],
  "matchingScore": number,        // 0 a 100
  "recomendacao": string,        // "Forte Recomendação", "Recomendado", "Considerar" ou "Não Recomendado"
  "pontosFortes": string[],
  "pontosAtencao": string[],
  "aderenciaRequisitos": [
    {
      "requisito": string,
      "score": number,           // 0 a 100
      "evidencias": string[]
    }
  ]
}

Currículo (texto livre):
${String(texto || '').slice(0, 8000)}

Vaga selecionada:
Título: ${vagaTitulo}
Descrição: ${vagaDescricao}
Requisitos: ${vagaRequisitos}
`.trim();

  try {
    const resp = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content:
            'Você é um especialista em análise de currículos para recrutamento técnico. Responda sempre com JSON válido.',
        },
        { role: 'user', content: prompt },
      ],
      temperature: 0.2,
    });
    const content = resp.choices?.[0]?.message?.content || '{}';

    try {
      const parsed = JSON.parse(content);
      // Garante campos mínimos esperados pelo restante do backend/frontend
      return {
        summary: parsed.summary || '',
        skills: Array.isArray(parsed.skills) ? parsed.skills : [],
        keywords: Array.isArray(parsed.keywords) ? parsed.keywords : [],
        experiences: Array.isArray(parsed.experiences) ? parsed.experiences : [],
        matchingScore: Number.isFinite(parsed.matchingScore)
          ? parsed.matchingScore
          : 0,
        recomendacao: parsed.recomendacao || '',
        pontosFortes: Array.isArray(parsed.pontosFortes)
          ? parsed.pontosFortes
          : [],
        pontosAtencao: Array.isArray(parsed.pontosAtencao)
          ? parsed.pontosAtencao
          : [],
        aderenciaRequisitos: Array.isArray(parsed.aderenciaRequisitos)
          ? parsed.aderenciaRequisitos
          : [],
      };
    } catch (_) {
      // Se o modelo não retornar JSON válido, usamos o conteúdo bruto como summary
      return {
        summary: content,
        skills: [],
        keywords: [],
        experiences: [],
        matchingScore: 0,
        recomendacao: '',
        pontosFortes: [],
        pontosAtencao: [],
        aderenciaRequisitos: [],
        error: 'INVALID_JSON_FROM_OPENAI',
      };
    }
  } catch (e) {
    console.error('❌ Erro ao chamar OpenAI para análise de currículo:', e.message);
    // Fallback seguro quando a API de IA estiver sem crédito/quota ou indisponível
    return {
      summary:
        'Análise automática indisponível no momento (limite de uso da API de IA ou erro de conexão).',
      skills: [],
      keywords: [],
      experiences: [],
      matchingScore: 0,
      recomendacao: 'Análise indisponível',
      pontosFortes: [],
      pontosAtencao: [],
      aderenciaRequisitos: [],
      error: 'OPENAI_UNAVAILABLE',
    };
  }
}

async function gerarPerguntasEntrevista({ resumo, skills = [], vaga = '', quantidade = 8 }) {
  if (!openai) return ['OPENAI não configurado'];
  const prompt = `Gere ${quantidade} perguntas (técnicas e comportamentais) em português, como JSON array de strings. Resumo:${resumo}\nSkills:${skills.join(
    ', ',
  )}\nVaga:${vaga}`;
  const resp = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Você é um entrevistador técnico sênior.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.3,
  });
  const content = resp.choices?.[0]?.message?.content || '[]';
  try {
    const arr = JSON.parse(content);
    return Array.isArray(arr) ? arr : [String(content)];
  } catch {
    return [content];
  }
}

// Chat da entrevista: gera resposta baseada no histórico e no contexto
async function responderChatEntrevista({
  historico = [],
  mensagemAtual = '',
  analise = {},
  vagaDesc = '',
  textoCurriculo = '',
}) {
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

  const contexto = `Resumo: ${(analise.summary || '').slice(
    0,
    800,
  )}\nSkills: ${(analise.skills || []).join(', ')}\nKeywords: ${(analise.keywords || []).join(
    ', ',
  )}\nVaga: ${String(vagaDesc || '').slice(0, 1000)}\n`;
  const extra = textoCurriculo
    ? `Trechos do currículo:\n${String(textoCurriculo).slice(0, 1500)}`
    : '';

  const msgs = [
    { role: 'system', content: system },
    { role: 'system', content: contexto + extra },
    ...historico.map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: String(m.conteudo || ''),
    })),
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

async function avaliarResposta({ pergunta, resposta }) {
  if (!openai) {
    // fallback simples sem IA
    return {
      score: 70,
      verdict: 'ADEQUADO',
      rationale_text: 'Sem IA configurada: avaliação padrão. Resposta coerente em termos gerais.',
      suggested_followups: ['Peça exemplos práticos com métricas', 'Investigue experiência recente']
    };
  }
  const prompt = `Avalie a resposta do candidato à pergunta da entrevista. Retorne um JSON com campos: score (0..100), verdict em ['FORTE','ADEQUADO','FRACO','INCONSISTENTE'], rationale_text (string), suggested_followups (array de strings).\nPergunta: ${pergunta}\nResposta: ${resposta}`;
  const resp = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Você é um avaliador técnico. Responda apenas JSON válido.'},
      { role: 'user', content: prompt }
    ],
    temperature: 0.2,
  });
  const content = resp.choices?.[0]?.message?.content || '{}';
  try { return JSON.parse(content); } catch { return { score: 60, verdict: 'ADEQUADO', rationale_text: content, suggested_followups: [] }; }
}

async function gerarRelatorioEntrevista({ candidato, vaga, respostas = [], feedbacks = [] }) {
  // Fusão simples: sumariza com base nos feedbacks
  if (!openai) {
    const strengths = feedbacks.filter(f => (f.verdict || '').toUpperCase() === 'FORTE').map(f => f.topic || 'Ponto forte');
    const risks = feedbacks.filter(f => (f.verdict || '').toUpperCase() === 'FRACO' || (f.verdict || '').toUpperCase() === 'INCONSISTENTE').map(f => f.topic || 'Risco');
    const score = Math.round((feedbacks.reduce((a, b) => a + (Number(b.score)||60), 0) / Math.max(1, feedbacks.length)));
    const recommendation = score >= 80 ? 'APROVAR' : (score >= 65 ? 'DÚVIDA' : 'REPROVAR');
    return {
      summary_text: `Resumo automático (sem IA): candidato ${candidato} para a vaga ${vaga}.`,
      strengths,
      risks,
      recommendation,
    };
  }
  const prompt = `Com base nas respostas e feedbacks abaixo, gere um relatório de entrevista em JSON com campos: summary_text (string), strengths (array de strings), risks (array de strings), recommendation em ['APROVAR','DÚVIDA','REPROVAR'].\nRespostas: ${JSON.stringify(respostas).slice(0, 6000)}\nFeedbacks: ${JSON.stringify(feedbacks).slice(0, 6000)}`;
  const resp = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Você é um tech lead avaliando entrevistas. Responda apenas JSON válido.'},
      { role: 'user', content: prompt }
    ],
    temperature: 0.2,
  });
  const content = resp.choices?.[0]?.message?.content || '{}';
  try {
    return JSON.parse(content);
  } catch {
    return {
      summary_text: content,
      strengths: [],
      risks: [],
      recommendation: 'DÚVIDA',
    };
  }
}

module.exports = {
  gerarAnaliseCurriculo,
  gerarPerguntasEntrevista,
  responderChatEntrevista,
  avaliarResposta,
  gerarRelatorioEntrevista,
};
