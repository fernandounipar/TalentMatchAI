const OpenAI = require('openai');
const { openaiApiKey } = require('../config');

const openai = new OpenAI({
    apiKey: openaiApiKey,
});

// Gera perguntas para entrevista com base no currículo e vaga
async function gerarPerguntas(curriculo, vaga) {
    const prompt = `Com base no seguinte currículo e descrição de vaga, gere 5 perguntas técnicas e 3 perguntas comportamentais para uma entrevista.\n\nCurrículo:\n${curriculo}\n\nVaga:\n${vaga}`;

    const response = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
    });

    return response.choices[0].message.content;
}

module.exports = { gerarPerguntas };
