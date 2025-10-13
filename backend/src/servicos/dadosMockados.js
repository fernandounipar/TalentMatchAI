/**
 * Dados Mockados para TalentMatchIA
 * Usado para desenvolvimento e testes sem necessidade de banco de dados
 */

const dadosMockados = {
  // Candidatos
  candidatos: [
    {
      id: '1',
      nome: 'João Silva',
      email: 'joao.silva@email.com',
      telefone: '(11) 98765-4321',
      linkedin_url: 'https://linkedin.com/in/joaosilva',
      github_url: 'https://github.com/joaosilva',
      qtd_curriculos: 2,
      qtd_entrevistas: 3,
      criado_em: '2024-10-01T10:00:00Z',
    },
    {
      id: '2',
      nome: 'Maria Santos',
      email: 'maria.santos@email.com',
      telefone: '(11) 98765-4322',
      linkedin_url: 'https://linkedin.com/in/mariasantos',
      github_url: 'https://github.com/mariasantos',
      qtd_curriculos: 1,
      qtd_entrevistas: 2,
      criado_em: '2024-10-02T11:30:00Z',
    },
    {
      id: '3',
      nome: 'Carlos Oliveira',
      email: 'carlos.oliveira@email.com',
      telefone: '(11) 98765-4323',
      linkedin_url: 'https://linkedin.com/in/carlosoliveira',
      github_url: 'https://github.com/carlosoliveira',
      qtd_curriculos: 3,
      qtd_entrevistas: 1,
      criado_em: '2024-10-03T09:15:00Z',
    },
    {
      id: '4',
      nome: 'Ana Paula',
      email: 'ana.paula@email.com',
      telefone: '(11) 98765-4324',
      linkedin_url: null,
      github_url: null,
      qtd_curriculos: 1,
      qtd_entrevistas: 0,
      criado_em: '2024-10-05T14:20:00Z',
    },
  ],

  // Vagas
  vagas: [
    {
      id: '1',
      titulo: 'Desenvolvedor Full Stack',
      descricao: 'Desenvolver e manter aplicações web usando React, Node.js e PostgreSQL.',
      requisitos: 'React, Node.js, PostgreSQL, 3+ anos de experiência',
      status: 'aberta',
      tecnologias: 'React, Node.js, PostgreSQL, Docker, Git',
      nivel: 'Pleno',
      criado_em: '2024-09-15T08:00:00Z',
    },
    {
      id: '2',
      titulo: 'UX/UI Designer',
      descricao: 'Criar interfaces intuitivas e experiências de usuário excepcionais.',
      requisitos: 'Figma, Adobe XD, Portfólio, 2+ anos',
      status: 'aberta',
      tecnologias: 'Figma, Adobe XD, Sketch, Prototyping',
      nivel: 'Pleno',
      criado_em: '2024-09-20T10:00:00Z',
    },
    {
      id: '3',
      titulo: 'DevOps Engineer',
      descricao: 'Gerenciar infraestrutura cloud e CI/CD pipelines.',
      requisitos: 'AWS, Docker, Kubernetes, Jenkins, 4+ anos',
      status: 'aberta',
      tecnologias: 'AWS, Docker, Kubernetes, Terraform, Jenkins',
      nivel: 'Senior',
      criado_em: '2024-09-25T09:00:00Z',
    },
  ],

  // Currículos
  curriculos: [
    {
      id: '1',
      candidato_id: '1',
      vaga_id: '1',
      nome_arquivo: 'curriculo_joao_silva.pdf',
      caminho_arquivo: '/uploads/curriculo_joao_silva.pdf',
      texto_extraido: 'João Silva - Desenvolvedor Full Stack. 5 anos de experiência com React, Node.js...',
      analise_ia: {
        pontuacao: 85,
        competencias: ['React', 'Node.js', 'PostgreSQL', 'Docker', 'Git'],
        experiencia_anos: 5,
        pontos_fortes: ['Sólida experiência com stack', 'Perfil GitHub ativo'],
        pontos_atencao: ['Experiência com testes poderia ser mais detalhada'],
      },
      pontuacao: 85,
      criado_em: '2024-10-01T10:30:00Z',
    },
  ],

  // Entrevistas
  entrevistas: [
    {
      id: '1',
      candidato_id: '1',
      vaga_id: '1',
      curriculo_id: '1',
      status: 'concluida',
      data_hora: '2024-10-08T14:00:00Z',
      perguntas: [
        {
          id: '1',
          texto: 'Explique o conceito de idempotência em APIs RESTful',
          categoria: 'tecnica',
          resposta: 'Idempotência significa que uma operação pode ser repetida múltiplas vezes sem causar efeitos colaterais adicionais.',
          avaliacao_ia: {
            feedback: 'Resposta clara e objetiva, demonstrando conhecimento sólido.',
          },
          pontuacao: 8,
        },
        {
          id: '2',
          texto: 'Como você estrutura testes automatizados?',
          categoria: 'tecnica',
          resposta: 'Utilizo Jest para testes unitários e de integração, com mocks para dependências externas.',
          avaliacao_ia: {
            feedback: 'Excelente! Mencionou ferramentas adequadas e boas práticas.',
          },
          pontuacao: 9,
        },
      ],
      avaliacao_final: {
        pontuacao_geral: 85,
        recomendacao: 'contratar',
      },
      observacoes: 'Candidato demonstrou excelente conhecimento técnico.',
      criado_em: '2024-10-08T14:00:00Z',
    },
    {
      id: '2',
      candidato_id: '2',
      vaga_id: '2',
      curriculo_id: null,
      status: 'agendada',
      data_hora: '2024-10-15T10:00:00Z',
      perguntas: null,
      avaliacao_final: null,
      observacoes: null,
      criado_em: '2024-10-10T09:00:00Z',
    },
  ],

  // Relatórios
  relatorios: [
    {
      id: '1',
      entrevista_id: '1',
      candidato_nome: 'João Silva',
      vaga_titulo: 'Desenvolvedor Full Stack',
      pontuacao_geral: 85,
      recomendacao: 'contratar',
      analise_detalhada: {
        conhecimento_tecnico: 88,
        experiencia_pratica: 85,
        comunicacao: 82,
        resolucao_problemas: 90,
        fit_cultural: 78,
      },
      pontos_fortes: [
        'Excelente domínio de tecnologias do stack',
        'Raciocínio lógico sólido',
        'Boa comunicação',
        'Experiência com boas práticas',
      ],
      pontos_melhoria: [
        'Aprofundar conhecimento em otimização SQL',
        'Experiência com metodologias ágeis',
      ],
      observacoes: 'Candidato altamente recomendado para a vaga.',
      gerado_em: '2024-10-08T16:00:00Z',
    },
  ],

  // Histórico de Entrevistas
  historico: [
    {
      id: '1',
      candidato: 'João Silva',
      vaga: 'Desenvolvedor Full Stack',
      data: '2024-10-08',
      status: 'Aprovado',
      pontuacao: 85,
    },
    {
      id: '2',
      candidato: 'Maria Santos',
      vaga: 'UX/UI Designer',
      data: '2024-10-05',
      status: 'Em Análise',
      pontuacao: 78,
    },
    {
      id: '3',
      candidato: 'Carlos Oliveira',
      vaga: 'DevOps Engineer',
      data: '2024-10-03',
      status: 'Aprovado',
      pontuacao: 92,
    },
    {
      id: '4',
      candidato: 'João Silva',
      vaga: 'Senior Developer',
      data: '2024-09-28',
      status: 'Reprovado',
      pontuacao: 65,
    },
  ],

  // Dashboard
  dashboard: {
    vagas: 8,
    candidatos: 142,
    entrevistas: 23,
    aprovados: 12,
    estatisticas: {
      curriculos_recebidos: 142,
      triagem_inicial: 68,
      entrevistas_realizadas: 23,
      aprovados: 12,
    },
    atividades_recentes: [
      {
        tipo: 'curriculo',
        candidato: 'João Silva',
        acao: 'enviou currículo para',
        vaga: 'Desenvolvedor Full Stack',
        tempo: '5 min atrás',
      },
      {
        tipo: 'entrevista',
        candidato: 'Maria Santos',
        acao: 'entrevista concluída para',
        vaga: 'UX Designer',
        tempo: '1 hora atrás',
      },
      {
        tipo: 'aprovacao',
        candidato: 'Carlos Oliveira',
        acao: 'foi aprovado para',
        vaga: 'DevOps Engineer',
        tempo: '2 horas atrás',
      },
    ],
  },

  // Perguntas sugeridas pela IA
  perguntas_sugeridas: [
    {
      categoria: 'tecnica',
      texto: 'Explique o conceito de idempotência em APIs RESTful e dê exemplos.',
    },
    {
      categoria: 'tecnica',
      texto: 'Como você estrutura seus testes em aplicações Node.js?',
    },
    {
      categoria: 'tecnica',
      texto: 'Descreva sua experiência com otimização de queries SQL no PostgreSQL.',
    },
    {
      categoria: 'comportamental',
      texto: 'Conte sobre um projeto desafiador que você liderou.',
    },
    {
      categoria: 'situacional',
      texto: 'Como você lidaria com um bug crítico em produção?',
    },
    {
      categoria: 'comportamental',
      texto: 'Descreva uma situação em que você teve que trabalhar com prazos apertados.',
    },
  ],
};

module.exports = dadosMockados;
