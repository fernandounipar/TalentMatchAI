/**
 * GitHub API Service (RF4)
 * Integração com GitHub API para enriquecer perfis técnicos de candidatos
 */

const axios = require('axios');

class GitHubService {
  constructor() {
    this.baseURL = 'https://api.github.com';
    this.timeout = 10000; // 10s timeout
    this.rateLimit = {
      remaining: null,
      reset: null
    };
  }

  /**
   * Cria cliente axios com configurações
   */
  createClient() {
    const headers = {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'TalentMatchIA-Recruiter'
    };

    // Adicionar token se disponível (aumenta rate limit de 60 para 5000 req/h)
    if (process.env.GITHUB_TOKEN) {
      headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`;
    }

    return axios.create({
      baseURL: this.baseURL,
      timeout: this.timeout,
      headers
    });
  }

  /**
   * Atualiza informações de rate limit
   */
  updateRateLimit(headers) {
    if (headers['x-ratelimit-remaining']) {
      this.rateLimit.remaining = parseInt(headers['x-ratelimit-remaining']);
      this.rateLimit.reset = new Date(parseInt(headers['x-ratelimit-reset']) * 1000);
    }
  }

  /**
   * Verifica se está no rate limit
   */
  isRateLimited() {
    if (this.rateLimit.remaining === null) return false;
    if (this.rateLimit.remaining === 0) {
      const now = new Date();
      if (now < this.rateLimit.reset) {
        return true;
      }
    }
    return false;
  }

  /**
   * Busca dados do perfil de usuário
   */
  async getUserProfile(username) {
    if (this.isRateLimited()) {
      throw new Error(`GitHub API rate limit exceeded. Resets at ${this.rateLimit.reset.toISOString()}`);
    }

    try {
      const client = this.createClient();
      const response = await client.get(`/users/${username}`);
      
      this.updateRateLimit(response.headers);

      return {
        username: response.data.login,
        github_id: response.data.id,
        avatar_url: response.data.avatar_url,
        profile_url: response.data.html_url,
        bio: response.data.bio,
        location: response.data.location,
        blog: response.data.blog,
        company: response.data.company,
        email: response.data.email,
        hireable: response.data.hireable,
        public_repos: response.data.public_repos,
        public_gists: response.data.public_gists,
        followers: response.data.followers,
        following: response.data.following,
        created_at: response.data.created_at,
        updated_at: response.data.updated_at
      };
    } catch (error) {
      if (error.response?.status === 404) {
        throw new Error(`GitHub user '${username}' not found`);
      }
      if (error.response?.status === 403) {
        this.updateRateLimit(error.response.headers);
        throw new Error('GitHub API rate limit exceeded');
      }
      throw new Error(`GitHub API error: ${error.message}`);
    }
  }

  /**
   * Busca repositórios públicos do usuário
   */
  async getUserRepositories(username, options = {}) {
    const { sort = 'updated', per_page = 100 } = options;

    try {
      const client = this.createClient();
      const response = await client.get(`/users/${username}/repos`, {
        params: {
          type: 'owner',
          sort,
          per_page,
          direction: 'desc'
        }
      });

      this.updateRateLimit(response.headers);

      return response.data.map(repo => ({
        name: repo.name,
        full_name: repo.full_name,
        description: repo.description,
        html_url: repo.html_url,
        language: repo.language,
        stargazers_count: repo.stargazers_count,
        forks_count: repo.forks_count,
        watchers_count: repo.watchers_count,
        size: repo.size,
        created_at: repo.created_at,
        updated_at: repo.updated_at,
        pushed_at: repo.pushed_at,
        is_fork: repo.fork,
        topics: repo.topics || []
      }));
    } catch (error) {
      if (error.response?.status === 404) {
        return [];
      }
      throw new Error(`Failed to fetch repositories: ${error.message}`);
    }
  }

  /**
   * Analisa repositórios e extrai insights
   */
  analyzeRepositories(repos) {
    // Filtrar forks (focar em repos originais)
    const originalRepos = repos.filter(r => !r.is_fork);

    // Contar linguagens
    const languageStats = {};
    let totalRepos = 0;

    originalRepos.forEach(repo => {
      if (repo.language) {
        languageStats[repo.language] = (languageStats[repo.language] || 0) + 1;
        totalRepos++;
      }
    });

    // Top linguagens com percentual
    const topLanguages = Object.entries(languageStats)
      .map(([name, count]) => ({
        name,
        repos_count: count,
        percentage: totalRepos > 0 ? ((count / totalRepos) * 100).toFixed(2) : 0
      }))
      .sort((a, b) => b.repos_count - a.repos_count)
      .slice(0, 10);

    // Total de stars/forks
    const totalStars = repos.reduce((sum, r) => sum + r.stargazers_count, 0);
    const totalForks = repos.reduce((sum, r) => sum + r.forks_count, 0);

    // Top repos por stars
    const topRepos = originalRepos
      .sort((a, b) => b.stargazers_count - a.stargazers_count)
      .slice(0, 5)
      .map(r => ({
        name: r.name,
        description: r.description || '',
        language: r.language,
        stars: r.stargazers_count,
        forks: r.forks_count,
        url: r.html_url
      }));

    // Calcular atividade recente (repos atualizados nos últimos 6 meses)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const recentRepos = repos.filter(r => new Date(r.updated_at) > sixMonthsAgo);

    // Última atividade
    const lastActivityDate = repos.length > 0
      ? repos.reduce((latest, r) => {
          const repoDate = new Date(r.updated_at);
          return repoDate > latest ? repoDate : latest;
        }, new Date(0))
      : null;

    // Detectar skills a partir de linguagens e topics
    const skillsSet = new Set();
    
    // Adicionar linguagens
    topLanguages.forEach(lang => skillsSet.add(lang.name));
    
    // Adicionar topics relevantes
    repos.forEach(repo => {
      if (repo.topics && repo.topics.length > 0) {
        repo.topics.forEach(topic => {
          // Filtrar topics genéricos
          const genericTopics = ['hacktoberfest', 'good-first-issue', 'beginner-friendly'];
          if (!genericTopics.includes(topic)) {
            skillsSet.add(topic);
          }
        });
      }
    });

    // Score de completude do perfil (0-100)
    const completenessScore = this.calculateCompletenessScore({
      hasRepos: repos.length > 0,
      hasOriginalRepos: originalRepos.length > 0,
      hasStars: totalStars > 0,
      hasRecentActivity: recentRepos.length > 0,
      repoCount: repos.length
    });

    return {
      top_languages: topLanguages,
      total_stars: totalStars,
      total_forks: totalForks,
      top_repos: topRepos,
      recent_activity_count: recentRepos.length,
      last_activity_date: lastActivityDate ? lastActivityDate.toISOString() : null,
      skills_detected: Array.from(skillsSet).slice(0, 20),
      profile_completeness_score: completenessScore,
      original_repos_count: originalRepos.length,
      fork_repos_count: repos.length - originalRepos.length
    };
  }

  /**
   * Calcula score de completude do perfil (0-100)
   */
  calculateCompletenessScore(profile) {
    let score = 0;

    if (profile.hasRepos) score += 30;
    if (profile.hasOriginalRepos) score += 20;
    if (profile.hasStars) score += 15;
    if (profile.hasRecentActivity) score += 20;

    if (profile.repoCount >= 1) score += 3;
    if (profile.repoCount >= 5) score += 3;
    if (profile.repoCount >= 10) score += 3;
    if (profile.repoCount >= 20) score += 3;
    if (profile.repoCount >= 50) score += 3;

    return Math.min(score, 100);
  }

  /**
   * Busca e analisa perfil completo (profile + repos + análise)
   */
  async getCompleteProfile(username) {
    try {
      const profile = await this.getUserProfile(username);
      const repos = await this.getUserRepositories(username);
      const analysis = this.analyzeRepositories(repos);

      return {
        ...profile,
        summary: analysis
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Retorna informações do rate limit atual
   */
  getRateLimitInfo() {
    return {
      remaining: this.rateLimit.remaining,
      reset: this.rateLimit.reset,
      is_limited: this.isRateLimited()
    };
  }
}

module.exports = new GitHubService();
