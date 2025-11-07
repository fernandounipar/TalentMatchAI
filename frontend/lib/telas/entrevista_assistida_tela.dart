import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

/// Tela de Entrevista Assistida por IA (com chat ao backend)
class EntrevistaAssistidaTela extends StatefulWidget {
  final String candidato;
  final String vaga;
  final String entrevistaId;
  final ApiCliente api;
  final void Function(Map<String, dynamic> relatorio) onFinalizar;
  final VoidCallback onCancelar;

  const EntrevistaAssistidaTela({
    super.key,
    required this.candidato,
    required this.vaga,
    required this.entrevistaId,
    required this.api,
    required this.onFinalizar,
    required this.onCancelar,
  });

  @override
  State<EntrevistaAssistidaTela> createState() => _EntrevistaAssistidaTelaState();
}

class _EntrevistaAssistidaTelaState extends State<EntrevistaAssistidaTela> {
  final TextEditingController _controlador = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _enviando = false;
  final List<Map<String, dynamic>> _mensagens = [];
  List<String> _sugeridas = const [];
  bool _gerandoPerguntas = false;
  bool _finalizando = false;

  @override
  void initState() {
    super.initState();
    _carregarMensagens();
  }

  @override
  void dispose() {
    _controlador.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarMensagens() async {
    try {
      final msgs = await widget.api.listarMensagens(widget.entrevistaId);
      setState(() {
        _mensagens
          ..clear()
          ..addAll(msgs.map((m) => _fromApiMsg(m)));
      });
    } catch (_) {}
  }

  Map<String, dynamic> _fromApiMsg(Map m) {
    final role = (m['role'] ?? 'assistant') as String;
    final remetente = role == 'assistant' ? 'IA' : 'Recrutador';
    return {
      'remetente': remetente,
      'texto': m['conteudo'] ?? '',
      'timestamp': DateTime.tryParse(m['criado_em']?.toString() ?? '') ?? DateTime.now(),
    };
  }

  Future<void> _enviarMensagem(String texto) async {
    if (texto.trim().isEmpty || _enviando) return;
    setState(() {
      _mensagens.add({'remetente': 'Recrutador', 'texto': texto, 'timestamp': DateTime.now()});
      _enviando = true;
    });
    _controlador.clear();
    try {
      final r = await widget.api.enviarMensagem(widget.entrevistaId, texto);
      final resp = r['resposta'] ?? {};
      setState(() => _mensagens.add(_fromApiMsg(resp)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao enviar: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
                          Text('Entrevista em Andamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Candidato: ${widget.candidato} • Vaga: ${widget.vaga}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onCancelar,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _finalizando
                          ? null
                          : () async {
                              setState(() => _finalizando = true);
                              try {
                                final relatorio = await widget.api.gerarRelatorio(widget.entrevistaId);
                                widget.onFinalizar(relatorio);
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text('Falha ao gerar relatório: $e')));
                              } finally {
                                if (mounted) setState(() => _finalizando = false);
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: Text(_finalizando ? 'Gerando...' : 'Finalizar & Gerar Relatório'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Corpo: Chat + Lateral
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat principal
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _mensagens.length,
                            itemBuilder: (context, index) => _BolhaMensagem(mensagem: _mensagens[index]),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controlador,
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Digite sua pergunta/comentário...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _enviando ? null : () => _enviarMensagem(_controlador.text),
                              icon: const Icon(Icons.send, size: 18),
                              label: Text(_enviando ? 'Enviando...' : 'Enviar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Painel lateral com perguntas sugeridas
              SizedBox(
                width: 320,
                child: Card(
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
                        if (_sugeridas.isEmpty)
                          Text(
                            'Nenhuma pergunta gerada ainda. Clique no botão abaixo para gerar.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          )
                        else
                          ..._sugeridas.map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('• $q'),
                              )),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _gerandoPerguntas
                              ? null
                              : () async {
                                  setState(() => _gerandoPerguntas = true);
                                  try {
                                    final qs = await widget.api.gerarPerguntas(widget.entrevistaId);
                                    setState(() => _sugeridas = qs.map<String>((e) => e.toString()).toList());
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Falha ao gerar perguntas: $e')),
                                    );
                                  } finally {
                                    if (mounted) setState(() => _gerandoPerguntas = false);
                                  }
                                },
                          icon: const Icon(Icons.psychology),
                          label: Text(_gerandoPerguntas ? 'Gerando...' : 'Gerar perguntas (IA)'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await widget.api.gerarRelatorio(widget.entrevistaId);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Relatório gerado/atualizado.')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Falha ao gerar relatório: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Gerar relatório'),
                        ),
                      ],
                    ),
                  ),
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
    return Align(
      alignment: isIA ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isIA ? Colors.grey.shade100 : const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensagem['remetente'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isIA ? Colors.grey.shade700 : Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mensagem['texto'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: isIA ? Colors.black87 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
