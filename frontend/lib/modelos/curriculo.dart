/// Modelo de Currículo
class Curriculo {
  final String id;
  final String candidatoId;
  final String? vagaId;
  final String nomeArquivo;
  final String caminhoArquivo;
  final String? textoExtraido;
  final Map<String, dynamic>? analiseIa;
  final double? pontuacao;
  final DateTime criadoEm;

  Curriculo({
    required this.id,
    required this.candidatoId,
    this.vagaId,
    required this.nomeArquivo,
    required this.caminhoArquivo,
    this.textoExtraido,
    this.analiseIa,
    this.pontuacao,
    required this.criadoEm,
  });

  factory Curriculo.fromJson(Map<String, dynamic> json) {
    return Curriculo(
      id: json['id'].toString(),
      candidatoId: json['candidato_id'].toString(),
      vagaId: json['vaga_id']?.toString(),
      nomeArquivo: json['nome_arquivo'] as String,
      caminhoArquivo: json['caminho_arquivo'] as String,
      textoExtraido: json['texto_extraido'] as String?,
      analiseIa: json['analise_ia'] as Map<String, dynamic>?,
      pontuacao: (json['pontuacao'] as num?)?.toDouble(),
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidato_id': candidatoId,
      'vaga_id': vagaId,
      'nome_arquivo': nomeArquivo,
      'caminho_arquivo': caminhoArquivo,
      'texto_extraido': textoExtraido,
      'analise_ia': analiseIa,
      'pontuacao': pontuacao,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
