import 'dart:math';

class MockDatabase {
  MockDatabase._();
  static final MockDatabase _instance = MockDatabase._();
  factory MockDatabase() => _instance;

  final Random _rand = Random(42);

  final List<Map<String, dynamic>> _vagas = [
    {
      'id': '1',
      'titulo': 'Desenvolvedor Full Stack',
      'descricao':
          'Desenvolver e manter aplicações web usando React, Node.js e PostgreSQL. Experiência com APIs RESTful.',
      'requisitos': 'React, Node.js, PostgreSQL, 3+ anos',
      'status': 'aberta',
      'nivel': 'Pleno',
      'tecnologias': 'React, Node.js, PostgreSQL, Docker',
      'candidatos': 25,
    },
    {
      'id': '2',
      'titulo': 'UX/UI Designer',
      'descricao':
          'Criar interfaces intuitivas e experiências de usuário excepcionais. Trabalhar com Figma e prototipação.',
      'requisitos': 'Figma, Adobe XD, Portfólio, 2+ anos',
      'status': 'aberta',
      'nivel': 'Pleno',
      'tecnologias': 'Figma, Adobe XD, Sketch',
      'candidatos': 18,
    },
    {
      'id': '3',
      'titulo': 'DevOps Engineer',
      'descricao': 'Gerenciar infraestrutura cloud, CI/CD pipelines e automação de processos.',
      'requisitos': 'AWS, Docker, Kubernetes, Jenkins, 4+ anos',
      'status': 'aberta',
      'nivel': 'Senior',
      'tecnologias': 'AWS, Docker, Kubernetes, Terraform',
      'candidatos': 12,
    },
    {
      'id': '4',
      'titulo': 'Data Scientist',
      'descricao': 'Analisar dados, criar modelos de ML e gerar insights para tomada de decisão.',
      'requisitos': 'Python, Pandas, Scikit-learn, SQL, 3+ anos',
      'status': 'pausada',
      'nivel': 'Pleno',
      'tecnologias': 'Python, TensorFlow, Pandas, SQL',
      'candidatos': 8,
    },
    {
      'id': '5',
      'titulo': 'Product Manager',
      'descricao':
          'Liderar roadmap de produto, definir prioridades e trabalhar com times multidisciplinares.',
      'requisitos': 'Gestão de produtos, Agile, 5+ anos',
      'status': 'aberta',
      'nivel': 'Senior',
      'tecnologias': 'Jira, Miro, Analytics',
      'candidatos': 15,
    },
    {
      'id': '6',
      'titulo': 'Desenvolvedor Mobile Flutter',
      'descricao': 'Desenvolver aplicativos móveis multiplataforma com Flutter e Dart.',
      'requisitos': 'Flutter, Dart, Firebase, 2+ anos',
      'status': 'fechada',
      'nivel': 'Pleno',
      'tecnologias': 'Flutter, Dart, Firebase, REST API',
      'candidatos': 30,
    },
  ];

  final List<Map<String, dynamic>> _candidatos = [
    {
      'id': '1',
      'nome': 'João Silva',
      'email': 'joao.silva@talentmatch.com',
      'qtd_curriculos': 3,
      'qtd_entrevistas': 1,
    },
    {
      'id': '2',
      'nome': 'Maria Souza',
      'email': 'maria.souza@talentmatch.com',
      'qtd_curriculos': 2,
      'qtd_entrevistas': 2,
    },
    {
      'id': '3',
      'nome': 'Carlos Lima',
      'email': 'carlos.lima@talentmatch.com',
      'qtd_curriculos': 1,
      'qtd_entrevistas': 0,
    },
    {
      'id': '4',
      'nome': 'Ana Paula',
      'email': 'ana.paula@talentmatch.com',
      'qtd_curriculos': 4,
      'qtd_entrevistas': 3,
    },
  ];

  final List<Map<String, dynamic>> _historico = [
    {
      'id': '1',
      'candidato': 'João Silva',
      'vaga': 'Desenvolvedor Full Stack',
      'criado_em': '2024-06-10T14:32:00Z',
      'tem_relatorio': true,
    },
    {
      'id': '2',
      'candidato': 'Maria Souza',
      'vaga': 'UX/UI Designer',
      'criado_em': '2024-06-09T10:15:00Z',
      'tem_relatorio': false,
    },
    {
      'id': '3',
      'candidato': 'Carlos Lima',
      'vaga': 'DevOps Engineer',
      'criado_em': '2024-06-05T18:45:00Z',
      'tem_relatorio': true,
    },
    {
      'id': '4',
      'candidato': 'Ana Paula',
      'vaga': 'Product Manager',
      'criado_em': '2024-05-30T09:00:00Z',
      'tem_relatorio': false,
    },
  ];

  final Map<String, Map<String, dynamic>> _entrevistas = {
    'ent-1': {
      'id': 'ent-1',
      'candidato': 'João Silva',
      'vaga': 'Desenvolvedor Full Stack',
      'perguntasGeradas': [
        'Explique como garantir qualidade em uma API RESTful.',
        'Conte sobre um desafio recente que resolveu com Node.js.',
      ],
      'mensagens': [
        {
          'role': 'assistant',
          'conteudo':
              'Olá, sou a TalentMatchIA. Vamos conduzir a entrevista técnica para a vaga de Desenvolvedor Full Stack.'
        },
      ],
    },
  };

