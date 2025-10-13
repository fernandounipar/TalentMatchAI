import 'package:flutter/material.dart';
import 'package:talentmatchia_frontend/componentes/widgets.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F3FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeroContent(context),
                        const SizedBox(height: 40),
                        const IlustracaoHero(),
                      ],
                    );
                  }
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildHeroContent(context)),
                      const SizedBox(width: 60),
                      const IlustracaoHero(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análise inteligente de currículos e entrevistas',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 800 ? 32 : 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3730A3),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Economize tempo, reduza vieses e contrate com precisão. O TalentMatchIA analisa currículos, gera perguntas e entrega relatórios completos — sem substituir o olhar humano.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Acessar Plataforma'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDemo,
                    icon: const Icon(Icons.play_circle, size: 18),
                    label: const Text('Ver Demo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
