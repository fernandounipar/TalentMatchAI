import 'package:flutter/material.dart';

/// Tela de Configurações
class ConfiguracoesTela extends StatefulWidget {
  const ConfiguracoesTela({super.key});

  @override
  State<ConfiguracoesTela> createState() => _ConfiguracoesTelaState();
}

class _ConfiguracoesTelaState extends State<ConfiguracoesTela> {
  final _nomeController = TextEditingController(text: 'Patricia Recrutadora');
  final _emailController = TextEditingController(text: 'patricia@talentmatch.com');
  final _empresaController = TextEditingController(text: 'TalentMatch IA');
  
  bool _notificacoesEmail = true;
  bool _notificacoesPush = false;
  bool _lgpdAtivo = true;
  bool _criptografiaAtiva = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Configurações',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie suas preferências e segurança',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Perfil
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Perfil do Usuário',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Stack(
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Color(0xFF4F46E5),
                                child: Icon(Icons.person, size: 50, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF4F46E5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Nome Completo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('E-mail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Empresa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _empresaController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Perfil atualizado com sucesso!')),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Salvar Alterações'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Configurações
              Expanded(
                child: Column(
                  children: [
                    // Notificações
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notifications, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text(
                                  'Notificações',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Notificações por E-mail'),
                              subtitle: const Text('Receba atualizações por e-mail'),
                              value: _notificacoesEmail,
                              onChanged: (value) => setState(() => _notificacoesEmail = value),
                            ),
                            SwitchListTile(
                              title: const Text('Notificações Push'),
                              subtitle: const Text('Alertas em tempo real'),
                              value: _notificacoesPush,
                              onChanged: (value) => setState(() => _notificacoesPush = value),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Privacidade e Segurança
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.security, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text(
                                  'Privacidade & Segurança',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.verified_user, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Sistema Protegido',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Todos os dados são criptografados e armazenados com segurança. O sistema está em conformidade com LGPD e GDPR.',
                                    style: TextStyle(fontSize: 13, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: Icon(
                                _lgpdAtivo ? Icons.check_circle : Icons.cancel,
                                color: _lgpdAtivo ? Colors.green : Colors.red,
                              ),
                              title: const Text('Conformidade LGPD'),
                              subtitle: const Text('Lei Geral de Proteção de Dados'),
                              trailing: Switch(
                                value: _lgpdAtivo,
                                onChanged: (value) => setState(() => _lgpdAtivo = value),
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                _criptografiaAtiva ? Icons.lock : Icons.lock_open,
                                color: _criptografiaAtiva ? Colors.green : Colors.red,
                              ),
                              title: const Text('Criptografia de Dados'),
                              subtitle: const Text('AES-256 para dados sensíveis'),
                              trailing: Switch(
                                value: _criptografiaAtiva,
                                onChanged: (value) => setState(() => _criptografiaAtiva = value),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: const Text('LGPD'),
                                  backgroundColor: Colors.green.shade100,
                                  avatar: Icon(Icons.check, color: Colors.green.shade700, size: 18),
                                ),
                                Chip(
                                  label: const Text('GDPR'),
                                  backgroundColor: Colors.blue.shade100,
                                  avatar: Icon(Icons.check, color: Colors.blue.shade700, size: 18),
                                ),
                                Chip(
                                  label: const Text('ISO 27001'),
                                  backgroundColor: Colors.purple.shade100,
                                  avatar: Icon(Icons.check, color: Colors.purple.shade700, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // IA e Análise
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.psychology, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text(
                                  'Configurações de IA',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Modelo de IA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: 'GPT-4',
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'GPT-4', child: Text('GPT-4 (Recomendado)')),
                                DropdownMenuItem(value: 'GPT-3.5', child: Text('GPT-3.5 Turbo')),
                                DropdownMenuItem(value: 'Claude', child: Text('Claude 2')),
                              ],
                              onChanged: (value) {},
                            ),
                            const SizedBox(height: 16),
                            const Text('Nível de Detalhe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Slider(
                              value: 0.7,
                              onChanged: (value) {},
                              divisions: 10,
                              label: 'Detalhado',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quantidade de perguntas e insights gerados pela IA',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

          const SizedBox(height: 24),

          // Sobre o Sistema
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo.shade700, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TalentMatch IA',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text('Versão 1.0.0 • Build 2025.10.12'),
                        const SizedBox(height: 8),
                        Text(
                          'Sistema de recrutamento inteligente com análise de currículos, entrevistas assistidas por IA e relatórios automatizados.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'TalentMatch IA',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.psychology, size: 48, color: Color(0xFF4F46E5)),
                        children: const [
                          Text('Desenvolvido com Flutter e Node.js'),
                          SizedBox(height: 8),
                          Text('© 2025 TalentMatch IA. Todos os direitos reservados.'),
                        ],
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Sobre'),
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
