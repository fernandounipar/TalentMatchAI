import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';
import '../modelos/vaga.dart';
import '../componentes/tm_button.dart';
import '../componentes/tm_chip.dart';
import '../design_system/tm_tokens.dart';

/// Tela de Gerenciamento de Vagas
class VagasTela extends StatefulWidget {
  final ApiCliente api;
  final bool isAdmin;

  const VagasTela({
    super.key,
    required this.api,
    this.isAdmin = false,
  });

  @override
  State<VagasTela> createState() => _VagasTelaState();
}

class _VagasTelaState extends State<VagasTela> {
  List<Vaga> _vagas = [];
  int _page = 1;
  String _searchTerm = '';
  String _filterStatus = 'all';
  bool _carregando = true;
  final Set<int> _hoveredCards = <int>{};

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _requisitosController = TextEditingController();
  final _localController = TextEditingController();
  final _salarioController = TextEditingController();
  final _tagsController = TextEditingController();
  String _senioridade = 'Pleno';
  String _regime = 'CLT';
  Vaga? _editingVaga;

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _requisitosController.dispose();
    _localController.dispose();
    _salarioController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _carregarVagas() async {
    setState(() => _carregando = true);
    try {
      final status = _filterStatus == 'all' ? null : (_filterStatus.toLowerCase() == 'aberta' ? 'open' : _filterStatus.toLowerCase());
      final q = _searchTerm.trim().isEmpty ? null : _searchTerm.trim();
      final itens = await widget.api.vagas(page: _page, limit: 20, status: status, q: q);
      final vagas = itens.map((j) {
        final createdAt = DateTime.tryParse(j['created_at']?.toString() ?? '');
        final candidatosCount = j['candidates_count'] ?? j['candidatos'] ?? 0;
        return Vaga(
          id: (j['id'] ?? '').toString(),
          titulo: j['title']?.toString() ?? '',
          descricao: j['description']?.toString() ?? '',
          requisitos: j['requirements']?.toString() ?? '',
          requisitosList: (j['requirements']?.toString() ?? '').split('\n'),
          senioridade: j['seniority']?.toString(),
          regime: j['location_type']?.toString(),
          local: null,
          status: (() {
            final s = (j['status'] ?? '').toString();
            return s == 'open' ? 'aberta' : s;
          })(),
          salario: null,
          tags: const [],
          criadoEm: createdAt ?? DateTime.now(),
          candidatos: candidatosCount is int
              ? candidatosCount
              : int.tryParse(candidatosCount.toString()) ?? 0,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _vagas = vagas;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Vaga> get _filteredVagas {
    return _vagas.where((vaga) {
      final matchesSearch = vaga.titulo.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          vaga.descricao.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesStatus = _filterStatus == 'all' || vaga.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _openDialog([Vaga? vaga]) {
    _editingVaga = vaga;
    
    if (vaga != null) {
      _tituloController.text = vaga.titulo;
      _descricaoController.text = vaga.descricao;
      _requisitosController.text = (vaga.requisitosList ?? []).join('\n');
      _localController.text = vaga.local ?? '';
      _salarioController.text = vaga.salario ?? '';
      _tagsController.text = (vaga.tags ?? []).join(', ');
      _senioridade = vaga.senioridade ?? 'Pleno';
      _regime = vaga.regime ?? 'CLT';
    } else {
      _tituloController.clear();
      _descricaoController.clear();
      _requisitosController.clear();
      _localController.clear();
      _salarioController.clear();
      _tagsController.clear();
      _senioridade = 'Pleno';
      _regime = 'CLT';
    }

    showDialog(
      context: context,
      builder: (context) => _buildDialog(),
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final payload = {
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'requisitos': _requisitosController.text,
        'status': (_editingVaga?.status ?? 'aberta').toLowerCase(),
        'tecnologias': _tagsController.text,
        'nivel': _senioridade,
      };
      if (_editingVaga != null) {
        await widget.api.atualizarVaga(_editingVaga!.id, payload);
      } else {
        await widget.api.criarVaga(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      await _carregarVagas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingVaga != null ? 'Vaga atualizada com sucesso!' : 'Vaga criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao salvar vaga'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta vaga?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.api.deletarVaga(id);
                await _carregarVagas();
                if (!mounted) return;
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Vaga excluída com sucesso!'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Falha ao excluir vaga'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // Status cores migradas para TMChip.jobStatus (ver TMTokens/TMStatusColors)

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeader = constraints.maxWidth < 720;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompactHeader),
              const SizedBox(height: 24),
              _buildFilters(isCompactHeader),
              const SizedBox(height: 24),
              if (_filteredVagas.isEmpty)
                _buildEmptyState()
              else
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final width = gridConstraints.maxWidth;
                    final crossAxisCount = width >= 1024 ? 2 : 1;
                    final childAspectRatio = width >= 1024 ? 1.2 : 1.05;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: _filteredVagas.length,
                      itemBuilder: (context, index) {
                        final vaga = _filteredVagas[index];
                        return _buildVagaCard(vaga, index);
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _page > 1 ? () { setState(() { _page -= 1; }); _carregarVagas(); } : null,
                    child: const Text('Anterior'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () { setState(() { _page += 1; }); _carregarVagas(); },
                    child: const Text('Próxima'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final headerContent = <Widget>[
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vagas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gerencie as vagas abertas e seu pipeline',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      if (widget.isAdmin)
        TMButton('Nova Vaga', icon: Icons.add, onPressed: () => _openDialog()),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vagas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gerencie as vagas abertas e seu pipeline',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          if (widget.isAdmin)
            TMButton('Nova Vaga', icon: Icons.add, onPressed: () => _openDialog()),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: headerContent,
    );
  }

  Widget _buildFilters(bool isCompact) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  _buildStatusDropdown(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: _buildStatusDropdown()),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar vagas...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (value) => setState(() => _searchTerm = value),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _filterStatus,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_list, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Todos os Status')),
        DropdownMenuItem(value: 'Aberta', child: Text('Aberta')),
        DropdownMenuItem(value: 'Pausada', child: Text('Pausada')),
        DropdownMenuItem(value: 'Fechada', child: Text('Fechada')),
      ],
      onChanged: (value) => setState(() => _filterStatus = value ?? 'all'),
    );
  }

  Widget _buildVagaCard(Vaga vaga, int index) {
    final isHovered = _hoveredCards.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCards.add(index)),
      onExit: (_) => setState(() => _hoveredCards.remove(index)),
      child: Card(
        elevation: isHovered ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _openDialog(vaga),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaga.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TMTokens.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.work_outline, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              vaga.senioridade ?? 'Não especificado',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Color(0xFF6B7280))),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vaga.local ?? 'Remoto',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TMChip.jobStatus(vaga.status),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                vaga.descricao,
                style: const TextStyle(fontSize: 14, color: TMTokens.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Salary
              if (vaga.salario != null && vaga.salario!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: TMTokens.text),
                    const SizedBox(width: 4),
                    Text(
                      vaga.salario!,
                      style: const TextStyle(fontSize: 14, color: TMTokens.text),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...((vaga.tags ?? []).take(4).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 12, color: TMTokens.text),
                        ),
                      ))),
                  if ((vaga.tags ?? []).length > 4)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${(vaga.tags ?? []).length - 4}',
                        style: const TextStyle(fontSize: 12, color: TMTokens.text),
                      ),
                    ),
                ],
              ),
              const Spacer(),

              // Footer
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 16, color: TMTokens.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${vaga.candidatos ?? 0} candidatos',
                          style: const TextStyle(fontSize: 14, color: TMTokens.textMuted),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _openDialog(vaga),
                          color: const Color(0xFF6B7280),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _handleDelete(vaga.id),
                          color: const Color(0xFF6B7280),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma vaga encontrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchTerm.isNotEmpty || _filterStatus != 'all'
                    ? 'Tente ajustar os filtros de busca'
                    : (widget.isAdmin
                        ? 'Comece criando sua primeira vaga'
                        : 'Nenhuma vaga cadastrada ainda'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              if (_searchTerm.isEmpty && _filterStatus == 'all' && widget.isAdmin) ...[
                const SizedBox(height: 16),
                TMButton('Nova Vaga', icon: Icons.add, onPressed: () => _openDialog()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialog() {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingVaga != null ? 'Editar Vaga' : 'Nova Vaga',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Preencha as informações da vaga para publicá-la',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text('Título da Vaga *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tituloController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Desenvolvedor Full Stack Senior',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),

                      // Descrição
                      const Text('Descrição *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descricaoController,
                        decoration: InputDecoration(
                          hintText: 'Descreva a vaga, responsabilidades e o que você procura...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 4,
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),

                      // Requisitos
                      const Text('Requisitos (um por linha) *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _requisitosController,
                        decoration: InputDecoration(
                          hintText: 'React e TypeScript avançado\nNode.js e Express\nPostgreSQL',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 5,
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),

                      // Senioridade e Regime
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Senioridade *', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _senioridade,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Junior', child: Text('Junior')),
                                    DropdownMenuItem(value: 'Pleno', child: Text('Pleno')),
                                    DropdownMenuItem(value: 'Senior', child: Text('Senior')),
                                    DropdownMenuItem(value: 'Especialista', child: Text('Especialista')),
                                  ],
                                  onChanged: (value) => setState(() => _senioridade = value!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Regime *', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _regime,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'CLT', child: Text('CLT')),
                                    DropdownMenuItem(value: 'PJ', child: Text('PJ')),
                                    DropdownMenuItem(value: 'Estágio', child: Text('Estágio')),
                                    DropdownMenuItem(value: 'Temporário', child: Text('Temporário')),
                                  ],
                                  onChanged: (value) => setState(() => _regime = value!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Localização
                      const Text('Localização *', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _localController,
                        decoration: InputDecoration(
                          hintText: 'Ex: São Paulo - Híbrido',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),

                      // Salário
                      const Text('Faixa Salarial (opcional)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _salarioController,
                        decoration: InputDecoration(
                          hintText: 'Ex: R\$ 8.000 - R\$ 12.000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      const Text('Tags (separadas por vírgula)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          hintText: 'Ex: React, Node.js, TypeScript',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TMButton('Cancelar', variant: TMButtonVariant.secondary, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  TMButton(_editingVaga != null ? 'Salvar Alterações' : 'Criar Vaga', onPressed: _handleSave),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
