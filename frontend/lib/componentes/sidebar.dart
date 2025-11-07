import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final String activeSection;
  final Function(String) onSectionChange;
  final String userName;
  final String userRole;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.activeSection,
    required this.onSectionChange,
    required this.userName,
    required this.userRole,
    required this.onLogout,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isMobileOpen = false;

  final List<Map<String, dynamic>> menuItems = [
    {'id': 'dashboard', 'label': 'Dashboard', 'icon': Icons.home},
    {'id': 'vagas', 'label': 'Vagas', 'icon': Icons.work},
    {'id': 'candidatos', 'label': 'Candidatos', 'icon': Icons.people},
    {'id': 'upload', 'label': 'Upload de Currículo', 'icon': Icons.upload_file},
    {'id': 'entrevistas', 'label': 'Entrevistas', 'icon': Icons.calendar_today},
    {'id': 'relatorios', 'label': 'Relatórios', 'icon': Icons.assessment},
    {'id': 'historico', 'label': 'Histórico', 'icon': Icons.history},
    {'id': 'configuracoes', 'label': 'Configurações', 'icon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

        return Stack(
          children: [
            // Mobile Menu Button
            if (!isLargeScreen)
              Positioned(
                top: 16,
                left: 16,
                child: FloatingActionButton.small(
                  onPressed: () {
                    setState(() {
                      isMobileOpen = !isMobileOpen;
                    });
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: Icon(
                    isMobileOpen ? Icons.close : Icons.menu,
                    color: Colors.grey[800],
                  ),
                ),
              ),

            // Mobile Overlay
            if (isMobileOpen && !isLargeScreen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isMobileOpen = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),

            // Sidebar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              bottom: 0,
              left: (!isLargeScreen && !isMobileOpen) ? -288 : 0,
              width: 288,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                  boxShadow: isLargeScreen
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                ),
                child: _buildSidebarContent(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'TM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TalentMatch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    'IA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Navigation
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: menuItems.map((item) {
                final isActive = widget.activeSection == item['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        widget.onSectionChange(item['id'] as String);
                        if (MediaQuery.of(context).size.width < 1024) {
                          setState(() {
                            isMobileOpen = false;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEFF6FF) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isActive
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isActive ? FontWeight.w600 : FontWeight.normal,
                                  color: isActive
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // User Profile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.userRole,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                color: const Color(0xFF6B7280),
                tooltip: 'Sair',
                onPressed: widget.onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
