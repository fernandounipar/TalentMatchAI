import 'package:flutter/material.dart';

import '../componentes/tm_button.dart';
import '../design_system/tm_tokens.dart';
import '../servicos/api_cliente.dart';

class RelatoriosTela extends StatefulWidget {
  final ApiCliente api;
  final void Function(String entrevistaId, Map<String, dynamic> relatorio)
      onAbrirRelatorio;

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
  final List<_ReportItem> _itensFiltrados = [];
  final Set<int> _hovered = <int>{};

  // Filtros
  String? _filtroRecomendacao;
  String? _filtroVaga;
  String _ordenacao =
      'data_desc'; // data_desc, data_asc, score_desc, score_asc, nome_asc
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final hist = await widget.api.historico();
      debugPrint('=== HISTÓRICO RECEBIDO: ${hist.length} itens ===');

      final comRelatorio = hist
          .whereType<Map<String, dynamic>>()
          .where((e) => e['tem_relatorio'] == true)
          .toList();

      debugPrint('=== COM RELATÓRIO: ${comRelatorio.length} itens ===');
      for (final item in comRelatorio) {
        debugPrint(
            '  - ID: ${item['id']}, Candidato: ${item['candidato']}, tem_relatorio: ${item['tem_relatorio']}');
      }

      _itens.clear();

      // Para cada entrevista com relatório, buscar os dados reais
      for (final e in comRelatorio) {
        try {
          final entrevistaId = e['id']?.toString();
          if (entrevistaId == null) {
            debugPrint('  ⚠️ ID nulo para: ${e['candidato']}');
            continue;
          }

          debugPrint(
              '  📋 Buscando relatório para ID: $entrevistaId (${e['candidato']})');

          // Buscar relatório real do backend usando o método do ApiCliente
          final report =
              await widget.api.obterRelatorioEntrevista(entrevistaId);

          debugPrint(
              '  ✅ Relatório recebido: ${report['candidate_name']} - ${report['recommendation']}');

          // Mapear recommendation para português
          final recMap = {
            'APPROVE': 'Aprovar',
            'MAYBE': 'Considerar',
            'REJECT': 'Não Recomendado',
            'PENDING': 'Pendente',
          };

          final recomendacao = recMap[report['recommendation']] ?? 'Pendente';
          final overallScore = (report['overall_score'] ?? 0.0).toDouble();
          final percent =
              overallScore <= 10 ? (overallScore * 10) : overallScore;
          final rating = (percent / 20.0)
              .clamp(0.0, 5.0); // Converte 0-100 em 0-5 estrelas

          // Extrair critérios do content (se disponível)
          List<_Criterion> criterios = [];
          if (report['content'] != null) {
            final content = report['content'];
            if (content is Map && content['criterios'] != null) {
              final critList = content['criterios'] as List?;
              if (critList != null) {
                criterios = critList.map((c) {
                  return _Criterion(
                    nome: c['nome']?.toString() ?? '',
                    nota: (c['nota'] ?? 0).toInt(),
                  );
                }).toList();
              }
            }
          }

          // Se não houver critérios, usar padrões baseados no score
          if (criterios.isEmpty) {
            final baseScore = (rating * 0.8).round();
            criterios = [
              _Criterion(nome: 'Conhecimento Técnico', nota: baseScore),
              _Criterion(nome: 'Comunicação', nota: (baseScore * 0.9).round()),
              _Criterion(nome: 'Experiência', nota: baseScore),
              _Criterion(
                  nome: 'Fit Cultural',
                  nota: (baseScore * 1.1).round().clamp(0, 5)),
            ];
          }

          _itens.add(_ReportItem(
            id: entrevistaId,
            candidato: report['candidate_name'] ??
                e['candidato']?.toString() ??
                'Candidato',
            vaga: report['job_title'] ?? e['vaga']?.toString() ?? 'Vaga',
            geradoEm:
                DateTime.tryParse(report['generated_at']?.toString() ?? '') ??
                    DateTime.now(),
            recomendacao: recomendacao,
            rating: rating.clamp(0.0, 5.0),
            criterios: criterios,
            sintese: report['summary_text'] ??
                report['content']?['summary_text'] ??
                'Relatório em análise.',
            relatorio: report,
          ));

          debugPrint(
              '  ✅ Item adicionado: ${report['candidate_name']} - Rating: $rating');
        } catch (reportError) {
          // Se falhar ao buscar um relatório específico, continua com o próximo
          debugPrint(
              '  ❌ Erro ao buscar relatório da entrevista ${e['id']}: $reportError');
          continue;
        }
      }

