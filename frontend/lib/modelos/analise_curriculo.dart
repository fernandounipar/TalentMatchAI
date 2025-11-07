class AderenciaRequisito {
  final String requisito;
  final int score;
  final List<String> evidencias;

  const AderenciaRequisito({
    required this.requisito,
    required this.score,
    required this.evidencias,
  });

  factory AderenciaRequisito.fromJson(Map<String, dynamic> json) {
    return AderenciaRequisito(
      requisito: json['requisito']?.toString() ?? '',
      score: json['score'] is int
          ? json['score'] as int
          : int.tryParse(json['score']?.toString() ?? '') ?? 0,
      evidencias: (json['evidencias'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requisito': requisito,
      'score': score,
      'evidencias': evidencias,
    };
  }
}

class AnaliseCurriculo {
  final int matchingScore;
  final String recomendacao;
  final String resumo;
  final List<String> pontosFortes;
  final List<String> pontosAtencao;
  final List<AderenciaRequisito> aderenciaRequisitos;

  const AnaliseCurriculo({
    required this.matchingScore,
    required this.recomendacao,
    required this.resumo,
    required this.pontosFortes,
    required this.pontosAtencao,
    required this.aderenciaRequisitos,
  });

  factory AnaliseCurriculo.fromJson(Map<String, dynamic> json) {
    return AnaliseCurriculo(
      matchingScore: json['matchingScore'] is int
          ? json['matchingScore'] as int
          : int.tryParse(json['matchingScore']?.toString() ?? '') ?? 0,
      recomendacao: json['recomendacao']?.toString() ?? '',
      resumo: json['resumo']?.toString() ?? '',
      pontosFortes: (json['pontosFortes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pontosAtencao: (json['pontosAtencao'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aderenciaRequisitos: (json['aderenciaRequisitos'] as List?)
              ?.map((item) => AderenciaRequisito.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchingScore': matchingScore,
      'recomendacao': recomendacao,
      'resumo': resumo,
      'pontosFortes': pontosFortes,
      'pontosAtencao': pontosAtencao,
      'aderenciaRequisitos':
          aderenciaRequisitos.map((item) => item.toJson()).toList(),
    };
  }
}
