import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';
import '../design_system/tm_tokens.dart';
import '../modelos/historico.dart';

class HistoricoTela extends StatefulWidget {
  final ApiCliente api;
  final void Function(String entrevistaId, Map<String, dynamic> relatorio)?
      onAbrirRelatorio;

  const HistoricoTela({
    super.key,
    required this.api,
    this.onAbrirRelatorio,
  });

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela> {
  List<AtividadeHistorico> _atividades = [];
  bool _carregando = true;
  String _busca = '';
  String _filtroTipo = 'Todos';
  String _filtroEntidade = 'Todas';
  final Set<int> _hovered = <int>{};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final hist = await widget.api.historico();
      _atividades = hist.map<AtividadeHistorico>((e) {
        final m = e as Map<String, dynamic>;
        final created = DateTime.tryParse(
                m['criado_em']?.toString() ?? m['data']?.toString() ?? '') ??
            DateTime.now();
        final tipo = m['tipo']?.toString() ??
            (m['vaga'] != null ? 'Entrevista' : 'Edição');
        final entidade = m['entidade']?.toString() ??
            (tipo == 'Upload' ? 'Currículo' : 'Entrevista');
        final entidadeId =
            (m['entidade_id'] ?? m['entidadeId'] ?? m['id'] ?? '').toString();
        final usuario = (m['usuario'] ?? m['candidato'] ?? '').toString();
        final vaga = m['vaga']?.toString();
        final temRelatorio = m['tem_relatorio'] == true;

        final descricaoBackend = m['descricao']?.toString();
        final descricao = descricaoBackend ??
            (() {
              if (tipo == 'Upload') {
                final filename = m['filename']?.toString();
                return 'Upload de currículo ${filename ?? ''}'.trim();
              }
              if (tipo == 'Entrevista') {
                return 'Entrevista ${temRelatorio ? 'com relatório' : 'registrada'} para ${vaga ?? 'Vaga'}';
              }
              return vaga ?? '';
            })();

        return AtividadeHistorico(
          id: (m['id'] ?? '').toString(),
          usuario: usuario.isEmpty ? '—' : usuario,
          descricao: descricao,
          tipo: tipo,
          entidade: entidade,
          entidadeId: entidadeId,
          data: created,
        );
      }).toList();
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<AtividadeHistorico> get _filtradas {
    return _atividades.where((a) {
      final matchBusca = _busca.trim().isEmpty ||
          a.descricao.toLowerCase().contains(_busca.toLowerCase()) ||
          a.usuario.toLowerCase().contains(_busca.toLowerCase());
      final matchTipo = _filtroTipo == 'Todos' || a.tipo == _filtroTipo;
      final matchEntidade =
          _filtroEntidade == 'Todas' || a.entidade == _filtroEntidade;
      return matchBusca && matchTipo && matchEntidade;
    }).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  Map<DateTime, List<AtividadeHistorico>> get _agrupadasPorDia {
    final mapa = <DateTime, List<AtividadeHistorico>>{};
    for (final a in _filtradas) {
      final k = DateTime(a.data.year, a.data.month, a.data.day);
      mapa.putIfAbsent(k, () => []).add(a);
    }
    final ordenadas = Map.fromEntries(
        mapa.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
    return ordenadas;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Histórico & Auditoria',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: TMTokens.text)),
          const SizedBox(height: 4),
          const Text('Rastreie todas as atividades e eventos do sistema',
              style: TextStyle(fontSize: 16, color: TMTokens.textMuted)),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 24),
          ..._agrupadasPorDia.entries.map((e) => _diaSection(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 12,
                        top: 12,
                        child: Icon(Icons.search,
                            size: 18, color: TMTokens.textMuted),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar atividades...',
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
                        onChanged: (v) => setState(() => _busca = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: _tipoDropdown()),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: _entidadeDropdown()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoDropdown() {
    const tipos = [
      'Todos',
      'Upload',
      'Análise',
      'Entrevista',
      'Aprovação',
      'Reprovação',
      'Edição'
    ];
    return DropdownButtonFormField<String>(
      initialValue: _filtroTipo,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_alt, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items:
          tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _filtroTipo = v ?? 'Todos'),
    );
  }

  Widget _entidadeDropdown() {
    const ents = ['Todas', 'Candidato', 'Vaga', 'Entrevista'];
    return DropdownButtonFormField<String>(
      initialValue: _filtroEntidade,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_list, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TMTokens.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items:
          ents.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _filtroEntidade = v ?? 'Todas'),
    );
  }

  Widget _diaSection(DateTime dia, List<AtividadeHistorico> itens) {
    final titulo = _formatarDiaCompleto(dia);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TMTokens.text)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: TMTokens.border)),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(itens.length, (i) => _atividadeCard(itens[i], i)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _atividadeCard(AtividadeHistorico a, int index) {
    final isHovered = _hovered.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered.add(index)),
      onExit: (_) => setState(() => _hovered.remove(index)),
      child: Card(
        elevation: isHovered ? 6 : 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconeCategoria(a.tipo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(a.descricao,
                              style: const TextStyle(
                                  color: TMTokens.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        Text(_tempoDecorrido(a.data),
                            style: const TextStyle(
                                color: TMTokens.textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(a.usuario,
                            style: const TextStyle(
                                fontSize: 12, color: TMTokens.textMuted)),
                        const SizedBox(width: 8),
                        const Text('•',
                            style: TextStyle(color: TMTokens.textMuted)),
                        const SizedBox(width: 8),
                        _badgeEntidade(a.entidade),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _verDetalhes(a),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Ver detalhes',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: TMTokens.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconeCategoria(String tipo) {
    IconData icon;
    Color bg;
    Color fg;
    switch (tipo) {
      case 'Upload':
        icon = Icons.upload_file;
        bg = TMTokens.info.withValues(alpha: 0.15);
        fg = TMTokens.info;
        break;
      case 'Análise':
        icon = Icons.psychology;
        bg = TMTokens.secondary.withValues(alpha: 0.15);
        fg = TMTokens.secondary;
        break;
      case 'Entrevista':
        icon = Icons.calendar_today;
        bg = TMTokens.warning.withValues(alpha: 0.15);
        fg = TMTokens.warning;
        break;
      case 'Aprovação':
        icon = Icons.check_circle;
        bg = TMTokens.success.withValues(alpha: 0.15);
        fg = TMTokens.success;
        break;
      case 'Reprovação':
        icon = Icons.cancel;
        bg = TMTokens.error.withValues(alpha: 0.15);
        fg = TMTokens.error;
        break;
      case 'Edição':
      default:
        icon = Icons.edit_square;
        bg = TMTokens.textMuted.withValues(alpha: 0.15);
        fg = TMTokens.textMuted;
        break;
    }
    return Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: fg, size: 20),
    );
  }

  Widget _badgeEntidade(String entidade) {
    Color fg;
    Color bg;
    switch (entidade) {
      case 'Vaga':
        fg = TMTokens.primary;
        bg = TMTokens.primary.withValues(alpha: 0.08);
        break;
      case 'Entrevista':
        fg = TMTokens.warning;
        bg = TMTokens.warning.withValues(alpha: 0.15);
        break;
      case 'Candidato':
      default:
        fg = TMTokens.secondary;
        bg = TMTokens.secondary.withValues(alpha: 0.15);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bg)),
      child: Text(entidade,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  String _tempoDecorrido(DateTime data) {
    final a = DateTime.now();
    final d = a.difference(data);
    if (d.inMinutes < 1) return 'Agora há pouco';
    if (d.inHours < 1) return 'Há ${d.inMinutes}min';
    if (d.inHours < 24) return 'Há ${d.inHours}h';
    final dias = d.inDays;
    if (dias == 1) return 'Ontem';
    if (dias < 7) return 'Há $dias dias';
    if (dias < 30) return 'Há ${(dias / 7).floor()} semanas';
    return 'Há ${(dias / 30).floor()} meses';
  }

  String _formatarDiaCompleto(DateTime d) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];
    return '${d.day.toString().padLeft(2, '0')} de ${meses[d.month - 1]} de ${d.year}';
  }

  void _verDetalhes(AtividadeHistorico a) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Abrir detalhes de ${a.entidade} (${a.entidadeId})')),
    );
  }
}