  final Map<String, Map<String, dynamic>> _relatorios = {};

  final List<Map<String, dynamic>> _usuarios = [
    {
      'id': 'u-1',
      'nome': 'Ana Clara',
      'email': 'ana@talentmatch.ai',
      'perfil': 'ADMIN',
    },
    {
      'id': 'u-2',
      'nome': 'Bruno Santos',
      'email': 'bruno@talentmatch.ai',
      'perfil': 'RECRUTADOR',
    },
  ];

  int _vagaSeq = 100;
  int _entrevistaSeq = 2;
  int _usuarioSeq = 3;

  Map<String, dynamic> login(String email, String senha) {
    return {
      'token': 'mock-token',
      'usuario': {
        'nome': email.split('@').first,
        'email': email,
        'perfil': email.contains('admin') ? 'ADMIN' : 'RECRUTADOR',
      },
    };
  }

  Map<String, dynamic> dashboard() {
    final totalVagas = _vagas.where((v) => v['status'] != 'fechada').length;
    final totalCurriculos = _candidatos.fold<int>(0, (acc, c) => acc + (c['qtd_curriculos'] as int));
    final entrevistas = _historico.length;
    final relatorios = _historico.where((e) => e['tem_relatorio'] == true).length;
    return {
      'vagas': totalVagas,
      'curriculos': totalCurriculos,
      'entrevistas': entrevistas,
      'relatorios': relatorios,
      'tendencias': [
        {'label': 'Match alto', 'valor': 68},
        {'label': 'Match médio', 'valor': 22},
        {'label': 'Match baixo', 'valor': 10},
      ],
    };
  }

  List<Map<String, dynamic>> vagas() => List<Map<String, dynamic>>.from(_vagas);

  Map<String, dynamic> criarVaga(Map<String, dynamic> vaga) {
    final nova = {
      ...vaga,
      'id': (++_vagaSeq).toString(),
      'status': vaga['status'] ?? 'aberta',
      'candidatos': vaga['candidatos'] ?? _rand.nextInt(12) + 1,
    };
    _vagas.insert(0, nova);
    return nova;
  }

  List<Map<String, dynamic>> candidatos() => List<Map<String, dynamic>>.from(_candidatos);

  List<Map<String, dynamic>> historico() => List<Map<String, dynamic>>.from(_historico);

  Map<String, dynamic> uploadCurriculo({
    required String filename,
    required Map<String, dynamic>? candidato,
    String? vagaId,
  }) {
    final vaga = _vagas.firstWhere(
      (v) => v['id'] == vagaId,
      orElse: () => _vagas.first,
    );
    final nomeCandidato = (candidato != null && (candidato['nome'] as String?)?.isNotEmpty == true)
        ? candidato['nome'] as String
        : 'Candidato(a) ${_rand.nextInt(50)}';

    final entrevistaId = 'ent-${_entrevistaSeq++}';
    final analise = {
      'summary':
          'Currículo analisado com sucesso. Pontos fortes em ${vaga['tecnologias']}. Experiência alinhada com a vaga.',
      'skills': (vaga['tecnologias'] as String)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'experiences': [
        'Experiência prévia relevante em projetos ${vaga['titulo']}.',
        'Contribuições significativas em equipes ágeis multidisciplinares.',
      ],
      'pontuacao': 80 + _rand.nextInt(15),
    };

    final candidatoInfo = {
      'nome': nomeCandidato,
      'email': '${nomeCandidato.toLowerCase().replaceAll(' ', '.')}@exemplo.com',
    };

    _candidatos.add({
      'id': 'cand-${_candidatos.length + 1}',
      'nome': nomeCandidato,
      'email': candidatoInfo['email'],
      'qtd_curriculos': 1,
      'qtd_entrevistas': 0,
    });

    final entrevista = {
      'id': entrevistaId,
      'candidato': nomeCandidato,
      'vaga': vaga['titulo'],
      'mensagens': [
        {
          'role': 'assistant',
          'conteudo':
              'Olá $nomeCandidato, obrigado pelo interesse na vaga de ${vaga['titulo']}. Vamos iniciar nossa conversa!'
        },
      ],
      'perguntasGeradas': <String>[],
    };
    _entrevistas[entrevistaId] = entrevista;

    _historico.insert(0, {
      'id': entrevistaId,
      'candidato': nomeCandidato,
      'vaga': vaga['titulo'],
      'criado_em': DateTime.now().toUtc().toIso8601String(),
      'tem_relatorio': false,
    });

    return {
      'candidato': candidatoInfo,
      'curriculo': {
        'nome_arquivo': filename,
        'analise_json': analise,
      },
      'vaga': Map<String, dynamic>.from(vaga),
      'entrevista': {'id': entrevistaId},
    };
  }

  List<Map<String, dynamic>> listarMensagens(String entrevistaId) {
    final entrevista = _entrevistas[entrevistaId];
    if (entrevista == null) return [];
    return List<Map<String, dynamic>>.from(entrevista['mensagens'] as List);
  }

