import '../modelos/vaga.dart';
import '../modelos/candidato.dart';
import '../modelos/usuario.dart';
import '../modelos/historico.dart';
import '../modelos/dashboard.dart';

// Usuário atual
final usuarioAtual = Usuario(
  id: '1',
  nome: 'Ana Silva',
  email: 'ana.silva@empresa.com',
  role: 'recrutador',
  companyId: 'company-1',
  avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Ana',
);

final empresaAtual = Empresa(
  id: 'company-1',
  nome: 'TechCorp Brasil',
  tipo: 'CNPJ',
  documento: '12.345.678/0001-90',
  corPrimaria: '#2B6CB0',
);

// Vagas mockadas
final List<Vaga> mockVagas = [
  Vaga.create(
    id: '1',
    titulo: 'Desenvolvedor Full Stack Senior',
    descricao: 'Buscamos desenvolvedor experiente para liderar projetos de transformação digital.',
    requisitos: [
      'React e TypeScript avançado',
      'Node.js e Express',
      'PostgreSQL e MongoDB',
      'Arquitetura de microsserviços',
      'AWS ou Azure'
    ],
    senioridade: 'Senior',
    regime: 'CLT',
    local: 'São Paulo - Híbrido',
    status: 'Aberta',
    salario: 'R\$ 12.000 - R\$ 16.000',
    tags: ['React', 'Node.js', 'TypeScript', 'AWS'],
    createdAt: DateTime(2024, 10, 15),
    candidatos: 24,
  ),
  Vaga.create(
    id: '2',
    titulo: 'Designer UX/UI Pleno',
    descricao: 'Profissional criativo para desenvolver interfaces intuitivas e centradas no usuário.',
    requisitos: [
      'Figma avançado',
      'Design System',
      'Prototipagem',
      'Testes de usabilidade',
      'Design responsivo'
    ],
    senioridade: 'Pleno',
    regime: 'CLT',
    local: 'Remote',
    status: 'Aberta',
    salario: 'R\$ 7.000 - R\$ 9.000',
    tags: ['Figma', 'UX', 'UI', 'Design System'],
    createdAt: DateTime(2024, 10, 20),
    candidatos: 18,
  ),
  Vaga.create(
    id: '3',
    titulo: 'Engenheiro de Dados',
    descricao: 'Profissional para construir e manter pipelines de dados escaláveis.',
    requisitos: [
      'Python avançado',
      'Apache Spark',
      'Data Warehouse',
      'ETL/ELT',
      'BigQuery ou Redshift'
    ],
    senioridade: 'Pleno',
    regime: 'PJ',
    local: 'São Paulo - Presencial',
    status: 'Pausada',
    salario: 'R\$ 10.000 - R\$ 13.000',
    tags: ['Python', 'Spark', 'ETL', 'BigQuery'],
    createdAt: DateTime(2024, 9, 10),
    candidatos: 12,
  ),
];

