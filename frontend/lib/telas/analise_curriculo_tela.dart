import 'package:flutter/material.dart';
import '../componentes/widgets.dart';

/// Tela de Análise de Currículo
class AnaliseCurriculoTela extends StatelessWidget {
  final String vaga;
  final String candidato;
  final String arquivo;
  final VoidCallback onEntrevistar;
  final VoidCallback onVoltar;

  const AnaliseCurriculoTela({
    super.key,
    required this.vaga,
    required this.candidato,
    required this.arquivo,
    required this.onEntrevistar,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    // Dados mockados da análise
    const pontuacao = 85.0;
    final competencias = [
      {'nome': 'React', 'nivel': 90},
      {'nome': 'Node.js', 'nivel': 85},
      {'nome': 'PostgreSQL', 'nivel': 75},
      {'nome': 'Docker', 'nivel': 70},
      {'nome': 'Git', 'nivel': 95},
    ];

    final experiencias = [
      'Desenvolvedor Full Stack na TechCorp (3 anos)',
      'Desenvolvedor Backend na StartupXYZ (2 anos)',
      'Freelancer em projetos web (1 ano)',
    ];

    final pontosFortes = [
      'Sólida experiência com tecnologias do stack (React, Node.js)',
      'Conhecimento comprovado em arquitetura de APIs RESTful',
      'Experiência com Docker e containerização',
      'Perfil GitHub ativo com contribuições open source',
    ];

    final pontosAtencao = [
      'Experiência com PostgreSQL poderia ser mais aprofundada',
      'Currículo não menciona testes automatizados',
    ];

    final perguntasSugeridas = [
      {'categoria': 'técnica', 'texto': 'Explique o conceito de idempotência em APIs RESTful e dê exemplos.'},
      {'categoria': 'técnica', 'texto': 'Como você estrutura seus testes em aplicações Node.js?'},
      {'categoria': 'técnica', 'texto': 'Descreva sua experiência com otimização de queries SQL no PostgreSQL.'},
      {'categoria': 'comportamental', 'texto': 'Conte sobre um projeto desafiador que você liderou.'},
      {'categoria': 'situacional', 'texto': 'Como você lidaria com um bug crítico em produção?'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão Voltar
          TextButton.icon(
            onPressed: onVoltar,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Voltar'),
          ),
          const SizedBox(height: 8),

          // Título
          Text(
            'Análise de Currículo — $candidato',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
          ),
          const SizedBox(height: 8),
          Text(
            'Vaga: $vaga',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Card de Resumo
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const BadgePontuacao(pontuacao: pontuacao, tamanho: 80),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compatibilidade Geral',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'O candidato possui boa compatibilidade com a vaga. Experiência sólida nas tecnologias principais.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: const Text('Recomendado'),
                              backgroundColor: Colors.green.shade100,
                              avatar: Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                            ),
                            const Chip(label: Text('5 anos de experiência')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Competências Técnicas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.code, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text('Competências Técnicas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...competencias.map((comp) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(comp['nome'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('${comp['nivel']}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (comp['nivel'] as int) / 100,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    // Experiências
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.work_outline, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text('Experiências', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...experiencias.map((exp) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_right, size: 20, color: Colors.black54),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(exp, style: const TextStyle(fontSize: 14))),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pontos Fortes e Atenção
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.thumb_up, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text('Pontos Fortes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...pontosFortes.map((ponto) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(ponto, style: const TextStyle(fontSize: 13))),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            const Text('Pontos de Atenção', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...pontosAtencao.map((ponto) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info, size: 18, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(ponto, style: const TextStyle(fontSize: 13))),
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

          // Perguntas Sugeridas pela IA
          const Text(
            'Perguntas Sugeridas pela IA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: perguntasSugeridas.map((pergunta) {
                  Color corCategoria = pergunta['categoria'] == 'técnica'
                      ? Colors.blue
                      : pergunta['categoria'] == 'comportamental'
                          ? Colors.purple
                          : Colors.orange;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: corCategoria.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: corCategoria.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: corCategoria,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (pergunta['categoria'] as String).toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(pergunta['texto'] as String, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onVoltar,
                child: const Text('Voltar'),
              ),
              const SizedBox(width: 12),
              BotaoPrimario(
                texto: 'Iniciar Entrevista',
                icone: Icons.mic,
                onPressed: onEntrevistar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
