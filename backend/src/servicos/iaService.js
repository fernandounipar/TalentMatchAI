const OpenAI = require('openai');
const { openaiApiKey } = require('../config');
const db = require('../config/database');
const openRouterService = require('./openRouterService');

// Cache simples de clientes OpenAI por token
const openaiClientsByToken = new Map();

async function getOpenAIClientForCompany(companyId) {
  let token = null;

  // 1) Tenta buscar API Key específica do tenant (provider = 'OPENAI')
  if (companyId) {
    try {
      const r = await db.query(
        `SELECT token
           FROM chaves_api
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

      console.log('\n🔍 [DEBUG] JSON retornado pelo OpenRouter (fallback inicial):');
      console.log(JSON.stringify(resultadoOpenRouter, null, 2));

      // Adapta formato do OpenRouter para o formato esperado pelo frontend
      const openRouterModel = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast';
      const resultadoAdaptado = {
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
        educacao: Array.isArray(resultadoOpenRouter.educacao)
          ? resultadoOpenRouter.educacao
          : [],
        certificacoes: Array.isArray(resultadoOpenRouter.certificacoes)
          ? resultadoOpenRouter.certificacoes
          : [],
        provider: 'OPENROUTER',
        model: openRouterModel,
      };

      console.log('\n🔄 [DEBUG] JSON adaptado para o frontend (fallback inicial):');
      console.log(JSON.stringify(resultadoAdaptado, null, 2));
      console.log('\n');

      return resultadoAdaptado;
    } catch (openRouterError) {
      console.error('❌ Erro ao usar OpenRouter:', openRouterError.message);
      const openRouterModel = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast';
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
        educacao: [],
        certificacoes: [],
        provider: 'OPENROUTER',
        error: 'AI_UNAVAILABLE',
        model: openRouterModel,
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
      model: 'gpt-4o-mini',
    };
  }

  const prompt = `
Você é o motor de análise de currículos do sistema TalentMatchIA.
Analise o currículo e a vaga abaixo e responda APENAS com um JSON válido.

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

Regras CRÍTICAS de preenchimento:
1) "candidato": EXTRAIA COM MÁXIMA ATENÇÃO.
   - Nome: Geralmente na primeira linha ou em destaque.
   - Email: Procure por @.
   - Telefone: Procure por formatos (XX) XXXXX-XXXX ou +55...
   - Links: Extraia URLs completas de LinkedIn e GitHub. Se apenas o usuário for citado (ex: github.com/usuario), complete a URL.
2) "experiencias":
   - "periodo": COPIE EXATAMENTE como está no documento (ex: "Jan 2020 - Atual", "2019-2021"). NÃO converta para datas ISO. Se não houver data, use null.
   - Ordene da mais recente para a mais antiga.
3) "summary": Resumo profissional focado na aderência à vaga (3-5 linhas).
4) "matchingScore": 0 a 100 (seja rigoroso).
5) "recomendacao": "Forte Recomendação" | "Recomendado" | "Considerar" | "Não Recomendado".
6) Se algum dado não existir, use null. NÃO ALUCINE DADOS.

Currículo (texto extraído):
${String(texto || '').slice(0, 12000)}

