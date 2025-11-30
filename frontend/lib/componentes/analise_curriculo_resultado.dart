import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/tm_tokens.dart';
import '../modelos/analise_curriculo.dart';
import '../utils/date_utils.dart' as date_utils;

/// Bloco reutilizável para exibir o resultado da análise de currículo
/// usando apenas dados reais vindos do backend.
class AnaliseCurriculoResultado extends StatefulWidget {
  final AnaliseCurriculo analise;
  final Map<String, dynamic>? analiseBruta;
  final Map<String, dynamic>? candidato;
  final Map<String, dynamic>? vaga;
  final VoidCallback? onAprovar;
  final VoidCallback? onReprovar;
  final void Function(DateTime data)? onAgendar;
  final VoidCallback? onGerarPerguntas;

  const AnaliseCurriculoResultado({
    super.key,
    required this.analise,
    this.analiseBruta,
    this.candidato,
    this.vaga,
    this.onAprovar,
    this.onReprovar,
    this.onAgendar,
    this.onGerarPerguntas,
  });

  @override
  State<AnaliseCurriculoResultado> createState() =>
      _AnaliseCurriculoResultadoState();
}

class _AnaliseCurriculoResultadoState extends State<AnaliseCurriculoResultado> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  bool _mostrarAgendamento = false;
  bool _mostrarAprovacao = false;
  bool _mostrarReprovacao = false;

  @override
  void dispose() {
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  String? _stringFrom(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  String _firstNonEmpty(List<dynamic> attempts, {String fallback = ''}) {
    for (final attempt in attempts) {
      final v = _stringFrom(attempt);
      if (v != null) return v;
    }
    return fallback;
  }

  List<String> _listFromKeys(List<String> keys) {
    for (final key in keys) {
      final value = widget.analiseBruta?[key];
      if (value is List) {
        return value
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(RegExp(r'[,;\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  Future<void> _selecionarData() async {
    final hoje = date_utils.DateUtils.agora();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
      locale: const Locale('pt', 'BR'),
    );

    if (!mounted || selecionada == null) return;

    final dataFormatada =
        '${selecionada.day.toString().padLeft(2, '0')}/${selecionada.month.toString().padLeft(2, '0')}/${selecionada.year}';
    setState(() {
      _dataController.text = dataFormatada;
    });
  }

  String? _formatarHora(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }
    if (digits.length < 3) return null;

    final separatorIndex = digits.length - 2;
    final hoursStr = digits.substring(0, separatorIndex);
    final minutesStr = digits.substring(separatorIndex);

    final hour = int.tryParse(hoursStr);
    final minute = int.tryParse(minutesStr);
    if (hour == null || minute == null) return null;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, String>> _experienciasDetalhadas() {
    final raw = widget.analiseBruta?['experiencias'] ??
        widget.analiseBruta?['experiences'];
    final List<Map<String, String>> parsed = [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          parsed.add({
            'cargo':
                _stringFrom(item['cargo']) ?? _stringFrom(item['role']) ?? '',
            'empresa': _stringFrom(item['empresa']) ??
                _stringFrom(item['company']) ??
                '',
            'periodo': _stringFrom(item['periodo']) ??
                _stringFrom(item['inicio']) ??
                '',
            'descricao': _stringFrom(item['descricao']) ??
                _stringFrom(item['summary']) ??
                '',
          });
        } else if (item is String) {
          parsed.add({'descricao': item});
        }
      }
    }

    // Se não veio estruturado, converte lista simples de experiências em descrição
    if (parsed.isEmpty) {
      final simples =
          _listFromKeys(['experiences', 'experiencia', 'experiencias']);
      parsed.addAll(simples.map((e) => {'descricao': e}));
    }
    return parsed;
  }

  List<Map<String, String>> _educacaoDetalhada() {
    final raw =
        widget.analiseBruta?['educacao'] ?? widget.analiseBruta?['education'];
    final List<Map<String, String>> parsed = [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          parsed.add({
            'curso':
                _stringFrom(item['curso']) ?? _stringFrom(item['course']) ?? '',
            'instituicao': _stringFrom(item['instituicao']) ??
                _stringFrom(item['institution']) ??
                '',
            'periodo': _stringFrom(item['periodo']) ??
                _stringFrom(item['period']) ??
                '',
            'status': _stringFrom(item['status']) ?? '',
          });
        } else if (item is String) {
          parsed.add({'curso': item});
        }
      }
    }

    // Se não veio estruturado, converte lista simples
    if (parsed.isEmpty) {
      final simples = _listFromKeys(['education', 'formacao', 'educacao']);
      parsed.addAll(simples.map((e) => {'curso': e}));
    }
    return parsed;
  }

  List<Map<String, String>> _certificacoesDetalhadas() {
    final raw = widget.analiseBruta?['certificacoes'] ??
        widget.analiseBruta?['certifications'];
    final List<Map<String, String>> parsed = [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          parsed.add({
            'nome':
                _stringFrom(item['nome']) ?? _stringFrom(item['name']) ?? '',
            'instituicao': _stringFrom(item['instituicao']) ??
                _stringFrom(item['institution']) ??
                '',
            'ano': _stringFrom(item['ano']) ?? _stringFrom(item['year']) ?? '',
            'cargaHoraria': _stringFrom(item['cargaHoraria']) ??
                _stringFrom(item['hours']) ??
                '',
          });
        } else if (item is String) {
          parsed.add({'nome': item});
        }
      }
    }

    // Se não veio estruturado, converte lista simples
    if (parsed.isEmpty) {
      final simples = _listFromKeys(['certifications', 'certificacoes']);
      parsed.addAll(simples.map((e) => {'nome': e}));
    }
    return parsed;
  }

  Color _scoreColor(int score) {
    if (score >= 85) return TMTokens.success;
    if (score >= 70) return TMTokens.warning;
    return TMTokens.error;
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: bg.withValues(alpha: ((bg.a * 255.0).round() & 0xff) * 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: TMTokens.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.analise.matchingScore.clamp(0, 100);
    final recomendacao = widget.analise.recomendacao;
    final resumo = _firstNonEmpty([
      widget.analiseBruta?['summary'],
      widget.analiseBruta?['resumo'],
      widget.analiseBruta?['experiencia'],
      widget.analise.resumo,
    ]);

    final candidatoNome = _firstNonEmpty([
      widget.candidato?['nome'],
      widget.candidato?['full_name'],
      widget.candidato?['name'],
    ]);
    final email = _firstNonEmpty([widget.candidato?['email']]);
    final telefone = _firstNonEmpty(
        [widget.candidato?['telefone'], widget.candidato?['phone']]);
    final github = _firstNonEmpty([widget.candidato?['github']]);
    final linkedin = _firstNonEmpty([widget.candidato?['linkedin']]);
    final vagaTitulo =
        _firstNonEmpty([widget.vaga?['title'], widget.vaga?['titulo']]);

    final skills = _listFromKeys(['skills', 'keywords']);
    final softSkills = _listFromKeys(
        ['softSkills', 'soft_skills', 'softskills', 'comportamentais']);
    final experienciasDetalhadas = _experienciasDetalhadas();
    final formacoesDetalhadas = _educacaoDetalhada();
    final certificacoesDetalhadas = _certificacoesDetalhadas();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreCard(score, recomendacao, resumo),
        const SizedBox(height: 16),
        _buildCandidatoCard(
          candidatoNome: candidatoNome,
          email: email,
          telefone: telefone,
          github: github,
          linkedin: linkedin,
          vagaTitulo: vagaTitulo,
        ),
        if (experienciasDetalhadas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Experiência Profissional',
            icon: Icons.work_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: experienciasDetalhadas.map((exp) {
                final titulo = [
                  exp['cargo'],
                  if ((exp['empresa'] ?? '').isNotEmpty) exp['empresa'],
                ].whereType<String>().where((e) => e.isNotEmpty).join(' • ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              titulo.isEmpty ? 'Experiência' : titulo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((exp['periodo'] ?? '').isNotEmpty)
                            Text(
                              exp['periodo']!,
                              style: const TextStyle(
                                color: TMTokens.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      if ((exp['descricao'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(exp['descricao']!),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        if (formacoesDetalhadas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Formação Acadêmica',
            icon: Icons.school_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: formacoesDetalhadas.map((formacao) {
                final titulo = [
                  formacao['curso'],
                  if ((formacao['instituicao'] ?? '').isNotEmpty)
                    formacao['instituicao'],
                ].where((e) => e != null && e.isNotEmpty).join(' • ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              titulo.isEmpty ? 'Formação' : titulo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((formacao['periodo'] ?? '').isNotEmpty)
                            Text(
                              formacao['periodo']!,
                              style: const TextStyle(
                                color: TMTokens.secondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                      if ((formacao['status'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          formacao['status']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: TMTokens.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        if (skills.isNotEmpty || softSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Competências',
            icon: Icons.code,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (skills.isNotEmpty) ...[
                  const Text(
                    'Habilidades Técnicas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((s) => _buildBadge(s, const Color(0xFFEDE9FE),
                            const Color(0xFF6B21A8)))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (softSkills.isNotEmpty) ...[
                  const Text(
                    'Soft Skills',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: softSkills
                        .map((s) => _buildBadge(s, const Color(0xFFDBEAFE),
                            const Color(0xFF1E3A8A)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (widget.analise.aderenciaRequisitos.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Aderência aos Requisitos',
            icon: Icons.track_changes,
            child: Column(
              children: widget.analise.aderenciaRequisitos
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.requisito,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${item.score}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _scoreColor(item.score),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: item.score / 100,
                            minHeight: 8,
                            backgroundColor: TMTokens.border,
                            color: _scoreColor(item.score),
                          ),
                          if (item.evidencias.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...item.evidencias.map(
                              (ev) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 12, bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            color: TMTokens.secondary)),
                                    Expanded(child: Text(ev)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (certificacoesDetalhadas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Certificações',
            icon: Icons.workspace_premium_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: certificacoesDetalhadas.map((cert) {
                final titulo = [
                  cert['nome'],
                  if ((cert['instituicao'] ?? '').isNotEmpty)
                    cert['instituicao'],
                ].where((e) => e != null && e.isNotEmpty).join(' • ');

                final detalhes = [
                  if ((cert['ano'] ?? '').isNotEmpty) cert['ano'],
                  if ((cert['cargaHoraria'] ?? '').isNotEmpty)
                    cert['cargaHoraria'],
                ].where((e) => e != null && e.isNotEmpty).join(' • ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo.isEmpty ? 'Certificação' : titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (detalhes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          detalhes,
                          style: const TextStyle(
                            fontSize: 13,
                            color: TMTokens.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildActions(
            candidatoNome, vagaTitulo, email, telefone, github, linkedin),
        if (_mostrarAgendamento) ...[
          const SizedBox(height: 12),
          _buildAgendamentoCard(
              candidatoNome, vagaTitulo, email, telefone, github, linkedin),
        ],
        if (_mostrarAprovacao) ...[
          const SizedBox(height: 12),
          _buildStatusCard(
              'Aprovado',
              Colors.green.shade100,
              Colors.green.shade800,
              candidatoNome,
              vagaTitulo,
              email,
              telefone,
              github,
              linkedin),
        ],
        if (_mostrarReprovacao) ...[
          const SizedBox(height: 12),
          _buildStatusCard(
              'Reprovado',
              Colors.red.shade100,
              Colors.red.shade800,
              candidatoNome,
              vagaTitulo,
              email,
              telefone,
              github,
              linkedin),
        ],
      ],
    );
  }

  Widget _buildScoreCard(int score, String recomendacao, String resumo) {
    return Card(
      color: const Color(0xFFF6F5FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TMTokens.r16),
        side: const BorderSide(color: Color(0xFFE9D5FF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score de Compatibilidade',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF6B21A8)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recomendacao,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF312E81),
                    ),
                  ),
                  if (resumo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      resumo,
                      style: const TextStyle(color: TMTokens.secondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFEDE9FE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.verified, color: Color(0xFF7C3AED)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatoCard({
    required String candidatoNome,
    required String? email,
    required String? telefone,
    required String? github,
    required String? linkedin,
    required String? vagaTitulo,
  }) {
    final nomeDisplay =
        candidatoNome.isEmpty ? 'Nome não informado' : candidatoNome;
    final vagaDisplay = (vagaTitulo != null && vagaTitulo.isNotEmpty)
        ? vagaTitulo
        : 'Vaga não informada';
    final emailDisplay =
        (email != null && email.isNotEmpty) ? email : 'E-mail não informado';
    final telefoneDisplay = (telefone != null && telefone.isNotEmpty)
        ? telefone
        : 'Telefone não informado';

    return _sectionCard(
      title: 'Informações do Candidato',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              nomeDisplay,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Vaga: $vagaDisplay',
              style: const TextStyle(color: TMTokens.secondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.mail_outlined,
                    size: 18, color: TMTokens.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(emailDisplay)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 18, color: TMTokens.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(telefoneDisplay)),
              ],
            ),
          ),
          if (github != null && github.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 18, color: TMTokens.secondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(github)),
                ],
              ),
            ),
          if (linkedin != null && linkedin.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: TMTokens.secondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(linkedin)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(
    String candidatoNome,
    String? vagaTitulo,
    String? email,
    String? telefone,
    String? github,
    String? linkedin,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _mostrarAgendamento = true;
                    _mostrarAprovacao = false;
                    _mostrarReprovacao = false;
                  });
                },
                child: const Text('Agendar Entrevista'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _mostrarAgendamento = false;
                    _mostrarAprovacao = true;
                    _mostrarReprovacao = false;
                  });
                  widget.onAprovar?.call();
                },
                child: const Text('Aprovar Candidato'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _mostrarAgendamento = false;
                    _mostrarAprovacao = false;
                    _mostrarReprovacao = true;
                  });
                  widget.onReprovar?.call();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: TMTokens.error),
                  foregroundColor: TMTokens.error,
                ),
                child: const Text('Reprovar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgendamentoCard(
    String candidatoNome,
    String? vagaTitulo,
    String? email,
    String? telefone,
    String? github,
    String? linkedin,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_available, color: TMTokens.primary),
                SizedBox(width: 8),
                Text(
                  'Agendar Entrevista',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCandidatoCard(
              candidatoNome: candidatoNome,
              email: email,
              telefone: telefone,
              github: github,
              linkedin: linkedin,
              vagaTitulo: vagaTitulo,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dataController,
                    readOnly: true,
                    onTap: _selecionarData,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      hintText: 'dd/mm/aaaa',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _horaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      const _HoraInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      hintText: '14:00',
                      suffixIcon: Icon(Icons.schedule),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  final horaFormatada = _formatarHora(_horaController.text);

                  if (_dataController.text.isEmpty || horaFormatada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Preencha data e hora para agendar.')),
                    );
                    return;
                  }

                  try {
                    final dateParts = _dataController.text.split('/');

                    if (dateParts.length != 3) {
                      throw const FormatException('Formato inválido');
                    }

                    final day = int.parse(dateParts[0]);
                    final month = int.parse(dateParts[1]);
                    final year = int.parse(dateParts[2]);
                    final horaParts = horaFormatada.split(':');
                    final hour = int.parse(horaParts[0]);
                    final minute = int.parse(horaParts[1]);

                    if (hour > 23 || minute > 59) {
                      throw const FormatException('Hora inválida');
                    }

                    final dt = DateTime(year, month, day, hour, minute);
                    setState(() {
                      _horaController.text = horaFormatada;
                    });
                    widget.onAgendar?.call(dt);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Data/Hora inválida. Use dd/mm/aaaa e HH:mm.')),
                    );
                  }
                },
                child: const Text('Salvar agendamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String status,
    Color bg,
    Color fg,
    String candidatoNome,
    String? vagaTitulo,
    String? email,
    String? telefone,
    String? github,
    String? linkedin,
  ) {
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'Reprovado'
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  color: fg,
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCandidatoCard(
              candidatoNome: candidatoNome,
              email: email,
              telefone: telefone,
              github: github,
              linkedin: linkedin,
              vagaTitulo: vagaTitulo,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoraInputFormatter extends TextInputFormatter {
  const _HoraInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }

    String formatted;
    if (digits.length <= 2) {
      formatted = digits;
    } else {
      final separatorIndex = digits.length - 2;
      final hours = digits.substring(0, separatorIndex);
      final minutes = digits.substring(separatorIndex);
      formatted = '$hours:$minutes';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