  Map<String, dynamic> enviarMensagem(String entrevistaId, String mensagem) {
    final entrevista = _entrevistas[entrevistaId];
    if (entrevista == null) {
      return {
        'resposta': {
          'role': 'assistant',
          'conteudo': 'Contexto da entrevista não encontrado. Utilize o upload de currículo para iniciar uma nova sessão.',
          'criado_em': DateTime.now().toUtc().toIso8601String(),
        }
      };
    }

    final mensagens = entrevista['mensagens'] as List;
    mensagens.add({
      'role': 'user',
      'conteudo': mensagem,
      'criado_em': DateTime.now().toUtc().toIso8601String(),
    });

    final resposta = {
      'role': 'assistant',
      'conteudo':
          'Obrigado pela resposta! Poderia detalhar um exemplo prático relacionado a "${mensagem.split(' ').take(4).join(' ')}"?',
      'criado_em': DateTime.now().toUtc().toIso8601String(),
    };
    mensagens.add(resposta);

    return {'resposta': resposta};
  }

  List<String> gerarPerguntas(String entrevistaId, {int qtd = 8}) {
    final entrevista = _entrevistas[entrevistaId];
    if (entrevista == null) {
      return [
        'Conte sobre um projeto relevante para a vaga.',
        'Quais tecnologias você domina para entregar resultados rapidamente?',
      ];
    }

    final vagaTitulo = entrevista['vaga'] as String? ?? 'a vaga';
    final perguntas = <String>[
      'Qual foi o maior desafio técnico que enfrentou em projetos relacionados a $vagaTitulo?',
      'Como você garante qualidade e testes automatizados no seu trabalho?',
      'Descreva uma situação em que colaborou com times multidisciplinares.',
      'Quais indicadores você monitora para garantir sucesso em $vagaTitulo?',
      'Como você se mantém atualizado(a) sobre tendências relevantes à função?',
    ];

    final geradas = List<String>.generate(
      qtd.clamp(1, perguntas.length),
      (index) => perguntas[index % perguntas.length],
    );

    entrevista['perguntasGeradas'] = geradas;
    return geradas;
  }

  Map<String, dynamic> gerarRelatorio(String entrevistaId) {
    final entrevista = _entrevistas[entrevistaId];
    final candidato = entrevista?['candidato'] as String? ?? 'Candidato';
    final vaga = entrevista?['vaga'] as String? ?? 'Vaga';
    final score = 80 + _rand.nextInt(15);

    final relatorio = {
      'pontuacao_geral': score,
      'recomendacao': score > 85 ? 'Contratar' : 'Manter em pipeline',
      'resumo':
          'O candidato $candidato demonstrou conhecimento consistente para a vaga de $vaga, apresentando boa comunicação e exemplos concretos.',
      'competencias': [
        {'nome': 'Conhecimento Técnico', 'nota': 82 + _rand.nextInt(10)},
        {'nome': 'Experiência Prática', 'nota': 78 + _rand.nextInt(10)},
        {'nome': 'Comunicação', 'nota': 76 + _rand.nextInt(8)},
        {'nome': 'Resolução de Problemas', 'nota': 80 + _rand.nextInt(8)},
        {'nome': 'Fit Cultural', 'nota': 74 + _rand.nextInt(8)},
      ],
      'pontos_fortes': [
        'Boa profundidade técnica em ${entrevista?['vaga'] ?? 'tecnologias da vaga'}.',
        'Respondeu com exemplos claros de impacto no negócio.',
        'Demonstra postura colaborativa e foco em entrega de valor.',
      ],
      'pontos_melhoria': [
        'Detalhar métricas utilizadas para mensurar sucesso.',
        'Explorar experiências recentes com metodologias ágeis.',
      ],
      'respostas_destaque': [
        {
          'pergunta': 'Como você estrutura testes automatizados?',
          'categoria': 'técnica',
          'nota': 8,
          'feedback': 'Apresentou pipeline completo de testes e CI/CD.',
        },
        {
          'pergunta': 'Conte sobre um projeto desafiador.',
          'categoria': 'comportamental',
          'nota': 9,
          'feedback': 'Explicou impacto real e como coordenou a equipe.',
        },
      ],
      'gerado_em': DateTime.now().toUtc().toIso8601String(),
      'candidato': candidato,
      'vaga': vaga,
    };

    _relatorios[entrevistaId] = relatorio;

    final indexHistorico = _historico.indexWhere((e) => e['id'] == entrevistaId);
    if (indexHistorico != -1) {
      _historico[indexHistorico] = {
        ..._historico[indexHistorico],
        'tem_relatorio': true,
      };
    }

    return relatorio;
  }

  Map<String, dynamic> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    String perfil = 'RECRUTADOR',
    Map<String, dynamic>? company,
  }) {
    final novo = {
      'id': 'u-${_usuarioSeq++}',
      'nome': nome,
      'email': email,
      'perfil': perfil,
      if (company != null) 'empresa': company,
    };
    _usuarios.add(novo);
    return novo;
  }
}
