import 'package:flutter/material.dart';

/// Dashboard - Implementação seguindo layout React
/// Grid responsivo de 12 colunas com estatísticas, tabelas e insights
class DashboardTela extends StatelessWidget {
  const DashboardTela({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com título e botões de ação
          _buildHeader(context),
          const SizedBox(height: 24),
          
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
          children: const [
            _StatCard(
              title: 'Vagas abertas',
              value: '12',
              subtitle: '+2 esta semana',
            ),
            _StatCard(
              title: 'Currículos recebidos',
              value: '87',
              subtitle: '+18 hoje',
            ),
            _StatCard(
              title: 'Entrevistas agendadas',
              value: '5',
              subtitle: '2 nas próximas 24h',
            ),
            _StatCard(
              title: 'Relatórios gerados',
              value: '3',
              subtitle: '1 pendente',
            ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        columns: const [
          DataColumn(label: Text('Título')),
          DataColumn(label: Text('Candidatos')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Última atualização')),
          DataColumn(label: Text('')),
        ],
        rows: [
          _buildRowVaga('Desenvolvedor Full Stack', 21, 'Em análise', '12/10/2025'),
          _buildRowVaga('Analista de Dados', 14, 'Entrevistas', '11/10/2025'),
          _buildRowVaga('UX/UI Designer', 9, 'Triagem', '10/10/2025'),
          _buildRowVaga('DevOps Engineer', 7, 'Aguardando gestor', '09/10/2025'),
        ],
      ),
    );
  }

  DataRow _buildRowVaga(String titulo, int candidatos, String status, String data) {
    return DataRow(
      cells: [
        DataCell(Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text('$candidatos')),
        DataCell(
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
        ),
        DataCell(Text(data, style: TextStyle(color: Colors.grey[500]))),
        DataCell(
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chevron_right, size: 16),
            label: const Text('Detalhes', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildEntrevistasRecentes(BuildContext context) {
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
            _buildInterviewItem(
              'João Silva',
              'Desenvolvedor Python',
              'Relatório disponível',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInterviewItem(
              'Marina Alves',
              'UX Designer',
              'Análise em andamento',
              Icons.warning_amber,
              Colors.amber,
            ),
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
    MaterialColor corIcone,
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
              Icon(icon, size: 16, color: corIcone[600]),
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
            _buildReportItem(
              'Entrevista — João Silva (Python)',
              '12/10/2025',
              'Concluído',
            ),
            const SizedBox(height: 12),
            _buildReportItem(
              'Entrevista — Marina Alves (UX)',
              '11/10/2025',
              'Em revisão',
            ),
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
              _buildInsightItem(
                Icons.search,
                'Triagem',
                '3 currículos com alta compatibilidade para Engenheiro de Dados.',
              ),
              const SizedBox(height: 12),
              _buildInsightItem(
                Icons.calendar_today,
                'Agenda',
                '2 entrevistas nas próximas 24h.',
              ),
              const SizedBox(height: 12),
              _buildInsightItem(
                Icons.bar_chart,
                'Tendência',
                'Tempo médio de triagem reduziu 15% nesta semana.',
              ),
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
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
