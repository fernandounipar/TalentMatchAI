/// Modelo de Vaga
class Vaga {
  final String id;
  final String titulo;
  final String descricao;
  final String requisitos;
  final String status; // 'aberta', 'fechada', 'pausada'
  final String? tecnologias;
  final String? nivel; // 'junior', 'pleno', 'senior'
  final DateTime criadoEm;

  Vaga({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.requisitos,
    this.status = 'aberta',
    this.tecnologias,
    this.nivel,
    required this.criadoEm,
  });

  factory Vaga.fromJson(Map<String, dynamic> json) {
    return Vaga(
      id: json['id'].toString(),
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      requisitos: json['requisitos'] as String,
      status: json['status'] as String? ?? 'aberta',
      tecnologias: json['tecnologias'] as String?,
      nivel: json['nivel'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'requisitos': requisitos,
      'status': status,
      'tecnologias': tecnologias,
      'nivel': nivel,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
