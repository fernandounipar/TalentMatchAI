require('dotenv').config();

module.exports = {
    openaiApiKey: process.env.OPENAI_API_KEY,
    githubToken: process.env.GITHUB_TOKEN, // Adicionar ao .env.example
};
