import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../componentes/analise_curriculo_resultado.dart';
import '../design_system/tm_tokens.dart';
import '../modelos/analise_curriculo.dart';
import '../servicos/api_cliente.dart';
import '../componentes/tm_upload.dart';
import '../componentes/tm_button.dart';

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
  Map<String, dynamic>? _analiseBruta;
  Map<String, dynamic>? _candidato;
  Map<String, dynamic>? _vaga;
  String? _iaProvider;
  DateTime? _inicioUpload;
  double? _duracaoSegundos;

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
      if (!mounted) return;

      // Converter jobs da API em estrutura usada pelo dropdown
      // e filtrar apenas vagas abertas (status = 'open' no backend)
      final vagasAbertas = lista.where((vaga) {
        final status = (vaga['status'] ?? '').toString().toLowerCase();
        return status == 'open';
      }).map<Map<String, dynamic>>((vaga) {
        return {
          'id': vaga['id']?.toString(),
          'titulo': vaga['title']?.toString() ?? '',
          'status': vaga['status']?.toString() ?? '',
          // candidatos ainda não vem do backend; mantemos 0 até ter contagem real
          'candidatos': vaga['candidatos'] ?? 0,
        };
      }).toList();

      setState(() {
        _vagas = vagasAbertas;
        // Não seleciona vaga automaticamente; usuário deve escolher
        // Mantém seleção atual se ainda existir na lista
        if (_vagaSelecionadaId != null &&
            !_vagas.any((vaga) => vaga['id']?.toString() == _vagaSelecionadaId)) {
          _vagaSelecionadaId = null;
        }
      });
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
      const maxSizeBytes = 5 * 1024 * 1024; // 5MB
      
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

      if ((file.size) > maxSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('O arquivo excede o limite de 5MB.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() => _arquivo = file);
    }
  }

  /// Converte progress (pode ser String, int ou double) para double
  double? _parseProgress(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  Future<void> _simularUploadEAnalise() async {
    if (_arquivo == null || _vagaSelecionadaId == null) return;
    try {
      setState(() {
        _uploadStatus = UploadStatus.uploading;
        _uploadProgress = 10;
        _inicioUpload = DateTime.now();
        _duracaoSegundos = null;
      });

      final resp = await widget.api.uploadCurriculoBytes(
        bytes: _arquivo!.bytes!,
        filename: _arquivo!.name,
        candidato: {'nome': 'Candidato'},
        vagaId: _vagaSelecionadaId,
      );

      // Cast correto para evitar erros de tipo LinkedHashMap
      final cur = Map<String, dynamic>.from(resp['curriculo'] ?? {});
      final analiseRaw = cur['analise_json'] ?? cur['parsed_json'];
      
      // Parse do JSON se vier como string
      Map<String, dynamic> analiseMap;
      if (analiseRaw is String) {
        try {
          analiseMap = Map<String, dynamic>.from(
            jsonDecode(analiseRaw) as Map
          );
        } catch (e) {
          debugPrint('❌ Erro ao parsear análise JSON: $e');
          analiseMap = <String, dynamic>{};
        }
      } else if (analiseRaw is Map<String, dynamic>) {
        analiseMap = Map<String, dynamic>.from(analiseRaw);
      } else {
        analiseMap = <String, dynamic>{};
      }
      
      final job = Map<String, dynamic>.from(resp['ingestion_job'] ?? {});
      final cand = Map<String, dynamic>.from(resp['candidato'] ?? {});
      final vaga = Map<String, dynamic>.from(resp['vaga'] ?? {});
      final iaProvider = resp['ia_provider'] ?? resp['provider'] ?? analiseMap['provider'];

      if (job['id'] != null) {
        // Converter progress para double de forma segura
        final initialProgress = _parseProgress(job['progress']) ?? 20.0;
        setState(() {
          _uploadStatus = UploadStatus.parsing;
          _uploadProgress = initialProgress;
        });

        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 400));
          try {
            final j =
                await widget.api.getIngestionJob(job['id'].toString());
            final prog = _parseProgress(j['progress']) ?? _uploadProgress;
            setState(() {
              _uploadProgress = prog;
            });
            if ((j['status'] as String).toLowerCase() == 'completed') {
              break;
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() => _uploadStatus = UploadStatus.analyzing);
        }
      }

      final a = AnaliseCurriculo.fromJson(analiseMap);
      if (!mounted) return;
      final fim = DateTime.now();
      setState(() {
        _uploadStatus = UploadStatus.complete;
        _analise = a;
        _analiseBruta = analiseMap;
        _candidato = cand;
        _vaga = vaga;
        _iaProvider = iaProvider?.toString();
        if (_inicioUpload != null) {
          _duracaoSegundos =
              fim.difference(_inicioUpload!).inMilliseconds / 1000.0;
        }
      });

      widget.onUploaded(resp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadStatus = UploadStatus.error);
      _duracaoSegundos = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar/analisar currículo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetarUpload() {
    setState(() {
      _arquivo = null;
      _vagaSelecionadaId = null;
      _uploadStatus = UploadStatus.idle;
      _uploadProgress = 0.0;
      _analise = null;
      _dragActive = false;
      _analiseBruta = null;
      _candidato = null;
      _vaga = null;
      _iaProvider = null;
      _inicioUpload = null;
      _duracaoSegundos = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultadoDisponivel =
        _uploadStatus == UploadStatus.complete && _analise != null;
    final isWide = MediaQuery.of(context).size.width > 1080;

    final uploadCard = _buildUploadCard(resultadoDisponivel);
    final rightPane = Padding(
      padding: EdgeInsets.only(left: isWide ? 20 : 0, top: isWide ? 0 : 20),
      child: _buildResultadoPane(resultadoDisponivel),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: uploadCard),
                    Expanded(flex: 2, child: rightPane),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    uploadCard,
                    const SizedBox(height: 20),
                    rightPane,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Análise de Currículos',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: TMTokens.text,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Upload e análise inteligente de currículos com IA',
          style: TextStyle(color: TMTokens.secondary),
        ),
      ],
    );
  }

  Widget _buildUploadCard(bool resultadoDisponivel) {
    final canStartUpload = _arquivo != null &&
        _vagaSelecionadaId != null &&
        _uploadStatus == UploadStatus.idle;

    final tempo = _duracaoSegundos != null
        ? '${_duracaoSegundos!.toStringAsFixed(1)}s'
        : '--';
    final iaProvider = _iaProviderLabel();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.upload_file, color: TMTokens.primary),
                    SizedBox(width: 8),
                    Text(
                      'Upload de Currículo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (resultadoDisponivel)
                  TextButton.icon(
                    onPressed: _resetarUpload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Novo upload'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _vagaSelecionadaId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Vaga',
                hintText: 'Selecione uma vaga',
              ),
              items: _vagas.map((vaga) {
                final candidatos = vaga['candidatos'] ?? 0;
                return DropdownMenuItem<String>(
                  value: vaga['id']?.toString(),
                  child: Text(
                    '${vaga['titulo']} ($candidatos candidatos)',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) => _vagas.map((vaga) {
                final candidatos = vaga['candidatos'] ?? 0;
                return Text(
                  '${vaga['titulo']} ($candidatos candidatos)',
                  overflow: TextOverflow.ellipsis,
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _vagaSelecionadaId = value);
              },
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: _uploadStatus != UploadStatus.idle ? 0.6 : 1,
              child: MouseRegion(
                onEnter: (_) => _setDragActive(true),
                onExit: (_) => _setDragActive(false),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TMTokens.r12),
                  onTap: _uploadStatus == UploadStatus.idle ? _selecionarArquivo : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _arquivo != null
                        ? _buildArquivoSelecionado()
                        : TMUploadArea(
                            dragActive: _dragActive,
                            onPick: _selecionarArquivo,
                            helper: 'PDF, DOCX, TXT (máx. 5MB)',
                          ),
                  ),
                ),
              ),
            ),
            if (_uploadStatus != UploadStatus.idle &&
                _uploadStatus != UploadStatus.complete) ...[
              const SizedBox(height: 16),
              _buildProgressoUpload(),
            ],
            if (resultadoDisponivel) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(TMTokens.r8),
                  border: Border.all(color: const Color(0xFF22C55E)),
                ),
                child: const Text(
                  'Análise concluída com sucesso!',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(TMTokens.r8),
                border: Border.all(color: TMTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações da análise',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile('Tempo decorrido', tempo),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoTile(
                          'Último score',
                          _analise != null ? '${_analise!.matchingScore}%' : '--',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoTile('IA utilizada', iaProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TMButton(
                'Analisar Currículo com IA',
                icon: Icons.auto_awesome,
                variant: TMButtonVariant.primary,
                onPressed: canStartUpload ? _simularUploadEAnalise : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: TMTokens.secondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildResultadoPane(bool resultadoDisponivel) {
    if (!resultadoDisponivel) {
      if (_uploadStatus != UploadStatus.idle &&
          _uploadStatus != UploadStatus.error) {
        return _buildLoadingCard();
      }
      return _buildWaitingCard();
    }

    return AnaliseCurriculoResultado(
      analise: _analise!,
      analiseBruta: _analiseBruta,
      candidato: _candidato,
      vaga: _vaga,
      onAprovar: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidato marcado como aprovado.')),
        );
      },
      onGerarPerguntas: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use a aba Entrevistas para gerar perguntas com IA.')),
        );
      },
    );
  }

  Widget _buildWaitingCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TMTokens.r16),
        side: const BorderSide(
          color: TMTokens.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome, size: 48, color: TMTokens.secondary),
            SizedBox(height: 12),
            Text(
              'Aguardando Upload',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(
              'Faça upload de um currículo para iniciar a análise com IA',
              style: TextStyle(color: TMTokens.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    final status = () {
      switch (_uploadStatus) {
        case UploadStatus.uploading:
          return 'Enviando arquivo...';
        case UploadStatus.parsing:
          return 'Extraindo informações...';
        case UploadStatus.analyzing:
          return 'Analisando com IA...';
        default:
          return 'Processando...';
      }
    }();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${_uploadProgress.toInt()}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _uploadProgress / 100,
              backgroundColor: TMTokens.border,
              color: TMTokens.primary,
              minHeight: 8,
            ),
          ],
        ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TMTokens.r12),
        border: Border.all(color: TMTokens.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFF6FF),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: TMTokens.primary,
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
                        color: TMTokens.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDescricao,
                      style: const TextStyle(
                        fontSize: 14,
                        color: TMTokens.secondary,
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
                  color: TMTokens.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress / 100,
            backgroundColor: TMTokens.border,
            color: TMTokens.primary,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  String _iaProviderLabel() {
    final raw = (_iaProvider ?? _analiseBruta?['provider'] ?? '').toString();
    if (raw.isNotEmpty) {
      final lower = raw.toLowerCase();
      if (lower.contains('openrouter') || lower.contains('router')) {
        return 'OpenRouter';
      }
      if (lower.contains('groq')) {
        return 'Groq';
      }
      if (lower.contains('openai')) {
        return 'OpenAI';
      }
      return raw;
    }

    // Heurística: se veio campos típicos do OpenRouter, assume OpenRouter
    if (_analiseBruta != null &&
        (_analiseBruta!.containsKey('pontosFortesVaga') ||
            _analiseBruta!.containsKey('pontosFracosVaga'))) {
      return 'OpenRouter';
    }

    return 'OpenAI (padrão)';
  }
}
