const https = require('https');

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_MODEL = process.env.OPENROUTER_MODEL || 'x-ai/grok-4.1-fast'; // Modelo padrão

/**
 * Faz chamada para OpenRouter API
 */
async function chamarOpenRouter(mensagens, options = {}) {
  if (!OPENROUTER_API_KEY) {
    throw new Error('OPENROUTER_API_KEY não configurada no .env');
  }

  const payload = JSON.stringify({
    model: options.model || OPENROUTER_MODEL,
    messages: mensagens,
    temperature: options.temperature ?? 0.7,
    max_tokens: options.max_tokens || 2048,
    top_p: options.top_p ?? 1,
    // Adiciona suporte a reasoning se necessário
    ...(options.reasoning ? { reasoning: { enabled: true } } : {})
  });

  return new Promise((resolve, reject) => {
    const reqOptions = {
      hostname: 'openrouter.ai',
      path: '/api/v1/chat/completions',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
        'HTTP-Referer': 'https://talentmatchia.app', // Opcional: para estatísticas
        'X-Title': 'TalentMatchIA', // Opcional: nome da aplicação
        'Content-Length': Buffer.byteLength(payload, 'utf8')
      },
      timeout: 180000 // 180 segundos (alguns modelos podem demorar mais)
    };

    const req = https.request(reqOptions, (res) => {
      // Coleta chunks como Buffer para decodificar UTF-8 corretamente
      const chunks = [];

      res.on('data', (chunk) => {
        chunks.push(chunk);
      });

      res.on('end', () => {
        // Concatena buffers e decodifica como UTF-8
        const data = Buffer.concat(chunks).toString('utf8');
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data);
            const message = response.choices[0].message;

            // Retorna objeto com conteúdo e reasoning_details se disponível
            resolve({
              content: message.content,
              reasoning_details: message.reasoning_details || null
            });
          } catch (error) {
            reject(new Error(`Erro ao parsear resposta OpenRouter: ${error.message}`));
          }
        } else if (res.statusCode === 429) {
          reject(new Error('Limite de requisições do OpenRouter atingido. Aguarde alguns segundos.'));
        } else if (res.statusCode === 401) {
          try {
            const errorData = JSON.parse(data);
            const errorMsg = errorData.error?.message || 'Chave API inválida';
            reject(new Error(`OpenRouter: ${errorMsg}. Gere uma nova chave em https://openrouter.ai/keys`));
          } catch {
            reject(new Error('OpenRouter: Autenticação falhou. Verifique sua OPENROUTER_API_KEY em https://openrouter.ai/keys'));
          }
        } else if (res.statusCode === 402) {
          reject(new Error('Créditos insuficientes no OpenRouter. Adicione créditos em https://openrouter.ai/credits'));
        } else {
          reject(new Error(`Erro OpenRouter ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error(`Erro de conexão com OpenRouter: ${error.message}`));
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Timeout na requisição para OpenRouter (180s)'));
    });

    req.write(payload);
    req.end();
  });
}

/**
 * Analisa currículo usando OpenRouter
 */
async function analisarCurriculo(textoCurriculo, vaga = null) {
  // Helper para processar requisitos (pode ser string ou array)
  const formatarRequisitos = (req) => {
    if (!req) return 'Não especificado';
    if (typeof req === 'string') return req;
    if (Array.isArray(req)) return req.join(', ');
    return 'Não especificado';
  };

  const prompt = vaga
    ? `Você é um especialista em RH e recrutamento. Analise o currículo abaixo e avalie a aderência do candidato à vaga especificada.

CURRÍCULO:
${textoCurriculo}

VAGA:
Título: ${vaga.titulo || vaga.title}
Requisitos: ${formatarRequisitos(vaga.requisitos || vaga.requirements)}

Retorne um JSON com a seguinte estrutura (APENAS o JSON, sem texto adicional):
{
  "candidato": {
    "nome": string ou null,
    "email": string ou null,
    "telefone": string ou null,
    "github": string ou null,
    "linkedin": string ou null
  },
  "experiencias": [
    {
      "cargo": string ou null,
      "empresa": string ou null,
      "periodo": string ou null,
      "descricao": string ou null
    }
  ],
  "educacao": [
    {
      "curso": string ou null,
      "instituicao": string ou null,
      "periodo": string ou null,
      "status": string ou null
    }
  ],
  "certificacoes": [
    {
      "nome": string ou null,
      "instituicao": string ou null,
      "ano": string ou null,
      "cargaHoraria": string ou null
    }
  ],
  "skills": ["skill1", "skill2", ...],
  "experiencia": "Descrição resumida da experiência do candidato",
  "senioridade": "Júnior|Pleno|Sênior|Especialista",
  "aderenciaVaga": 85,
  "pontosFortesVaga": ["ponto1", "ponto2"],
  "pontosFracosVaga": ["ponto1", "ponto2"]
}

Instruções:
- Extraia dados de contato (nome, email, telefone, GitHub, LinkedIn) do currículo
- Se houver apenas usuário do GitHub, monte a URL: https://github.com/USUARIO
- Liste as experiências profissionais com cargo, empresa, período e descrição
- Extraia formação acadêmica (curso, instituição, período, status: "Concluído"/"Em andamento"/"Trancado")
- Extraia certificações (nome, instituição, ano, carga horária se informado)
- Copie períodos exatamente como aparecem no currículo (ex: "2009 ~ 2011" ou "jan/2020 - atual")
- Não invente dados: use null para informações não encontradas
- O campo "experiencia" deve ser um resumo geral em 2-3 frases`
    : `Você é um especialista em RH. Analise o currículo abaixo e extraia informações relevantes.

CURRÍCULO:
${textoCurriculo}

Retorne um JSON com a seguinte estrutura (APENAS o JSON, sem texto adicional):
{
  "candidato": {
    "nome": string ou null,
    "email": string ou null,
    "telefone": string ou null,
    "github": string ou null,
    "linkedin": string ou null
  },
  "experiencias": [
    {
      "cargo": string ou null,
      "empresa": string ou null,
      "periodo": string ou null,
      "descricao": string ou null
    }
  ],
  "educacao": [
    {
      "curso": string ou null,
      "instituicao": string ou null,
      "periodo": string ou null,
      "status": string ou null
    }
  ],
  "certificacoes": [
    {
      "nome": string ou null,
      "instituicao": string ou null,
      "ano": string ou null,
      "cargaHoraria": string ou null
    }
  ],
  "skills": ["skill1", "skill2", ...],
  "experiencia": "Descrição resumida da experiência do candidato",
  "senioridade": "Júnior|Pleno|Sênior|Especialista"
}

Instruções:
- Extraia dados de contato (nome, email, telefone, GitHub, LinkedIn)
- Se houver apenas usuário do GitHub, monte a URL: https://github.com/USUARIO
- Liste as experiências profissionais com cargo, empresa, período e descrição
- Extraia formação acadêmica (curso, instituição, período, status: "Concluído"/"Em andamento"/"Trancado")
- Extraia certificações (nome, instituição, ano, carga horária se informado)
- Copie períodos exatamente como aparecem no currículo (ex: "2009 ~ 2011" ou "jan/2020 - atual")
- Não invente dados: use null para informações não encontradas`;

  try {
    const resposta = await chamarOpenRouter(
      [{ role: 'user', content: prompt }],
      { temperature: 0.3, max_tokens: 1500 }
    );

    // Remove markdown code blocks se houver
    let jsonText = resposta.content.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }

    const resultado = JSON.parse(jsonText);

    // Garante estrutura mínima
    return {
      candidato: resultado.candidato || null,
      experiencias: Array.isArray(resultado.experiencias) ? resultado.experiencias : [],
      educacao: Array.isArray(resultado.educacao) ? resultado.educacao : [],
      certificacoes: Array.isArray(resultado.certificacoes) ? resultado.certificacoes : [],
      skills: resultado.skills || [],
      experiencia: resultado.experiencia || 'Não especificado',
      senioridade: resultado.senioridade || 'Júnior',
      aderenciaVaga: resultado.aderenciaVaga || null,
      pontosFortesVaga: resultado.pontosFortesVaga || [],
      pontosFracosVaga: resultado.pontosFracosVaga || []
    };
  } catch (error) {
    console.error('❌ Erro ao analisar currículo com OpenRouter:', error.message);
    throw error;
  }
}

/**
 * Gera perguntas para entrevista usando OpenRouter
 */
async function gerarPerguntasEntrevista(vaga, curriculo = null) {
  const prompt = curriculo
    ? `Você é um especialista em recrutamento. Gere 5 perguntas relevantes para uma entrevista baseada na vaga e no currículo do candidato.

VAGA:
${JSON.stringify(vaga, null, 2)}

CURRÍCULO DO CANDIDATO:
${curriculo}

Retorne um JSON array com a seguinte estrutura (APENAS o JSON, sem texto adicional):
[
  {
    "texto": "Pergunta aqui?",
    "categoria": "Técnica|Comportamental|Situacional|Cultural",
    "peso": 1-5
  }
]`
    : `Você é um especialista em recrutamento. Gere 5 perguntas relevantes para uma entrevista baseada na vaga.

VAGA:
${JSON.stringify(vaga, null, 2)}

Retorne um JSON array com a seguinte estrutura (APENAS o JSON, sem texto adicional):
[
  {
    "texto": "Pergunta aqui?",
    "categoria": "Técnica|Comportamental|Situacional|Cultural",
    "peso": 1-5
  }
]`;

  try {
    const resposta = await chamarOpenRouter(
      [{ role: 'user', content: prompt }],
      { temperature: 0.7, max_tokens: 1500 }
    );

    let jsonText = resposta.content.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }

    return JSON.parse(jsonText);
  } catch (error) {
    console.error('❌ Erro ao gerar perguntas com OpenRouter:', error.message);
    throw error;
  }
}

/**
 * Avalia resposta de entrevista usando OpenRouter
 */
async function avaliarResposta(pergunta, resposta) {
  const prompt = `Você é um especialista em recrutamento. Avalie a resposta do candidato para a pergunta da entrevista.

PERGUNTA: ${pergunta}
RESPOSTA: ${resposta}

Retorne um JSON com a seguinte estrutura (APENAS o JSON, sem texto adicional):
{
  "nota": 1-10,
  "feedback": "Feedback construtivo sobre a resposta",
  "pontosFortesResposta": ["ponto1", "ponto2"],
  "pontosMelhoria": ["ponto1", "ponto2"]
}`;

  try {
    const respostaIA = await chamarOpenRouter(
      [{ role: 'user', content: prompt }],
      { temperature: 0.3, max_tokens: 800 }
    );

    let jsonText = respostaIA.content.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }

    return JSON.parse(jsonText);
  } catch (error) {
    console.error('❌ Erro ao avaliar resposta com OpenRouter:', error.message);
    throw error;
  }
}

module.exports = {
  chamarOpenRouter,
  analisarCurriculo,
  gerarPerguntasEntrevista,
  avaliarResposta
};
