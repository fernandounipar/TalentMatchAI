import 'package:intl/intl.dart';

/// Utilitario para manipulacao de datas no fuso horario de Brasilia (America/Sao_Paulo)
/// UTC-3 (horario padrao)
class DateUtils {
  static final Duration _brasiliaOffset = const Duration(hours: -3);

  /// Retorna a data/hora atual no fuso horario de Brasilia
  static DateTime agora() {
    final utc = DateTime.now().toUtc();
    return utc.add(_brasiliaOffset);
  }

  /// Converte uma data UTC para o fuso de Brasilia
  static DateTime? paraHorarioBrasilia(DateTime? date) {
    if (date == null) return null;
    final utc = date.toUtc();
    return utc.add(_brasiliaOffset);
  }

  /// Converte uma string ISO para DateTime no fuso de Brasilia
  static DateTime? parseParaBrasilia(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final parsed = DateTime.parse(dateString);
      return paraHorarioBrasilia(parsed);
    } catch (e) {
      return null;
    }
  }

  /// Converte uma data de Brasilia para UTC
  static DateTime? paraUTC(DateTime? date) {
    if (date == null) return null;
    return date.subtract(_brasiliaOffset);
  }

  /// Formata uma data para string ISO com offset de Brasilia (-03:00)
  static String? formatarParaISO(DateTime? date) {
    if (date == null) return null;
    final brasilia = paraHorarioBrasilia(date);
    if (brasilia == null) return null;

    final formatted = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(brasilia);
    return '$formatted-03:00';
  }

  /// Formata uma data para exibicao no formato brasileiro
  /// Exemplo: "30/11/2025 14:30" ou "30/11/2025"
  static String formatarParaExibicao(DateTime? date, {bool incluirHora = true}) {
    if (date == null) return '';
    final brasilia = paraHorarioBrasilia(date);
    if (brasilia == null) return '';

    if (incluirHora) {
      return DateFormat('dd/MM/yyyy HH:mm').format(brasilia);
    }
    return DateFormat('dd/MM/yyyy').format(brasilia);
  }

  /// Formata uma data para exibicao relativa (ex: "ha 5 minutos", "ontem")
  static String formatarRelativo(DateTime? date) {
    if (date == null) return '';
    final brasilia = paraHorarioBrasilia(date);
    if (brasilia == null) return '';

    final now = agora();
    final diff = now.difference(brasilia);

    if (diff.inSeconds < 60) {
      return 'agora';
    } else if (diff.inMinutes < 60) {
      final min = diff.inMinutes;
      return 'ha $min ${min == 1 ? 'minuto' : 'minutos'}';
    } else if (diff.inHours < 24) {
      final hrs = diff.inHours;
      return 'ha $hrs ${hrs == 1 ? 'hora' : 'horas'}';
    } else if (diff.inDays == 1) {
      return 'ontem';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return 'ha $days dias';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'ha $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return 'ha $months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (diff.inDays / 365).floor();
      return 'ha $years ${years == 1 ? 'ano' : 'anos'}';
    }
  }

  /// Retorna o inicio do dia atual em Brasilia (00:00:00)
  static DateTime inicioDoDia() {
    final hoje = agora();
    return DateTime(hoje.year, hoje.month, hoje.day);
  }

  /// Retorna o fim do dia atual em Brasilia (23:59:59.999)
  static DateTime fimDoDia() {
    final hoje = agora();
    return DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59, 999);
  }

  /// Verifica se uma data ja expirou (comparando com agora em Brasilia)
  static bool jaExpirou(DateTime? dataExpiracao) {
    if (dataExpiracao == null) return true;
    return agora().isAfter(paraHorarioBrasilia(dataExpiracao)!);
  }

  /// Formata duracao em minutos para exibicao legivel
  /// Exemplo: 90 -> "1h 30min"
  static String formatarDuracao(int? minutos) {
    if (minutos == null || minutos <= 0) return '';
    
    if (minutos < 60) {
      return '${minutos}min';
    }
    
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    
    if (mins == 0) {
      return '${horas}h';
    }
    return '${horas}h ${mins}min';
  }
}
