import 'package:flutter/material.dart';

import '../modelos/candidato.dart';
import '../servicos/api_cliente.dart';
import '../componentes/tm_chip.dart';
import '../componentes/tm_button.dart';
import '../design_system/tm_tokens.dart';

class CandidatosTela extends StatefulWidget {
  final ApiCliente api;

  const CandidatosTela({super.key, required this.api});

  @override
  State<CandidatosTela> createState() => _CandidatosTelaState();
}

class _CandidatosTelaState extends State<CandidatosTela> {
  List<Candidato> _candidatos = [];
  int _page = 1;
  bool _carregando = true;
  String _searchTerm = '';
  String _filterStatus = 'all';
  String _filterSkill = 'all';
  List<String> _skills = const [];
  final Set<int> _hoveredCards = <int>{};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      // carrega skills disponíveis
      try {
        _skills = await widget.api.skills();
      } catch (_) {}
      // carrega candidatos (opcionalmente o filtro de skill é aplicado no cliente)
      final q = _searchTerm.trim().isEmpty ? null : _searchTerm.trim();
      final skill = _filterSkill == 'all' ? null : _filterSkill;
      final itens = await widget.api
          .candidatos(page: _page, limit: 20, q: q, skill: skill);
      final candidatos = itens
          .map((item) => Candidato.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) =>
            (b.createdAt ?? b.criadoEm).compareTo(a.createdAt ?? a.criadoEm));
      if (!mounted) return;
      setState(() {
        _candidatos = candidatos;
        _carregando = false;
      });
    } catch (e, stack) {
      debugPrint('Erro ao carregar candidatos: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar candidatos: $e')),
      );
    }
  }

  List<Candidato> get _filteredCandidatos {
    return _candidatos.where((candidato) {
      final search = _searchTerm.toLowerCase();
      final matchesSearch = candidato.nome.toLowerCase().contains(search) ||
          candidato.email.toLowerCase().contains(search);
      final status = candidato.status ?? '';
      final applications = candidato.applications ?? [];
      final matchesStatus = _filterStatus == 'all' ||
          status.toLowerCase() == _filterStatus.toLowerCase() ||
          applications.any((app) =>
              (app['status'] ?? '').toString().toLowerCase() ==
              _filterStatus.toLowerCase());
      final matchesSkill = _filterSkill == 'all' ||
          (candidato.skills ?? const [])
              .map((e) => e.toLowerCase())
              .contains(_filterSkill.toLowerCase());
      return matchesSearch && matchesStatus && matchesSkill;
    }).toList();
  }

  String _avatarUrl(String nome) {
    final encoded = Uri.encodeComponent(nome);
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$encoded';
  }

  Color _matchingScoreColor(int? score) {
    if (score == null) return const Color(0xFF9CA3AF);
    if (score >= 85) return const Color(0xFF047857);
    if (score >= 70) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  String _getVagaTitulo(String? vagaId) {
    if (vagaId == null) return 'Sem vaga';
    return '—';
  }

  Future<void> _openCandidatoDialog(Candidato candidato) async {
    Map<String, dynamic>? githubData;

    // Fetch GitHub data if URL exists
    if (candidato.githubUrl != null && candidato.githubUrl!.isNotEmpty) {
      // Optimistic fetch, update state inside dialog if possible or just wait
      try {
        githubData = await widget.api.obterDadosGithub(candidato.id);
      } catch (_) {
        // ignore error
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        backgroundImage:
                            NetworkImage(_avatarUrl(candidato.nome)),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: _matchingScoreColor(
                                              candidato.matchingScore)),
                                    ),
                                    child: Text(
                                      'Match: ${candidato.matchingScore}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _matchingScoreColor(
                                            candidato.matchingScore),
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
                        Text(candidato.email,
                            style: const TextStyle(color: Color(0xFF374151))),
                        if (candidato.telefone != null &&
                            candidato.telefone!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(candidato.telefone!,
                              style: const TextStyle(color: Color(0xFF374151))),
                        ],
                        if (candidato.github != null ||
                            candidato.linkedin != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (candidato.github != null)
                                _buildLinkPill(
                                    'GitHub', Icons.code, candidato.github!),
                              if (candidato.linkedin != null)
                                _buildLinkPill(
                                    'LinkedIn',
                                    Icons.business_center_outlined,
                                    candidato.linkedin!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (githubData != null) ...[
                    const SizedBox(height: 24),
                    _buildDialogSection(
                      icon: Icons.code,
                      titulo: 'GitHub',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (githubData['avatar_url'] != null)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      NetworkImage(githubData['avatar_url']),
                                ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('@${githubData['username']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    '${githubData['followers']} seguidores • ${githubData['public_repos']} repositórios',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (githubData['bio'] != null) ...[
                            const SizedBox(height: 8),
                            Text(githubData['bio'],
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 12),
                          if (githubData['repos'] is List)
                            ...((githubData['repos'] as List).map((repo) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.book_outlined,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(repo['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF2563EB))),
                                          if (repo['description'] != null)
                                            Text(repo['description'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    if (repo['language'] != null)
                                      Text(repo['language'],
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star_border,
                                        size: 14, color: Colors.amber),
                                    Text('${repo['stars']}',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              );
                            })),
                        ],
                      ),
                    ),
                  ],
                  if (candidato.skills != null &&
                      candidato.skills!.isNotEmpty) ...[
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: const Color(0xFFD1D5DB)),
                                ),
                                child: Text(skill,
                                    style: const TextStyle(
                                        color: Color(0xFF374151))),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  if (candidato.experiencia != null &&
                      candidato.experiencia!.isNotEmpty) ...[
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
                              border: Border(
                                  left: BorderSide(
                                      color: Color(0xFFBFDBFE), width: 2)),
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
                                Text(exp.empresa,
                                    style: const TextStyle(
                                        color: Color(0xFF4B5563))),
                                const SizedBox(height: 2),
                                Text(exp.periodo,
                                    style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12)),
                                if (exp.descricao.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(exp.descricao,
                                      style: const TextStyle(
                                          color: Color(0xFF374151))),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (candidato.educacao != null &&
                      candidato.educacao!.isNotEmpty) ...[
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
                                Text(edu.instituicao,
                                    style: const TextStyle(
                                        color: Color(0xFF4B5563))),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: const Color(0xFFD1D5DB)),
                                      ),
                                      child: Text(
                                        edu.tipo,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4B5563)),
                                      ),
                                    ),
                                    Text(edu.periodo,
                                        style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 12)),
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
                          child:
                              TMButton('Agendar Entrevista', onPressed: () {})),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TMButton('Ver Currículo',
                              variant: TMButtonVariant.secondary,
                              onPressed: () {})),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) => TMChip.candidateStatus(status);

  Widget _buildDialogSection(
      {required IconData icon, required String titulo, required Widget child}) {
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
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600),
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
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Candidatos',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Visualize e gerencie todos os candidatos',
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _abrirFormularioCandidato(),
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Novo Candidato'),
                    ),
                  ],
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
                          ? 1.4
                          : width >= 900
                              ? 1.3
                              : 1.2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _filteredCandidatos.length,
                        itemBuilder: (context, index) {
                          final candidato = _filteredCandidatos[index];
                          return _buildCandidatoCard(candidato, index);
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
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Todos os Status')),
        DropdownMenuItem(value: 'Novo', child: Text('Novo')),
        DropdownMenuItem(value: 'Em Análise', child: Text('Em Análise')),
        DropdownMenuItem(
            value: 'Entrevista Agendada', child: Text('Entrevista Agendada')),
        DropdownMenuItem(value: 'Aprovado', child: Text('Aprovado')),
        DropdownMenuItem(value: 'Reprovado', child: Text('Reprovado')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _filterStatus = value);
      },
    );
  }

  Widget _buildSkillDropdown() {
    return DropdownButtonFormField<String>(
      value: _filterSkill,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.code, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('Todas as Skills')),
        ..._skills.map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _filterSkill = value);
      },
    );
  }

  Widget _buildCandidatoCard(Candidato candidato, int index) {
    final isHovered = _hoveredCards.contains(index);
    final status = candidato.status ?? 'Novo';
    final skills = candidato.skills ?? [];

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCards.add(index)),
      onExit: (_) => setState(() => _hoveredCards.remove(index)),
      child: Card(
        elevation: isHovered ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openCandidatoDialog(candidato),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidato.nome,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TMTokens.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            candidato.email,
                            style: const TextStyle(
                                color: TMTokens.textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (candidato.applications != null &&
                            candidato.applications!.isNotEmpty)
                          ...candidato.applications!.map((app) {
                            final st = app['status']?.toString() ?? 'Novo';
                            final title = app['job_title']?.toString();
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Tooltip(
                                message: title != null ? 'Vaga: $title' : '',
                                child: _buildStatusBadge(st),
                              ),
                            );
                          })
                        else
                          _buildStatusBadge(status),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: TMTokens.textMuted),
                          onPressed: () =>
                              _abrirFormularioCandidato(editar: candidato),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.redAccent),
                          onPressed: () async {
                            try {
                              await widget.api.deletarCandidato(candidato.id);
                              await _carregar();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Candidato excluído')));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Falha ao excluir candidato')));
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                if (candidato.matchingScore != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Matching Score',
                          style: TextStyle(
                              fontSize: 11, color: TMTokens.textMuted)),
                      Text(
                        '${candidato.matchingScore}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _matchingScoreColor(candidato.matchingScore),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: (candidato.matchingScore ?? 0) / 100,
                      backgroundColor: TMTokens.border,
                      color: _matchingScoreColor(candidato.matchingScore),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (candidato.vagaId != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          size: 14, color: TMTokens.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getVagaTitulo(candidato.vagaId),
                          style: const TextStyle(
                              fontSize: 11, color: TMTokens.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (candidato.telefone != null &&
                    candidato.telefone!.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone_in_talk_outlined,
                          size: 14, color: TMTokens.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          candidato.telefone!,
                          style: const TextStyle(
                              fontSize: 11, color: TMTokens.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (skills.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...skills.take(3).map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: const Color(0xFFD1D5DB)),
                              ),
                              child: Text(skill,
                                  style: const TextStyle(
                                      fontSize: 10, color: TMTokens.text)),
                            ),
                          ),
                      if (skills.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Text('+${skills.length - 3}',
                              style: const TextStyle(
                                  fontSize: 10, color: TMTokens.text)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _criarCandidatura(Candidato candidato) async {
    // Seleciona vaga e estágio
    final vagas = await widget.api.vagas();
    if (!mounted) return;
    String? jobId;
    String? stageId;
    bool loading = false;
    List<Map<String, dynamic>> stages = const [];
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setSB) {
        return AlertDialog(
          title: const Text('Nova Candidatura'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: jobId,
                  items: [
                    ...vagas.map((v) => DropdownMenuItem(
                        value: v['id'].toString(),
                        child: Text(v['title']?.toString() ?? 'Vaga')))
                  ],
                  onChanged: (v) async {
                    setSB(() {
                      jobId = v;
                      stages = const [];
                      stageId = null;
                    });
                    if (v != null) {
                      try {
                        final pipe = await widget.api.obterPipeline(v);
                        final st = (pipe['stages'] as List)
                            .cast<Map<String, dynamic>>();
                        setSB(() {
                          stages = st;
                          stageId =
                              st.isNotEmpty ? st.first['id'].toString() : null;
                        });
                      } catch (_) {}
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Vaga'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  items: stages
                      .map((s) => DropdownMenuItem(
                          value: s['id'].toString(),
                          child: Text(s['name'].toString())))
                      .toList(),
                  onChanged: (v) => setSB(() => stageId = v),
                  decoration:
                      const InputDecoration(labelText: 'Estágio inicial'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: (loading || jobId == null)
                  ? null
                  : () async {
                      setSB(() => loading = true);
                      try {
                        await widget.api.criarCandidatura(
                            jobId: jobId!,
                            candidateId: candidato.id,
                            stageId: stageId);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Candidatura criada')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Falha ao criar candidatura')));
                      } finally {
                        if (context.mounted) setSB(() => loading = false);
                      }
                    },
              child: Text(loading ? 'Criando...' : 'Criar'),
            ),
          ],
        );
      }),
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
            Icon(Icons.emoji_events_outlined,
                size: 56, color: Color(0xFF9CA3AF)),
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

  Future<void> _abrirFormularioCandidato({Candidato? editar}) async {
    final nome = TextEditingController(text: editar?.nome ?? '');
    final email = TextEditingController(text: editar?.email ?? '');
    final telefone = TextEditingController(text: editar?.telefone ?? '');
    final linkedin = TextEditingController(
        text: editar?.linkedin ?? editar?.linkedinUrl ?? '');
    final github =
        TextEditingController(text: editar?.github ?? editar?.githubUrl ?? '');
    final skills =
        TextEditingController(text: (editar?.skills ?? const []).join(', '));
    bool loading = false;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) => AlertDialog(
            title: Text(editar == null ? 'Novo Candidato' : 'Editar Candidato'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nome,
                        decoration:
                            const InputDecoration(labelText: 'Nome completo')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'E-mail')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: telefone,
                        decoration:
                            const InputDecoration(labelText: 'Telefone')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: linkedin,
                        decoration:
                            const InputDecoration(labelText: 'LinkedIn URL')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: github,
                        decoration:
                            const InputDecoration(labelText: 'GitHub URL')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: skills,
                        decoration: const InputDecoration(
                            labelText: 'Skills (separadas por vírgula)')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        setStateSB(() => loading = true);
                        try {
                          final skillsList = skills.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (editar == null) {
                            await widget.api.criarCandidato(
                              nome: nome.text.trim(),
                              email: email.text.trim(),
                              telefone: telefone.text.trim(),
                              linkedin: linkedin.text.trim(),
                              githubUrl: github.text.trim(),
                              skills: skillsList,
                            );
                          } else {
                            await widget.api.atualizarCandidato(
                              editar.id,
                              nome: nome.text.trim(),
                              email: email.text.trim(),
                              telefone: telefone.text.trim(),
                              linkedin: linkedin.text.trim(),
                              githubUrl: github.text.trim(),
                              skills: skillsList,
                            );
                          }
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          await _carregar();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Salvo com sucesso')));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Falha ao salvar')));
                        } finally {
                          if (mounted) setStateSB(() => loading = false);
                        }
                      },
                child: Text(loading ? 'Salvando...' : 'Salvar'),
              )
            ],
          ),
        );
      },
    );
  }
}
