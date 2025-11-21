import 'package:flutter/material.dart';

import '../design_system/tm_tokens.dart';
import '../modelos/analise_curriculo.dart';

/// Bloco reutilizável para exibir o resultado da análise de currículo
/// usando apenas dados reais vindos do backend.
class AnaliseCurriculoResultado extends StatelessWidget {
  final AnaliseCurriculo analise;
  final Map<String, dynamic>? analiseBruta;
  final Map<String, dynamic>? candidato;
  final Map<String, dynamic>? vaga;
  final VoidCallback? onAprovar;
  final VoidCallback? onGerarPerguntas;

  const AnaliseCurriculoResultado({
    super.key,
    required this.analise,
    this.analiseBruta,
    this.candidato,
    this.vaga,
    this.onAprovar,
    this.onGerarPerguntas,
  });

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
      final value = analiseBruta?[key];
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

  List<Map<String, String>> _experienciasDetalhadas() {
    final raw = analiseBruta?['experiencias'] ?? analiseBruta?['experiences'];
    final List<Map<String, String>> parsed = [];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          parsed.add({
            'cargo': _stringFrom(item['cargo']) ?? _stringFrom(item['role']) ?? '',
            'empresa': _stringFrom(item['empresa']) ?? _stringFrom(item['company']) ?? '',
            'periodo': _stringFrom(item['periodo']) ?? _stringFrom(item['inicio']) ?? '',
            'descricao': _stringFrom(item['descricao']) ?? _stringFrom(item['summary']) ?? '',
          });
        } else if (item is String) {
          parsed.add({'descricao': item});
        }
      }
    }

    // Se não veio estruturado, converte lista simples de experiências em descrição
    if (parsed.isEmpty) {
      final simples = _listFromKeys(['experiences', 'experiencia', 'experiencias']);
      parsed.addAll(simples.map((e) => {'descricao': e}));
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
        border: Border.all(color: bg.withOpacity(0.5)),
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
    final score = analise.matchingScore.clamp(0, 100);
    final recomendacao = analise.recomendacao;
    final resumo = _firstNonEmpty([
      analiseBruta?['summary'],
      analiseBruta?['resumo'],
      analiseBruta?['experiencia'],
      analise.resumo,
    ]);

    final candidatoNome = _firstNonEmpty([
      candidato?['nome'],
      candidato?['full_name'],
      candidato?['name'],
    ]);
    final email = _firstNonEmpty([candidato?['email']]);
    final telefone = _firstNonEmpty([candidato?['telefone'], candidato?['phone']]);
    final vagaTitulo = _firstNonEmpty([vaga?['title'], vaga?['titulo']]);

    final skills = _listFromKeys(['skills', 'keywords']);
    final softSkills = _listFromKeys(['softSkills', 'soft_skills', 'softskills', 'comportamentais']);
    final experienciasDetalhadas = _experienciasDetalhadas();
    final formacoes = _listFromKeys(['education', 'formacao', 'educacao']);
    final certificacoes = _listFromKeys(['certifications', 'certificacoes']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreCard(score, recomendacao, resumo),
        const SizedBox(height: 16),
        _buildCandidatoCard(
          candidatoNome: candidatoNome,
          email: email,
          telefone: telefone,
          vagaTitulo: vagaTitulo,
          resumo: resumo,
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
                ].where((e) => e != null && e!.isNotEmpty).join(' • ');

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
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((exp['periodo'] ?? '').isNotEmpty)
                            Text(
                              exp['periodo']!,
                              style: const TextStyle(
                                color: TMTokens.secondary,
                                fontSize: 13,
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
        if (formacoes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Formação Acadêmica',
            icon: Icons.school_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: formacoes
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(f),
                    ),
                  )
                  .toList(),
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
                        .map((s) => _buildBadge(s, const Color(0xFFEDE9FE), const Color(0xFF6B21A8)))
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
                        .map((s) => _buildBadge(s, const Color(0xFFDBEAFE), const Color(0xFF1E3A8A)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (analise.aderenciaRequisitos.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Aderência aos Requisitos',
            icon: Icons.track_changes,
            child: Column(
              children: analise.aderenciaRequisitos
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
                                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                                padding: const EdgeInsets.only(left: 12, bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: TMTokens.secondary)),
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
        if (certificacoes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Certificações',
            icon: Icons.workspace_premium_outlined,
            child: Column(
              children: certificacoes
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: TMTokens.success),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onAprovar,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Aprovar Candidato'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: onGerarPerguntas,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: TMTokens.border),
                ),
                child: const Text('Gerar Perguntas de Entrevista'),
              ),
            ),
          ],
        ),
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
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B21A8)),
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
    required String? vagaTitulo,
    required String resumo,
  }) {
    final nomeDisplay = candidatoNome.isEmpty ? 'Nome não informado' : candidatoNome;
    final vagaDisplay = (vagaTitulo != null && vagaTitulo.isNotEmpty) ? vagaTitulo : 'Vaga não informada';
    final emailDisplay = (email != null && email.isNotEmpty) ? email : 'E-mail não informado';
    final telefoneDisplay = (telefone != null && telefone.isNotEmpty) ? telefone : 'Telefone não informado';

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
                const Icon(Icons.mail_outlined, size: 18, color: TMTokens.secondary),
                const SizedBox(width: 8),
                Text(emailDisplay),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: TMTokens.secondary),
                const SizedBox(width: 8),
                Text(telefoneDisplay),
              ],
            ),
          ),
          if (resumo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                resumo,
                style: const TextStyle(color: TMTokens.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
