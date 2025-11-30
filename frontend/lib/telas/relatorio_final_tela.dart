import 'package:flutter/material.dart';
import '../componentes/widgets.dart';
import '../servicos/api_cliente.dart'; // Import necessário
import '../utils/date_utils.dart' as date_utils;

/// Tela de Relatório Final da Entrevista
class RelatorioFinalTela extends StatefulWidget {
  final String candidato;
  final String vaga;
  final VoidCallback onVoltar;
  final Map<String, dynamic>? relatorio;
  final ApiCliente? api; // Opcional, mas necessário para CRUD

  const RelatorioFinalTela({
    super.key,
    required this.candidato,
    required this.vaga,
    required this.onVoltar,
    this.relatorio,
    this.api,
  });

  @override
  State<RelatorioFinalTela> createState() => _RelatorioFinalTelaState();
}

class _RelatorioFinalTelaState extends State<RelatorioFinalTela> {
  late Map<String, dynamic>? _relatorio;
  bool _carregando = false;
  bool _processandoDecisao = false;
  String? _statusDecisao; // 'approved', 'rejected', null

  @override
  void initState() {
    super.initState();
    _relatorio = widget.relatorio;
    // Verificar se já tem uma decisão prévia
    final result = _relatorio?['result'] ?? _relatorio?['interview_result'];
    if (result == 'approved') {
      _statusDecisao = 'approved';
    } else if (result == 'rejected') {
      _statusDecisao = 'rejected';
    }
  }

