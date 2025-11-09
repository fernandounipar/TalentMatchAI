import 'package:flutter/material.dart';

import '../servicos/api_cliente.dart';
import '../componentes/tm_card_kpi.dart';
import '../componentes/tm_table.dart';
import '../componentes/tm_chip.dart';
import '../design_system/tm_tokens.dart';

/// Dashboard - Implementação seguindo layout React
/// Grid responsivo de 12 colunas com estatísticas, tabelas e insights
class DashboardTela extends StatefulWidget {
  final ApiCliente api;
  const DashboardTela({super.key, required this.api});

  @override
  State<DashboardTela> createState() => _DashboardTelaState();
}

class _DashboardTelaState extends State<DashboardTela> {
  Map<String, dynamic>? _stats;
  bool _carregando = false;
  List<Map<String, dynamic>> _vagas = const [];
  List<Map<String, dynamic>> _historico = const [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final stats = await widget.api.dashboard();
      final vagas = await widget.api.vagas();
      final historico = await widget.api.historico();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _vagas = vagas.cast<Map<String, dynamic>>();
        _historico = historico.cast<Map<String, dynamic>>();
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com título e botões de ação
            _buildHeader(context),
            const SizedBox(height: 24),

            if (_carregando)
              const LinearProgressIndicator(minHeight: 2),

            const SizedBox(height: 12),

            // Grid de 4 cards de estatísticas
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Row: Minhas Vagas (7 cols) + Entrevistas Recentes (5 cols)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1024) {
                  return Column(
                    children: [
                      _buildMinhasVagas(context),
                      const SizedBox(height: 16),
                      _buildEntrevistasRecentes(context),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildMinhasVagas(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _buildEntrevistasRecentes(context),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Row: Relatórios Recentes (7 cols) + Insights da IA (5 cols)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1024) {
                  return Column(
                    children: [
                      _buildRelatoriosRecentes(),
                      const SizedBox(height: 16),
                      _buildInsightsIA(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildRelatoriosRecentes(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _buildInsightsIA(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bem-vinda! 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumo do seu dia. Domingo, 12 de outubro de 2025',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        if (MediaQuery.of(context).size.width >= 768)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova Vaga'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Upload Currículo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final vagas = _stats?['vagas'] ?? 12;
    final curriculos = _stats?['curriculos'] ?? 87;
    final entrevistas = _stats?['entrevistas'] ?? 5;
    final relatorios = _stats?['relatorios'] ?? 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1200) columns = 2;
        if (constraints.maxWidth < 640) columns = 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            TMCardKPI(title: 'Vagas abertas', value: '$vagas', delta: 'Atualizado', icon: Icons.work_outline),
            TMCardKPI(title: 'Currículos recebidos', value: '$curriculos', delta: '24h', icon: Icons.description_outlined, accentColor: TMTokens.info),
            TMCardKPI(title: 'Entrevistas registradas', value: '$entrevistas', delta: 'No histórico', icon: Icons.calendar_today_outlined, accentColor: TMTokens.secondary),
            TMCardKPI(title: 'Relatórios gerados', value: '$relatorios', delta: 'Com IA', icon: Icons.assessment_outlined, accentColor: TMTokens.emphasis),
          ],
        );
      },
    );
  }

  Widget _buildMinhasVagas(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Minhas Vagas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTableVagas(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableVagas() {
    final rows = _vagas.take(5).map((vaga) {
      final titulo = vaga['titulo']?.toString() ?? 'Vaga';
      final candidatos = vaga['candidatos']?.toString() ?? '-';
      final status = vaga['status']?.toString() ?? 'Aberta';
      final atualizado = vaga['atualizado_em']?.toString() ?? 'Recente';
      return DataRow(cells: [
        DataCell(Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(candidatos)),
        DataCell(TMChip.jobStatus(status)),
        DataCell(Text(atualizado, style: TextStyle(color: Colors.grey[500]))),
        const DataCell(Icon(Icons.chevron_right, size: 18, color: TMTokens.secondary)),
      ]);
    }).toList();

    return TMDataTable(
      columns: const [
        DataColumn(label: Text('Título')),
        DataColumn(label: Text('Candidatos')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Última atualização')),
        DataColumn(label: Text('')),
      ],
      rows: rows,
      state: rows.isEmpty ? TMTableState.empty : TMTableState.normal,
      emptyMessage: 'Nenhuma vaga cadastrada',
    );
  }

  Widget _buildEntrevistasRecentes(BuildContext context) {
    final entrevistas = _historico.take(3).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Entrevistas Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Nova Entrevista', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entrevistas.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Nenhuma entrevista registrada ainda.'),
              )
            else
              ...entrevistas.map((ent) {
                final status = ent['tem_relatorio'] == true ? 'Relatório disponível' : 'Em análise';
                final icone = ent['tem_relatorio'] == true ? Icons.check_circle : Icons.timelapse;
                final cor = ent['tem_relatorio'] == true ? Colors.green : Colors.amber;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInterviewItem(
                    ent['candidato']?.toString() ?? '-',
                    ent['vaga']?.toString() ?? '-',
                    status,
                    icone,
                    cor,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewItem(
    String nome,
    String cargo,
    String status,
    IconData icon,
    Color corIcone,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cargo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icon, size: 16, color: corIcone),
              const SizedBox(width: 6),
              Text(
                status,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text('Abrir', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelatoriosRecentes() {
    final relatorios = _historico.where((e) => e['tem_relatorio'] == true).take(4).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Relatórios Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Exportar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (relatorios.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Nenhum relatório finalizado ainda.'),
              )
            else
              ...relatorios.map((rel) {
                final titulo = 'Entrevista — ${rel['candidato']} (${rel['vaga']})';
                final data = DateTime.tryParse(rel['criado_em']?.toString() ?? '');
                final status = rel['tem_relatorio'] == true ? 'Concluído' : 'Em andamento';
                final dataFormatada = data != null
                    ? '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}'
                    : 'Recente';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReportItem(titulo, dataFormatada, status),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String titulo, String data, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text('Ver', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsIA() {
    final tendencias = (_stats?['tendencias'] as List?)?.whereType<Map>().toList() ?? [];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0F3FF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insights da IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (tendencias.isEmpty) ...[
                _buildInsightItem(
                  Icons.lightbulb_outline,
                  'Fique de olho',
                  'Ative o upload de currículos para gerar novos insights em tempo real.',
                ),
              ] else ...[
                for (final insight in tendencias) ...[
                  _buildInsightItem(
                    Icons.bar_chart,
                    insight['label']?.toString() ?? 'Insight',
                    '${insight['valor']}% dos candidatos nessa categoria.',
                  ),
                  const SizedBox(height: 12),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String titulo, String texto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de Estatística
// _StatCard substituído por TMCardKPI
