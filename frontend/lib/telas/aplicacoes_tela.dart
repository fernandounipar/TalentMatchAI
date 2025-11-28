import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';
import '../design_system/tm_tokens.dart';
import '../componentes/tm_button.dart';
import '../componentes/tm_chip.dart';

class AplicacoesTela extends StatefulWidget {
  final ApiCliente api;

  const AplicacoesTela({super.key, required this.api});

  @override
  State<AplicacoesTela> createState() => _AplicacoesTelaState();
}

class _AplicacoesTelaState extends State<AplicacoesTela> {
  bool _carregando = false;
  List<dynamic> _vagas = [];
  String? _vagaSelecionadaId;

  // Pipeline data
  Map<String, dynamic>? _pipeline;
  List<dynamic> _stages = [];
  List<dynamic> _applications = [];

  // Drag state
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() => _carregando = true);
    try {
      final vagas = await widget.api.vagas(limit: 100, status: 'open');
      setState(() {
        _vagas = vagas;
        if (_vagas.isNotEmpty) {
          _vagaSelecionadaId = _vagas.first['id'].toString();
          _carregarPipeline();
        } else {
          _carregando = false;
        }
      });
    } catch (e) {
      setState(() => _carregando = false);
      _erro('Erro ao carregar vagas: $e');
    }
  }

  Future<void> _carregarPipeline() async {
    if (_vagaSelecionadaId == null) return;
    setState(() => _carregando = true);
    try {
      // Carregar pipeline e estágios
      final pData = await widget.api.obterPipeline(_vagaSelecionadaId!);

      // Carregar candidaturas
      final apps =
          await widget.api.listarCandidaturas(jobId: _vagaSelecionadaId);

      setState(() {
        _pipeline = pData['pipeline'];
        _stages = pData['stages'] ?? [];
        _applications = apps;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      _erro('Erro ao carregar quadro: $e');
    }
  }

  Future<void> _moverCandidatura(String appId, String toStageId) async {
    // Optimistic update
    final appIndex =
        _applications.indexWhere((a) => a['id'].toString() == appId);
    if (appIndex == -1) return;

    final oldStage = _applications[appIndex]['stage'];
    final newStageName =
        _stages.firstWhere((s) => s['id'].toString() == toStageId)['name'];

    setState(() {
      _applications[appIndex]['stage'] = newStageName;
      // Precisamos atualizar o stage_id se tivéssemos essa info no objeto application,
      // mas o backend retorna 'stage' como nome. O importante é o visual atualizar.
    });

    try {
      await widget.api.moverCandidatura(
        applicationId: appId,
        toStageId: toStageId,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _applications[appIndex]['stage'] = oldStage;
      });
      _erro('Erro ao mover candidatura: $e');
    }
  }

  void _erro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_carregando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_vagas.isEmpty)
            _buildEmptyState()
          else
            Expanded(child: _buildKanbanBoard()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quadro de Aplicações',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: TMTokens.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gerencie o fluxo de candidatos por vaga',
              style: TextStyle(fontSize: 16, color: TMTokens.textMuted),
            ),
          ],
        ),
        if (_vagas.isNotEmpty)
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TMTokens.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _vagaSelecionadaId,
                isExpanded: true,
                hint: const Text('Selecione uma vaga'),
                items: _vagas.map((v) {
                  return DropdownMenuItem<String>(
                    value: v['id'].toString(),
                    child: Text(
                      v['title'] ?? 'Sem título',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _vagaSelecionadaId = val);
                    _carregarPipeline();
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.work_off_outlined,
              size: 64, color: TMTokens.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma vaga aberta encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie uma vaga para começar a receber candidaturas.',
            style: TextStyle(color: TMTokens.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular largura das colunas
        // Se tela pequena, scroll horizontal. Se grande, fit.
        final minColWidth = 280.0;
        final totalWidth = _stages.length * (minColWidth + 16.0);
        final useScroll = totalWidth > constraints.maxWidth;

        Widget content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _stages.map((stage) {
            return Container(
              width: minColWidth,
              margin: const EdgeInsets.only(right: 16),
              child: _buildKanbanColumn(stage),
            );
          }).toList(),
        );

        if (useScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }

        // Se couber, expandir colunas para preencher espaço
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _stages.map((stage) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildKanbanColumn(stage),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKanbanColumn(Map<String, dynamic> stage) {
    final stageName = stage['name'] ?? '';
    final stageId = stage['id'].toString();

    // Filtrar aplicações deste estágio
    // O backend retorna 'stage' com o nome do estágio atual
    final apps = _applications.where((a) {
      final s = a['stage']?.toString() ?? '';
      return s == stageName;
    }).toList();

    return DragTarget<String>(
      onWillAccept: (data) => true,
      onAccept: (appId) {
        _moverCandidatura(appId, stageId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isHovered
                ? TMTokens.primary.withOpacity(0.05)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: isHovered ? Border.all(color: TMTokens.primary) : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stageName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TMTokens.text,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${apps.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TMTokens.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Cards list
              Expanded(
                child: ListView.separated(
                  itemCount: apps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildCard(apps[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> app) {
    final appId = app['id'].toString();
    final candidateName = app['candidate_name'] ?? 'Candidato';
    final score = app['score'] ?? 0; // Se tiver score no futuro

    return Draggable<String>(
      data: appId,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TMTokens.primary),
          ),
          child: Text(candidateName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _cardContent(app),
      ),
      onDragStarted: () => setState(() => _isDragging = true),
      onDragEnd: (_) => setState(() => _isDragging = false),
      child: _cardContent(app),
    );
  }

  Widget _cardContent(Map<String, dynamic> app) {
    final candidateName = app['candidate_name'] ?? 'Candidato';
    final createdAt = DateTime.tryParse(app['created_at']?.toString() ?? '');
    final dateStr =
        createdAt != null ? '${createdAt.day}/${createdAt.month}' : '--/--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            candidateName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: TMTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entrou: $dateStr',
                style: const TextStyle(fontSize: 12, color: TMTokens.textMuted),
              ),
              const Icon(Icons.more_horiz, size: 16, color: TMTokens.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
