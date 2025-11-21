import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../componentes/analise_curriculo_resultado.dart';
import '../design_system/tm_tokens.dart';
import '../modelos/analise_curriculo.dart';

/// Tela de Análise de Currículo (usa dados reais se fornecidos)
class AnaliseCurriculoTela extends StatelessWidget {
  final String vaga;
  final String candidato;
  final String arquivo;
  final String? fileUrl;
  final Map<String, dynamic>? analise;
  final VoidCallback onEntrevistar;
  final VoidCallback onVoltar;

  const AnaliseCurriculoTela({
    super.key,
    required this.vaga,
    required this.candidato,
    required this.arquivo,
    this.analise,
    this.fileUrl,
    required this.onEntrevistar,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    final analiseModel =
        (analise != null && analise!.isNotEmpty) ? AnaliseCurriculo.fromJson(analise!) : null;

    final candidatoMap = {
      'nome': candidato,
      'email': analise?['email'],
      'telefone': analise?['telefone'] ?? analise?['phone'],
    };
    final vagaMap = {'titulo': vaga};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onVoltar,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Voltar'),
              ),
              const Spacer(),
              if (fileUrl != null)
                OutlinedButton.icon(
                  onPressed: () => html.window.open(fileUrl!, '_blank'),
                  icon: const Icon(Icons.download),
                  label: Text(arquivo),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Análise de Currículos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: TMTokens.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Candidato: $candidato • Vaga: $vaga',
            style: const TextStyle(color: TMTokens.secondary),
          ),
          const SizedBox(height: 16),
          if (analiseModel == null)
            _buildSemAnalise()
          else
            AnaliseCurriculoResultado(
              analise: analiseModel,
              analiseBruta: analise,
              candidato: candidatoMap,
              vaga: vagaMap,
              onGerarPerguntas: onEntrevistar,
              onAprovar: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Candidato aprovado para a próxima etapa.')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSemAnalise() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: TMTokens.secondary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ainda não há análise disponível para este currículo. '
                'Envie o arquivo pela tela de upload para gerar a análise com IA.',
                style: TextStyle(color: TMTokens.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
