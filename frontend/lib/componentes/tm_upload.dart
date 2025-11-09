import 'package:flutter/material.dart';
import '../design_system/tm_tokens.dart';

/// Área de upload estilizada (drag visual + clique)
class TMUploadArea extends StatelessWidget {
  final bool dragActive;
  final VoidCallback onPick;
  final String? helper;

  const TMUploadArea({
    super.key,
    required this.dragActive,
    required this.onPick,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = dragActive ? TMTokens.primary : TMTokens.border;
    final bg = dragActive ? const Color(0xFFEFF6FF) : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TMTokens.r12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, color: TMTokens.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            'Arraste o arquivo aqui ou clique para enviar',
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            helper ?? 'Formatos aceitos: PDF, DOCX, TXT',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TMTokens.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.folder_open),
            label: const Text('Selecionar arquivo'),
          ),
        ],
      ),
    );
  }
}

