const OpenAI = require('openai');
const { openaiApiKey } = require('../config');
const db = require('../config/database');
const openRouterService = require('./openRouterService');

// Cache simples de clientes OpenAI por token para evitar recriar em cada chamada
const openaiClientsByToken = new Map();

async function getOpenAIClientForCompany(companyId) {
  let token = null;

  // 1) Tenta buscar API Key específica do tenant (provider = 'OPENAI')
  if (companyId) {
    try {
      const r = await db.query(
        `SELECT token
           FROM api_keys
          WHERE company_id = $1
            AND provider = 'OPENAI'
            AND is_active = true
          ORDER BY created_at DESC
          LIMIT 1`,
        [companyId]
      );
      if (r.rows[0]?.token) {
        token = r.rows[0].token;
      }
    } catch (e) {
      // Falha em buscar do banco não deve quebrar o fluxo; cai para fallback .env
      // eslint-disable-next-line no-console
      console.error('❌ Erro ao buscar OPENAI_API_KEY em api_keys:', e.message);
    }
  }

  // 2) Fallback: usa variável de ambiente global (caso não haja registro por empresa)
  if (!token) {
    token = openaiApiKey || null;
  }

  if (!token) return null;

  if (openaiClientsByToken.has(token)) {
    return openaiClientsByToken.get(token);
  }
  const client = new OpenAI({ apiKey: token });
  openaiClientsByToken.set(token, client);
  return client;
}

/**
 * Analisa o texto de um currículo com contexto opcional da vaga.
 *
 * Segundo parâmetro (vagaCtx) pode ser:
 *  - um objeto com { titulo, descricao, requisitos, ... }
 *  - ou qualquer outro valor legacy (ex.: apenas vagaId), que será ignorado
 */