  /// Aprovar candidato e finalizar a vaga
  Future<void> _aprovarCandidato() async {
    if (widget.api == null || _relatorio == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprovar Candidato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja aprovar ${widget.candidato} para a vaga ${widget.vaga}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'A vaga será finalizada e marcada como preenchida.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Aprovar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processandoDecisao = true);
    try {
      final jobId = _relatorio!['job_id']?.toString() ?? '';
      final interviewId = _relatorio!['interview_id']?.toString() ?? '';
      final candidateId = _relatorio!['candidate_id']?.toString();
      final candidateName = _relatorio!['candidate_name']?.toString() ?? widget.candidato;
      final candidateEmail = _relatorio!['candidate_email']?.toString() ?? '';

      if (jobId.isEmpty) {
        throw Exception('ID da vaga não encontrado no relatório');
      }

      await widget.api!.finalizarVaga(
        jobId,
        candidateId: candidateId,
        candidateName: candidateName,
        candidateEmail: candidateEmail,
        interviewId: interviewId.isNotEmpty ? interviewId : null,
      );

      if (mounted) {
        setState(() => _statusDecisao = 'approved');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$candidateName aprovado! Vaga finalizada.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aprovar candidato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processandoDecisao = false);
    }
  }

  /// Reprovar candidato
  Future<void> _reprovarCandidato() async {
    if (widget.api == null || _relatorio == null) return;

    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprovar Candidato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja reprovar ${widget.candidato} para a vaga ${widget.vaga}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo da reprovação (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Descreva o motivo...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.cancel),
            label: const Text('Reprovar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processandoDecisao = true);
    try {
      final jobId = _relatorio!['job_id']?.toString() ?? '';
      final interviewId = _relatorio!['interview_id']?.toString() ?? '';
      final candidateId = _relatorio!['candidate_id']?.toString();

      if (jobId.isEmpty) {
        throw Exception('ID da vaga não encontrado no relatório');
      }

      await widget.api!.reprovarCandidato(
        jobId,
        candidateId: candidateId,
        interviewId: interviewId.isNotEmpty ? interviewId : null,
        reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
      );

      if (mounted) {
        setState(() => _statusDecisao = 'rejected');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.white),
                const SizedBox(width: 8),
                Text('${widget.candidato} foi reprovado.'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reprovar candidato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processandoDecisao = false);
    }
  }

  Future<void> _deletarRelatorio() async {
    if (widget.api == null || _relatorio == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Relatório'),
        content: const Text(
            'Tem certeza que deseja excluir este relatório? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _carregando = true);
    try {
      final id = _relatorio!['id'] ?? _relatorio!['report_id'];
      if (id == null) throw Exception('ID do relatório não encontrado');

      await widget.api!.deletarRelatorio(id.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório excluído com sucesso')),
        );
        widget.onVoltar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editarRelatorio() async {
    if (widget.api == null || _relatorio == null) return;

    final resumoController = TextEditingController(
        text: _relatorio!['resumo'] ?? _relatorio!['summary_text'] ?? '');
    String recomendacao = (_relatorio!['recomendacao'] ??
            _relatorio!['recommendation'] ??
            'PENDING')
        .toString()
        .toUpperCase();

    // Mapeamento para UI (EN -> PT)
    final recOptions = ['APPROVE', 'MAYBE', 'REJECT', 'PENDING'];
    final recLabels = {
      'APPROVE': 'Aprovar',
      'MAYBE': 'Dúvida',
      'REJECT': 'Reprovar',
      'PENDING': 'Pendente',
    };

    // Garante que o valor atual esteja na lista
    if (!recOptions.contains(recomendacao)) {
      if (recomendacao == 'APROVAR')
        recomendacao = 'APPROVE';
      else if (recomendacao == 'DÚVIDA' || recomendacao == 'DUVIDA')
        recomendacao = 'MAYBE';
      else if (recomendacao == 'REPROVAR')
        recomendacao = 'REJECT';
      else
        recomendacao = 'PENDING';
    }

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar Relatório'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recomendação',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: recomendacao,
                    items: recOptions.map((r) {
                      return DropdownMenuItem(
                          value: r, child: Text(recLabels[r] ?? r));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => recomendacao = v);
                    },
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Resumo Executivo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: resumoController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Edite o resumo do relatório...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (changed != true) return;

    setState(() => _carregando = true);
    try {
      final id = _relatorio!['id'] ?? _relatorio!['report_id'];
      if (id == null) throw Exception('ID do relatório não encontrado');

      final payload = {
        'summary_text': resumoController.text,
        'recommendation': recomendacao,
      };

      final atualizado =
          await widget.api!.atualizarRelatorio(id.toString(), payload);

      if (mounted) {
        setState(() {
          // Atualiza o estado local mesclando os dados
          _relatorio = {...?_relatorio, ...atualizado};

          // Se o backend retornar chaves diferentes, garantimos a atualização local para refletir na UI imediatamente
          if (atualizado['summary_text'] != null) {
            _relatorio!['resumo'] = atualizado['summary_text'];
            _relatorio!['summary_text'] = atualizado['summary_text'];
          }
          if (atualizado['recommendation'] != null) {
            _relatorio!['recomendacao'] = atualizado['recommendation'];
            _relatorio!['recommendation'] = atualizado['recommendation'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório atualizado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao atualizar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mapeia estrutura do backend (interview_reports) e mantém compatibilidade com formatos antigos
    final rawScore =
        _relatorio?['pontuacao_geral'] ?? _relatorio?['overall_score'];
    double pontuacaoGeral;
    if (rawScore is num) {
      pontuacaoGeral = rawScore.toDouble();
      // Se vier 0-10, converte para 0-100 visualmente se necessário, ou mantém se o componente esperar 0-100
      // O componente BadgePontuacao parece esperar 0-100. Se vier <= 10, multiplicamos.
      if (pontuacaoGeral <= 10) pontuacaoGeral *= 10;
    } else {
      final rec = (_relatorio?['recomendacao'] ?? _relatorio?['recommendation'])
              ?.toString()
              .toUpperCase() ??
          '';
      if (rec == 'APROVAR' || rec == 'APPROVE') {
        pontuacaoGeral = 90;
      } else if (rec == 'DÚVIDA' || rec == 'DUVIDA' || rec == 'MAYBE') {
        pontuacaoGeral = 70;
      } else if (rec == 'REPROVAR' ||
          rec == 'REJECT' ||
          rec == 'NÃO RECOMENDADO') {
        pontuacaoGeral = 40;
      } else {
        pontuacaoGeral = 0;
      }
    }

    final recomendacaoRaw =
        (_relatorio?['recomendacao'] ?? _relatorio?['recommendation'])
                ?.toString()
                .toUpperCase() ??
            '';
    final recomendacao = () {
      switch (recomendacaoRaw) {
        case 'APROVAR':
        case 'APPROVE':
          return 'Aprovar';
        case 'DÚVIDA':
        case 'DUVIDA':
        case 'MAYBE':
          return 'Dúvida';
        case 'REPROVAR':
        case 'REJECT':
        case 'NÃO RECOMENDADO':
          return 'Reprovar';
        default:
          return recomendacaoRaw.isEmpty ? 'Sem recomendação' : recomendacaoRaw;
      }
    }();

    final resumo =
        (_relatorio?['resumo'] ?? _relatorio?['summary_text'])?.toString() ??
            'Resumo não disponível para esta entrevista.';

    final analiseDetalhada = <String, num>{
      if (_relatorio?['competencias'] is List)
        for (final item in _relatorio!['competencias'] as List)
          if (item is Map && item['nome'] != null && item['nota'] != null)
            item['nome'].toString(): (item['nota'] as num),
    };

    // Converte strengths/pontos_fortes para List<String> de forma segura
    List<String> _toStringList(dynamic value) {
      if (value == null) return const <String>[];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value];
      return const <String>[];
    }

    final pontosFortes = _toStringList(_relatorio?['pontos_fortes']).isNotEmpty
        ? _toStringList(_relatorio?['pontos_fortes'])
        : _toStringList(_relatorio?['strengths']);

    final pontosMelhoria =
        _toStringList(_relatorio?['pontos_melhoria']).isNotEmpty
            ? _toStringList(_relatorio?['pontos_melhoria'])
            : _toStringList(_relatorio?['risks']);

    // Buscar respostas em destaque do relatório ou do content (JSON interno)
    final contentData = _relatorio?['content'] is Map 
        ? _relatorio!['content'] as Map<String, dynamic>
        : null;
    final respostasDestaque = (_relatorio?['respostas_destaque'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        (contentData?['respostas_destaque'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão Voltar
          TextButton.icon(
            onPressed: widget.onVoltar,
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
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Candidato: ${widget.candidato} • Vaga: ${widget.vaga}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerado em: ${_formatarData(_relatorio?['gerado_em'] ?? _relatorio?['created_at'])}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Relatório exportado como PDF')),
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
                            const SnackBar(
                                content: Text('Relatório compartilhado')),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Compartilhar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                      ),
                      // Menu de Opções (CRUD)
                      if (widget.api != null) ...[
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'edit') _editarRelatorio();
                            if (value == 'delete') _deletarRelatorio();
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Editar'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Excluir',
                                    style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  color: _corRecomendacao(recomendacao).withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        BadgePontuacao(pontuacao: pontuacaoGeral, tamanho: 90),
                        const SizedBox(height: 16),
                        const Text(
                          'Pontuação Geral',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          resumo,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Análise por Competência',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ...analiseDetalhada.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key,
                                          style: const TextStyle(fontSize: 13)),
                                      Text('${entry.value}%',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
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
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...pontosFortes.map((ponto) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 20, color: Colors.green.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(ponto,
                                        style: const TextStyle(
                                            fontSize: 14, height: 1.5)),
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
                            Icon(Icons.trending_up,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Pontos de Melhoria',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...pontosMelhoria.map((ponto) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline,
                                      size: 20, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(ponto,
                                        style: const TextStyle(
                                            fontSize: 14, height: 1.5)),
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

          ...respostasDestaque.map(
            (resposta) => _cardResposta(
              pergunta: resposta['pergunta']?.toString() ?? '',
              categoria: resposta['categoria']?.toString() ?? '',
              pontuacao:
                  (resposta['nota'] ?? resposta['pontuacao'] ?? 0) as num,
              feedback: resposta['feedback']?.toString() ?? '',
            ),
          ),
          if (respostasDestaque.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Nenhuma resposta em destaque disponível.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 32),

          // Card de Decisão do Recrutador
          if (widget.api != null) ...[
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                          child: const Icon(
                            Icons.gavel,
                            color: Color(0xFF4F46E5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decisão do Recrutador',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Avalie o candidato e tome uma decisão final',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge de status da IA
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _corRecomendacao(recomendacao).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _corRecomendacao(recomendacao),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 16,
                                color: _corRecomendacao(recomendacao),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'IA: $recomendacao',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _corRecomendacao(recomendacao),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Status atual da decisão
                    if (_statusDecisao != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _statusDecisao == 'approved'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _statusDecisao == 'approved'
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _statusDecisao == 'approved'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _statusDecisao == 'approved'
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusDecisao == 'approved'
                                        ? 'Candidato Aprovado ✓'
                                        : 'Candidato Reprovado',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _statusDecisao == 'approved'
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _statusDecisao == 'approved'
                                        ? 'A vaga foi finalizada e marcada como preenchida.'
                                        : 'O candidato foi marcado como reprovado para esta vaga.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _statusDecisao == 'approved'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _processandoDecisao
                                  ? null
                                  : _reprovarCandidato,
                              icon: _processandoDecisao
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cancel),
                              label: const Text('Reprovar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _processandoDecisao
                                  ? null
                                  : _aprovarCandidato,
                              icon: _processandoDecisao
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: const Text('Aprovar e Finalizar Vaga'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Ao aprovar, a vaga será finalizada automaticamente e não receberá mais candidaturas.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Próximos passos e ações podem ser derivados futuramente a partir do relatório
        ],
      ),
    );
  }

  Widget _cardResposta({
    required String pergunta,
    required String categoria,
    required num pontuacao,
    required String feedback,
  }) {
    final corCategoria = _corCategoria(categoria.toLowerCase());
    return Card(
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
                    pergunta,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: corCategoria.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoria.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: corCategoria,
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
                    i < pontuacao.round() ? Icons.star : Icons.star_border,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${pontuacao.toStringAsFixed(1)}/10',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feedback,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(dynamic valor) {
    if (valor == null) {
      final now = date_utils.DateUtils.agora();
      return '${now.day}/${now.month}/${now.year}';
    }
    if (valor is DateTime) {
      return '${valor.day}/${valor.month}/${valor.year}';
    }
    final parsed = date_utils.DateUtils.parseParaBrasilia(valor.toString());
    if (parsed == null) {
      final now = date_utils.DateUtils.agora();
      return '${now.day}/${now.month}/${now.year}';
    }
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  Color _corRecomendacao(String recomendacao) {
    switch (recomendacao.toLowerCase()) {
      case 'contratar':
      case 'aprovar':
        return Colors.green;
      case 'dúvida':
      case 'duvida':
      case 'considerar':
        return Colors.orange;
      case 'reprovar':
      case 'não_recomendado':
      case 'não recomendar':
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
