import 'package:flutter/material.dart';
import '../componentes/widgets.dart';

/// Tela de Entrevista Assistida por IA
class EntrevistaAssistidaTela extends StatefulWidget {
  final String candidato;
  final String vaga;
  final VoidCallback onFinalizar;
  final VoidCallback onCancelar;

  const EntrevistaAssistidaTela({
    super.key,
    required this.candidato,
    required this.vaga,
    required this.onFinalizar,
    required this.onCancelar,
  });

  @override
  State<EntrevistaAssistidaTela> createState() => _EntrevistaAssistidaTelaState();
}

class _EntrevistaAssistidaTelaState extends State<EntrevistaAssistidaTela> {
  final TextEditingController _controlador = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _gravando = false;
  
  final List<Map<String, dynamic>> _mensagens = [
    {
      'remetente': 'IA',
      'texto': 'Olá! Vou auxiliar você nesta entrevista. Vamos começar?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'remetente': 'IA',
      'texto': 'Primeira pergunta técnica: Você pode explicar o conceito de idempotência em APIs RESTful e dar exemplos práticos?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
      'categoria': 'técnica',
    },
    {
      'remetente': 'Candidato',
      'texto': 'Sim, idempotência significa que uma operação pode ser repetida múltiplas vezes sem causar efeitos colaterais adicionais. Por exemplo, um GET ou DELETE devem ser idempotentes.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
    },
    {
      'remetente': 'IA',
      'texto': '✓ Resposta boa! O candidato demonstra conhecimento sólido sobre idempotência.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      'insight': true,
      'pontuacao': 8,
    },
    {
      'remetente': 'IA',
      'texto': 'Próxima pergunta: Como você estrutura testes automatizados em aplicações Node.js?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'categoria': 'técnica',
    },
    {
      'remetente': 'Candidato',
      'texto': 'Utilizo Jest para testes unitários e de integração. Estruturo com describe/it, mocks para dependências externas, e sempre busco cobertura acima de 80%.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
    },
    {
      'remetente': 'IA',
      'texto': '✓ Excelente! Mencionou ferramentas adequadas e boas práticas de cobertura.',
      'timestamp': DateTime.now().subtract(const Duration(seconds: 45)),
      'insight': true,
      'pontuacao': 9,
    },
  ];

  final List<Map<String, String>> _perguntasSugeridas = [
    {'texto': 'Conte sobre um projeto desafiador que você liderou.', 'categoria': 'comportamental'},
    {'texto': 'Como você lidaria com um bug crítico em produção?', 'categoria': 'situacional'},
    {'texto': 'Descreva sua experiência com otimização de queries SQL.', 'categoria': 'técnica'},
  ];

  @override
  void dispose() {
    _controlador.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviarMensagem(String texto) {
    if (texto.trim().isEmpty) return;

    setState(() {
      _mensagens.add({
        'remetente': 'Recrutador',
        'texto': texto,
        'timestamp': DateTime.now(),
      });
    });

    _controlador.clear();
    
    // Simular resposta da IA após 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _mensagens.add({
            'remetente': 'IA',
            'texto': 'Sugestão: Você pode aprofundar perguntando sobre experiências específicas relacionadas a esta resposta.',
            'timestamp': DateTime.now(),
            'insight': true,
          });
        });
      }
    });

    // Auto scroll
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Card(
          color: const Color(0xFF4F46E5),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.mic, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Entrevista em Andamento',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Candidato: ${widget.candidato} • Vaga: ${widget.vaga}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onCancelar,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Finalizar Entrevista'),
                            content: const Text('Deseja finalizar a entrevista e gerar o relatório?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onFinalizar();
                                },
                                child: const Text('Finalizar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Finalizar & Gerar Relatório'),
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

        const SizedBox(height: 16),

        // Conteúdo Principal
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat Principal
              Expanded(
                flex: 2,
                child: Card(
                  child: Column(
                    children: [
                      // Área de mensagens
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _mensagens.length,
                          itemBuilder: (context, i) {
                            final msg = _mensagens[i];
                            return _BolhaMensagem(mensagem: msg);
                          },
                        ),
                      ),

                      // Campo de entrada
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() => _gravando = !_gravando);
                              },
                              icon: Icon(_gravando ? Icons.mic : Icons.mic_none),
                              color: _gravando ? Colors.red : Colors.grey,
                              tooltip: 'Gravar áudio',
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controlador,
                                decoration: InputDecoration(
                                  hintText: 'Digite uma pergunta ou observação...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onSubmitted: _enviarMensagem,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _enviarMensagem(_controlador.text),
                              icon: const Icon(Icons.send),
                              color: const Color(0xFF4F46E5),
                              tooltip: 'Enviar',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Painel Lateral
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    // Perguntas Sugeridas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text('Perguntas Sugeridas', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._perguntasSugeridas.map((pergunta) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _controlador.text = pergunta['texto']!;
                                    },
                                    style: OutlinedButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pergunta['categoria']!.toUpperCase(),
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pergunta['texto']!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pontuação Atual
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Pontuação Atual', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            const BadgePontuacao(pontuacao: 82, tamanho: 70),
                            const SizedBox(height: 8),
                            Text(
                              'Baseado em ${_mensagens.where((m) => m['pontuacao'] != null).length} respostas',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BolhaMensagem extends StatelessWidget {
  final Map<String, dynamic> mensagem;

  const _BolhaMensagem({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final isIA = mensagem['remetente'] == 'IA';
    final isCandidato = mensagem['remetente'] == 'Candidato';
    final isInsight = mensagem['insight'] == true;

    return Align(
      alignment: isIA ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: isIA ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (mensagem['categoria'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _corCategoria(mensagem['categoria'] as String),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (mensagem['categoria'] as String).toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isInsight
                    ? Colors.amber.shade50
                    : isIA
                        ? Colors.grey.shade100
                        : isCandidato
                            ? Colors.blue.shade50
                            : const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(16),
                border: isInsight ? Border.all(color: Colors.amber.shade300) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensagem['remetente'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isIA || isCandidato || isInsight ? Colors.grey.shade700 : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensagem['texto'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isIA || isCandidato || isInsight ? Colors.black87 : Colors.white,
                    ),
                  ),
                  if (mensagem['pontuacao'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Pontuação: ${mensagem['pontuacao']}/10',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