async function gerarAnaliseCurriculo(texto, vagaCtx, opts = {}) {
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

  const client = await getOpenAIClientForCompany(opts.companyId);

  // Fallback automático para OpenRouter se OpenAI não estiver disponível
  if (!client && process.env.OPENROUTER_API_KEY) {
    console.log('⚠️  OpenAI não configurada. Usando OpenRouter como fallback...');
    try {
      const resultadoOpenRouter = await openRouterService.analisarCurriculo(texto, {
        titulo: vagaTitulo,
        descricao: vagaDescricao,
        requisitos: vagaRequisitos
      });
      
      // Adapta formato do OpenRouter para o formato esperado pelo frontend
      return {
        summary: resultadoOpenRouter.experiencia || 'Análise realizada com sucesso',
        skills: resultadoOpenRouter.skills || [],
        keywords: resultadoOpenRouter.skills || [],
        experiences: resultadoOpenRouter.experiencia ? [resultadoOpenRouter.experiencia] : [],
        matchingScore: resultadoOpenRouter.aderenciaVaga || 0,
        recomendacao: _determinarRecomendacao(resultadoOpenRouter.aderenciaVaga || 0),
        pontosFortes: resultadoOpenRouter.pontosFortesVaga || [],
        pontosAtencao: resultadoOpenRouter.pontosFracosVaga || [],
        aderenciaRequisitos: _gerarAderenciaRequisitos(vagaRequisitos, resultadoOpenRouter),
        candidato: resultadoOpenRouter.candidato || null,
        experiencias: Array.isArray(resultadoOpenRouter.experiencias)
          ? resultadoOpenRouter.experiencias
          : [],
        provider: 'OPENROUTER',
      };
    } catch (openRouterError) {
      console.error('❌ Erro ao usar OpenRouter:', openRouterError.message);
      return {
        summary: 'Análise de IA indisponível no momento.',
        skills: [],
        keywords: [],
        experiences: [],
        matchingScore: 0,
        recomendacao: 'Análise indisponível',
        pontosFortes: [],
        pontosAtencao: [],
        aderenciaRequisitos: [],
        candidato: null,
        experiencias: [],
        provider: 'OPENROUTER',
        error: 'AI_UNAVAILABLE',
      };
    }
  }

  // Fallback final quando nem OpenAI nem Groq estão configurados
  if (!client) {
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
      candidato: null,
      experiencias: [],
      provider: 'OPENAI',
      error: 'OPENAI_UNAVAILABLE',
    };
  }

  const prompt = `
Você é o motor de análise de currículos do sistema TalentMatchIA (frontend em Flutter, backend em Node.js e banco PostgreSQL).
Analise o currículo e a vaga abaixo e responda APENAS com um JSON válido, sem comentários e sem texto extra fora do JSON.

O formato exato do JSON deve ser:
{
  "summary": string,
  "skills": string[],
  "keywords": string[],
  "experiences": string[],

  "candidato": {
    "nome": string | null,
    "email": string | null,
    "telefone": string | null,
    "github": string | null,
    "linkedin": string | null
  },

  "experiencias": [
    {
      "cargo": string | null,
      "empresa": string | null,
      "periodo": string | null,
      "descricao": string | null
    }
  ],

  "matchingScore": number,
  "recomendacao": string,
  "pontosFortes": string[],
  "pontosAtencao": string[],
  "aderenciaRequisitos": [
    {
      "requisito": string,
      "score": number,
      "evidencias": string[]
    }
  ]
}

Regras de preenchimento:
1) "summary": resumo em 3–5 frases do perfil, focando na vaga.
2) "skills" e "keywords": habilidades técnicas/comportamentais e palavras-chave em português quando possível.
3) "candidato": preencha nome/email/telefone/github/linkedin se existirem; caso contrário, use null.
   - Se só houver usuário do GitHub, monte a URL: https://github.com/USUARIO
4) "experiencias": lista estruturada de experiências; copie o período exatamente como está no currículo (ex.: "2009 ~ 2011" ou "jan/2020 - atual").
5) "experiences": lista de frases curtas resumindo pontos principais (pode reaproveitar descrições).
6) "matchingScore": 0 a 100 considerando aderência à vaga.
7) "recomendacao": use exatamente um destes valores: "Forte Recomendação" | "Recomendado" | "Considerar" | "Não Recomendado".
8) "pontosFortes"/"pontosAtencao": liste pontos fortes e lacunas/alertas.
9) "aderenciaRequisitos": um objeto por requisito da vaga com score 0..100 e evidências citando o currículo (ou justificando ausência).
10) Dados ausentes: use null ou [] e NÃO invente empresas, datas, tecnologias ou links.

Retorne APENAS o JSON, sem markdown, sem explicações adicionais.

Currículo (texto livre):
${String(texto || '').slice(0, 8000)}

Vaga selecionada:
Título: ${vagaTitulo}
Descrição: ${vagaDescricao}
Requisitos: ${vagaRequisitos}
`.trim();

  try {
    const resp = await client.chat.completions.create({
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
        candidato: parsed.candidato || null,
        experiencias: Array.isArray(parsed.experiencias)
          ? parsed.experiencias
          : [],
        provider: 'OPENAI',
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
        candidato: null,
        experiencias: [],
        provider: 'OPENAI',
        error: 'INVALID_JSON_FROM_OPENAI',
      };
    }
  } catch (e) {
    console.error('❌ Erro ao chamar OpenAI para análise de currículo:', e.message);
    
    // Tenta OpenRouter como fallback automático
    if (process.env.OPENROUTER_API_KEY && (e.message.includes('429') || e.message.includes('quota') || e.message.includes('401'))) {
      console.log('⚠️  OpenAI com erro. Tentando OpenRouter...');
      try {
        const resultadoOpenRouter = await openRouterService.analisarCurriculo(texto, {
          titulo: vagaTitulo,
          descricao: vagaDescricao,
          requisitos: vagaRequisitos
        });
        
        // Adapta formato do OpenRouter para o formato esperado pelo frontend
        return {
          summary: resultadoOpenRouter.experiencia || 'Análise realizada com sucesso',
          skills: resultadoOpenRouter.skills || [],
          keywords: resultadoOpenRouter.skills || [],
          experiences: resultadoOpenRouter.experiencia ? [resultadoOpenRouter.experiencia] : [],
          matchingScore: resultadoOpenRouter.aderenciaVaga || 0,
          recomendacao: _determinarRecomendacao(resultadoOpenRouter.aderenciaVaga || 0),
          pontosFortes: resultadoOpenRouter.pontosFortesVaga || [],
          pontosAtencao: resultadoOpenRouter.pontosFracosVaga || [],
          aderenciaRequisitos: _gerarAderenciaRequisitos(vagaRequisitos, resultadoOpenRouter),
          candidato: resultadoOpenRouter.candidato || null,
          experiencias: Array.isArray(resultadoOpenRouter.experiencias)
            ? resultadoOpenRouter.experiencias
            : [],
          provider: 'OPENROUTER',
        };
      } catch (openRouterError) {
        console.error('❌ Erro ao usar OpenRouter como fallback:', openRouterError.message);
      }
    }
    
    // Fallback seguro quando todas as APIs falharem
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
      candidato: null,
      experiencias: [],
      provider: 'OPENAI',
      error: 'OPENAI_UNAVAILABLE',
    };
  }
}

