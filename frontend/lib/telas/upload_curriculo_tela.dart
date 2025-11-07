import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../modelos/analise_curriculo.dart';
import '../servicos/api_cliente.dart';
import '../servicos/dados_mockados.dart';

enum UploadStatus { idle, uploading, parsing, analyzing, complete, error }

/// Tela de Upload de Currículo com análise por IA
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
  UploadStatus _uploadStatus = UploadStatus.idle;
  double _uploadProgress = 0.0;
  String? _vagaSelecionadaId;
  List<Map<String, dynamic>> _vagas = [];
  AnaliseCurriculo? _analise;
  bool _dragActive = false;

  void _setDragActive(bool value) {
    if (_uploadStatus != UploadStatus.idle) {
      value = false;
    }
    if (_dragActive == value) return;
    setState(() {
      _dragActive = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    try {
      final lista = await widget.api.vagas();
      if (mounted) {
        setState(() {
          _vagas = List<Map<String, dynamic>>.from(lista);
          if (_vagas.isNotEmpty) {
            _vagaSelecionadaId = _vagas.first['id']?.toString();
          }
        });
      }
    } catch (_) {
      // mantém lista vazia em caso de erro
    }
  }

  Future<void> _selecionarArquivo() async {
    if (_uploadStatus != UploadStatus.idle) return;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'txt', 'docx'],
    );
    
    if (res != null && res.files.isNotEmpty) {
      final file = res.files.first;
      // Validar tipo de arquivo
      final validTypes = ['pdf', 'txt', 'docx'];
      final extension = file.extension?.toLowerCase();
      
      if (extension == null || !validTypes.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, envie um arquivo PDF, DOCX ou TXT'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() => _arquivo = file);
    }
  }

  Future<void> _simularUploadEAnalise() async {
    if (_arquivo == null || _vagaSelecionadaId == null) return;

    // Upload
    setState(() {
      _uploadStatus = UploadStatus.uploading;
      _uploadProgress = 0.0;
    });

    await _animarProgresso(100, 10, 100);

    // Parsing
    if (!mounted) return;
    setState(() {
      _uploadStatus = UploadStatus.parsing;
      _uploadProgress = 0.0;
    });

    await _animarProgresso(100, 20, 150);

    // Analyzing
    if (!mounted) return;
    setState(() {
      _uploadStatus = UploadStatus.analyzing;
      _uploadProgress = 0.0;
    });

    await _animarProgresso(100, 5, 200);

    // Complete
    if (!mounted) return;
    
    final analiseMock = mockAnaliseCurriculo;

    if (!mounted) return;
    setState(() {
      _uploadStatus = UploadStatus.complete;
      _analise = analiseMock;
    });

    Map<String, dynamic>? vagaSelecionada;
    if (_vagaSelecionadaId != null) {
      for (final vaga in _vagas) {
        if (vaga['id']?.toString() == _vagaSelecionadaId) {
          vagaSelecionada = vaga;
          break;
        }
      }
    }

    final candidatoMock =
        mockCandidatos.isNotEmpty ? mockCandidatos.first.toJson() : {'nome': 'Candidato'};

    widget.onUploaded({
      'candidato': candidatoMock,
      'vaga': vagaSelecionada,
      'curriculo': {
        'nome_arquivo': _arquivo?.name ?? 'curriculo.pdf',
        'tamanho_bytes': _arquivo?.size,
        'analise_json': analiseMock.toJson(),
      },
      'entrevista': null,
    });
  }

  Future<void> _animarProgresso(
      int targetProgress, int increment, int delayMs) async {
    while (_uploadProgress < targetProgress) {
      await Future.delayed(Duration(milliseconds: delayMs));
      if (!mounted) return;
      setState(() {
        _uploadProgress = (_uploadProgress + increment).clamp(0, 100);
      });
    }
  }

  void _resetarUpload() {
    setState(() {
      _arquivo = null;
      _vagaSelecionadaId = _vagas.isNotEmpty ? _vagas.first['id']?.toString() : null;
      _uploadStatus = UploadStatus.idle;
      _uploadProgress = 0.0;
      _analise = null;
      _dragActive = false;
    });
  }

  Color _getRecomendacaoColor(String recomendacao) {
    switch (recomendacao) {
      case 'Forte Recomendação':
        return Colors.green;
      case 'Recomendado':
        return Colors.blue;
      case 'Considerar':
        return Colors.orange;
      case 'Não Recomendado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green.shade600;
    if (score >= 70) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    // Se a análise estiver completa, mostra resultado
    if (_uploadStatus == UploadStatus.complete && _analise != null) {
      return _buildResultadoAnalise();
    }

    // Senão, mostra formulário de upload
    return _buildFormularioUpload();
  }

  Widget _buildResultadoAnalise() {
    final analise = _analise!;
    final matchingScore = analise.matchingScore;
    final recomendacao = analise.recomendacao;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Análise de Currículo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Resultado da análise por IA',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _resetarUpload,
                icon: const Icon(Icons.refresh),
                label: const Text('Analisar Novo Currículo'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF93C5FD), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                      child: Center(
                        child: Text(
                          '$matchingScore',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matching Score',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Compatibilidade com a vaga',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getRecomendacaoColor(recomendacao).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recomendacao,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getRecomendacaoColor(recomendacao),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resumo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Resumo da Análise',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    analise.resumo,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pontos Fortes e Atenção
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pontos Fortes
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up,
                                color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Pontos Fortes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...analise.pontosFortes.map((ponto) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ponto,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Pontos de Atenção
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Pontos de Atenção',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...analise.pontosAtencao.map((ponto) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.orange.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ponto,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Aderência aos Requisitos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.track_changes, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Aderência aos Requisitos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Análise detalhada de cada requisito da vaga',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  ...analise.aderenciaRequisitos.map((item) {
                    final requisito = item.requisito;
                    final score = item.score;
                    final evidencias = item.evidencias;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  requisito,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(score),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: score / 100,
                            backgroundColor: Colors.grey.shade200,
                            color: _getScoreColor(score),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          if (evidencias.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...evidencias.map((evidencia) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, bottom: 6),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        evidencia as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Ações
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Agendar Entrevista'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aprovar Candidato'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reprovar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioUpload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload de Currículo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Envie currículos para análise automática por IA',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Seleção de Vaga
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar Vaga',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Escolha a vaga para qual está recrutando',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _vagaSelecionadaId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Selecione uma vaga...'),
                    items: _vagas.map((vaga) {
                      final candidatos = vaga['candidatos'] ?? 0;
                      return DropdownMenuItem<String>(
                        value: vaga['id']?.toString(),
                        child: Text(
                          '${vaga['titulo']} ($candidatos candidatos)',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _vagaSelecionadaId = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Área de Upload (Drag and Drop)
          Card(
            child: MouseRegion(
              onEnter: (_) => _setDragActive(true),
              onExit: (_) => _setDragActive(false),
              child: InkWell(
                onTap: _uploadStatus == UploadStatus.idle
                    ? _selecionarArquivo
                    : null,
                onHover: (hovering) => _setDragActive(hovering),
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _dragActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _dragActive
                        ? const Color(0xFFEFF6FF)
                        : Colors.transparent,
                  ),
                  child: _arquivo != null
                      ? _buildArquivoSelecionado()
                      : _buildAreaUpload(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progresso do Upload
          if (_uploadStatus != UploadStatus.idle &&
              _uploadStatus != UploadStatus.complete)
            _buildProgressoUpload(),

          if (_uploadStatus != UploadStatus.idle &&
              _uploadStatus != UploadStatus.complete)
            const SizedBox(height: 24),

          // Informações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como funciona:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Após o upload, nossa IA irá extrair as informações do currículo, analisar a experiência, habilidades e formação do candidato, e calcular um score de compatibilidade com os requisitos da vaga selecionada. O processo leva cerca de 10 segundos.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botão de Ação
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _arquivo != null &&
                      _vagaSelecionadaId != null &&
                      _uploadStatus == UploadStatus.idle
                  ? _simularUploadEAnalise
                  : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analisar Currículo com IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArquivoSelecionado() {
    return Column(
      children: [
        const Icon(
          Icons.description,
          size: 64,
          color: Color(0xFF2563EB),
        ),
        const SizedBox(height: 16),
        Text(
          _arquivo!.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${(_arquivo!.size / 1024).toStringAsFixed(2)} KB',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        if (_uploadStatus == UploadStatus.idle) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() => _arquivo = null),
            icon: const Icon(Icons.close),
            label: const Text('Remover arquivo'),
          ),
        ],
      ],
    );
  }

  Widget _buildAreaUpload() {
    return Column(
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        const Text(
          'Arraste e solte o currículo aqui',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ou clique para selecionar',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Formatos aceitos: PDF, DOCX, TXT (máx. 10MB)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressoUpload() {
    String statusTexto = '';
    String statusDescricao = '';

    switch (_uploadStatus) {
      case UploadStatus.uploading:
        statusTexto = 'Enviando arquivo...';
        statusDescricao = 'Fazendo upload do currículo';
        break;
      case UploadStatus.parsing:
        statusTexto = 'Extraindo informações...';
        statusDescricao = 'Processando conteúdo do documento';
        break;
      case UploadStatus.analyzing:
        statusTexto = 'Analisando com IA...';
        statusDescricao = 'Avaliando compatibilidade com a vaga';
        break;
      default:
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF6FF),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTexto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescricao,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_uploadProgress.toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress / 100,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF2563EB),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
