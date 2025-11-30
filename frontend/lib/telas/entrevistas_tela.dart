import 'package:flutter/material.dart';

import '../componentes/tm_button.dart';
import '../componentes/tm_chip.dart';
import '../design_system/tm_tokens.dart';
import '../servicos/api_cliente.dart';

class EntrevistasTela extends StatefulWidget {
  final ApiCliente api;
  final void Function(String entrevistaId, String candidato, String vaga)
      onAbrirAssistida;
  final void Function(String entrevistaId, String candidato, String vaga)
      onAbrirRelatorio;

  const EntrevistasTela({
    super.key,
    required this.api,
    required this.onAbrirAssistida,
    required this.onAbrirRelatorio,
  });

  @override
  State<EntrevistasTela> createState() => _EntrevistasTelaState();
}

class _EntrevistasTelaState extends State<EntrevistasTela> {
  bool _carregando = true;
  final List<_InterviewCardData> _itens = [];
  final List<_InterviewCardData> _itensFiltrados = [];
  final Set<int> _hovered = <int>{};
  int _page = 1;
  final TextEditingController _buscaController = TextEditingController();
  DateTimeRange? _intervaloDatas;

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _itens.clear();
      final list =
          await widget.api.listarEntrevistas(page: _page, to: null, from: null);
      for (final m in list.whereType<Map<String, dynamic>>()) {
        final status = (m['status']?.toString() ?? '').toLowerCase();
        final tipo = status == 'completed'
            ? _InterviewType.concluded
            : _InterviewType.scheduled;
        final dt = DateTime.tryParse(m['scheduled_at']?.toString() ?? '')
            ?.toLocal();
        _itens.add(_InterviewCardData(
          id: m['id']?.toString() ?? '',
          tipo: tipo,
          candidato: m['candidate_name']?.toString() ?? 'Candidato',
          vaga: m['job_title']?.toString() ?? 'Vaga',
          status: status.isEmpty ? 'scheduled' : status,
          quando: dt,
          duracaoMin: null,
          perguntas: null,
          rating: null,
        ));
      }

      // Ordena: agendadas primeiro, depois recentes
      _itens.sort((a, b) {
        if (a.tipo != b.tipo) return a.tipo.index.compareTo(b.tipo.index);
        return (b.quando ?? DateTime(0)).compareTo(a.quando ?? DateTime(0));
      });
      _aplicarFiltros();
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aplicarFiltros() {
    final busca = _buscaController.text.toLowerCase().trim();
    final inicio = _intervaloDatas?.start;
    final fim = _intervaloDatas?.end;

    setState(() {
      _itensFiltrados
        ..clear()
        ..addAll(_itens.where((item) {
          final matchBusca = busca.isEmpty ||
              item.candidato.toLowerCase().contains(busca) ||
              item.vaga.toLowerCase().contains(busca);

          final dt = item.quando;
          final matchData = (inicio == null || fim == null || dt == null)
              ? true
              : _isSameOrAfter(dt, inicio) && _isSameOrBefore(dt, fim);

          return matchBusca && matchData;
        }));
    });
  }

  bool _isSameOrAfter(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return !aDate.isBefore(bDate);
  }

  bool _isSameOrBefore(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return !aDate.isAfter(bDate);
  }

  String _formatarIntervalo(DateTimeRange range) {
    final ini =
        '${range.start.day.toString().padLeft(2, '0')}/${range.start.month.toString().padLeft(2, '0')}';
    final fim =
        '${range.end.day.toString().padLeft(2, '0')}/${range.end.month.toString().padLeft(2, '0')}';
    return '$ini - $fim';
  }

