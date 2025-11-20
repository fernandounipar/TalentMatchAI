/**
 * Serviço de IA usando Groq (alternativa gratuita e rápida)
 * 
 * Groq oferece acesso gratuito a modelos de IA como:
 * - Llama 3 (70B) - muito poderoso
 * - Mixtral (8x7B) - ótimo custo-benefício
 * 
 * Docs: https://console.groq.com/docs/quickstart
 */

const https = require('https');

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile'; // Modelo atualizado (Nov 2024)

/**
 * Faz chamada para Groq API
 */
async function chamarGroq(mensagens, options = {}) {
  if (!GROQ_API_KEY) {
    throw new Error('GROQ_API_KEY não configurada no .env');
  }

  const payload = JSON.stringify({
    model: options.model || GROQ_MODEL,
    messages: mensagens,
    temperature: options.temperature ?? 0.7,
    max_tokens: options.max_tokens || 2048,
    top_p: options.top_p ?? 1,
    stream: false
  });

  return new Promise((resolve, reject) => {
    const reqOptions = {
      hostname: 'api.groq.com',
      path: '/openai/v1/chat/completions',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      },
      timeout: 30000 // 30 segundos
    };

    const req = https.request(reqOptions, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data);
            resolve(response.choices[0].message.content);
          } catch (error) {
            reject(new Error(`Erro ao parsear resposta Groq: ${error.message}`));
          }
        } else if (res.statusCode === 429) {
          reject(new Error('Limite de requisições do Groq atingido. Aguarde alguns segundos.'));
        } else if (res.statusCode === 401) {
          reject(new Error('GROQ_API_KEY inválida. Verifique sua chave em https://console.groq.com/keys'));
        } else {
          reject(new Error(`Erro Groq ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error(`Erro de conexão com Groq: ${error.message}`));
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Timeout na requisição para Groq (30s)'));
    });

    req.write(payload);
    req.end();
  });
}

/**
 * Analisa currículo usando Groq
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
  "skills": ["skill1", "skill2", ...],
  "experiencia": "Descrição resumida da experiência",
  "senioridade": "Júnior|Pleno|Sênior|Especialista",
  "aderenciaVaga": 85,
  "pontosFortesVaga": ["ponto1", "ponto2"],
  "pontosFracosVaga": ["ponto1", "ponto2"]
}`
    : `Você é um especialista em RH. Analise o currículo abaixo e extraia informações relevantes.

CURRÍCULO:
${textoCurriculo}

Retorne um JSON com a seguinte estrutura (APENAS o JSON, sem texto adicional):
{
  "skills": ["skill1", "skill2", ...],
  "experiencia": "Descrição resumida da experiência",
  "senioridade": "Júnior|Pleno|Sênior|Especialista"
}`;

  try {
    const resposta = await chamarGroq(
      [{ role: 'user', content: prompt }],
      { temperature: 0.3, max_tokens: 1500 }
    );

    // Remove markdown code blocks se houver
    let jsonText = resposta.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }

    const resultado = JSON.parse(jsonText);
    
    // Garante estrutura mínima
    return {
      skills: resultado.skills || [],
      experiencia: resultado.experiencia || 'Não especificado',
      senioridade: resultado.senioridade || 'Júnior',
      aderenciaVaga: resultado.aderenciaVaga || null,
      pontosFortesVaga: resultado.pontosFortesVaga || [],
      pontosFracosVaga: resultado.pontosFracosVaga || []
    };
  } catch (error) {
    console.error('❌ Erro ao analisar currículo com Groq:', error.message);
    throw error;
  }
}

/**
 * Gera perguntas para entrevista usando Groq
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
    const resposta = await chamarGroq(
      [{ role: 'user', content: prompt }],
      { temperature: 0.7, max_tokens: 1500 }
    );

    let jsonText = resposta.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }

    return JSON.parse(jsonText);
  } catch (error) {
    console.error('❌ Erro ao gerar perguntas com Groq:', error.message);
    throw error;
  }
}

/**
 * Avalia resposta de entrevista usando Groq
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
    const respostaIA = await chamarGroq(
      [{ role: 'user', content: prompt }],
      { temperature: 0.3, max_tokens: 800 }
    );

    let jsonText = respostaIA.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }

    return JSON.parse(jsonText);
  } catch (error) {
    console.error('❌ Erro ao avaliar resposta com Groq:', error.message);
    throw error;
  }
}

module.exports = {
  chamarGroq,
  analisarCurriculo,
  gerarPerguntasEntrevista,
  avaliarResposta
};
