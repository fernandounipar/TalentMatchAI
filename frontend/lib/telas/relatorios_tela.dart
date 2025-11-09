import 'package:flutter/material.dart';

import '../componentes/tm_button.dart';
import '../componentes/tm_chip.dart';
import '../design_system/tm_tokens.dart';
import '../servicos/api_cliente.dart';

class RelatoriosTela extends StatefulWidget {
  final ApiCliente api;
  final void Function(String candidato, String vaga) onAbrirRelatorio;

  const RelatoriosTela({
    super.key,
    required this.api,
    required this.onAbrirRelatorio,
  });

  @override
  State<RelatoriosTela> createState() => _RelatoriosTelaState();
}

class _RelatoriosTelaState extends State<RelatoriosTela> {
  bool _carregando = true;
  final List<_ReportItem> _itens = [];
  final Set<int> _hovered = <int>{};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final hist = await widget.api.historico();
      final comRelatorio = hist.whereType<Map<String, dynamic>>()
          .where((e) => e['tem_relatorio'] == true)
          .toList();
      _itens
        ..clear()
        ..addAll(comRelatorio.map((e) {
          final candidato = e['candidato']?.toString() ?? 'Candidato';
          final vaga = e['vaga']?.toString() ?? 'Vaga';
          final criado = DateTime.tryParse(e['criado_em']?.toString() ?? '') ?? DateTime.now();
          return _ReportItem(
            candidato: candidato,
            vaga: vaga,
            geradoEm: criado.add(const Duration(hours: 1, minutes: 30)),
            recomendacao: 'Aprovar',
            rating: 4.6,
            criterios: const [
              _Criterion(nome: 'Conhecimento Técnico', nota: 5),
              _Criterion(nome: 'Comunicação', nota: 4),
              _Criterion(nome: 'Experiência Relevante', nota: 5),
              _Criterion(nome: 'Liderança', nota: 4),
            ],
            sintese:
                'Candidato demonstrou excelente conhecimento técnico e fit cultural. Respostas consistentes e bem fundamentadas. Experiência prévia em liderança técnica é um diferencial.',
          );
        }));

      // Ordena por data de geração (mais recentes primeiro)
      _itens.sort((a, b) => (b.geradoEm).compareTo(a.geradoEm));
    } catch (_) {
      // fallback silencioso – mantemos a tela vazia se falhar
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _formatarDataHoraPt(DateTime d) {
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final dia = d.day.toString().padLeft(2, '0');
    final mes = meses[d.month - 1];
    final ano = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$dia de $mes de $ano às $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Relatórios de Entrevistas',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TMTokens.text),
              ),
              const SizedBox(height: 4),
              const Text(
                'Visualize análises detalhadas das entrevistas realizadas',
                style: TextStyle(fontSize: 16, color: TMTokens.textMuted),
              ),
              const SizedBox(height: 24),
              if (_itens.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _itens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildCard(_itens[index], index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(_ReportItem item, int index) {
    final isHovered = _hovered.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered.add(index)),
      onExit: (_) => setState(() => _hovered.remove(index)),
      child: Card(
        elevation: isHovered ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onAbrirRelatorio(item.candidato, item.vaga),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.candidato, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: TMTokens.text)),
                          const SizedBox(height: 4),
                          Text(item.vaga, style: const TextStyle(fontSize: 14, color: TMTokens.textMuted)),
                          const SizedBox(height: 6),
                          Text('Gerado em ${_formatarDataHoraPt(item.geradoEm)}', style: const TextStyle(fontSize: 12, color: TMTokens.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TMChip(
                          item.recomendacao,
                          fg: TMStatusColors.candidateFg['Aprovado'],
                          bg: TMStatusColors.candidateBg['Aprovado'],
                          icon: Icons.check_circle_outline,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, color: TMTokens.primary),
                            const SizedBox(width: 6),
                            Text(item.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: TMTokens.text)),
                            const SizedBox(width: 4),
                            const Text('/ 5.0', style: TextStyle(color: TMTokens.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.sintese,
                  style: const TextStyle(color: TMTokens.text, fontSize: 14, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTwoCols = constraints.maxWidth >= 640;
                    final children = item.criterios.map((c) => _criterionTile(c)).toList();
                    if (isTwoCols) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3.8,
                        children: children,
                      );
                    }
                    return Column(
                      children: children.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: e)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _criterionTile(_Criterion c) {
    final percent = (c.nota.clamp(0, 5) / 5.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(c.nome, style: const TextStyle(fontSize: 13, color: TMTokens.textMuted)),
            Text('${c.nota}/5', style: const TextStyle(fontSize: 13, color: TMTokens.text)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final filled = constraints.maxWidth * percent;
            return Container(
              height: 6,
              decoration: BoxDecoration(
                color: TMTokens.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 6,
                  width: filled,
                  decoration: BoxDecoration(
                    color: TMTokens.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          },
        ),
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
              Icon(Icons.insert_drive_file_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Nenhum relatório disponível', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TMTokens.text)),
              const SizedBox(height: 8),
              const Text('Finalize uma entrevista para gerar o relatório', style: TextStyle(fontSize: 14, color: TMTokens.textMuted)),
              const SizedBox(height: 16),
              TMButton('Voltar ao Dashboard', icon: Icons.chevron_left, onPressed: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportItem {
  final String candidato;
  final String vaga;
  final DateTime geradoEm;
  final String recomendacao; // Aprovar / Considerar / Não Recomendado
  final double rating; // 0..5
  final List<_Criterion> criterios;
  final String sintese;

  _ReportItem({
    required this.candidato,
    required this.vaga,
    required this.geradoEm,
    required this.recomendacao,
    required this.rating,
    required this.criterios,
    required this.sintese,
  });
}

class _Criterion {
  final String nome;
  final int nota; // 0..5
  const _Criterion({required this.nome, required this.nota});
}

