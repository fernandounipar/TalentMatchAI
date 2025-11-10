import 'package:flutter/material.dart';
import 'package:talentmatchia_frontend/componentes/widgets.dart';

class LandingTela extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onDemo;

  const LandingTela({
    super.key,
    required this.onLogin,
    required this.onDemo,
  });

  @override
  State<LandingTela> createState() => _LandingTelaState();
}

enum _LandingSection { recursos, processos, relato, faq }

class _LandingTelaState extends State<LandingTela> {
  final ScrollController _scrollController = ScrollController();
  final Map<_LandingSection, GlobalKey> _sectionKeys = {
    _LandingSection.recursos: GlobalKey(),
    _LandingSection.processos: GlobalKey(),
    _LandingSection.relato: GlobalKey(),
    _LandingSection.faq: GlobalKey(),
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(_LandingSection section) {
    final key = _sectionKeys[section];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F3FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeroSection(constraints.maxWidth)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1, indent: 24, endIndent: 24)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildTrustedSection()),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _sectionKeys[_LandingSection.recursos],
                      child: _buildRecursosSection(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _sectionKeys[_LandingSection.processos],
                      child: _buildProcessosSection(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _sectionKeys[_LandingSection.relato],
                      child: _buildRelatosIASection(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildMetricasSection()),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _sectionKeys[_LandingSection.faq],
                      child: _buildFaqSection(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCtaFinalSection()),
                  SliverToBoxAdapter(child: _buildFooter()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(double maxWidth) {
    final isMobile = maxWidth < 840;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 32 : 64,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFFDF4FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LandingTopBar(
                onLogin: widget.onLogin,
                onDemo: widget.onDemo,
                onNavigate: _scrollTo,
              ),
              SizedBox(height: isMobile ? 32 : 72),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 5,
                    child: _HeroContent(
                      onDemo: widget.onDemo,
                      onLogin: widget.onLogin,
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 0 : 56, height: isMobile ? 32 : 0),
                  const Expanded(flex: 4, child: IlustracaoHero()),
                ],
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: const [
                  _BadgeDestaque(icone: Icons.shield_moon, texto: 'Conformidade LGPD e GDPR'),
                  _BadgeDestaque(icone: Icons.auto_awesome, texto: 'IA como co-piloto, não substituto'),
                  _BadgeDestaque(icone: Icons.timer, texto: 'Resultados em menos de 10 segundos'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'Tecnologia confiável para escalar processos seletivos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 32,
                runSpacing: 16,
                children: const [
                  _LogoEmpresa(nome: 'TechCorp'),
                  _LogoEmpresa(nome: 'InovaRH'),
                  _LogoEmpresa(nome: 'Skyline Digital'),
                  _LogoEmpresa(nome: 'FutureWorks'),
                  _LogoEmpresa(nome: 'RocketHR'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecursosSection() {
    final recursos = [
      (
        icone: Icons.upload_file,
        titulo: 'Upload inteligente',
        descricao:
            'Arraste currículos em PDF, DOCX ou TXT. A IA extrai e estrutura experiências, habilidades e certificações.',
      ),
      (
        icone: Icons.forum_outlined,
        titulo: 'Roteiro de entrevistas',
        descricao:
            'Perguntas estratégicas personalizadas para cada vaga, com notas sugeridas e critérios objetivos.',
      ),
      (
        icone: Icons.analytics_outlined,
        titulo: 'Insights em tempo real',
        descricao:
            'Pontuação de aderência, pontos fortes e riscos automaticamente gerados durante a entrevista.',
      ),
      (
        icone: Icons.description_outlined,
        titulo: 'Relatórios acionáveis',
        descricao:
            'Resumo executivo, recomendações e trilha de evidências exportáveis em PDF ou integração com ATS.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                titulo: 'Tudo que o RH precisa em um só lugar',
                descricao:
                    'Unimos análise de dados com o julgamento humano. Configure pipelines, acompanhe métricas e entregue feedbacks consistentes.',
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth < 900;
                  final isMobile = constraints.maxWidth < 600;
                  final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 220,
                    ),
                    itemCount: recursos.length,
                    itemBuilder: (context, index) {
                      final item = recursos[index];
                      return _FeatureCard(
                        icone: item.icone,
                        titulo: item.titulo,
                        descricao: item.descricao,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessosSection() {
    final etapas = [
      (
        titulo: '1. Configure sua vaga',
        descricao:
            'Cadastre requisitos, senioridade, regime e defina as tags que mais importam para seu time.',
      ),
      (
        titulo: '2. IA analisa e sugere',
        descricao:
            'Receba matching score, trilha de evidências e perguntas de aprofundamento em segundos.',
      ),
      (
        titulo: '3. Entrevista guiada',
        descricao:
            'Marque respostas, acompanhe timers, gere notas automáticas e consolide tudo em relatórios objetivos.',
      ),
    ];

    return Container(
      color: const Color(0xFF101828),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                titulo: 'Processo inteiro orquestrado com IA',
                descricao:
                    'Da triagem à decisão final, mantenha o recrutador no comando com roteiros claros e dados confiáveis.',
                cor: Colors.white,
                descricaoColor: Color(0xFFA3A8B2),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isVertical = constraints.maxWidth < 960;
                  return Flex(
                    direction: isVertical ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (var i = 0; i < etapas.length; i++)
                              Padding(
                                padding: EdgeInsets.only(bottom: i == etapas.length - 1 ? 0 : 24),
                                child: _ProcessStep(
                                  indice: i + 1,
                                  titulo: etapas[i].titulo,
                                  descricao: etapas[i].descricao,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: isVertical ? 0 : 48, height: isVertical ? 32 : 0),
                      Expanded(
                        child: _ProcessHighlightCard(onDemo: widget.onDemo),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatosIASection() {
    final destaques = [
      (
        titulo: 'Sugestões contextuais',
        descricao:
            'Para cada resposta do candidato, a IA gera follow-ups sugerindo aprofundamentos e marcando sinais de alerta.',
      ),
      (
        titulo: 'Comparativo entre candidatos',
        descricao:
            'Visualize rapidamente quem está mais aderente aos critérios técnicos e comportamentais definidos.',
      ),
      (
        titulo: 'Integração com GitHub e ATS',
        descricao:
            'Traga repositórios públicos, histórico de commits e sincronize notas com os sistemas atuais da sua empresa.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVertical = constraints.maxWidth < 960;
              return Flex(
                direction: isVertical ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                          titulo: 'IA ao lado do recrutador',
                          descricao:
                              'Transforme entrevistas em conversas inteligentes. O assistente sugere perguntas, captura insights e constrói relatórios automaticamente.',
                        ),
                        const SizedBox(height: 32),
                        ...destaques.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _InsightListTile(
                              titulo: d.titulo,
                              descricao: d.descricao,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isVertical ? 0 : 40, height: isVertical ? 32 : 0),
                  Expanded(
                    child: _IAInsightCard(onLogin: widget.onLogin),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricasSection() {
    final metricas = [
      ('85%', 'Acurácia mínima nas análises de IA'),
      ('10s', 'Tempo máximo para analisar um currículo'),
      ('99,5%', 'Disponibilidade garantida em contrato'),
      ('+120', 'Empresas já utilizando o TalentMatchIA'),
    ];

    return Container(
      color: const Color(0xFFEEF2FF),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 24,
            spacing: 24,
            children: metricas
                .map(
                  (m) => _MetricaCard(
                    valor: m.$1,
                    descricao: m.$2,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = [
      (
        pergunta: 'A IA substitui o recrutador?',
        resposta:
            'Não. O TalentMatchIA atua como assistente. Ele organiza dados, sugere perguntas e gera relatórios, mas a decisão final permanece com o RH.',
      ),
      (
        pergunta: 'Como os dados ficam protegidos?',
        resposta:
            'Aplicamos criptografia em repouso e em trânsito, controles de acesso por perfil e cumprimos LGPD/GDPR com trilha completa de auditoria.',
      ),
      (
        pergunta: 'A solução integra com sistemas existentes?',
        resposta:
            'Sim. Exportamos relatórios em PDF, temos webhooks e endpoints para ATS e Slack. Integrações adicionais podem ser habilitadas sob demanda.',
      ),
      (
        pergunta: 'Quanto tempo leva para implementar?',
        resposta:
            'Em média 2 semanas. Oferecemos onboarding assistido, templates de vagas e conectores pré-configurados.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                titulo: 'Perguntas frequentes',
                descricao: 'Transparência total para que seu time tome a decisão com confiança.',
                alinhamentoCentro: true,
              ),
              const SizedBox(height: 32),
              ...faqs.map(
                (faq) => _FaqItem(
                  pergunta: faq.pergunta,
                  resposta: faq.resposta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaFinalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pronto para dar superpoderes ao seu RH?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Teste o TalentMatchIA gratuitamente por 14 dias. Não requer cartão de crédito.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onDemo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4F46E5),
                      ),
                      child: const Text('Experimentar demo agora'),
                    ),
                    OutlinedButton(
                      onPressed: widget.onLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text('Entrar na plataforma'),
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

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isVertical = constraints.maxWidth < 900;
                  return Flex(
                    direction: isVertical ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TalentMatchIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'IA que potencializa decisões humanas. Plataforma completa para recrutamento técnico justo e eficiente.',
                              style: TextStyle(color: Colors.white70, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isVertical ? 0 : 48, height: isVertical ? 32 : 0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FooterLink(titulo: 'Produto', links: [
                              'Dashboard',
                              'Análise de Currículos',
                              'Entrevista Assistida',
                              'Relatórios',
                            ]),
                          ],
                        ),
                      ),
                      SizedBox(width: isVertical ? 0 : 48, height: isVertical ? 32 : 0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FooterLink(titulo: 'Recursos', links: [
                              'Roadmap',
                              'Segurança e LGPD',
                              'Integrações',
                              'Central de ajuda',
                            ]),
                          ],
                        ),
                      ),
                      SizedBox(width: isVertical ? 0 : 48, height: isVertical ? 32 : 0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FooterLink(titulo: 'Contato', links: [
                              'suporte@talentmatch.ai',
                              '+55 (11) 4000-1234',
                              'Rua da Inovação, 123 • São Paulo/SP',
                              'Termos e privacidade',
                            ]),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFF1F2937)),
              const SizedBox(height: 16),
              const Text(
                '© 2024 TalentMatchIA. Todos os direitos reservados.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingTopBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onDemo;
  final void Function(_LandingSection section) onNavigate;

  const _LandingTopBar({
    required this.onLogin,
    required this.onDemo,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 720;
    final itens = [
      ('Recursos', _LandingSection.recursos),
      ('Como funciona', _LandingSection.processos),
      ('Assistente IA', _LandingSection.relato),
      ('FAQ', _LandingSection.faq),
    ];

    return Row(
      children: [
        const _LogoMarca(),
        const Spacer(),
        if (!isCompact)
          ...itens.map(
            (item) => TextButton(
              onPressed: () => onNavigate(item.$2),
              child: Text(item.$1),
            ),
          ),
        if (!isCompact) const SizedBox(width: 12),
        TextButton(onPressed: onLogin, child: const Text('Entrar')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onDemo,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: const Text('Experimentar demo'),
        ),
      ],
    );
  }
}

class _LogoMarca extends StatelessWidget {
  const _LogoMarca();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
            ),
          ),
          child: const Center(
            child: Text(
              'TM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TalentMatchIA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              'Assistente inteligente para recrutadores',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  final VoidCallback onDemo;
  final VoidCallback onLogin;
  final bool isMobile;

  const _HeroContent({
    required this.onDemo,
    required this.onLogin,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final headlineStyle = TextStyle(
      fontSize: isMobile ? 36 : 48,
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: const Color(0xFF1F2358),
    );

    final descricaoStyle = TextStyle(
      fontSize: 18,
      height: 1.6,
      color: Colors.grey.shade600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Nova versão • Coleta automática de evidências',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('IA que potencializa decisões humanas no recrutamento.', style: headlineStyle),
        const SizedBox(height: 16),
        Text(
          'Simplifique o fluxo de análise de currículos, gere perguntas sob medida e acompanhe entrevistas com relatórios em tempo real.',
          style: descricaoStyle,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: onDemo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Ver demo guiada'),
            ),
            OutlinedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: const Text('Entrar agora'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(color: Colors.indigo.shade200),
                foregroundColor: const Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _HeroMetric(titulo: 'Tempo médio de triagem', valor: '5x mais rápido'),
            _HeroMetric(titulo: 'Aderência média', valor: '92%'),
            _HeroMetric(titulo: 'Satisfação dos gestores', valor: '9,4/10'),
          ],
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String titulo;
  final String valor;

  const _HeroMetric({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BadgeDestaque extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _BadgeDestaque({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LogoEmpresa extends StatelessWidget {
  final String nome;

  const _LogoEmpresa({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        nome,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titulo;
  final String descricao;
  final Color cor;
  final Color descricaoColor;
  final bool alinhamentoCentro;

  const _SectionHeader({
    required this.titulo,
    required this.descricao,
    this.cor = const Color(0xFF1F2937),
    this.descricaoColor = const Color(0xFF4B5563),
    this.alinhamentoCentro = false,
  });

  @override
  Widget build(BuildContext context) {
    final textAlign = alinhamentoCentro ? TextAlign.center : TextAlign.start;
    final crossAxis = alinhamentoCentro ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          titulo,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: cor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: alinhamentoCentro ? 600 : double.infinity,
          child: Text(
            descricao,
            textAlign: textAlign,
            style: TextStyle(color: descricaoColor, fontSize: 16, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;

  const _FeatureCard({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final int indice;
  final String titulo;
  final String descricao;

  const _ProcessStep({
    required this.indice,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2333),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C3347)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF22C55E)],
              ),
            ),
            child: Center(
              child: Text(
                indice.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: const TextStyle(color: Color(0xFFCBD5F5), height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessHighlightCard extends StatelessWidget {
  final VoidCallback onDemo;

  const _ProcessHighlightCard({required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2333),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2C3347)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 40, offset: Offset(0, 24)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pipeline monitorado em tempo real',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Acompanhe candidatos por etapa, receba alertas de SLA e acione a IA para gerar follow-ups automáticos.',
            style: TextStyle(color: Color(0xFFCBD5F5), height: 1.6),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF2A3147),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _MiniStatus(label: 'Triagem', valor: '18 candidatos', progresso: 0.7, cor: Color(0xFF4F46E5)),
                SizedBox(height: 12),
                _MiniStatus(label: 'Entrevista técnica', valor: '7 candidatos', progresso: 0.45, cor: Color(0xFF22C55E)),
                SizedBox(height: 12),
                _MiniStatus(label: 'Gestor', valor: '3 candidatos', progresso: 0.2, cor: Color(0xFFFACC15)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onDemo,
            icon: const Icon(Icons.visibility),
            label: const Text('Ver pipeline completo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final String label;
  final String valor;
  final double progresso;
  final Color cor;

  const _MiniStatus({
    required this.label,
    required this.valor,
    required this.progresso,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }
}

class _InsightListTile extends StatelessWidget {
  final String titulo;
  final String descricao;

  const _InsightListTile({
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_fix_high, color: Color(0xFF4F46E5), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                Text(
                  descricao,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IAInsightCard extends StatelessWidget {
  final VoidCallback onLogin;

  const _IAInsightCard({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Relatório automático',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF111827)),
                ),
                SizedBox(height: 8),
                Text(
                  'Resumo executivo, pontos fortes e riscos gerados instantaneamente após a entrevista, com trilha de evidências.',
                  style: TextStyle(color: Color(0xFF475569), height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E7FF)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bullet(texto: 'Geração de perguntas adaptativas por senioridade'),
                SizedBox(height: 8),
                _Bullet(texto: 'Transcrição opcional de áudio e identificação de palavras-chave'),
                SizedBox(height: 8),
                _Bullet(texto: 'Notas automáticas com justificativa baseada em evidências'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Ver fluxo completo na plataforma'),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String texto;

  const _Bullet({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: Color(0xFF475569), height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final String valor;
  final String descricao;

  const _MetricaCard({required this.valor, required this.descricao});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white70),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF312E81),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String pergunta;
  final String resposta;

  const _FaqItem({required this.pergunta, required this.resposta});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        onExpansionChanged: (value) => setState(() => _aberto = value),
        initiallyExpanded: _aberto,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          widget.pergunta,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        children: [
          Text(
            widget.resposta,
            style: TextStyle(color: Colors.grey.shade600, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String titulo;
  final List<String> links;

  const _FooterLink({required this.titulo, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              link,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
