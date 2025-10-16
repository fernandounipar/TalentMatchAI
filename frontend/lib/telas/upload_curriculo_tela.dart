import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../componentes/widgets.dart';
import '../servicos/api_cliente.dart';

/// Tela de Upload de Currículo
class UploadCurriculoTela extends StatefulWidget {
  final ApiCliente api;
  final void Function(Map<String, dynamic> resultado) onUploaded;
  final VoidCallback onBack;

  const UploadCurriculoTela({
    super.key,
    required this.api,
    required this.onUploaded,
    required this.onBack,
  });

  @override
  State<UploadCurriculoTela> createState() => _UploadCurriculoTelaState();
}

class _UploadCurriculoTelaState extends State<UploadCurriculoTela> {
  PlatformFile? _arquivo;
  bool _enviando = false;
  String? _vagaSelecionadaId;
  List<Map<String, dynamic>> _vagas = [];

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    try {
      final lista = await widget.api.vagas();
      setState(() {
        _vagas = List<Map<String, dynamic>>.from(lista);
        if (_vagas.isNotEmpty) _vagaSelecionadaId = _vagas.first['id'];
      });
    } catch (_) {
      // mantém lista vazia em caso de erro
    }
  }

  Future<void> _selecionarArquivo() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'txt', 'docx'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _arquivo = res.files.first);
    }
  }

  Future<void> _enviar() async {
    if (_arquivo == null) return;
    setState(() => _enviando = true);
    try {
      final bytes = _arquivo!.bytes;
      if (bytes == null) throw Exception('Arquivo sem bytes');
      final resultado = await widget.api.uploadCurriculoBytes(
        bytes: bytes,
        filename: _arquivo!.name,
        candidato: {'nome': 'Candidato'},
        vagaId: _vagaSelecionadaId,
      );
      widget.onUploaded(resultado);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no upload: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão Voltar
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Voltar'),
        ),
        const SizedBox(height: 8),

        // Título
        const Text(
          'Upload de Currículo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Envie o currículo do candidato para análise com IA',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        // Card de Upload
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seleção de Vaga
                const Text('Selecione a vaga:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _vagaSelecionadaId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _vagas
                      .map((v) => DropdownMenuItem(
                            value: v['id'] as String,
                            child: Text(v['titulo'] as String),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _vagaSelecionadaId = value),
                ),
                const SizedBox(height: 24),

                // Área de Upload
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.indigo.shade200, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.indigo.shade50.withOpacity(0.3),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.indigo.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Arraste o arquivo ou clique para selecionar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Formatos aceitos: PDF, TXT, DOCX (máx. 10MB)',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _selecionarArquivo,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Selecionar Arquivo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      if (_arquivo != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _arquivo!.name,
                                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _arquivo = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Informações adicionais
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'A IA analisará o currículo e identificará competências, experiências e compatibilidade com a vaga.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botões de Ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    BotaoPrimario(
                      texto: _enviando ? 'Enviando...' : 'Analisar com IA',
                      icone: Icons.psychology,
                      onPressed: !_enviando && _arquivo != null ? _enviar : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