// Candidatos mockados
final List<Candidato> mockCandidatos = [
  Candidato(
    id: '1',
    nome: 'Carlos Eduardo Santos',
    email: 'carlos.santos@email.com',
    telefone: '+55 11 98765-4321',
    github: 'https://github.com/carloseduardo',
    linkedin: 'https://linkedin.com/in/carloseduardo',
    status: 'Em Análise',
    vagaId: '1',
    matchingScore: 92,
    experiencia: [
      ExperienciaProfissional(
        cargo: 'Tech Lead',
        empresa: 'StartupXYZ',
        periodo: '2021 - Atual',
        descricao: 'Liderança técnica de equipe de 8 desenvolvedores, arquitetura de microsserviços em AWS.',
      ),
      ExperienciaProfissional(
        cargo: 'Desenvolvedor Senior',
        empresa: 'FinTech ABC',
        periodo: '2018 - 2021',
        descricao: 'Desenvolvimento de APIs REST e integração com sistemas bancários.',
      ),
    ],
    educacao: [
      Educacao(
        curso: 'Ciência da Computação',
        instituicao: 'USP',
        periodo: '2014 - 2018',
        tipo: 'Graduação',
      ),
    ],
    skills: ['React', 'TypeScript', 'Node.js', 'AWS', 'Docker', 'PostgreSQL', 'MongoDB', 'Microservices'],
    createdAt: DateTime(2024, 10, 25),
    criadoEm: DateTime(2024, 10, 25),
  ),
  Candidato(
    id: '2',
    nome: 'Juliana Oliveira',
    email: 'juliana.oliveira@email.com',
    telefone: '+55 11 99876-5432',
    linkedin: 'https://linkedin.com/in/julianaoliveira',
    status: 'Entrevista Agendada',
    vagaId: '2',
    matchingScore: 88,
    experiencia: [
      ExperienciaProfissional(
        cargo: 'UX/UI Designer',
        empresa: 'Design Studio',
        periodo: '2020 - Atual',
        descricao: 'Design de interfaces para aplicativos mobile e web, criação de design systems.',
      ),
    ],
    educacao: [
      Educacao(
        curso: 'Design Gráfico',
        instituicao: 'FAAP',
        periodo: '2016 - 2020',
        tipo: 'Graduação',
      ),
    ],
    skills: ['Figma', 'Adobe XD', 'Prototyping', 'User Research', 'Design System', 'Accessibility'],
    createdAt: DateTime(2024, 10, 28),
    criadoEm: DateTime(2024, 10, 28),
  ),
  Candidato(
    id: '3',
    nome: 'Roberto Lima',
    email: 'roberto.lima@email.com',
    telefone: '+55 21 98888-7777',
    github: 'https://github.com/robertolima',
    status: 'Aprovado',
    vagaId: '1',
    matchingScore: 85,
    experiencia: [
      ExperienciaProfissional(
        cargo: 'Desenvolvedor Full Stack',
        empresa: 'TechCorp',
        periodo: '2019 - Atual',
        descricao: 'Desenvolvimento de aplicações web com React e Node.js.',
      ),
    ],
    educacao: [
      Educacao(
        curso: 'Engenharia de Software',
        instituicao: 'UFRJ',
        periodo: '2015 - 2019',
        tipo: 'Graduação',
      ),
    ],
    skills: ['React', 'Node.js', 'JavaScript', 'MySQL', 'Git', 'Agile'],
    createdAt: DateTime(2024, 10, 15),
    criadoEm: DateTime(2024, 10, 15),
  ),
  Candidato(
    id: '4',
    nome: 'Mariana Costa',
    email: 'mariana.costa@email.com',
    telefone: '+55 11 97777-6666',
    status: 'Reprovado',
    vagaId: '3',
    matchingScore: 62,
    experiencia: [
      ExperienciaProfissional(
        cargo: 'Analista de Dados Jr',
        empresa: 'Data Inc',
        periodo: '2022 - Atual',
        descricao: 'Análise de dados com Python e criação de dashboards.',
      ),
    ],
    educacao: [
      Educacao(
        curso: 'Estatística',
        instituicao: 'UNICAMP',
        periodo: '2018 - 2022',
        tipo: 'Graduação',
      ),
    ],
    skills: ['Python', 'Pandas', 'SQL', 'PowerBI', 'Excel'],
    createdAt: DateTime(2024, 9, 20),
    criadoEm: DateTime(2024, 9, 20),
  ),
  Candidato(
    id: '5',
    nome: 'Pedro Henrique Alves',
    email: 'pedro.alves@email.com',
    telefone: '+55 11 96666-5555',
    github: 'https://github.com/pedroalves',
    status: 'Novo',
    vagaId: '1',
    matchingScore: 78,
    skills: ['JavaScript', 'React', 'Vue.js', 'CSS', 'HTML', 'REST APIs'],
    createdAt: DateTime(2024, 11, 1),
    criadoEm: DateTime(2024, 11, 1),
  ),
];

