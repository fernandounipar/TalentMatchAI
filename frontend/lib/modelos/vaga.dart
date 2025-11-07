/// Modelo de Vaga (Estendido para compatibilidade com Figma)
class Vaga {
  final String id;
  final String titulo;
  final String descricao;
  final String requisitos; // String ou será convertido de List
  final String status; // 'Aberta', 'Fechada', 'Pausada'
  final String? tecnologias;
  final String? nivel; // 'Junior', 'Pleno', 'Senior', 'Especialista'
  final DateTime criadoEm;
  
  // Campos adicionais do Figma
  final List<String>? requisitosList;
  final String? senioridade; // Alias para nivel
  final String? regime; // 'CLT', 'PJ', 'Estágio', 'Temporário'
  final String? local;
  final String? salario;
  final List<String>? tags;
  final int? candidatos;
  final DateTime? createdAt; // Alias para criadoEm

  Vaga({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.requisitos,
    this.status = 'Aberta',
    this.tecnologias,
    this.nivel,
    required this.criadoEm,
    // Campos adicionais
    this.requisitosList,
    this.senioridade,
    this.regime,
    this.local,
    this.salario,
    this.tags,
    this.candidatos,
    this.createdAt,
  });

  // Constructor nomeado para criar vagas com campos estendidos
  factory Vaga.create({
    required String id,
    required String titulo,
    required String descricao,
    required List<String> requisitos,
    String status = 'Aberta',
    String? senioridade,
    String? regime,
    String? local,
    String? salario,
    List<String>? tags,
    DateTime? createdAt,
    int? candidatos,
  }) {
    return Vaga(
      id: id,
      titulo: titulo,
      descricao: descricao,
      requisitos: requisitos.join('\n'),
      status: status,
      criadoEm: createdAt ?? DateTime.now(),
      requisitosList: requisitos,
      senioridade: senioridade,
      regime: regime,
      local: local,
      salario: salario,
      tags: tags,
      candidatos: candidatos,
      createdAt: createdAt,
    );
  }

  // Getters de conveniência
  String get nivelExibicao => senioridade ?? nivel ?? 'Não especificado';
  DateTime get dataCriacao => createdAt ?? criadoEm;
  List<String> get requisitosLista => requisitosList ?? [requisitos];

  factory Vaga.fromJson(Map<String, dynamic> json) {
    // Suporta ambos os formatos (API e Mock)
    final reqList = json['requisitos'];
    String reqString;
    List<String>? reqListFinal;

    if (reqList is List) {
      reqListFinal = reqList.map((e) => e.toString()).toList();
      reqString = reqListFinal.join('\n');
    } else {
      reqString = reqList?.toString() ?? '';
      reqListFinal = reqString.split('\n').where((e) => e.trim().isNotEmpty).toList();
    }

    final tagsList = json['tags'];
    List<String>? tagsListFinal;
    if (tagsList is List) {
      tagsListFinal = tagsList.map((e) => e.toString()).toList();
    }

    return Vaga(
      id: json['id'].toString(),
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      requisitos: reqString,
      status: json['status'] as String? ?? 'Aberta',
      tecnologias: json['tecnologias'] as String?,
      nivel: json['nivel'] as String?,
      criadoEm: json['criado_em'] != null 
          ? DateTime.parse(json['criado_em'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      requisitosList: reqListFinal,
      senioridade: json['senioridade'] as String?,
      regime: json['regime'] as String?,
      local: json['local'] as String?,
      salario: json['salario'] as String?,
      tags: tagsListFinal,
      candidatos: json['candidatos'] as int?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
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
      if (requisitosList != null) 'requisitosList': requisitosList,
      if (senioridade != null) 'senioridade': senioridade,
      if (regime != null) 'regime': regime,
      if (local != null) 'local': local,
      if (salario != null) 'salario': salario,
      if (tags != null) 'tags': tags,
      if (candidatos != null) 'candidatos': candidatos,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