Vaga Alvo:
Título: ${vagaTitulo}
Desc: ${vagaDescricao}
Reqs: ${vagaRequisitos}
`.trim();

  try {
    console.log('🔍 Tentando análise com OpenAI (gpt-4o-mini)...');
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
    console.log('✅ OpenAI respondeu com sucesso');

    try {
      const parsed = JSON.parse(content);

      console.log('\n🔍 [DEBUG] JSON retornado pela OpenAI:');
      console.log(JSON.stringify(parsed, null, 2));
      console.log('\n');

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
        model: 'gpt-4o-mini',
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
        model: 'gpt-4o-mini',
        error: 'INVALID_JSON_FROM_OPENAI',
      };
    }
  } catch (e) {
    const errorMsg = e.message || String(e);
    console.error('❌ Erro ao chamar OpenAI para análise de currículo:', errorMsg);
    console.error('Stack:', e.stack);

    // Tenta OpenRouter como fallback automático para qualquer erro da OpenAI
    if (process.env.OPENROUTER_API_KEY) {
      console.log('⚠️  OpenAI com erro. Tentando OpenRouter como fallback...');
      console.log('Erro OpenAI:', errorMsg);

      try {
        const resultadoOpenRouter = await openRouterService.analisarCurriculo(texto, {
          titulo: vagaTitulo,
          descricao: vagaDescricao,
          requisitos: vagaRequisitos
        });

        const openRouterModel = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast';
        console.log('✅ OpenRouter retornou com sucesso. Modelo:', openRouterModel);

        console.log('\n🔍 [DEBUG] JSON retornado pelo OpenRouter:');
        console.log(JSON.stringify(resultadoOpenRouter, null, 2));

        // Adapta formato do OpenRouter para o formato esperado pelo frontend
        const resultadoAdaptado = {
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
          educacao: Array.isArray(resultadoOpenRouter.educacao)
            ? resultadoOpenRouter.educacao
            : [],
          certificacoes: Array.isArray(resultadoOpenRouter.certificacoes)
            ? resultadoOpenRouter.certificacoes
            : [],
          provider: 'OPENROUTER',
          model: openRouterModel,
        };

        console.log('\n🔄 [DEBUG] JSON adaptado para o frontend:');
        console.log(JSON.stringify(resultadoAdaptado, null, 2));
        console.log('\n');

        return resultadoAdaptado;
      } catch (openRouterError) {
        console.error('❌ Erro ao usar OpenRouter como fallback:', openRouterError.message);
        console.error('Stack OpenRouter:', openRouterError.stack);
      }
    }

    // Fallback seguro quando todas as APIs falharem
    console.error('\n⚠️  TODAS AS APIs DE IA FALHARAM!');
    console.error('OpenAI: Chave inválida ou limite atingido');
    console.error('OpenRouter: Chave inválida ou sem créditos');
    console.error('\n💡 Para resolver:');
    console.error('   1. Verifique/atualize OPENAI_API_KEY em https://platform.openai.com/api-keys');
    console.error('   2. Ou gere OPENROUTER_API_KEY em https://openrouter.ai/keys');
    console.error('   3. Verifique se tem créditos em sua conta\n');

    return {
      summary:
        'Nenhuma API de IA configurada ou disponível. Configure OpenAI ou OpenRouter no arquivo .env',
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
      provider: 'NONE',
      error: 'ALL_AI_SERVICES_UNAVAILABLE',
      model: 'none',
      errorDetails: {
        openai: errorMsg,
        openrouter: 'Falha ao conectar'
      }
    };
  }
}

// Função auxiliar para mapear categoria da IA para o enum do banco
function mapCategoriaToBanco(categoria) {
  const map = {
    'técnica': 'TECNICA',
    'tecnica': 'TECNICA',
    'Técnica': 'TECNICA',
    'Tecnica': 'TECNICA',
    'TÉCNICA': 'TECNICA',
    'TECNICA': 'TECNICA',
    'comportamental': 'COMPORTAMENTAL',
    'Comportamental': 'COMPORTAMENTAL',
    'COMPORTAMENTAL': 'COMPORTAMENTAL',
    'situacional': 'SITUACIONAL',
    'Situacional': 'SITUACIONAL',
    'SITUACIONAL': 'SITUACIONAL',
    'cultural': 'COMPORTAMENTAL', // Cultural mapeia para comportamental
    'Cultural': 'COMPORTAMENTAL',
    'CULTURAL': 'COMPORTAMENTAL',
  };
  return map[categoria] || 'TECNICA'; // Default para TECNICA se não reconhecer
}

async function gerarPerguntasEntrevista({ resumo, skills = [], vaga = '', quantidade = 8 }) {
  const companyId = (arguments[0] && arguments[0].companyId) || null;
  const client = await getOpenAIClientForCompany(companyId);

  // Função interna para tentar OpenRouter
  const tryOpenRouter = async () => {
    if (process.env.OPENROUTER_API_KEY) {
      console.log('⚠️  OpenAI indisponível. Tentando OpenRouter para gerar perguntas...');
      try {
        const curriculoTexto = `Resumo: ${resumo}\nSkills: ${skills.join(', ')}`;
        const vagaObj = { description: vaga }; // Adapta para objeto como esperado pelo service

        // O service retorna array de objetos { texto, categoria, peso }
        // Retornamos objetos com texto e kind mapeado para o enum do banco
        const perguntasOpenRouter = await openRouterService.gerarPerguntasEntrevista(vagaObj, curriculoTexto);

        if (Array.isArray(perguntasOpenRouter)) {
          return perguntasOpenRouter.map(p => ({
            texto: p.texto || p,
            kind: mapCategoriaToBanco(p.categoria)
          }));
        }
        return [];
      } catch (orError) {
        console.error('❌ Erro no OpenRouter (perguntas):', orError.message);
        return [{ texto: 'Erro ao gerar perguntas via IA (OpenRouter falhou).', kind: 'TECNICA' }];
      }
    }
    return [{ texto: 'OPENAI não configurado e OpenRouter indisponível.', kind: 'TECNICA' }];
  };

  if (!client) {
    return await tryOpenRouter();
  }

  const prompt = `Gere ${quantidade} perguntas para entrevista em português, retornando um JSON array de objetos.
