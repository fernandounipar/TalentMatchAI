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
  String _ordenacao = 'data_desc'; // data_desc, data_asc, score_desc, score_asc, nome_asc
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
        debugPrint('  - ID: ${item['id']}, Candidato: ${item['candidato']}, tem_relatorio: ${item['tem_relatorio']}');
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

          debugPrint('  📋 Buscando relatório para ID: $entrevistaId (${e['candidato']})');

          // Buscar relatório real do backend usando o método do ApiCliente
          final report =
              await widget.api.obterRelatorioEntrevista(entrevistaId);
          
          debugPrint('  ✅ Relatório recebido: ${report['candidate_name']} - ${report['recommendation']}');

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
          
          debugPrint('  ✅ Item adicionado: ${report['candidate_name']} - Rating: $rating');
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
        debugPrint('  - Filtro recomendação "$_filtroRecomendacao": ${lista.length} itens');
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
                          style:
                              TextStyle(fontSize: 16, color: TMTokens.textMuted),
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

              // Estatísticas
              if (_itens.isNotEmpty) _buildStats(),
              if (_itens.isNotEmpty) const SizedBox(height: 24),

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

  Widget _buildStats() {
    final total = _itens.length;
    final aprovados = _itens.where((i) => i.recomendacao == 'Aprovar').length;
    final considerar =
        _itens.where((i) => i.recomendacao == 'Considerar').length;
    final rejeitados =
        _itens.where((i) => i.recomendacao == 'Não Recomendado').length;
    final mediaScore = _itens.isEmpty
        ? 0.0
        : _itens.map((i) => i.rating).reduce((a, b) => a + b) / _itens.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            total.toString(),
            Icons.assessment,
            TMTokens.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Aprovados',
            aprovados.toString(),
            Icons.check_circle,
            TMTokens.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Considerar',
            considerar.toString(),
            Icons.pending,
            TMTokens.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rejeitados',
            rejeitados.toString(),
            Icons.cancel,
            TMTokens.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Média Score',
            mediaScore.toStringAsFixed(1),
            Icons.trending_up,
            TMTokens.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color cor) {
    return Card(
      elevation: 0,
      color: cor.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: TMTokens.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final vagas = {'Todas', ..._itens.map((i) => i.vaga)}.toList();
    final recomendacoes = {
      'Todos',
      ..._itens.map((i) => i.recomendacao)
    }.toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Busca
        SizedBox(
          width: 280,
          child: TextField(
            controller: _buscaController,
            decoration: InputDecoration(
              hintText: 'Buscar por candidato ou vaga...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _buscaController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _buscaController.clear();
                      },
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: TMTokens.border),
              ),
            ),
          ),
        ),

        // Filtro por Vaga
        DropdownButton<String>(
          value: _filtroVaga ?? 'Todas',
          items: vagas.map((v) {
            return DropdownMenuItem(value: v, child: Text(v));
          }).toList(),
          onChanged: (v) {
            setState(() {
              _filtroVaga = v == 'Todas' ? null : v;
              _aplicarFiltros();
            });
          },
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
        ),

        // Filtro por Recomendação
        DropdownButton<String>(
          value: _filtroRecomendacao ?? 'Todos',
          items: recomendacoes.map((r) {
            return DropdownMenuItem(value: r, child: Text(r));
          }).toList(),
          onChanged: (r) {
            setState(() {
              _filtroRecomendacao = r == 'Todos' ? null : r;
              _aplicarFiltros();
            });
          },
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
        ),

        // Ordenação
        DropdownButton<String>(
          value: _ordenacao,
          items: const [
            DropdownMenuItem(
                value: 'data_desc', child: Text('Data (recente)')),
            DropdownMenuItem(value: 'data_asc', child: Text('Data (antiga)')),
            DropdownMenuItem(value: 'score_desc', child: Text('Score (maior)')),
            DropdownMenuItem(value: 'score_asc', child: Text('Score (menor)')),
            DropdownMenuItem(value: 'nome_asc', child: Text('Nome (A-Z)')),
          ],
          onChanged: (v) {
            setState(() {
              _ordenacao = v!;
              _aplicarFiltros();
            });
          },
          underline: Container(),
          icon: const Icon(Icons.sort, size: 20),
        ),
      ],
    );
  }

  Widget _buildCard(_ReportItem item, int index) {
    final isHovered = _hovered.contains(index);
    
    // Cores por recomendação
    final badgeColors = {
      'Aprovar': (fg: const Color(0xFF15803D), bg: const Color(0xFFF0FDF4)),
      'Considerar': (fg: const Color(0xFFA16207), bg: const Color(0xFFFEF9C3)),
      'Não Recomendado': (fg: const Color(0xFFB91C1C), bg: const Color(0xFFFEE2E2)),
      'Pendente': (fg: const Color(0xFF475467), bg: const Color(0xFFF3F4F6)),
    };
    final badge = badgeColors[item.recomendacao] ?? badgeColors['Pendente']!;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered.add(index)),
      onExit: (_) => setState(() => _hovered.remove(index)),
      child: Card(
        elevation: isHovered ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onAbrirRelatorio(item.id, item.relatorio),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: TMTokens.primary.withAlpha(26),
                      child: Text(
                        item.candidato.isNotEmpty
                            ? item.candidato[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: TMTokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.candidato,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: TMTokens.text)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.work_outline,
                                  size: 14, color: TMTokens.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(item.vaga,
                                    style: const TextStyle(
                                        fontSize: 14, color: TMTokens.textMuted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: TMTokens.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                  _formatarDataHoraPt(item.geradoEm),
                                  style: const TextStyle(
                                      fontSize: 12, color: TMTokens.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Score e Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: badge.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.recomendacao == 'Aprovar'
                                    ? Icons.check_circle
                                    : item.recomendacao == 'Considerar'
                                        ? Icons.pending
                                        : Icons.cancel,
                                size: 16,
                                color: badge.fg,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.recomendacao,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: badge.fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: TMTokens.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: TMTokens.primary, size: 20),
                              const SizedBox(width: 6),
                              Text(item.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: TMTokens.primary)),
                              const SizedBox(width: 4),
                              const Text('/ 5.0',
                                  style: TextStyle(
                                      fontSize: 13, color: TMTokens.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                
                // Síntese
                Text(
                  item.sintese,
                  style: const TextStyle(
                      color: TMTokens.text, fontSize: 14, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Critérios
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.5,
                  children: item.criterios.map((c) => _criterionTile(c)).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Ação
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        widget.onAbrirRelatorio(item.id, item.relatorio),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Ver detalhes'),
                    style: TextButton.styleFrom(
                      foregroundColor: TMTokens.primary,
                    ),
                  ),
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
            Text(c.nome,
                style:
                    const TextStyle(fontSize: 13, color: TMTokens.textMuted)),
            Text('${c.nota}/5',
                style: const TextStyle(fontSize: 13, color: TMTokens.text)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final filled = constraints.maxWidth * percent;
            return Container(
              height: 6,
              decoration: BoxDecoration(
                color: TMTokens.primary.withAlpha(51),
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
              Icon(Icons.filter_alt_off,
                  size: 64, color: Colors.grey.shade400),
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
              TMButton('Limpar filtros',
                  icon: Icons.clear,
                  onPressed: () {
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
