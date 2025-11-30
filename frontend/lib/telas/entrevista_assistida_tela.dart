import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../servicos/api_cliente.dart';
import '../utils/date_utils.dart' as date_utils;

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
  State<EntrevistaAssistidaTela> createState() =>
      _EntrevistaAssistidaTelaState();
}

class _EntrevistaAssistidaTelaState extends State<EntrevistaAssistidaTela> {
  final TextEditingController _controlador = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _enviando = false;
  final List<Map<String, dynamic>> _mensagens = [];
  List<Map<String, dynamic>> _perguntas = const [];
  String? _perguntaSelecionadaId;
  List<Map<String, dynamic>> _respostas = const [];
  bool _gerandoPerguntas = false;
  bool _finalizando = false;
  
  // Controllers para respostas de cada pergunta
  final Map<String, TextEditingController> _respostaControllers = {};
  final Set<String> _salvandoResposta = {};

  @override
  void initState() {
    super.initState();
    _carregarMensagens();
  }

  @override
  void dispose() {
    _controlador.dispose();
    _scrollController.dispose();
    for (final c in _respostaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  
  TextEditingController _getRespostaController(String perguntaId) {
    return _respostaControllers.putIfAbsent(
      perguntaId,
      () => TextEditingController(),
    );
  }
  
  /// Normaliza texto removendo caracteres inválidos de encoding UTF-8
  /// e corrigindo possíveis problemas de codificação
  String _normalizarTexto(String texto) {
    if (texto.isEmpty) return texto;
    
    // Remove replacement character (�) - caractere de encoding inválido
    String normalizado = texto.replaceAll('\uFFFD', '');
    
    // Remove caracteres de controle exceto newline e tab
    normalizado = normalizado.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    // Remove múltiplos espaços consecutivos
    normalizado = normalizado.replaceAll(RegExp(r' {2,}'), ' ');
    
    return normalizado.trim();
  }
  
  Future<void> _salvarResposta(String perguntaId) async {
    final controller = _respostaControllers[perguntaId];
    if (controller == null || controller.text.trim().isEmpty) return;
    
    setState(() => _salvandoResposta.add(perguntaId));
    try {
      final saved = await widget.api.responderPergunta(
        widget.entrevistaId,
        questionId: perguntaId,
        texto: controller.text.trim(),
      );
      setState(() {
        _respostas = List.from(_respostas)..add(saved);
      });
      controller.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Resposta salva com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar resposta: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvandoResposta.remove(perguntaId));
    }
  }

  Future<void> _carregarMensagens() async {
    try {
      final msgs = await widget.api.listarMensagens(widget.entrevistaId);
      setState(() {
        _mensagens
          ..clear()
          ..addAll(msgs.map((m) => _fromApiMsg(m)));
      });
      // carrega perguntas e respostas persistidas
      try {
        final qs =
            await widget.api.listarPerguntasEntrevista(widget.entrevistaId);
        final asw =
            await widget.api.listarRespostasEntrevista(widget.entrevistaId);
        setState(() {
          _perguntas = qs.cast<Map<String, dynamic>>();
          _respostas = asw.cast<Map<String, dynamic>>();
        });
      } catch (_) {}
    } catch (_) {}
  }

  Map<String, dynamic> _fromApiMsg(Map m) {
    final role = (m['role'] ?? 'assistant') as String;
    final remetente = role == 'assistant' ? 'IA' : 'Recrutador';
    return {
      'remetente': remetente,
      'texto': m['conteudo'] ?? '',
      'timestamp':
          date_utils.DateUtils.parseParaBrasilia(m['criado_em']?.toString() ?? '') ?? date_utils.DateUtils.agora(),
    };
  }

  Future<void> _enviarMensagem(String texto) async {
    if (texto.trim().isEmpty || _enviando) return;
    setState(() {
      _mensagens.add({
        'remetente': 'Recrutador',
        'texto': texto,
        'timestamp': date_utils.DateUtils.agora()
      });
      _enviando = true;
    });
    _controlador.clear();
    try {
      final r = await widget.api.enviarMensagem(widget.entrevistaId, texto);
      final resp = r['resposta'] ?? {};
      setState(() => _mensagens.add(_fromApiMsg(resp)));
      // Se uma pergunta estiver selecionada, persiste como resposta
      if (_perguntaSelecionadaId != null) {
        try {
          final saved = await widget.api.responderPergunta(widget.entrevistaId,
              questionId: _perguntaSelecionadaId!, texto: texto);
          setState(() {
            _respostas = List.from(_respostas)..add(saved);
          });
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha ao enviar: $e')));
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

  // Tab 1: Lista de Perguntas e Respostas
  Widget _buildPerguntasTab() {
    return Card(
      child: _perguntas.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.question_answer,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Nenhuma pergunta gerada',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'Use a aba "Assistente" para gerar perguntas com IA',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _perguntas.length,
              itemBuilder: (context, index) {
                final pergunta = _perguntas[index];
                final perguntaId = pergunta['id'].toString();
                final resposta = _respostas.firstWhere(
                  (r) => r['question_id'] == perguntaId,
                  orElse: () => <String, dynamic>{},
                );
                final respostaController = _getRespostaController(perguntaId);
                final salvando = _salvandoResposta.contains(perguntaId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Pergunta ${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pergunta['kind']?.toString().toUpperCase() ??
                                    'TÉCNICA',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ),
                            // Botão de copiar pergunta
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: 'Copiar pergunta',
                              color: Colors.grey.shade600,
                              onPressed: () {
                                final textoPergunta = _normalizarTexto(
                                    pergunta['prompt']?.toString() ?? '');
                                Clipboard.setData(ClipboardData(text: textoPergunta));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📋 Pergunta copiada!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _normalizarTexto(pergunta['prompt']?.toString() ?? ''),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        if (resposta.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, 
                                      size: 16, color: Colors.green.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Resposta registrada:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(resposta['raw_text']?.toString() ?? ''),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: respostaController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Digite a resposta do candidato...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: salvando 
                                ? null 
                                : () => _salvarResposta(perguntaId),
                              icon: salvando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                              label: Text(salvando 
                                ? 'Salvando...' 
                                : 'Salvar Resposta'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Tab 2: Chat com IA
  Widget _buildChatTab() {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _mensagens.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('Inicie a conversa',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'A IA está pronta para auxiliar na entrevista',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _mensagens.length,
                      itemBuilder: (context, index) =>
                          _BolhaMensagem(mensagem: _mensagens[index]),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controlador,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem para a IA...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _enviando
                      ? null
                      : () => _enviarMensagem(_controlador.text),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(_enviando ? 'Enviando...' : 'Enviar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 3: Assistente IA (Gerar Perguntas)
  Widget _buildAssistenteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card: Gerar Perguntas com IA
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology,
                            color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gerar Perguntas com IA',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                              'A IA pode sugerir perguntas baseadas no perfil do candidato e requisitos da vaga',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _gerandoPerguntas
                        ? null
                        : () async {
                            setState(() => _gerandoPerguntas = true);
                            try {
                              await widget.api.gerarPerguntasAIParaEntrevista(
                                  widget.entrevistaId);
                              final qs = await widget.api
                                  .listarPerguntasEntrevista(
                                      widget.entrevistaId);
                              setState(() {
                                _perguntas = qs.cast<Map<String, dynamic>>();
                                if (_perguntaSelecionadaId == null &&
                                    _perguntas.isNotEmpty) {
                                  _perguntaSelecionadaId =
                                      _perguntas.first['id'].toString();
                                }
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '✨ ${_perguntas.length} perguntas geradas com sucesso!')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Falha ao gerar perguntas: $e')),
                              );
                            } finally {
                              if (mounted)
                                setState(() => _gerandoPerguntas = false);
                            }
                          },
                    icon: _gerandoPerguntas
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_gerandoPerguntas
                        ? 'Gerando Perguntas...'
                        : 'Gerar Perguntas Personalizadas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card: Adicionar Pergunta Manual
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text('Adicionar Pergunta Manual',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ctrl = TextEditingController();
                      await showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Adicionar Pergunta Manual'),
                          content: SizedBox(
                            width: 500,
                            child: TextField(
                              controller: ctrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Escreva a pergunta...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await widget.api.criarPerguntaManual(
                                      widget.entrevistaId,
                                      prompt: ctrl.text.trim());
                                  Navigator.of(context).pop();
                                  final qs = await widget.api
                                      .listarPerguntasEntrevista(
                                          widget.entrevistaId);
                                  if (!mounted) return;
                                  setState(() {
                                    _perguntas =
                                        qs.cast<Map<String, dynamic>>();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Pergunta adicionada com sucesso!')),
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Falha ao adicionar pergunta')),
                                  );
                                }
                              },
                              child: const Text('Adicionar'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Escrever Pergunta'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      foregroundColor: const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card: Perguntas Atuais
          if (_perguntas.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Perguntas Atuais',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_perguntas.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._perguntas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final q = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4F46E5).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF4F46E5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(q['prompt']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
                          Text('Entrevista em Andamento',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Candidato: ${widget.candidato} • Vaga: ${widget.vaga}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
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
                          side: const BorderSide(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _finalizando
                          ? null
                          : () async {
                              setState(() => _finalizando = true);
                              try {
                                final relatorio = await widget.api
                                    .gerarRelatorio(widget.entrevistaId);
                                widget.onFinalizar(relatorio);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Falha ao gerar relatório: $e')));
                              } finally {
                                if (mounted)
                                  setState(() => _finalizando = false);
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: Text(_finalizando
                          ? 'Gerando...'
                          : 'Finalizar & Gerar Relatório'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Corpo: Tabs com Perguntas, Chat e IA Assistente
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: TabBar(
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: const Color(0xFF4F46E5),
                    tabs: const [
                      Tab(icon: Icon(Icons.question_answer), text: 'Perguntas'),
                      Tab(
                          icon: Icon(Icons.chat_bubble_outline),
                          text: 'Chat IA'),
                      Tab(icon: Icon(Icons.psychology), text: 'Assistente'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Perguntas e Respostas
                      _buildPerguntasTab(),

                      // Tab 2: Chat com IA
                      _buildChatTab(),

                      // Tab 3: Assistente IA
                      _buildAssistenteTab(),
                    ],
                  ),
                ),
              ],
            ),
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