      debugPrint('=== TOTAL DE ITENS CARREGADOS: ${_itens.length} ===');
      _aplicarFiltros();
    } catch (e) {
      debugPrint('❌ Erro ao carregar relatórios: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _itensFiltrados.clear();
      var lista = List<_ReportItem>.from(_itens);

      debugPrint('🔍 Aplicando filtros: ${_itens.length} itens originais');

      // Filtro por busca (candidato ou vaga)
      final busca = _buscaController.text.toLowerCase().trim();
      if (busca.isNotEmpty) {
        lista = lista.where((item) {
          return item.candidato.toLowerCase().contains(busca) ||
              item.vaga.toLowerCase().contains(busca);
        }).toList();
        debugPrint('  - Filtro busca "$busca": ${lista.length} itens');
      }

      // Filtro por recomendação
      if (_filtroRecomendacao != null && _filtroRecomendacao != 'Todos') {
        lista = lista
            .where((item) => item.recomendacao == _filtroRecomendacao)
            .toList();
        debugPrint(
            '  - Filtro recomendação "$_filtroRecomendacao": ${lista.length} itens');
      }

      // Filtro por vaga
      if (_filtroVaga != null && _filtroVaga != 'Todas') {
        lista = lista.where((item) => item.vaga == _filtroVaga).toList();
        debugPrint('  - Filtro vaga "$_filtroVaga": ${lista.length} itens');
      }

      // Ordenação
      switch (_ordenacao) {
        case 'data_asc':
          lista.sort((a, b) => a.geradoEm.compareTo(b.geradoEm));
          break;
        case 'score_desc':
          lista.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'score_asc':
          lista.sort((a, b) => a.rating.compareTo(b.rating));
          break;
        case 'nome_asc':
          lista.sort((a, b) => a.candidato.compareTo(b.candidato));
          break;
        case 'data_desc':
        default:
          lista.sort((a, b) => b.geradoEm.compareTo(a.geradoEm));
      }

      _itensFiltrados.addAll(lista);
      debugPrint('✅ Itens filtrados final: ${_itensFiltrados.length}');
    });
  }

  String _formatarDataHoraPt(DateTime d) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Relatórios de Entrevistas',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: TMTokens.text),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Visualize análises detalhadas das entrevistas realizadas',
                          style: TextStyle(
                              fontSize: 16, color: TMTokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_itens.isNotEmpty)
                    TMButton(
                      'Atualizar',
                      icon: Icons.refresh,
                      onPressed: _carregar,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Filtros e Busca
              if (_itens.isNotEmpty) _buildFilters(),
              if (_itens.isNotEmpty) const SizedBox(height: 24),

              // Lista de Relatórios
              if (_itensFiltrados.isEmpty && _itens.isNotEmpty)
                _buildEmptyFilterState()
              else if (_itens.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _itensFiltrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildCard(_itensFiltrados[index], index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    final vagas = {'Todas', ..._itens.map((i) => i.vaga)}.toList();
    final recomendacoes =
        {'Todos', ..._itens.map((i) => i.recomendacao)}.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 12,
                        top: 12,
                        child: Icon(Icons.search,
                            size: 18, color: TMTokens.textMuted),
                      ),
                      TextField(
                        controller: _buscaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por candidato ou vaga...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: TMTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: TMTokens.border),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _vagaDropdown(vagas)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _recomendacaoDropdown(recomendacoes)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vagaDropdown(List<String> vagas) {
    return DropdownButtonFormField<String>(
      value: _filtroVaga ?? 'Todas',
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.work_outline, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      isExpanded: true,
      items: vagas.map((v) {
        return DropdownMenuItem(
            value: v, child: Text(v, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (v) {
        setState(() {
          _filtroVaga = v == 'Todas' ? null : v;
          _aplicarFiltros();
        });
      },
    );
  }

  Widget _recomendacaoDropdown(List<String> recomendacoes) {
    return DropdownButtonFormField<String>(
      value: _filtroRecomendacao ?? 'Todos',
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_list, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      isExpanded: true,
      items: recomendacoes.map((r) {
        return DropdownMenuItem(
            value: r, child: Text(r, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (r) {
        setState(() {
          _filtroRecomendacao = r == 'Todos' ? null : r;
          _aplicarFiltros();
        });
      },
    );
  }

  Widget _buildCard(_ReportItem item, int index) {
    final isHovered = _hovered.contains(index);

    // Cores por recomendação
    final badgeColors = {
      'Aprovar': (
        fg: const Color(0xFF166534),
        bg: const Color(0xFFDCFCE7)
      ), // green-800, green-100
      'Considerar': (
        fg: const Color(0xFF854D0E),
        bg: const Color(0xFFFEF9C3)
      ), // yellow-800, yellow-100
      'Não Recomendado': (
        fg: const Color(0xFF991B1B),
        bg: const Color(0xFFFEE2E2)
      ), // red-800, red-100
      'Pendente': (
        fg: const Color(0xFF374151),
        bg: const Color(0xFFF3F4F6)
      ), // gray-700, gray-100
    };
    final badge = badgeColors[item.recomendacao] ?? badgeColors['Pendente']!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered.add(index)),
      onExit: (_) => setState(() => _hovered.remove(index)),
      child: Card(
        elevation: isHovered ? 8 : 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onAbrirRelatorio(item.id, item.relatorio),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column: Name, Role, Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.candidato,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.vaga,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gerado em ${_formatarDataHoraPt(item.geradoEm)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Column: Badge & Score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: badge.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.recomendacao == 'Aprovar'
                                    ? Icons.check_circle_outline
                                    : item.recomendacao == 'Considerar'
                                        ? Icons.help_outline
                                        : Icons.cancel_outlined,
                                size: 16,
                                color: badge.fg,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.recomendacao,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: badge.fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Score
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '/ 5.0',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description (Sintese)
                Text(
                  item.sintese,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Skills Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children:
                      item.criterios.map((c) => _criterionTile(c)).toList(),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              c.nome,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
            Text(
              '${c.nota}/5',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final filled = constraints.maxWidth * percent;
            return Container(
              height: 6,
              width: double.infinity,
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
              Icon(Icons.insert_drive_file_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Nenhum relatório disponível',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TMTokens.text)),
              const SizedBox(height: 8),
              const Text('Finalize uma entrevista para gerar o relatório',
                  style: TextStyle(fontSize: 14, color: TMTokens.textMuted)),
              const SizedBox(height: 16),
              TMButton('Voltar ao Dashboard',
                  icon: Icons.chevron_left,
                  onPressed: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Nenhum relatório encontrado',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TMTokens.text)),
              const SizedBox(height: 8),
              const Text('Tente ajustar os filtros de busca',
                  style: TextStyle(fontSize: 14, color: TMTokens.textMuted)),
              const SizedBox(height: 16),
              TMButton('Limpar filtros', icon: Icons.clear, onPressed: () {
                setState(() {
                  _buscaController.clear();
                  _filtroRecomendacao = null;
                  _filtroVaga = null;
                  _aplicarFiltros();
                });
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportItem {
  final String id;
  final String candidato;
  final String vaga;
  final DateTime geradoEm;
  final String recomendacao; // Aprovar / Considerar / Não Recomendado
  final double rating; // 0..5
  final List<_Criterion> criterios;
  final String sintese;
  final Map<String, dynamic> relatorio;

  _ReportItem({
    required this.id,
    required this.candidato,
    required this.vaga,
    required this.geradoEm,
    required this.recomendacao,
    required this.rating,
    required this.criterios,
    required this.sintese,
    required this.relatorio,
  });
}

class _Criterion {
  final String nome;
  final int nota; // 0..5
  const _Criterion({required this.nome, required this.nota});
}
