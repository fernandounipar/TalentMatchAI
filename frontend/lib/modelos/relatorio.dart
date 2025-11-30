/// Modelo de Relatório de Entrevista
class Relatorio {
  final String id;
  final String entrevistaId;
  final String candidatoNome;
  final String vagaTitulo;
  final double pontuacaoGeral;
  final String recomendacao; // 'aprovar', 'dúvida', 'reprovar'
  final Map<String, dynamic> analiseDetalhada;
  final List<String> pontosFortes;
  final List<String> pontosMelhoria;
  final String? observacoes;
  final DateTime geradoEm;

  Relatorio({
    required this.id,
    required this.entrevistaId,
    required this.candidatoNome,
    required this.vagaTitulo,
    required this.pontuacaoGeral,
    required this.recomendacao,
    required this.analiseDetalhada,
    required this.pontosFortes,
    required this.pontosMelhoria,
    this.observacoes,
    required this.geradoEm,
  });

  factory Relatorio.fromJson(Map<String, dynamic> json) {
    return Relatorio(
      id: json['id'].toString(),
      entrevistaId: json['entrevista_id'].toString(),
      candidatoNome: json['candidato_nome'] as String,
      vagaTitulo: json['vaga_titulo'] as String,
      pontuacaoGeral: (json['pontuacao_geral'] as num).toDouble(),
      recomendacao: json['recomendacao'] as String,
      analiseDetalhada: json['analise_detalhada'] as Map<String, dynamic>,
      pontosFortes: List<String>.from(json['pontos_fortes'] as List),
      pontosMelhoria: List<String>.from(json['pontos_melhoria'] as List),
      observacoes: json['observacoes'] as String?,
      geradoEm: DateTime.parse(json['gerado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrevista_id': entrevistaId,
      'candidato_nome': candidatoNome,
      'vaga_titulo': vagaTitulo,
      'pontuacao_geral': pontuacaoGeral,
      'recomendacao': recomendacao,
      'analise_detalhada': analiseDetalhada,
      'pontos_fortes': pontosFortes,
      'pontos_melhoria': pontosMelhoria,
      'observacoes': observacoes,
      'gerado_em': geradoEm.toIso8601String(),
    };
  }
}