  String _formatarDataPt(DateTime d) {
    const meses = [
      'jan.',
      'fev.',
      'mar.',
      'abr.',
      'mai.',
      'jun.',
      'jul.',
      'ago.',
      'set.',
      'out.',
      'nov.',
      'dez.'
    ];
    final dia = d.day.toString().padLeft(2, '0');
    final mes = meses[d.month - 1];
    final ano = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$dia de $mes de $ano, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1024 ? 2 : 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact: width < 720),
              const SizedBox(height: 24),
              if (_itens.isNotEmpty) _buildFilters(),
              if (_itens.isNotEmpty) const SizedBox(height: 16),
              if (_itens.isEmpty)
                _buildEmptyState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: _itensFiltrados.length,
                  itemBuilder: (context, index) =>
                      _buildCard(_itensFiltrados[index], index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final content = <Widget>[
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrevistas',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: TMTokens.text),
            ),
            SizedBox(height: 4),
            Text(
              'Gerencie e conduza entrevistas assistidas por IA',
              style: TextStyle(fontSize: 16, color: TMTokens.textMuted),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      TMButton('Agendar Entrevista',
          icon: Icons.add, onPressed: _agendarEntrevista),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Entrevistas',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: TMTokens.text)),
          const SizedBox(height: 4),
          const Text('Gerencie e conduza entrevistas assistidas por IA',
              style: TextStyle(fontSize: 16, color: TMTokens.textMuted)),
          const SizedBox(height: 16),
          TMButton('Agendar Entrevista',
              icon: Icons.add, onPressed: _agendarEntrevista),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildFilters() {
    final temFiltroAtivo =
        _buscaController.text.isNotEmpty || _intervaloDatas != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 12,
                        top: 12,
                        child: Icon(Icons.search,
                            size: 18, color: TMTokens.textMuted),
                      ),
                      TextField(
                        controller: _buscaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por candidato ou vaga...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: TMTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: TMTokens.border),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_intervaloDatas == null
                        ? 'Intervalo de datas'
                        : _formatarIntervalo(_intervaloDatas!)),
                    onPressed: () async {
                      final hoje = DateTime.now();
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: hoje.subtract(const Duration(days: 365)),
                        lastDate: hoje.add(const Duration(days: 365)),
                        initialDateRange: _intervaloDatas,
                        locale: const Locale('pt', 'BR'),
                      );
                      if (range != null && mounted) {
                        setState(() => _intervaloDatas = range);
                        _aplicarFiltros();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (temFiltroAtivo)
                  TMButton(
                    'Limpar',
                    icon: Icons.clear,
                    variant: TMButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        _buscaController.clear();
                        _intervaloDatas = null;
                        _aplicarFiltros();
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_InterviewCardData item, int index) {
    final isHovered = _hovered.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered.add(index)),
      onExit: (_) => setState(() => _hovered.remove(index)),
      child: Card(
        elevation: isHovered ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (item.tipo == _InterviewType.scheduled) {
              widget.onAbrirAssistida(item.id, item.candidato, item.vaga);
            } else {
              widget.onAbrirRelatorio(item.id, item.candidato, item.vaga);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: TMTokens.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.candidato,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: TMTokens.text)),
                          const SizedBox(height: 4),
                          Text(item.vaga,
                              style: const TextStyle(
                                  fontSize: 13, color: TMTokens.textMuted)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        TMChip.interviewStatus(_displayStatus(item.status)),
                        const SizedBox(width: 4),
                        _acoesMenu(item),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Meta
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (item.quando != null)
                      _meta(
                          Icons.calendar_month, _formatarDataPt(item.quando!)),
                    if (item.duracaoMin != null)
                      _meta(Icons.access_time, '${item.duracaoMin} minutos'),
                    if (item.perguntas != null)
                      _meta(Icons.message_outlined,
                          '${item.perguntas} perguntas'),
                  ],
                ),
                if (item.rating != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: TMTokens.border)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text('${item.rating!.toStringAsFixed(1)} / 5.0',
                            style: const TextStyle(color: TMTokens.text)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: TMTokens.textMuted),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(fontSize: 13, color: TMTokens.textMuted)),
      ],
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Agendada';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      case 'no_show':
        return 'No-Show';
      default:
        return status;
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Nenhuma entrevista encontrada',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TMTokens.text)),
              const SizedBox(height: 8),
              const Text('Agende uma nova entrevista para começar',
                  style: TextStyle(fontSize: 14, color: TMTokens.textMuted)),
              const SizedBox(height: 16),
              TMButton('Agendar Entrevista',
                  icon: Icons.add, onPressed: _agendarEntrevista),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acoesMenu(_InterviewCardData item) {
    const options = ['scheduled', 'completed', 'cancelled', 'no_show'];
    // Garante que o status atual está na lista de opções
    final currentStatus =
        options.contains(item.status) ? item.status : 'scheduled';

    return PopupMenuButton<String>(
      tooltip: 'Ações',
      onSelected: (value) async {
        switch (value) {
          case 'status':
            await _alterarStatus(item);
            break;
          case 'edit':
            await _editarEntrevista(item);
            break;
          case 'cancel':
            await _cancelarEntrevista(item);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: const [
              Icon(Icons.checklist, size: 18),
              SizedBox(width: 8),
              Text('Atualizar status'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_calendar, size: 18),
              SizedBox(width: 8),
              Text('Editar agendamento'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: const [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancelar/Excluir', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  Future<void> _alterarStatus(_InterviewCardData item) async {
    const options = ['scheduled', 'completed', 'cancelled', 'no_show'];
    final currentStatus =
        options.contains(item.status) ? item.status : 'scheduled';
    var selecionado = currentStatus;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) {
        return AlertDialog(
          title: const Text('Atualizar status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((s) => RadioListTile<String>(
                      value: s,
                      groupValue: selecionado,
                      onChanged: (v) {
                        if (v != null) {
                          setSB(() => selecionado = v);
                        }
                      },
                      title: Text(_displayStatus(s)),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        );
      }),
    );

    if (ok != true || selecionado == currentStatus) return;

    try {
      await widget.api.atualizarEntrevista(item.id, status: selecionado);
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Status da entrevista atualizado com sucesso')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar status')));
    }
  }

  Future<void> _editarEntrevista(_InterviewCardData item) async {
    DateTime quando =
        item.quando ?? DateTime.now().add(const Duration(hours: 1));
    bool loading = false;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSB) {
        return AlertDialog(
          title: const Text('Editar agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(_formatarDataPt(quando)),
                subtitle: const Text('Toque para alterar'),
                onTap: () async {
                  final novo = await _selecionarDataHora(quando);
                  if (novo != null) {
                    setSB(() => quando = novo);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setSB(() => loading = true);
                      try {
                        await widget.api
                            .atualizarEntrevista(item.id, scheduledAt: quando);
                        Navigator.pop(ctx, true);
                      } catch (_) {
                        setSB(() => loading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Falha ao atualizar agendamento')),
                          );
                        }
                      }
                    },
              child: Text(loading ? 'Salvando...' : 'Salvar'),
            ),
          ],
        );
      }),
    );

    if (confirmou == true) {
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Agendamento atualizado com sucesso')));
      }
    }
  }

  Future<void> _cancelarEntrevista(_InterviewCardData item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar/Excluir entrevista'),
        content: Text(
            'Deseja cancelar a entrevista de ${item.candidato} para ${item.vaga}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Manter')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.api.atualizarEntrevista(item.id, status: 'cancelled');
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Entrevista cancelada/excluída com sucesso')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Falha ao cancelar/excluir a entrevista')));
    }
  }

  Future<DateTime?> _selecionarDataHora(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    final base = time != null
        ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
        : DateTime(date.year, date.month, date.day, initial.hour, initial.minute);
    return base.toLocal();
  }

  Future<void> _agendarEntrevista() async {
    final jobs = await widget.api.vagas();
    final cands = await widget.api.candidatos();
    if (!mounted) return;
    String? jobId;
    String? candidateId;
    String mode = 'online';
    DateTime when = DateTime.now().add(const Duration(days: 1));
    bool loading = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setSB) {
        return AlertDialog(
          title: const Text('Agendar Entrevista'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: jobId,
                  items: jobs
                      .map<DropdownMenuItem<String>>((j) => DropdownMenuItem(
                          value: j['id'].toString(),
                          child: Text(j['title']?.toString() ?? 'Vaga')))
                      .toList(),
                  onChanged: (v) => setSB(() => jobId = v),
                  decoration: const InputDecoration(labelText: 'Vaga'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: candidateId,
                  items: cands
                      .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['nome']?.toString() ??
                              c['full_name']?.toString() ??
                              'Candidato')))
                      .toList(),
                  onChanged: (v) => setSB(() => candidateId = v),
                  decoration: const InputDecoration(labelText: 'Candidato'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                    DropdownMenuItem(
                        value: 'on_site', child: Text('Presencial')),
                    DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                  ],
                  onChanged: (v) => setSB(() => mode = v ?? 'online'),
                  decoration: const InputDecoration(labelText: 'Modo'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('Quando: ${_formatarDataPt(when)}')),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                          context: context,
                          initialDate: when,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)));
                      if (!context.mounted) return;
                      if (date != null) {
                        final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(when));
                        if (time != null) {
                          setSB(() => when = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute));
                        } else {
                          setSB(() => when = DateTime(date.year, date.month,
                              date.day, when.hour, when.minute));
                        }
                      }
                    },
                    child: const Text('Alterar'),
                  )
                ])
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: (loading || jobId == null || candidateId == null)
                  ? null
                  : () async {
                      setSB(() => loading = true);
                      try {
                        await widget.api.agendarEntrevista(
                            jobId: jobId!,
                            candidateId: candidateId!,
                            scheduledAt: when,
                            mode: mode);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await _carregar();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Entrevista agendada')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Falha ao agendar entrevista')));
                      } finally {
                        if (context.mounted) setSB(() => loading = false);
                      }
                    },
              child: Text(loading ? 'Agendando...' : 'Agendar'),
            )
          ],
        );
      }),
    );
  }
}

enum _InterviewType { scheduled, concluded }

class _InterviewCardData {
  final String id;
  final _InterviewType tipo;
  final String candidato;
  final String vaga;
  final String status; // Agendada, Em Andamento, Concluída, Cancelada
  final DateTime? quando;
  final int? duracaoMin;
  final int? perguntas;
  final double? rating;

  _InterviewCardData({
    required this.id,
    required this.tipo,
    required this.candidato,
    required this.vaga,
    required this.status,
    this.quando,
    this.duracaoMin,
    this.perguntas,
    this.rating,
  });
}
