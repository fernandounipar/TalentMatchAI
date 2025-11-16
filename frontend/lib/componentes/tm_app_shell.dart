import 'package:flutter/material.dart';
import 'sidebar.dart' as legacy;
import '../design_system/tm_tokens.dart';

/// TMAppShell
/// Estrutura base do app (Sidebar + Main container responsivo)
class TMAppShell extends StatelessWidget {
  final String activeSection;
  final ValueChanged<String> onSectionChange;
  final Widget child;
  final String userName;
  final String userRole;
  final String? userPhotoUrl;
  final VoidCallback onLogout;

  const TMAppShell({
    super.key,
    required this.activeSection,
    required this.onSectionChange,
    required this.child,
    this.userName = 'Usuário',
    this.userRole = 'usuário',
    this.userPhotoUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (reutiliza componente existente)
          SizedBox(
            width: 288,
            child: legacy.Sidebar(
              activeSection: activeSection,
              onSectionChange: onSectionChange,
              userName: userName,
              userRole: userRole,
              userPhotoUrl: userPhotoUrl,
              onLogout: onLogout,
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              color: TMTokens.bg,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontal = constraints.maxWidth >= 1024 ? 32.0 : 24.0;
                    final vertical = constraints.maxWidth >= 1024 ? 32.0 : 24.0;
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

