const { githubToken } = require('../config');

// Função para buscar repositórios de um usuário no GitHub
async function buscarRepositorios(usuario) {
    const url = `https://api.github.com/users/${usuario}/repos`;
    const response = await fetch(url, {
        headers: {
            'Authorization': `token ${githubToken}`
        }
    });
    if (!response.ok) {
        throw new Error('Usuário do GitHub não encontrado.');
    }
    return response.json();
}

module.exports = { buscarRepositorios };
