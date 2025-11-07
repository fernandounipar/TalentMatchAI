class AtividadeHistorico {
  final String id;
  final String tipo; // 'Upload' | 'Análise' | 'Entrevista' | 'Aprovação' | 'Reprovação' | 'Edição'
  final String descricao;
  final String usuario;
  final DateTime data;
  final String entidade; // 'Vaga' | 'Candidato' | 'Entrevista'
  final String entidadeId;

  AtividadeHistorico({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.usuario,
    required this.data,
    required this.entidade,
    required this.entidadeId,
  });

  factory AtividadeHistorico.fromJson(Map<String, dynamic> json) {
    return AtividadeHistorico(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'Edição',
      descricao: json['descricao']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      data: json['data'] != null ? DateTime.parse(json['data'].toString()) : DateTime.now(),
      entidade: json['entidade']?.toString() ?? 'Candidato',
      entidadeId: json['entidadeId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'usuario': usuario,
      'data': data.toIso8601String(),
      'entidade': entidade,
      'entidadeId': entidadeId,
    };
  }

  String get icone {
    switch (tipo) {
      case 'Upload':
        return '📄';
      case 'Análise':
        return '🤖';
      case 'Entrevista':
        return '📅';
      case 'Aprovação':
        return '✅';
      case 'Reprovação':
        return '❌';
      case 'Edição':
        return '✏️';
      default:
        return '📌';
    }
  }

  String formatTempoDecorrido() {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inHours < 1) {
      final minutos = diferenca.inMinutes;
      return minutos < 1 ? 'Agora há pouco' : 'Há ${minutos}min';
    }
    if (diferenca.inHours < 24) return 'Há ${diferenca.inHours}h';
    final dias = diferenca.inDays;
    if (dias == 1) return 'Ontem';
    if (dias < 7) return 'Há $dias dias';
    if (dias < 30) return 'Há ${(dias / 7).floor()} semanas';
    return 'Há ${(dias / 30).floor()} meses';
  }
}
