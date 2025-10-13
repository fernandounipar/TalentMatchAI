import 'package:flutter/material.dart';
import '../componentes/widgets.dart';

/// Tela de Relatório Final da Entrevista
class RelatorioFinalTela extends StatelessWidget {
  final String candidato;
  final String vaga;
  final VoidCallback onVoltar;

  const RelatorioFinalTela({
    super.key,
    required this.candidato,
    required this.vaga,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    // Dados mockados do relatório
    const pontuacaoGeral = 85.0;
    const recomendacao = 'Contratar';

    final analiseDetalhada = {
      'Conhecimento Técnico': 88,
      'Experiência Prática': 85,
      'Comunicação': 82,
      'Resolução de Problemas': 90,
      'Fit Cultural': 78,
    };

    final pontosFortes = [
      'Excelente domínio de tecnologias do stack (React, Node.js, PostgreSQL)',
      'Demonstrou raciocínio lógico sólido na resolução de problemas técnicos',
      'Boa comunicação e capacidade de explicar conceitos complexos',
      'Experiência comprovada com boas práticas de desenvolvimento (testes, Git)',
      'Perfil proativo com contribuições open source no GitHub',
    ];

    final pontosMelhoria = [
      'Poderia aprofundar conhecimento em otimização de queries SQL',
      'Experiência com metodologias ágeis poderia ser mais aprofundada',
      'Considerar certificações em cloud computing (AWS, Azure)',
    ];

    final respostasDestaque = [
      {
        'pergunta': 'Explique o conceito de idempotência em APIs RESTful',
        'categoria': 'técnica',
        'pontuacao': 8,
        'feedback': 'Resposta clara e objetiva, demonstrando conhecimento sólido sobre o conceito.',
      },
      {
        'pergunta': 'Como você estrutura testes automatizados?',
        'categoria': 'técnica',
        'pontuacao': 9,
        'feedback': 'Excelente! Mencionou ferramentas adequadas e boas práticas de cobertura.',
      },
      {
        'pergunta': 'Conte sobre um projeto desafiador que você liderou',
        'categoria': 'comportamental',
        'pontuacao': 8,
        'feedback': 'Demonstrou liderança e capacidade de resolver conflitos em equipe.',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão Voltar
          TextButton.icon(
            onPressed: onVoltar,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Voltar ao Dashboard'),
          ),
          const SizedBox(height: 8),

          // Cabeçalho
          Card(
            color: const Color(0xFF4F46E5),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Relatório de Entrevista',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Candidato: $candidato • Vaga: $vaga',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerado em: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Relatório exportado como PDF')),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Relatório compartilhado')),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Compartilhar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Resumo Executivo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  color: _corRecomendacao(recomendacao).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const BadgePontuacao(pontuacao: pontuacaoGeral, tamanho: 90),
                        const SizedBox(height: 16),
                        const Text(
                          'Pontuação Geral',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _corRecomendacao(recomendacao),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recomendacao.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo Executivo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'O candidato $candidato demonstrou excelente adequação à vaga de $vaga, apresentando sólido conhecimento técnico e boa capacidade de comunicação. '
                          'Com pontuação geral de ${pontuacaoGeral.toInt()}%, recomendamos a contratação.',
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Análise por Competência',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ...analiseDetalhada.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key, style: const TextStyle(fontSize: 13)),
                                      Text('${entry.value}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: entry.value / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      color: const Color(0xFF4F46E5),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pontos Fortes e Melhorias
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Pontos Fortes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...pontosFortes.map((ponto) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(ponto, style: const TextStyle(fontSize: 14, height: 1.5)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Pontos de Melhoria',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...pontosMelhoria.map((ponto) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(ponto, style: const TextStyle(fontSize: 14, height: 1.5)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Respostas em Destaque
          const Text(
            'Respostas em Destaque',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          ...respostasDestaque.map((resposta) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              resposta['pergunta'] as String,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _corCategoria(resposta['categoria'] as String).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (resposta['categoria'] as String).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _corCategoria(resposta['categoria'] as String),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ...List.generate(
                            10,
                            (i) => Icon(
                              i < (resposta['pontuacao'] as int) ? Icons.star : Icons.star_border,
                              size: 18,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${resposta['pontuacao']}/10',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resposta['feedback'] as String,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 24),

          // Próximos Passos
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.next_plan, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Próximos Passos Recomendados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProximoPasso('1', 'Agendar segunda entrevista técnica com o time de desenvolvimento'),
                  _buildProximoPasso('2', 'Solicitar referências profissionais'),
                  _buildProximoPasso('3', 'Preparar proposta salarial competitiva'),
                  _buildProximoPasso('4', 'Verificar disponibilidade para início imediato'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: onVoltar,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao Dashboard'),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Rejeitar candidato
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Não Aprovar'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Aprovar Candidato'),
                          content: Text('Deseja aprovar $candidato para a próxima etapa?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$candidato aprovado com sucesso!')),
                                );
                              },
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Aprovar Candidato'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProximoPasso(String numero, String descricao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(descricao, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Color _corRecomendacao(String recomendacao) {
    switch (recomendacao.toLowerCase()) {
      case 'contratar':
        return Colors.green;
      case 'considerar':
        return Colors.orange;
      case 'não_recomendado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _corCategoria(String categoria) {
    switch (categoria) {
      case 'técnica':
        return Colors.blue;
      case 'comportamental':
        return Colors.purple;
      case 'situacional':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