async function gerarPerguntasEntrevista({ resumo, skills = [], vaga = '', quantidade = 8 }) {
  const client = await getOpenAIClientForCompany((arguments[0] && arguments[0].companyId) || null);
  if (!client) return ['OPENAI não configurado'];
  const prompt = `Gere ${quantidade} perguntas (técnicas e comportamentais) em português, como JSON array de strings. Resumo:${resumo}\nSkills:${skills.join(
    ', ',
  )}\nVaga:${vaga}`;
  const resp = await client.chat.completions.create({
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
  companyId = null,
}) {
  const client = await getOpenAIClientForCompany(companyId);

  if (!client) {
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

  const resp = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: msgs,
    temperature: 0.3,
  });
  const content = resp.choices?.[0]?.message?.content || '';
  return content.trim();
}

async function avaliarResposta({ pergunta, resposta, companyId = null }) {
  const client = await getOpenAIClientForCompany(companyId);

  if (!client) {
    // fallback simples sem IA
    return {
      score: 70,
      verdict: 'ADEQUADO',
      rationale_text: 'Sem IA configurada: avaliação padrão. Resposta coerente em termos gerais.',
      suggested_followups: ['Peça exemplos práticos com métricas', 'Investigue experiência recente']
    };
  }
  const prompt = `Avalie a resposta do candidato à pergunta da entrevista. Retorne um JSON com campos: score (0..100), verdict em ['FORTE','ADEQUADO','FRACO','INCONSISTENTE'], rationale_text (string), suggested_followups (array de strings).\nPergunta: ${pergunta}\nResposta: ${resposta}`;
  const resp = await client.chat.completions.create({
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

async function gerarRelatorioEntrevista({ candidato, vaga, respostas = [], feedbacks = [], companyId = null }) {
  // Fusão simples: sumariza com base nos feedbacks
  const client = await getOpenAIClientForCompany(companyId);

  if (!client) {
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
  const resp = await client.chat.completions.create({
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

// Funções auxiliares para adaptar resposta do OpenRouter
function _determinarRecomendacao(score) {
  if (score >= 90) return 'Forte Recomendação';
  if (score >= 75) return 'Recomendado';
  if (score >= 60) return 'Considerar';
  return 'Não Recomendado';
}

function _gerarAderenciaRequisitos(requisitosTexto, resultadoOpenRouter) {
  if (!requisitosTexto) return [];
  
  // Normaliza requisitos para array
  let requisitosLista = [];
  if (Array.isArray(requisitosTexto)) {
    requisitosLista = requisitosTexto.map(r => String(r).trim()).filter(r => r.length > 0);
  } else if (typeof requisitosTexto === 'string') {
    // Divide requisitos por vírgula ou quebra de linha
    requisitosLista = requisitosTexto
      .split(/[,\n]/)
      .map(r => r.trim())
      .filter(r => r.length > 0);
  } else {
    return [];
  }
  
  const skills = resultadoOpenRouter.skills || [];
  const pontosFortesVaga = resultadoOpenRouter.pontosFortesVaga || [];
  const aderenciaVaga = resultadoOpenRouter.aderenciaVaga || 0;
  
  return requisitosLista.map(requisito => {
    // Calcula score baseado em se o requisito está nas skills ou pontos fortes
    const encontradoEmSkills = skills.some(skill => 
      skill.toLowerCase().includes(requisito.toLowerCase()) ||
      requisito.toLowerCase().includes(skill.toLowerCase())
    );
    
    const encontradoEmPontoFortes = pontosFortesVaga.some(ponto =>
      ponto.toLowerCase().includes(requisito.toLowerCase())
    );
    
    let score = aderenciaVaga;
    if (encontradoEmSkills && encontradoEmPontoFortes) {
      score = Math.min(100, aderenciaVaga + 10);
    } else if (encontradoEmSkills) {
      score = aderenciaVaga;
    } else if (encontradoEmPontoFortes) {
      score = Math.max(70, aderenciaVaga - 10);
    } else {
      score = Math.max(0, aderenciaVaga - 30);
    }
    
    // Gera evidências
    const evidencias = [];
    if (encontradoEmSkills) {
      const skillsRelacionadas = skills.filter(skill =>
        skill.toLowerCase().includes(requisito.toLowerCase()) ||
        requisito.toLowerCase().includes(skill.toLowerCase())
      );
      evidencias.push(...skillsRelacionadas.map(s => `Habilidade: ${s}`));
    }
    
    if (encontradoEmPontoFortes) {
      const pontosRelacionados = pontosFortesVaga.filter(ponto =>
        ponto.toLowerCase().includes(requisito.toLowerCase())
      );
      if (pontosRelacionados.length > 0) {
        evidencias.push(pontosRelacionados[0]);
      }
    }
    
    if (evidencias.length === 0) {
      evidencias.push('Não foram encontradas evidências claras deste requisito');
    }
    
    return {
      requisito,
      score,
      evidencias
    };
  });
}

module.exports = {
  gerarAnaliseCurriculo,
  gerarPerguntasEntrevista,
  responderChatEntrevista,
  avaliarResposta,
  gerarRelatorioEntrevista,
};
