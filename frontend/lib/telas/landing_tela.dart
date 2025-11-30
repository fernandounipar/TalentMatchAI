import 'package:flutter/material.dart';

class _AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const secondary = Color(0xFF64748B);
  static const background = Color(0xFFF8FAFC);
  static const text = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);
}

class _AppTextStyles {
  static TextStyle h1(bool isMobile) => TextStyle(
        fontSize: isMobile ? 36 : 56,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: _AppColors.text,
        letterSpacing: -1.5,
      );

  static TextStyle h2(bool isMobile) => TextStyle(
        fontSize: isMobile ? 28 : 40,
        fontWeight: FontWeight.bold,
        color: _AppColors.text,
        letterSpacing: -0.5,
      );

  static TextStyle body(bool isMobile) => TextStyle(
        fontSize: isMobile ? 16 : 18,
        color: _AppColors.textLight,
        height: 1.6,
      );
}

class LandingTela extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onDemo;

  const LandingTela({
    super.key,
    required this.onLogin,
    required this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return SingleChildScrollView(
            child: Column(
              children: [
                _NavBar(onLogin: onLogin, onRegister: onDemo, isMobile: isMobile),
                _HeroSection(isMobile: isMobile, onRegister: onDemo),
                _ProblemSolutionSection(isMobile: isMobile),
                _FeaturesSection(isMobile: isMobile),
                _TechSpecsSection(isMobile: isMobile),
                _CallToActionSection(isMobile: isMobile, onRegister: onDemo),
                _Footer(isMobile: isMobile),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final bool isMobile;

  const _NavBar({
    required this.onLogin,
    required this.onRegister,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: 20,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'TalentMatchIA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (!isMobile)
            Row(
              children: [
                const _NavLink(title: 'Funcionalidades'),
                const _NavLink(title: 'Sobre'),
                const _NavLink(title: 'Tecnologia'),
                const SizedBox(width: 24),
                TextButton(
                  onPressed: onLogin,
                  child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Comecar Agora'),
                ),
              ],
            )
          else
            IconButton(onPressed: onLogin, icon: const Icon(Icons.menu)),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onRegister;

  const _HeroSection({required this.isMobile, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 60 : 100,
      ),
      color: _AppColors.background,
      child: isMobile
          ? Column(
              children: [
                _buildTextContent(context),
                const SizedBox(height: 48),
                _buildVisualContent(),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 5, child: _buildTextContent(context)),
                const SizedBox(width: 48),
                Expanded(flex: 6, child: _buildVisualContent()),
              ],
            ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'O futuro do RH chegou',
            style: TextStyle(
              color: _AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            style: _AppTextStyles.h1(isMobile),
            children: const [
              TextSpan(text: 'Seu assistente de '),
              TextSpan(
                text: 'Recrutamento Inteligente',
                style: TextStyle(color: _AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reduza a triagem manual e encontre os melhores talentos em segundos. O TalentMatchIA utiliza inteligência artificial para analisar currículos, gerar entrevistas e entregar relatórios precisos.',
          style: _AppTextStyles.body(isMobile),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 32),
        Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: const Text('Criar Conta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_circle_outline, size: 20),
              label: const Text('Ver Demonstracao'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                foregroundColor: _AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text('LGPD', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(width: 24),
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text('Analise em 10s', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildVisualContent() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 6, backgroundColor: Colors.red.shade200),
                        const SizedBox(width: 8),
                        CircleAvatar(radius: 6, backgroundColor: Colors.amber.shade200),
                        const SizedBox(width: 8),
                        CircleAvatar(radius: 6, backgroundColor: Colors.green.shade200),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(width: 60, color: Colors.grey.shade50),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _MockCard(color: Colors.blue.shade50, iconColor: Colors.blue),
                                    const SizedBox(width: 16),
                                    _MockCard(color: Colors.purple.shade50, iconColor: Colors.purple),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: _AppColors.primary.withValues(alpha: 0.2),
                    child: const Text('AS',
                        style: TextStyle(color: _AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ana Silva', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Dev Flutter Senior', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text('98% Match',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  final Color color;
  final Color iconColor;
  const _MockCard({required this.color, required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.auto_awesome, color: iconColor),
      ),
    );
  }
}

class _ProblemSolutionSection extends StatelessWidget {
  final bool isMobile;
  const _ProblemSolutionSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text('Por que o TalentMatchIA?', style: _AppTextStyles.h2(isMobile)),
          const SizedBox(height: 16),
          SizedBox(
            width: 700,
            child: Text(
              'O cenario atual de recrutamento e marcado por volume excessivo e triagem manual ineficiente. Nossa ferramenta nao substitui o recrutador, ela o empodera.',
              textAlign: TextAlign.center,
              style: _AppTextStyles.body(isMobile),
            ),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: const [
              _StatItem(value: '10s', label: 'Tempo médio de análise por CV'),
              _StatItem(value: '+85%', label: 'Acurácia na triagem com IA'),
              _StatItem(value: '24/7', label: 'Disponibilidade do sistema'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold, color: _AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 16, color: _AppColors.textLight)),
      ],
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final bool isMobile;
  const _FeaturesSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 80),
      color: _AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('Funcionalidades Poderosas', style: _AppTextStyles.h2(isMobile))),
          const SizedBox(height: 48),
          GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            shrinkWrap: true,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: isMobile ? 2.0 : 1.4,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _FeatureCard(
                icon: Icons.upload_file,
                title: 'Análise de Currículos',
                description:
                    'Upload de PDF/TXT com extração automática de dados e ranqueamento por compatibilidade.',
              ),
              _FeatureCard(
                icon: Icons.psychology,
                title: 'Entrevistas com IA',
                description:
                    'Assistente que gera perguntas estratégicas baseadas no perfil do candidato e requisitos da vaga.',
              ),
              _FeatureCard(
                icon: Icons.assessment,
                title: 'Relatórios Objetivos',
                description:
                    'Receba insights detalhados pós-entrevista para decisões mais assertivas e justas.',
              ),
              _FeatureCard(
                icon: Icons.work_outline,
                title: 'Gestão de Vagas',
                description:
                    'Controle total dos processos seletivos e candidatos em um quadro Kanban intuitivo.',
              ),
              _FeatureCard(
                icon: Icons.code,
                title: 'Integracao GitHub',
                description: 'Analise automática de repositórios para candidatos técnicos (opcional).',
              ),
              _FeatureCard(
                icon: Icons.record_voice_over,
                title: 'Transcrição de Áudio',
                description: 'Transforme entrevistas gravadas em texto pesquisável automaticamente.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({required this.icon, required this.title, required this.description});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        transform: Matrix4.translationValues(0.0, _isHovered ? -6.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? _AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? _AppColors.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 10 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isHovered ? _AppColors.primary : _AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon,
                  color: _isHovered ? Colors.white : _AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _AppColors.text)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(widget.description,
                  style: const TextStyle(color: _AppColors.textLight, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechSpecsSection extends StatelessWidget {
  final bool isMobile;
  const _TechSpecsSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 80),
      child: Column(
        children: [
          Text('Arquitetura Segura e Escalavel', style: _AppTextStyles.h2(isMobile)),
          const SizedBox(height: 48),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: const [
              _TechPill(icon: Icons.flutter_dash, label: 'Flutter Web'),
              _TechPill(icon: Icons.dns, label: 'Node.js Backend'),
              _TechPill(icon: Icons.storage, label: 'PostgreSQL'),
              _TechPill(icon: Icons.security, label: 'LGPD'),
              _TechPill(icon: Icons.auto_awesome, label: 'OpenAI API'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TechPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: _AppColors.secondary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: _AppColors.secondary)),
        ],
      ),
    );
  }
}

class _CallToActionSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onRegister;

  const _CallToActionSection({required this.isMobile, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AppColors.primary, _AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Pronto para transformar seu recrutamento?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Junte-se a empresas que já utilizam IA para contratar melhor e mais rápido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Solicitar Acesso'),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isMobile;
  const _Footer({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: _AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'TalentMatchIA 2025',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Desenvolvido por Fernando e Marcelo',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String title;
  const _NavLink({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(foregroundColor: _AppColors.textLight),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}
