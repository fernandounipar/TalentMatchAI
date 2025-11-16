import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../componentes/widgets.dart';

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
    required this.onEntrevistar,
    required this.onVoltar,
    this.analise,
    this.fileUrl,
  });

  @override
  Widget build(BuildContext context) {
    final summary = (analise?['summary'] as String?) ??
        (analise?['resumo'] as String?) ??
        'O candidato possui boa compatibilidade com a vaga. Experiência sólida nas tecnologias principais.';
    final skills = (analise?['skills'] as List?)?.cast<String>() ??
        const ['React', 'Node.js', 'PostgreSQL', 'Docker', 'Git'];
    final experiencias = (analise?['experiences'] as List?)?.cast<String>() ??
        const [
          'Desenvolvedor Full Stack na TechCorp (3 anos)',
          'Desenvolvedor Backend na StartupXYZ (2 anos)',
          'Freelancer em projetos web (1 ano)',
        ];

    final pontuacao = () {
      final raw = analise?['matchingScore'];
      if (raw is num) return raw.toDouble().clamp(0, 100);
      if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) return parsed.clamp(0, 100);
      }
      return 0.0;
    }();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(onPressed: onVoltar, icon: const Icon(Icons.chevron_left), label: const Text('Voltar')),
          const SizedBox(height: 8),
          Text('Análise de Currículo • $candidato',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
          const SizedBox(height: 8),
          Text('Vaga: $vaga', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 24),

          // Resumo e score
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                BadgePontuacao(pontuacao: pontuacao, tamanho: 80),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Compatibilidade Geral',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(summary, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      Chip(label: const Text('Arquivo')),
                      Chip(label: Text(arquivo)),
                      if (fileUrl != null)
                        TextButton.icon(
                          onPressed: () => html.window.open(fileUrl!, '_blank'),
                          icon: const Icon(Icons.download),
                          label: const Text('Baixar'),
                        ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // Competências e experiências
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.code, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text('Competências Técnicas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 16),
                    ...skills.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(s, style: const TextStyle(fontWeight: FontWeight.w500)),
                                const Text('80%', style: TextStyle(fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  value: 0.8,
                                  backgroundColor: Colors.black12,
                                  color: Color(0xFF4F46E5),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.work_outline, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text('Experiências', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 16),
                    ...experiencias.map((exp) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.arrow_right, size: 20, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(child: Text(exp, style: const TextStyle(fontSize: 14))),
                          ]),
                        )),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(onPressed: onVoltar, child: const Text('Voltar')),
            const SizedBox(width: 12),
            BotaoPrimario(texto: 'Iniciar Entrevista', icone: Icons.mic, onPressed: onEntrevistar),
          ]),
        ],
      ),
    );
  }
}