Cada objeto deve ter:
- "texto": a pergunta
- "categoria": "Técnica", "Comportamental" ou "Situacional"

Contexto:
Resumo: ${resumo}
Skills: ${skills.join(', ')}
Vaga: ${vaga}

Retorne APENAS o JSON array, sem texto adicional.`;

  try {
    const resp = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'Você é um entrevistador técnico sênior. Sempre retorne JSON válido.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.3,
    });
    const content = resp.choices?.[0]?.message?.content || '[]';
    try {
      let jsonText = content.trim();
      // Remove possíveis marcadores de código
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.replace(/```\n?/g, '');
      }
      const arr = JSON.parse(jsonText);
      if (Array.isArray(arr)) {
        return arr.map(item => {
          if (typeof item === 'string') {
            return { texto: item, kind: 'TECNICA' };
          }
          return {
            texto: item.texto || item.pergunta || String(item),
            kind: mapCategoriaToBanco(item.categoria)
          };
        });
      }
      return [{ texto: String(content), kind: 'TECNICA' }];
    } catch {
      return [{ texto: content, kind: 'TECNICA' }];
    }
  } catch (e) {
    console.error('❌ Erro na OpenAI (perguntas):', e.message);
    return await tryOpenRouter();
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

  // Função para tentar OpenRouter como fallback
  const tryOpenRouter = async () => {
    if (process.env.OPENROUTER_API_KEY) {
      console.log('⚠️  OpenAI indisponível. Tentando OpenRouter para chat...');
      try {
        const response = await openRouterService.chamarOpenRouter(msgs, { temperature: 0.3, max_tokens: 1000 });
        return response.content?.trim() || 'Resposta não disponível.';
      } catch (orError) {
        console.error('❌ Erro no OpenRouter (chat):', orError.message);
        return 'Desculpe, não foi possível processar sua mensagem no momento. Tente novamente.';
      }
    }
    return 'Serviço de IA temporariamente indisponível. Tente novamente em alguns instantes.';
  };

  const client = await getOpenAIClientForCompany(companyId);

  if (!client) {
    return await tryOpenRouter();
  }

  try {
    const resp = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: msgs,
      temperature: 0.3,
    });
    const content = resp.choices?.[0]?.message?.content || '';
    return content.trim();
  } catch (e) {
    console.error('❌ Erro na OpenAI (chat):', e.message);
    return await tryOpenRouter();
  }
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
      { role: 'system', content: 'Você é um avaliador técnico. Responda apenas JSON válido.' },
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

  const fallbackResult = () => {
    const strengths = feedbacks.filter(f => (f.verdict || '').toUpperCase() === 'FORTE').map(f => f.topic || 'Ponto forte');
    const risks = feedbacks.filter(f => (f.verdict || '').toUpperCase() === 'FRACO' || (f.verdict || '').toUpperCase() === 'INCONSISTENTE').map(f => f.topic || 'Risco');
    const score = Math.round((feedbacks.reduce((a, b) => a + (Number(b.score) || 60), 0) / Math.max(1, feedbacks.length)));
    // Usar valores em português
    const recommendation = score >= 80 ? 'APROVAR' : (score >= 65 ? 'DÚVIDA' : 'REPROVAR');
    
    // Gerar respostas em destaque a partir das respostas com melhor/pior score
    const respostasDestaque = respostas
      .filter(r => r.resposta && r.resposta.length > 10)
      .slice(0, 3)
      .map((r, i) => ({
        pergunta: r.pergunta || `Pergunta ${i + 1}`,
        categoria: r.tipo || 'técnico',
        nota: r.score || Math.round(score / 10),
        feedback: `Resposta registrada durante a entrevista.`
      }));
    
    return {
      summary_text: `Resumo automático (sem IA): candidato ${candidato} para a vaga ${vaga}.`,
      strengths: strengths.length > 0 ? strengths : ['Disponibilidade para entrevista'],
      risks: risks.length > 0 ? risks : ['Aguardando mais informações'],
      recommendation,
      overall_score: score || 50,
      respostas_destaque: respostasDestaque,
    };
  };

  // Se não há respostas nem feedbacks, usar fallback
  if (respostas.length === 0 && feedbacks.length === 0) {
    console.log('⚠️ [RF7] Sem respostas ou feedbacks para gerar relatório, usando fallback');
    return fallbackResult();
  }

  console.log(`📊 [RF7] Gerando relatório IA para ${candidato} - Vaga: ${vaga} - ${respostas.length} respostas, ${feedbacks.length} feedbacks`);

  const systemPrompt = `Você é um especialista em RH e tech lead avaliando entrevistas técnicas. 
Analise as respostas do candidato de forma objetiva e profissional.
Responda APENAS com JSON válido, sem markdown ou texto adicional.`;

  // Prompt melhorado com mais contexto
  const prompt = `Avalie a entrevista do candidato "${candidato}" para a vaga "${vaga}".

RESPOSTAS DA ENTREVISTA:
${respostas.map((r, i) => `${i + 1}. Pergunta: ${r.pergunta}\n   Resposta: ${r.resposta || 'Não respondida'}${r.score ? `\n   Score: ${r.score}/10` : ''}`).join('\n\n')}

${feedbacks.length > 0 ? `AVALIAÇÕES ANTERIORES:\n${feedbacks.map(f => `- ${f.topic}: ${f.verdict} (${f.score}/10) - ${f.comment || 'Sem comentário'}`).join('\n')}` : ''}

Gere um relatório JSON com os seguintes campos:
{
  "summary_text": "Resumo executivo de 2-3 parágrafos avaliando o desempenho geral do candidato, pontos de destaque e áreas de atenção",
  "overall_score": <número de 0 a 100 representando a pontuação geral>,
  "strengths": ["lista de 3-5 pontos fortes específicos identificados"],
  "risks": ["lista de 2-4 pontos de atenção ou riscos identificados"],
  "recommendation": "APROVAR" | "DÚVIDA" | "REPROVAR",
  "technical_assessment": "Avaliação técnica em 1-2 frases",
  "cultural_fit": "Avaliação de fit cultural em 1-2 frases",
  "next_steps": ["sugestões de próximos passos"],
  "respostas_destaque": [
    {
      "pergunta": "A pergunta técnica feita ao candidato",
      "categoria": "técnico" | "comportamental" | "experiência",
      "nota": <número de 0 a 10>,
      "feedback": "Breve análise de por que essa resposta foi destaque (positivo ou negativo)"
    }
  ]
}

IMPORTANTE para respostas_destaque:
- Selecione 1-3 respostas mais relevantes (boas ou ruins) das PERGUNTAS TÉCNICAS listadas acima
- NÃO use conversas informais ou mensagens de chat genéricas
- Cada resposta deve ter uma análise objetiva do porquê foi selecionada`;

  const messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: prompt }
  ];

  // Função para tentar OpenRouter
  const tryOpenRouter = async () => {
    if (!openRouterService) return null;
    try {
      const openRouterModel = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast';
      console.log('🔄 Tentando gerar relatório com OpenRouter:', openRouterModel);
      const orResp = await openRouterService.chamarOpenRouter(messages, {
        model: openRouterModel,
        temperature: 0.3,
        max_tokens: 2500
      });
      // chamarOpenRouter retorna { content, reasoning_details }
      const content = orResp?.content || null;
      if (content) {
        console.log('✅ OpenRouter gerou relatório com sucesso');
        // Log parcial do conteúdo para debug
        console.log('📝 Preview do relatório:', content.substring(0, 200) + '...');
      } else {
        console.log('⚠️ OpenRouter não retornou conteúdo');
      }
      return content;
    } catch (e) {
      console.error('❌ OpenRouter falhou para relatório:', e.message);
      return null;
    }
  };

  // Função para parsear resposta da IA
  const parseAIResponse = (content) => {
    if (!content) return null;
    
    // Tentar extrair JSON se vier com markdown
    let jsonStr = content;
    const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      jsonStr = jsonMatch[1].trim();
    }
    
    try {
      const parsed = JSON.parse(jsonStr);
      // Garantir campos obrigatórios
      return {
        summary_text: parsed.summary_text || parsed.summary || `Análise do candidato ${candidato} para a vaga ${vaga}.`,
        overall_score: parsed.overall_score || parsed.score || 70,
        strengths: Array.isArray(parsed.strengths) ? parsed.strengths : [],
        risks: Array.isArray(parsed.risks) ? parsed.risks : (Array.isArray(parsed.weaknesses) ? parsed.weaknesses : []),
        recommendation: parsed.recommendation || 'DÚVIDA',
        technical_assessment: parsed.technical_assessment || null,
        cultural_fit: parsed.cultural_fit || null,
        next_steps: Array.isArray(parsed.next_steps) ? parsed.next_steps : [],
        respostas_destaque: Array.isArray(parsed.respostas_destaque) ? parsed.respostas_destaque : [],
      };
    } catch (parseError) {
      console.error('❌ Erro ao parsear JSON da IA:', parseError.message);
      // Se falhou o parse, retorna o texto como summary
      return {
        summary_text: content.substring(0, 1000),
        overall_score: 60,
        strengths: [],
        risks: [],
        recommendation: 'DÚVIDA',
        respostas_destaque: [],
      };
    }
  };

  // Se não tem cliente OpenAI, tenta direto com OpenRouter
  if (!client) {
    console.log('⚠️ Sem cliente OpenAI, tentando OpenRouter direto para relatório...');
    const orContent = await tryOpenRouter();
    if (orContent) {
      const parsed = parseAIResponse(orContent);
      if (parsed) return parsed;
    }
    return fallbackResult();
  }

  // Tenta OpenAI primeiro
  try {
    const resp = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      temperature: 0.3,
      max_tokens: 2500,
    });
    const content = resp.choices?.[0]?.message?.content || '{}';
    const parsed = parseAIResponse(content);
    if (parsed) {
      console.log('✅ OpenAI gerou relatório com sucesso');
      return parsed;
    }
    return fallbackResult();
  } catch (openaiError) {
    console.error('OpenAI falhou para relatório, tentando OpenRouter:', openaiError.message);
    const orContent = await tryOpenRouter();
    if (orContent) {
      const parsed = parseAIResponse(orContent);
      if (parsed) return parsed;
    }
    // Fallback sem IA
    return fallbackResult();
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