// Histórico de atividades
final List<AtividadeHistorico> mockHistorico = [
  AtividadeHistorico(
    id: '1',
    tipo: 'Upload',
    descricao: 'Novo currículo enviado por Carlos Eduardo Santos',
    usuario: 'Sistema',
    data: DateTime(2024, 11, 4, 9, 23),
    entidade: 'Candidato',
    entidadeId: '1',
  ),
  AtividadeHistorico(
    id: '2',
    tipo: 'Análise',
    descricao: 'Análise de IA concluída para Carlos Eduardo Santos (Score: 92)',
    usuario: 'IA',
    data: DateTime(2024, 11, 4, 9, 24),
    entidade: 'Candidato',
    entidadeId: '1',
  ),
  AtividadeHistorico(
    id: '3',
    tipo: 'Entrevista',
    descricao: 'Entrevista agendada com Juliana Oliveira',
    usuario: 'Ana Silva',
    data: DateTime(2024, 11, 4, 14, 15),
    entidade: 'Entrevista',
    entidadeId: '1',
  ),
  AtividadeHistorico(
    id: '4',
    tipo: 'Aprovação',
    descricao: 'Roberto Lima aprovado para Desenvolvedor Full Stack Senior',
    usuario: 'Ana Silva',
    data: DateTime(2024, 11, 3, 16, 45),
    entidade: 'Candidato',
    entidadeId: '3',
  ),
  AtividadeHistorico(
    id: '5',
    tipo: 'Edição',
    descricao: 'Vaga "Designer UX/UI Pleno" atualizada',
    usuario: 'Ana Silva',
    data: DateTime(2024, 11, 3, 11, 20),
    entidade: 'Vaga',
    entidadeId: '2',
  ),
  AtividadeHistorico(
    id: '6',
    tipo: 'Reprovação',
    descricao: 'Mariana Costa reprovada para Engenheiro de Dados',
    usuario: 'João Mendes',
    data: DateTime(2024, 11, 2, 15, 30),
    entidade: 'Candidato',
    entidadeId: '4',
  ),
];

// Estatísticas do Dashboard
final mockDashboardStats = DashboardStats(
  vagasAtivas: 12,
  candidatosTotal: 156,
  entrevistasAgendadas: 8,
  aprovadosMes: 24,
  tendenciaVagas: 15,
  tendenciaCandidatos: 23,
  tendenciaEntrevistas: -5,
  tendenciaAprovados: 12,
);

// Dados do funil de seleção
final List<FunilEtapa> mockFunilData = [
  FunilEtapa(etapa: 'Candidatos', valor: 156, cor: '#3B82F6'),
  FunilEtapa(etapa: 'Triagem', valor: 89, cor: '#8B5CF6'),
  FunilEtapa(etapa: 'Entrevista', valor: 45, cor: '#EC4899'),
  FunilEtapa(etapa: 'Teste Técnico', valor: 28, cor: '#F59E0B'),
  FunilEtapa(etapa: 'Aprovados', valor: 24, cor: '#10B981'),
];

// Dados dos gráficos
final List<DadosGrafico> mockChartData = [
  DadosGrafico(mes: 'Jun', candidatos: 45, entrevistas: 28, aprovados: 12),
  DadosGrafico(mes: 'Jul', candidatos: 52, entrevistas: 31, aprovados: 15),
  DadosGrafico(mes: 'Ago', candidatos: 61, entrevistas: 35, aprovados: 18),
  DadosGrafico(mes: 'Set', candidatos: 58, entrevistas: 38, aprovados: 19),
  DadosGrafico(mes: 'Out', candidatos: 72, entrevistas: 42, aprovados: 22),
  DadosGrafico(mes: 'Nov', candidatos: 68, entrevistas: 40, aprovados: 24),
];
