import 'package:flutter/material.dart';

/// TalentMatchIA Design Tokens
/// Centraliza cores, espaçamentos, raios e sombras
class TMTokens {
  // Cores principais (tema claro)
  static const Color primary = Color(0xFF2B6CB0); // Azul principal
  static const Color secondary = Color(0xFF667085); // Cinza azulado (texto secundário)
  static const Color emphasis = Color(0xFF22C55E); // Ênfase (sucesso)

  // Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF0EA5E9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // Neutros
  static const Color bg = Color(0xFFF8FAFC); // fundo
  static const Color surface = Colors.white; // cartões
  static const Color border = Color(0xFFE5E7EB);
  static const Color text = Color(0xFF101828);
  static const Color textMuted = Color(0xFF475467);

  // Espaçamentos
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  // Raios
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;

  // Sombras (light)
  static const List<BoxShadow> shadowXSmall = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    )
  ];
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    )
  ];
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    )
  ];
}

/// Mapeamento de status → cores para Badges/Chips
class TMStatusColors {
  // Vagas
  static const Map<String, Color> jobBg = {
    // Vagas: cores seguindo o Figma (green/yellow/gray)
    'Aberta': Color(0xFFDCFCE7), // green-100
    'Pausada': Color(0xFFFEF9C3), // yellow-100
    'Fechada': Color(0xFFF3F4F6), // gray-100
    'Concluída': Color(0xFFDCFCE7),
  };
  static const Map<String, Color> jobFg = {
    'Aberta': Color(0xFF166534), // green-800
    'Pausada': Color(0xFF854D0E), // yellow-800
    'Fechada': Color(0xFF1F2937), // gray-800
    'Concluída': Color(0xFF166534),
  };

  // Candidatos
  static const Map<String, Color> candidateBg = {
    'Novo': Color(0xFFDBEAFE), // blue-100
    'Em análise': Color(0xFFFEFCE8), // yellow-100 (variação minúscula)
    'Em Análise': Color(0xFFFEF9C3), // yellow-100 (variação título)
    'Entrevista Agendada': Color(0xFFEDE9FE), // purple-100
    'Reprovado': Color(0xFFFEF2F2), // red-100
    'Aprovado': Color(0xFFF0FDF4), // green-100
  };
  static const Map<String, Color> candidateFg = {
    'Novo': Color(0xFF1E40AF), // blue-800
    'Em análise': Color(0xFFA16207), // yellow-700/800
    'Em Análise': Color(0xFFA16207),
    'Entrevista Agendada': Color(0xFF6B21A8), // purple-800
    'Reprovado': Color(0xFFB91C1C), // red-700/800
    'Aprovado': Color(0xFF15803D), // green-700/800
  };

  // Entrevistas
  static const Map<String, Color> interviewBg = {
    'Agendada': Color(0xFFDBEAFE), // blue-100
    'Em Andamento': Color(0xFFFEF9C3), // yellow-100
    'Concluída': Color(0xFFD1FAE5), // green-100
    'Cancelada': Color(0xFFFEE2E2), // red-100
  };
  static const Map<String, Color> interviewFg = {
    'Agendada': Color(0xFF1E40AF), // blue-800
    'Em Andamento': Color(0xFFA16207), // yellow-800
    'Concluída': Color(0xFF166534), // green-800
    'Cancelada': Color(0xFF991B1B), // red-800
  };
}
