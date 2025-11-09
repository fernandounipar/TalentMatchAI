import 'package:flutter/material.dart';

import '../componentes/tm_button.dart';
import '../componentes/tm_chip.dart';
import '../design_system/tm_tokens.dart';
import '../servicos/api_cliente.dart';
import '../servicos/dados_mockados.dart';

class EntrevistasTela extends StatefulWidget {
  final ApiCliente api;
  final void Function(String candidato, String vaga) onAbrirAssistida;
  final void Function(String candidato, String vaga) onAbrirRelatorio;

  const EntrevistasTela({
    super.key,
    required this.api,
    required this.onAbrirAssistida,
    required this.onAbrirRelatorio,
  });

  @override
  State<EntrevistasTela> createState() => _EntrevistasTelaState();
}

class _EntrevistasTelaState extends State<EntrevistasTela> {
  bool _carregando = true;
  final List<_InterviewCardData> _itens = [];
  final Set<int> _hovered = <int>{};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      // Agendadas a partir dos candidatos com status "Entrevista Agendada"
      final candidatosResp = await widget.api.candidatos();
      final candidatos = candidatosResp.whereType<Map<String, dynamic>>().toList();
      final agendadas = candidatos.where((c) => (c['status']?.toString() ?? '') == 'Entrevista Agendada');

      for (final c in agendadas) {
        final nome = c['nome']?.toString() ?? 'Candidato(a)';
        final vagaId = c['vagaId']?.toString();
        final vagaTitulo = _vagaTituloPorId(vagaId) ?? 'Vaga';
        final criadoEm = c['criadoEm'] is DateTime
            ? c['criadoEm'] as DateTime
            : (c['createdAt'] is DateTime ? c['createdAt'] as DateTime : DateTime.now());
        final quando = DateTime(criadoEm.year, criadoEm.month, criadoEm.day).add(const Duration(days: 10)).add(const Duration(hours: 14));

        _itens.add(
          _InterviewCardData(
            tipo: _InterviewType.scheduled,
            candidato: nome,
            vaga: vagaTitulo,
            status: 'Agendada',
            quando: quando,
            duracaoMin: null,
            perguntas: 3,
            rating: null,
          ),
        );
      }

      // Concluídas via histórico com tem_relatorio = true
      final historicoResp = await widget.api.historico();
      final historico = historicoResp.whereType<Map<String, dynamic>>().toList();
      for (final h in historico.where((e) => e['tem_relatorio'] == true)) {
        final nome = h['candidato']?.toString() ?? 'Candidato';
        final vaga = h['vaga']?.toString() ?? 'Vaga';
        final criado = DateTime.tryParse(h['criado_em']?.toString() ?? '') ?? DateTime.now().subtract(const Duration(days: 1));

        _itens.add(
          _InterviewCardData(
            tipo: _InterviewType.concluded,
            candidato: nome,
            vaga: vaga,
            status: 'Concluída',
            quando: criado,
            duracaoMin: 60,
            perguntas: 2,
            rating: 4.5,
          ),
        );
      }

