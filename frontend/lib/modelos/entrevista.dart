/// Modelo de Entrevista
class Entrevista {
  final String id;
  final String candidatoId;
  final String vagaId;
  final String? curriculoId;
  final String status; // 'agendada', 'em_andamento', 'concluida', 'cancelada'
  final DateTime? dataHora;
  final List<Pergunta>? perguntas;
  final Map<String, dynamic>? avaliacaoFinal;
  final String? observacoes;
  final DateTime criadoEm;

  Entrevista({
    required this.id,
    required this.candidatoId,
    required this.vagaId,
    this.curriculoId,
    this.status = 'agendada',
    this.dataHora,
    this.perguntas,
    this.avaliacaoFinal,
    this.observacoes,
    required this.criadoEm,
  });

  factory Entrevista.fromJson(Map<String, dynamic> json) {
    return Entrevista(
      id: json['id'].toString(),
      candidatoId: json['candidato_id'].toString(),
      vagaId: json['vaga_id'].toString(),
      curriculoId: json['curriculo_id']?.toString(),
      status: json['status'] as String? ?? 'agendada',
      dataHora: json['data_hora'] != null ? DateTime.parse(json['data_hora'] as String) : null,
      perguntas: json['perguntas'] != null
          ? (json['perguntas'] as List).map((p) => Pergunta.fromJson(p)).toList()
          : null,
      avaliacaoFinal: json['avaliacao_final'] as Map<String, dynamic>?,
      observacoes: json['observacoes'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidato_id': candidatoId,
      'vaga_id': vagaId,
      'curriculo_id': curriculoId,
      'status': status,
      'data_hora': dataHora?.toIso8601String(),
      'perguntas': perguntas?.map((p) => p.toJson()).toList(),
      'avaliacao_final': avaliacaoFinal,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}

/// Modelo de Pergunta para Entrevista
class Pergunta {
  final String id;
  final String texto;
  final String categoria; // 'tecnica', 'comportamental', 'situacional'
  final String? resposta;
  final Map<String, dynamic>? avaliacaoIa;
  final int? pontuacao;

  Pergunta({
    required this.id,
    required this.texto,
    this.categoria = 'tecnica',
    this.resposta,
    this.avaliacaoIa,
    this.pontuacao,
  });

  factory Pergunta.fromJson(Map<String, dynamic> json) {
    return Pergunta(
      id: json['id'].toString(),
      texto: json['texto'] as String,
      categoria: json['categoria'] as String? ?? 'tecnica',
      resposta: json['resposta'] as String?,
      avaliacaoIa: json['avaliacao_ia'] as Map<String, dynamic>?,
      pontuacao: json['pontuacao'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
      'categoria': categoria,
      'resposta': resposta,
      'avaliacao_ia': avaliacaoIa,
      'pontuacao': pontuacao,
    };
  }
}
