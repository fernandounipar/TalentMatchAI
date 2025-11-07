class DashboardStats {
  final int vagasAtivas;
  final int candidatosTotal;
  final int entrevistasAgendadas;
  final int aprovadosMes;
  final double tendenciaVagas;
  final double tendenciaCandidatos;
  final double tendenciaEntrevistas;
  final double tendenciaAprovados;

  DashboardStats({
    required this.vagasAtivas,
    required this.candidatosTotal,
    required this.entrevistasAgendadas,
    required this.aprovadosMes,
    required this.tendenciaVagas,
    required this.tendenciaCandidatos,
    required this.tendenciaEntrevistas,
    required this.tendenciaAprovados,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      vagasAtivas: json['vagasAtivas'] ?? 0,
      candidatosTotal: json['candidatosTotal'] ?? 0,
      entrevistasAgendadas: json['entrevistasAgendadas'] ?? 0,
      aprovadosMes: json['aprovadosMes'] ?? 0,
      tendenciaVagas: (json['tendenciaVagas'] ?? 0).toDouble(),
      tendenciaCandidatos: (json['tendenciaCandidatos'] ?? 0).toDouble(),
      tendenciaEntrevistas: (json['tendenciaEntrevistas'] ?? 0).toDouble(),
      tendenciaAprovados: (json['tendenciaAprovados'] ?? 0).toDouble(),
    );
  }
}

class FunilEtapa {
  final String etapa;
  final int valor;
  final String cor;

  FunilEtapa({
    required this.etapa,
    required this.valor,
    required this.cor,
  });

  factory FunilEtapa.fromJson(Map<String, dynamic> json) {
    return FunilEtapa(
      etapa: json['etapa']?.toString() ?? '',
      valor: json['valor'] ?? 0,
      cor: json['cor']?.toString() ?? '#3B82F6',
    );
  }
}

class DadosGrafico {
  final String mes;
  final int candidatos;
  final int entrevistas;
  final int aprovados;

  DadosGrafico({
    required this.mes,
    required this.candidatos,
    required this.entrevistas,
    required this.aprovados,
  });

  factory DadosGrafico.fromJson(Map<String, dynamic> json) {
    return DadosGrafico(
      mes: json['mes']?.toString() ?? '',
      candidatos: json['candidatos'] ?? 0,
      entrevistas: json['entrevistas'] ?? 0,
      aprovados: json['aprovados'] ?? 0,
    );
  }
}
