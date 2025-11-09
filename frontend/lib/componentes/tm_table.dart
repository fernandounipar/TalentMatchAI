import 'package:flutter/material.dart';
import '../design_system/tm_tokens.dart';

enum TMTableState { normal, loading, empty, error }

class TMDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final TMTableState state;
  final String? emptyMessage;
  final String? errorMessage;

  const TMDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.state = TMTableState.normal,
    this.emptyMessage,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (state == TMTableState.loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (state == TMTableState.error) {
      return _StateBox(
        icon: Icons.error_outline,
        title: 'Erro ao carregar',
        message: errorMessage ?? 'Tente novamente mais tarde.',
        color: TMTokens.error,
      );
    }
    if (rows.isEmpty || state == TMTableState.empty) {
      return _StateBox(
        icon: Icons.inbox_outlined,
        title: 'Sem registros',
        message: emptyMessage ?? 'Nenhum item para exibir.',
        color: TMTokens.secondary,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(
          fontSize: 14,
          color: TMTokens.textMuted,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: TMTokens.text,
        ),
        columns: columns,
        rows: rows,
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  const _StateBox({required this.icon, required this.title, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TMTokens.r12),
        border: Border.all(color: TMTokens.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: TMTokens.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