      // Ordena: agendadas primeiro, depois recentes
      _itens.sort((a, b) {
        if (a.tipo != b.tipo) return a.tipo.index.compareTo(b.tipo.index);
        return (b.quando ?? DateTime(0)).compareTo(a.quando ?? DateTime(0));
      });
    } catch (_) {
      // fallback silencioso já que usamos mocks via ApiCliente
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String? _vagaTituloPorId(String? vagaId) {
    if (vagaId == null) return null;
    try {
      final v = mockVagas.firstWhere((e) => e.id == vagaId);
      return v.titulo;
    } catch (_) {
      return null;
    }
  }

  String _formatarDataPt(DateTime d) {
    const meses = ['jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', 'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'];
    final dia = d.day.toString().padLeft(2, '0');
    final mes = meses[d.month - 1];
    final ano = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$dia de $mes de $ano, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1024 ? 2 : 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact: width < 720),
              const SizedBox(height: 24),
              if (_itens.isEmpty)
                _buildEmptyState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: _itens.length,
                  itemBuilder: (context, index) => _buildCard(_itens[index], index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final content = <Widget>[
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrevistas',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TMTokens.text),
            ),
            SizedBox(height: 4),
            Text(
              'Gerencie e conduza entrevistas assistidas por IA',
              style: TextStyle(fontSize: 16, color: TMTokens.textMuted),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      TMButton(
        'Agendar Entrevista',
        icon: Icons.add,
        onPressed: () {
          // Navega para a tela assistida com um contexto padrão
          final candidato = _itens.where((e) => e.tipo == _InterviewType.scheduled).map((e) => e.candidato).firstOrNull ?? 'João Silva';
          final vaga = _itens.where((e) => e.tipo == _InterviewType.scheduled).map((e) => e.vaga).firstOrNull ?? 'Desenvolvedor Full Stack';
          widget.onAbrirAssistida(candidato, vaga);
        },
      ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Entrevistas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TMTokens.text)),
          const SizedBox(height: 4),
          const Text('Gerencie e conduza entrevistas assistidas por IA', style: TextStyle(fontSize: 16, color: TMTokens.textMuted)),
          const SizedBox(height: 16),
          TMButton('Agendar Entrevista', icon: Icons.add, onPressed: () {
            final candidato = _itens.where((e) => e.tipo == _InterviewType.scheduled).map((e) => e.candidato).firstOrNull ?? 'João Silva';
            final vaga = _itens.where((e) => e.tipo == _InterviewType.scheduled).map((e) => e.vaga).firstOrNull ?? 'Desenvolvedor Full Stack';
            widget.onAbrirAssistida(candidato, vaga);
          }),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildCard(_InterviewCardData item, int index) {
    final isHovered = _hovered.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered.add(index)),
      onExit: (_) => setState(() => _hovered.remove(index)),
      child: Card(
        elevation: isHovered ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (item.tipo == _InterviewType.scheduled) {
              widget.onAbrirAssistida(item.candidato, item.vaga);
            } else {
              widget.onAbrirRelatorio(item.candidato, item.vaga);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: TMTokens.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.candidato, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: TMTokens.text)),
                          const SizedBox(height: 4),
                          Text(item.vaga, style: const TextStyle(fontSize: 13, color: TMTokens.textMuted)),
                        ],
                      ),
                    ),
                    TMChip.interviewStatus(item.status),
                  ],
                ),
                const SizedBox(height: 16),
                // Meta
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (item.quando != null)
                      _meta(Icons.calendar_month, _formatarDataPt(item.quando!)),
                    if (item.duracaoMin != null)
                      _meta(Icons.access_time, '${item.duracaoMin} minutos'),
                    if (item.perguntas != null)
                      _meta(Icons.message_outlined, '${item.perguntas} perguntas'),
                  ],
                ),
                if (item.rating != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: TMTokens.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text('${item.rating!.toStringAsFixed(1)} / 5.0', style: const TextStyle(color: TMTokens.text)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: TMTokens.textMuted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: TMTokens.textMuted)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Nenhuma entrevista encontrada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TMTokens.text)),
              const SizedBox(height: 8),
              const Text('Agende uma nova entrevista para começar', style: TextStyle(fontSize: 14, color: TMTokens.textMuted)),
              const SizedBox(height: 16),
              TMButton('Agendar Entrevista', icon: Icons.add, onPressed: () {
                widget.onAbrirAssistida('João Silva', 'Desenvolvedor Full Stack');
              }),
            ],
          ),
        ),
      ),
    );
  }
}

enum _InterviewType { scheduled, concluded }

class _InterviewCardData {
  final _InterviewType tipo;
  final String candidato;
  final String vaga;
  final String status; // Agendada, Em Andamento, Concluída, Cancelada
  final DateTime? quando;
  final int? duracaoMin;
  final int? perguntas;
  final double? rating;

  _InterviewCardData({
    required this.tipo,
    required this.candidato,
    required this.vaga,
    required this.status,
    this.quando,
    this.duracaoMin,
    this.perguntas,
    this.rating,
  });
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
