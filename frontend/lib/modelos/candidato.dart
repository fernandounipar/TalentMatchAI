/// Modelo de Candidato
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
  });

  factory Candidato.fromJson(Map<String, dynamic> json) {
    return Candidato(
      id: json['id'].toString(),
      nome: json['nome'] as String,
      email: json['email'] as String,
      telefone: json['telefone'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      githubUrl: json['github_url'] as String?,
      qtdCurriculos: json['qtd_curriculos'] as int? ?? 0,
      qtdEntrevistas: json['qtd_entrevistas'] as int? ?? 0,
      criadoEm: DateTime.parse(json['criado_em'] as String),
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
    };
  }
}
