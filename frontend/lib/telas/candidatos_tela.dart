import 'package:flutter/material.dart';

import '../modelos/candidato.dart';
import '../servicos/api_cliente.dart';
import '../servicos/dados_mockados.dart';

class CandidatosTela extends StatefulWidget {
  final ApiCliente api;

  const CandidatosTela({super.key, required this.api});

  @override
  State<CandidatosTela> createState() => _CandidatosTelaState();
}

class _CandidatosTelaState extends State<CandidatosTela> {
  List<Candidato> _candidatos = [];
  bool _carregando = true;
  String _searchTerm = '';
  String _filterStatus = 'all';
  String _filterVaga = 'all';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final itens = await widget.api.candidatos();
      final candidatos = itens
          .map((item) => Candidato.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => (b.createdAt ?? b.criadoEm).compareTo(a.createdAt ?? a.criadoEm));
      if (!mounted) return;
      setState(() {
        _candidatos = candidatos;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _candidatos = List<Candidato>.from(mockCandidatos)
          ..sort((a, b) => (b.createdAt ?? b.criadoEm).compareTo(a.createdAt ?? a.criadoEm));
        _carregando = false;
      });
    }
  }

  List<Candidato> get _filteredCandidatos {
    return _candidatos.where((candidato) {
      final search = _searchTerm.toLowerCase();
      final matchesSearch = candidato.nome.toLowerCase().contains(search) ||
          candidato.email.toLowerCase().contains(search);
      final status = candidato.status ?? '';
      final matchesStatus = _filterStatus == 'all' || status == _filterStatus;
      final matchesVaga = _filterVaga == 'all' || candidato.vagaId == _filterVaga;
      return matchesSearch && matchesStatus && matchesVaga;
    }).toList();
  }

  String _avatarUrl(String nome) {
    final encoded = Uri.encodeComponent(nome);
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$encoded';
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Novo':
        return const Color(0xFF1D4ED8);
      case 'Em Análise':
        return const Color(0xFFB45309);
      case 'Entrevista Agendada':
        return const Color(0xFF6D28D9);
      case 'Aprovado':
        return const Color(0xFF047857);
      case 'Reprovado':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status) {
      case 'Novo':
        return const Color(0xFFE0F2FE);
      case 'Em Análise':
        return const Color(0xFFFEF3C7);
      case 'Entrevista Agendada':
        return const Color(0xFFEDE9FE);
      case 'Aprovado':
        return const Color(0xFFD1FAE5);
      case 'Reprovado':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _matchingScoreColor(int? score) {
    if (score == null) return const Color(0xFF9CA3AF);
    if (score >= 85) return const Color(0xFF047857);
    if (score >= 70) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  String _getVagaTitulo(String? vagaId) {
    if (vagaId == null) return 'Sem vaga';
    final vagaEncontrada = mockVagas.where((vaga) => vaga.id == vagaId);
    if (vagaEncontrada.isNotEmpty) {
      return vagaEncontrada.first.titulo;
    }
    return 'Vaga não encontrada';
  }

  Future<void> _openCandidatoDialog(Candidato candidato) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(_avatarUrl(candidato.nome)),
                        backgroundColor: const Color(0xFFE5E7EB),
                        child: Text(
                          candidato.nome
                              .split(' ')
                              .where((e) => e.isNotEmpty)
                              .take(2)
                              .map((e) => e[0])
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              candidato.nome,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatusBadge(candidato.status ?? 'Novo'),
                                if (candidato.matchingScore != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: _matchingScoreColor(candidato.matchingScore)),
                                    ),
                                    child: Text(
                                      'Match: ${candidato.matchingScore}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _matchingScoreColor(candidato.matchingScore),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildDialogSection(
                    icon: Icons.mail_outline,
                    titulo: 'Contato',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(candidato.email, style: const TextStyle(color: Color(0xFF374151))),
                        if (candidato.telefone != null && candidato.telefone!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(candidato.telefone!, style: const TextStyle(color: Color(0xFF374151))),
                        ],
                        if (candidato.github != null || candidato.linkedin != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (candidato.github != null)
                                _buildLinkPill('GitHub', Icons.code, candidato.github!),
                              if (candidato.linkedin != null)
                                _buildLinkPill('LinkedIn', Icons.business_center_outlined, candidato.linkedin!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (candidato.skills != null && candidato.skills!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDialogSection(
                      icon: Icons.code,
                      titulo: 'Habilidades',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: candidato.skills!
                            .map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFFD1D5DB)),
                                ),
                                child: Text(skill, style: const TextStyle(color: Color(0xFF374151))),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (candidato.experiencia != null && candidato.experiencia!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDialogSection(
                      icon: Icons.work_outline,
                      titulo: 'Experiência Profissional',
                      child: Column(
                        children: candidato.experiencia!.map((exp) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.only(left: 12),
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Color(0xFFBFDBFE), width: 2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.cargo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(exp.empresa, style: const TextStyle(color: Color(0xFF4B5563))),
                                const SizedBox(height: 2),
                                Text(exp.periodo, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                                if (exp.descricao.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(exp.descricao, style: const TextStyle(color: Color(0xFF374151))),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (candidato.educacao != null && candidato.educacao!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDialogSection(
                      icon: Icons.school_outlined,
                      titulo: 'Formação Acadêmica',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: candidato.educacao!.map((edu) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  edu.curso,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(edu.instituicao, style: const TextStyle(color: Color(0xFF4B5563))),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0xFFD1D5DB)),
                                      ),
                                      child: Text(
                                        edu.tipo,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                                      ),
                                    ),
                                    Text(edu.periodo, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Agendar Entrevista'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          child: const Text('Ver Currículo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) return;
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusTextColor(status),
        ),
      ),
    );
  }

  Widget _buildDialogSection({required IconData icon, required String titulo, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF4338CA)),
            ),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: child,
        ),
      ],
    );
  }

  Widget _buildLinkPill(String label, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.open_in_new, size: 14, color: Color(0xFF2563EB)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Candidatos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Visualize e gerencie todos os candidatos',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                _buildFilters(isCompact),
                const SizedBox(height: 24),
                if (_filteredCandidatos.isEmpty)
                  _buildEmptyState()
                else
                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final width = gridConstraints.maxWidth;
                      final crossAxisCount = width >= 1320
                          ? 3
                          : width >= 900
                              ? 2
                              : 1;
                      final childAspectRatio = width >= 1320
                          ? 1.1
                          : width >= 900
                              ? 1.05
                              : 1.0;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _filteredCandidatos.length,
                        itemBuilder: (context, index) {
                          final candidato = _filteredCandidatos[index];
                          return _buildCandidatoCard(candidato);
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(bool isCompact) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou email...',
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
            ),
            const SizedBox(height: 16),
            isCompact
                ? Column(
                    children: [
                      _buildStatusDropdown(),
                      const SizedBox(height: 16),
                      _buildVagaDropdown(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildStatusDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildVagaDropdown()),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _filterStatus,
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
        DropdownMenuItem(value: 'Novo', child: Text('Novo')),
        DropdownMenuItem(value: 'Em Análise', child: Text('Em Análise')),
        DropdownMenuItem(value: 'Entrevista Agendada', child: Text('Entrevista Agendada')),
        DropdownMenuItem(value: 'Aprovado', child: Text('Aprovado')),
        DropdownMenuItem(value: 'Reprovado', child: Text('Reprovado')),
      ],
      onChanged: (value) => setState(() => _filterStatus = value ?? 'all'),
    );
  }

  Widget _buildVagaDropdown() {
    final vagas = mockVagas;
    return DropdownButtonFormField<String>(
      value: _filterVaga,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.work_outline, size: 20),
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
      items: [
        const DropdownMenuItem(value: 'all', child: Text('Todas as Vagas')),
        ...vagas.map((vaga) => DropdownMenuItem(value: vaga.id, child: Text(vaga.titulo))).toList(),
      ],
      onChanged: (value) => setState(() => _filterVaga = value ?? 'all'),
    );
  }

  Widget _buildCandidatoCard(Candidato candidato) {
    final status = candidato.status ?? 'Novo';
    final skills = candidato.skills ?? const [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCandidatoDialog(candidato),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(_avatarUrl(candidato.nome)),
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      candidato.nome
                          .split(' ')
                          .where((e) => e.isNotEmpty)
                          .take(2)
                          .map((e) => e[0])
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidato.nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          candidato.email,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              if (candidato.matchingScore != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Matching Score', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    Text(
                      '${candidato.matchingScore}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _matchingScoreColor(candidato.matchingScore),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (candidato.matchingScore ?? 0) / 100,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: _matchingScoreColor(candidato.matchingScore),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (candidato.vagaId != null) ...[
                Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getVagaTitulo(candidato.vagaId),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (candidato.telefone != null && candidato.telefone!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        candidato.telefone!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...skills.take(3).map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            child: Text(skill, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                          ),
                        ),
                    if (skills.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Text('+${skills.length - 3}', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_events_outlined, size: 56, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'Nenhum candidato encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros de busca',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
