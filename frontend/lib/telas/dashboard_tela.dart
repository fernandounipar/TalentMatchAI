import 'package:flutter/material.dart';
import '../componentes/widgets.dart';

class DashboardTela extends StatelessWidget {
  const DashboardTela({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados mockados para o dashboard
    final estatisticas = [
      {'titulo': 'Vagas Abertas', 'valor': '8', 'icone': Icons.work_outline, 'cor': Colors.indigo, 'subtitulo': '+2 esta semana'},
      {'titulo': 'Candidatos', 'valor': '142', 'icone': Icons.people_outline, 'cor': Colors.purple, 'subtitulo': '+15 novos'},
      {'titulo': 'Entrevistas', 'valor': '23', 'icone': Icons.calendar_today, 'cor': Colors.orange, 'subtitulo': '5 hoje'},
      {'titulo': 'Aprovados', 'valor': '12', 'icone': Icons.check_circle_outline, 'cor': Colors.green, 'subtitulo': '52% taxa'},
    ];

    final atividadesRecentes = [
      {'tipo': 'curriculo', 'candidato': 'João Silva', 'acao': 'enviou currículo para', 'vaga': 'Desenvolvedor Full Stack', 'tempo': '5 min atrás'},
      {'tipo': 'entrevista', 'candidato': 'Maria Santos', 'acao': 'entrevista concluída para', 'vaga': 'UX Designer', 'tempo': '1 hora atrás'},
      {'tipo': 'aprovacao', 'candidato': 'Carlos Oliveira', 'acao': 'foi aprovado para', 'vaga': 'DevOps Engineer', 'tempo': '2 horas atrás'},
      {'tipo': 'vaga', 'candidato': 'Sistema', 'acao': 'nova vaga criada:', 'vaga': 'Product Manager', 'tempo': '3 horas atrás'},
      {'tipo': 'curriculo', 'candidato': 'Ana Paula', 'acao': 'enviou currículo para', 'vaga': 'Data Scientist', 'tempo': '4 horas atrás'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        const Text(
          'Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
        ),
        const SizedBox(height: 8),
        Text(
          'Visão geral do processo seletivo',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Cards de Estatísticas
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: estatisticas.length,
              itemBuilder: (context, i) {
                final est = estatisticas[i];
                return CardEstatistica(
                  titulo: est['titulo'] as String,
                  valor: est['valor'] as String,
                  icone: est['icone'] as IconData,
                  cor: est['cor'] as Color,
                  subtitulo: est['subtitulo'] as String?,
                );
              },
            );
          },
        ),

        const SizedBox(height: 32),

        // Gráfico de Conversão (Mockado)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Funil de Seleção',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      _buildBarraFunil('Currículos Recebidos', 142, Colors.indigo),
                      _buildBarraFunil('Triagem Inicial', 68, Colors.purple),
                      _buildBarraFunil('Entrevistas Realizadas', 23, Colors.orange),
                      _buildBarraFunil('Aprovados', 12, Colors.green),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Metas do Mês',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      _buildMetaItem('Entrevistas', 23, 30, Colors.orange),
                      const SizedBox(height: 16),
                      _buildMetaItem('Contratações', 12, 15, Colors.green),
                      const SizedBox(height: 16),
                      _buildMetaItem('Vagas Fechadas', 5, 10, Colors.indigo),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Atividades Recentes
        const Text(
          'Atividades Recentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 16),

        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: atividadesRecentes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final ativ = atividadesRecentes[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _corAtividade(ativ['tipo'] as String).withOpacity(0.1),
                  child: Icon(_iconeAtividade(ativ['tipo'] as String), color: _corAtividade(ativ['tipo'] as String), size: 20),
                ),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(text: '${ativ['candidato']} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: '${ativ['acao']} '),
                      TextSpan(text: ativ['vaga'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                    ],
                  ),
                ),
                trailing: Text(
                  ativ['tempo'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarraFunil(String label, int valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text('$valor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valor / 142,
              backgroundColor: Colors.grey.shade200,
              color: cor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, int atual, int meta, Color cor) {
    final progresso = atual / meta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$atual/$meta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey.shade200,
            color: cor,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Color _corAtividade(String tipo) {
    switch (tipo) {
      case 'curriculo':
        return Colors.blue;
      case 'entrevista':
        return Colors.orange;
      case 'aprovacao':
        return Colors.green;
      case 'vaga':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _iconeAtividade(String tipo) {
    switch (tipo) {
      case 'curriculo':
        return Icons.description;
      case 'entrevista':
        return Icons.mic;
      case 'aprovacao':
        return Icons.check_circle;
      case 'vaga':
        return Icons.work;
      default:
        return Icons.info;
    }
  }
}
