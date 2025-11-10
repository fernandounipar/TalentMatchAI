// Classes auxiliares
class ExperienciaProfissional {
  final String cargo;
  final String empresa;
  final String periodo;
  final String descricao;

  ExperienciaProfissional({
    required this.cargo,
    required this.empresa,
    required this.periodo,
    required this.descricao,
  });

  factory ExperienciaProfissional.fromJson(Map<String, dynamic> json) {
    return ExperienciaProfissional(
      cargo: json['cargo']?.toString() ?? '',
      empresa: json['empresa']?.toString() ?? '',
      periodo: json['periodo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo': cargo,
      'empresa': empresa,
      'periodo': periodo,
      'descricao': descricao,
    };
  }
}

class Educacao {
  final String curso;
  final String instituicao;
  final String periodo;
  final String tipo; // 'Graduação', 'Pós-graduação', 'Mestrado', 'Doutorado', 'Técnico'

  Educacao({
    required this.curso,
    required this.instituicao,
    required this.periodo,
    required this.tipo,
  });

  factory Educacao.fromJson(Map<String, dynamic> json) {
    return Educacao(
      curso: json['curso']?.toString() ?? '',
      instituicao: json['instituicao']?.toString() ?? '',
      periodo: json['periodo']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'Graduação',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curso': curso,
      'instituicao': instituicao,
      'periodo': periodo,
      'tipo': tipo,
    };
  }
}

/// Modelo de Candidato (Estendido para compatibilidade com Figma)
class Candidato {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? linkedinUrl;
  final String? githubUrl;
  final int qtdCurriculos;
  final int qtdEntrevistas;
  final DateTime criadoEm;

  // Campos adicionais do Figma
  final String? github; // Alias para githubUrl
  final String? linkedin; // Alias para linkedinUrl
  final String? status; // 'Novo', 'Em Análise', 'Entrevista Agendada', 'Aprovado', 'Reprovado'
  final String? vagaId;
  final int? matchingScore;
  final List<ExperienciaProfissional>? experiencia;
  final List<Educacao>? educacao;
  final List<String>? skills;
  final DateTime? createdAt; // Alias para criadoEm

  Candidato({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.linkedinUrl,
    this.githubUrl,
    this.qtdCurriculos = 0,
    this.qtdEntrevistas = 0,
    required this.criadoEm,
    // Campos adicionais
    this.github,
    this.linkedin,
    this.status,
    this.vagaId,
    this.matchingScore,
    this.experiencia,
    this.educacao,
    this.skills,
    this.createdAt,
  });

  factory Candidato.fromJson(Map<String, dynamic> json) {
    // Parse experiência
    List<ExperienciaProfissional>? experienciaList;
    if (json['experiencia'] is List) {
      experienciaList = (json['experiencia'] as List)
          .map((e) => ExperienciaProfissional.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse educação
    List<Educacao>? educacaoList;
    if (json['educacao'] is List) {
      educacaoList = (json['educacao'] as List)
          .map((e) => Educacao.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse skills
    List<String>? skillsList;
    if (json['skills'] is List) {
      skillsList = (json['skills'] as List).map((e) => e.toString()).toList();
    }

    final fullName = json['nome'] ?? json['full_name'] ?? json['fullName'];
    return Candidato(
      id: json['id'].toString(),
      nome: fullName is String ? fullName : fullName?.toString() ?? '',
      email: json['email'] as String,
      telefone: json['telefone'] as String?,
      linkedinUrl: json['linkedin_url'] as String? ?? json['linkedin'] as String?,
      githubUrl: json['github_url'] as String? ?? json['github'] as String?,
      qtdCurriculos: json['qtd_curriculos'] as int? ?? 0,
      qtdEntrevistas: json['qtd_entrevistas'] as int? ?? 0,
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      // Campos adicionais
      github: json['github'] as String?,
      linkedin: json['linkedin'] as String?,
      status: json['status'] as String?,
      vagaId: json['vagaId'] as String?,
      matchingScore: json['matchingScore'] as int?,
      experiencia: experienciaList,
      educacao: educacaoList,
      skills: skillsList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'linkedin_url': linkedinUrl,
      'github_url': githubUrl,
      'qtd_curriculos': qtdCurriculos,
      'qtd_entrevistas': qtdEntrevistas,
      'criado_em': criadoEm.toIso8601String(),
      if (github != null) 'github': github,
      if (linkedin != null) 'linkedin': linkedin,
      if (status != null) 'status': status,
      if (vagaId != null) 'vagaId': vagaId,
      if (matchingScore != null) 'matchingScore': matchingScore,
      if (experiencia != null)
        'experiencia': experiencia!.map((e) => e.toJson()).toList(),
      if (educacao != null) 'educacao': educacao!.map((e) => e.toJson()).toList(),
      if (skills != null) 'skills': skills,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
