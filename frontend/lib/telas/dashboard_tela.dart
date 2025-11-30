import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../servicos/api_cliente.dart';
import '../componentes/tm_chip.dart';
import '../design_system/tm_tokens.dart';
import '../utils/date_utils.dart' as date_utils;

/// Dashboard - Versão aprimorada com design moderno
/// Grid responsivo com estatísticas animadas, gráficos e insights
class DashboardTela extends StatefulWidget {
  final ApiCliente api;
  final Map<String, dynamic>? userData;
  final VoidCallback? onIrConfiguracoes;
  final VoidCallback? onIrVagas;
  final VoidCallback? onIrEntrevistas;
  final VoidCallback? onIrCurriculos;

  const DashboardTela({
    super.key,
    required this.api,
    this.userData,
    this.onIrConfiguracoes,
    this.onIrVagas,
    this.onIrEntrevistas,
    this.onIrCurriculos,
  });

  @override
  State<DashboardTela> createState() => _DashboardTelaState();
}

class _DashboardTelaState extends State<DashboardTela>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _carregando = false;
  List<Map<String, dynamic>> _vagas = const [];
  List<Map<String, dynamic>> _historico = const [];
  String? _erro;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _carregarDados();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final statsResponse = await widget.api.dashboard();
      // A API retorna { data: { vagas, curriculos, ... } }
      final stats = statsResponse['data'] as Map<String, dynamic>? ?? {};

      final vagasRaw = await widget.api.vagas(page: 1, limit: 5);
      final vagas = vagasRaw.map<Map<String, dynamic>>((vaga) {
        final status = (vaga['status'] ?? '').toString();
        final atualizado =
            vaga['updated_at']?.toString() ?? vaga['created_at']?.toString();
        return {
          'titulo': vaga['title']?.toString() ?? '',
          'status': status,
          'candidatos': vaga['candidatos'] ?? 0,
          'atualizado_em': atualizado,
        };
      }).toList();

      final historico = await widget.api.historico();

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _vagas = vagas;
        _historico = historico.cast<Map<String, dynamic>>();
      });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Falha ao carregar dados do dashboard';
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _carregarDados,
      color: TMTokens.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),

              if (widget.userData != null &&
                  widget.userData!['company'] == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildOnboardingBanner(context),
                ),

              if (_carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildErroBanner(),
                ),

              const SizedBox(height: 24),

              // KPIs com animação
              _buildKPISection(),

              const SizedBox(height: 32),

              // Ações rápidas
              _buildQuickActions(context),

              const SizedBox(height: 32),

              // Grid principal: Vagas + Atividade Recente
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        _buildVagasCard(context),
                        const SizedBox(height: 24),
                        _buildAtividadeRecente(context),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildVagasCard(context)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildAtividadeRecente(context)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Insights e Performance
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        _buildInsightsCard(),
                        const SizedBox(height: 24),
                        _buildPerformanceCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildInsightsCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildPerformanceCard()),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final usuario = widget.userData?['user'] as Map<String, dynamic>?;
    final empresa = widget.userData?['company'] as Map<String, dynamic>?;
    final nome = usuario?['full_name']?.toString() ?? 'Usuário';
    final companyName = empresa?['name']?.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $nome 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: TMTokens.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                companyName != null && companyName.isNotEmpty
                    ? 'Aqui está o resumo das suas atividades'
                    : 'Aqui está o resumo das suas atividades',
                style: const TextStyle(
                  fontSize: 15,
                  color: TMTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _carregando ? null : _carregarDados,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TMTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TMTokens.border),
          ),
          child: _carregando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: TMTokens.textMuted,
                  size: 20,
                ),
        ),
      ),
    );
  }

  Widget _buildOnboardingBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: TMTokens.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete o cadastro da empresa',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Desbloqueie todas as funcionalidades do TalentMatchIA',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: widget.onIrConfiguracoes,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Configurar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TMTokens.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: TMTokens.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _erro ?? 'Falha ao carregar informações do dashboard.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(
            onPressed: _carregarDados,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    int toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    final vagas = toInt(_stats?['vagas']);
    final curriculos = toInt(_stats?['curriculos']);
    final entrevistas = toInt(_stats?['entrevistas']);
    final relatorios = toInt(_stats?['relatorios']);

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1100) columns = 2;
        if (constraints.maxWidth < 600) columns = 2;

        final kpis = [
          _KPIData(
            title: 'Vagas Abertas',
            value: vagas,
            icon: Icons.work_outline_rounded,
            color: TMTokens.primary,
            trend: '+2 esta semana',
            trendPositive: true,
          ),
          _KPIData(
            title: 'Currículos',
            value: curriculos,
            icon: Icons.description_outlined,
            color: TMTokens.info,
            trend: 'Total recebido',
            trendPositive: true,
          ),
          _KPIData(
            title: 'Entrevistas',
            value: entrevistas,
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFF8B5CF6),
            trend: 'Realizadas',
            trendPositive: true,
          ),
          _KPIData(
            title: 'Relatórios IA',
            value: relatorios,
            icon: Icons.auto_awesome_rounded,
            color: TMTokens.emphasis,
            trend: 'Gerados',
            trendPositive: true,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 4 ? 1.8 : 2.2,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            return _AnimatedKPICard(
              data: kpis[index],
              delay: Duration(milliseconds: 100 * index),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: TMTokens.text,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionButton(
              icon: Icons.add_rounded,
              label: 'Nova Vaga',
              color: TMTokens.primary,
              onTap: widget.onIrVagas,
            ),
            _QuickActionButton(
              icon: Icons.upload_file_rounded,
              label: 'Analisar Currículo',
              color: TMTokens.info,
              onTap: widget.onIrCurriculos,
            ),
            _QuickActionButton(
              icon: Icons.video_call_outlined,
              label: 'Nova Entrevista',
              color: const Color(0xFF8B5CF6),
              onTap: widget.onIrEntrevistas,
            ),
            _QuickActionButton(
              icon: Icons.assessment_outlined,
              label: 'Ver Relatórios',
              color: TMTokens.emphasis,
              onTap: widget.onIrEntrevistas,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVagasCard(BuildContext context) {
    return _DashboardCard(
      title: 'Vagas Recentes',
      action: TextButton.icon(
        onPressed: widget.onIrVagas,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Ver todas'),
      ),
      child: _vagas.isEmpty
          ? _buildEmptyState(
              icon: Icons.work_outline_rounded,
              message: 'Nenhuma vaga cadastrada',
              action: 'Criar primeira vaga',
              onAction: widget.onIrVagas,
            )
          : Column(
              children: _vagas.take(5).map((vaga) {
                final titulo = vaga['titulo']?.toString() ?? 'Vaga';
                final candidatos = vaga['candidatos']?.toString() ?? '0';
                final statusRaw = vaga['status']?.toString() ?? 'open';
                final status = statusRaw == 'open' ? 'aberta' : statusRaw;

                return _VagaListItem(
                  titulo: titulo,
                  candidatos: int.tryParse(candidatos) ?? 0,
                  status: status,
                  onTap: widget.onIrVagas,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAtividadeRecente(BuildContext context) {
    final atividades = _historico.take(5).toList();

    return _DashboardCard(
      title: 'Atividade Recente',
      action: TextButton.icon(
        onPressed: widget.onIrEntrevistas,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Ver histórico'),
      ),
      child: atividades.isEmpty
          ? _buildEmptyState(
              icon: Icons.history_rounded,
              message: 'Nenhuma atividade registrada',
              action: 'Iniciar entrevista',
              onAction: widget.onIrEntrevistas,
            )
          : Column(
              children: atividades.asMap().entries.map((entry) {
                final index = entry.key;
                final ativ = entry.value;
                final temRelatorio = ativ['tem_relatorio'] == true;

                return _AtividadeItem(
                  candidato: ativ['candidato']?.toString() ?? '-',
                  vaga: ativ['vaga']?.toString() ?? '-',
                  data: ativ['criado_em']?.toString(),
                  temRelatorio: temRelatorio,
                  isLast: index == atividades.length - 1,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildInsightsCard() {
    final tendencias =
        (_stats?['tendencias'] as List?)?.whereType<Map>().toList() ?? [];

    return _DashboardCard(
      title: 'Insights da IA',
      titleIcon: Icons.auto_awesome_rounded,
      titleIconColor: const Color(0xFF8B5CF6),
      gradient: const LinearGradient(
        colors: [Color(0xFFFAF5FF), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          if (tendencias.isEmpty) ...[
            _InsightItem(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Dica do dia',
              description:
                  'Faça upload de currículos para receber análises personalizadas com IA.',
              color: TMTokens.warning,
            ),
            const SizedBox(height: 12),
            _InsightItem(
              icon: Icons.trending_up_rounded,
              title: 'Melhore seu processo',
              description:
                  'Entrevistas com relatórios de IA têm 40% mais assertividade.',
              color: TMTokens.emphasis,
            ),
          ] else
            ...tendencias.take(3).map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightItem(
                    icon: Icons.bar_chart_rounded,
                    title: insight['label']?.toString() ?? 'Insight',
                    description:
                        '${insight['valor']}% dos candidatos nessa categoria.',
                    color: TMTokens.info,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    int toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    final entrevistas = toInt(_stats?['entrevistas']);
    final relatorios = toInt(_stats?['relatorios']);
    final taxaRelatorio =
        entrevistas > 0 ? ((relatorios / entrevistas) * 100).round() : 0;

    return _DashboardCard(
      title: 'Performance',
      titleIcon: Icons.speed_rounded,
      titleIconColor: TMTokens.emphasis,
      child: Column(
        children: [
          _PerformanceMetric(
            label: 'Taxa de Relatórios',
            value: taxaRelatorio,
            maxValue: 100,
            color: TMTokens.emphasis,
            suffix: '%',
          ),
          const SizedBox(height: 20),
          _PerformanceMetric(
            label: 'Entrevistas com IA',
            value: relatorios,
            maxValue: math.max(entrevistas, 1),
            color: TMTokens.info,
            suffix: '/$entrevistas',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    color: TMTokens.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    taxaRelatorio >= 70
                        ? 'Excelente! Continue usando a IA para otimizar suas contratações.'
                        : 'Gere mais relatórios com IA para aumentar a assertividade.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: TMTokens.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: TMTokens.textMuted,
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(action),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// WIDGETS AUXILIARES
// ============================================================

class _KPIData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendPositive;

  const _KPIData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendPositive,
  });
}

class _AnimatedKPICard extends StatefulWidget {
  final _KPIData data;
  final Duration delay;

  const _AnimatedKPICard({required this.data, required this.delay});

  @override
  State<_AnimatedKPICard> createState() => _AnimatedKPICardState();
}

class _AnimatedKPICardState extends State<_AnimatedKPICard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _countAnimation = IntTween(begin: 0, end: widget.data.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedKPICard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.value != widget.data.value) {
      _countAnimation = IntTween(begin: 0, end: widget.data.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TMTokens.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.data.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: TMTokens.textMuted,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.data.color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.data.icon,
                      size: 20, color: widget.data.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _countAnimation,
              builder: (context, child) {
                return Text(
                  '${_countAnimation.value}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: TMTokens.text,
                    letterSpacing: -1,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  widget.data.trendPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color:
                      widget.data.trendPositive ? TMTokens.success : TMTokens.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.data.trend,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.data.trendPositive
                          ? TMTokens.success
                          : TMTokens.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TMTokens.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TMTokens.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final Widget? action;
  final Widget child;
  final Gradient? gradient;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.titleIcon,
    this.titleIconColor,
    this.action,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TMTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon,
                          size: 20, color: titleIconColor ?? TMTokens.primary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: TMTokens.text,
                      ),
                    ),
                  ],
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _VagaListItem extends StatelessWidget {
  final String titulo;
  final int candidatos;
  final String status;
  final VoidCallback? onTap;

  const _VagaListItem({
    required this.titulo,
    required this.candidatos,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TMTokens.border),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    size: 18, color: TMTokens.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: TMTokens.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$candidatos candidato${candidatos != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TMTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TMChip.jobStatus(status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: TMTokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtividadeItem extends StatelessWidget {
  final String candidato;
  final String vaga;
  final String? data;
  final bool temRelatorio;
  final bool isLast;

  const _AtividadeItem({
    required this.candidato,
    required this.vaga,
    this.data,
    required this.temRelatorio,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    if (data != null) {
      dt = date_utils.DateUtils.parseParaBrasilia(data!);
    }
    final dataFormatada = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}'
        : 'Recente';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: temRelatorio ? TMTokens.success : TMTokens.warning,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  margin: const EdgeInsets.only(top: 4),
                  color: TMTokens.border,
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        candidato,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: TMTokens.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dataFormatada,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TMTokens.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  vaga,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TMTokens.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: temRelatorio
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    temRelatorio ? '✓ Relatório disponível' : '⏳ Em análise',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: temRelatorio
                          ? const Color(0xFF166534)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TMTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TMTokens.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TMTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final String suffix;

  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: TMTokens.textMuted,
              ),
            ),
            Text(
              '$value$suffix',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: .1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
