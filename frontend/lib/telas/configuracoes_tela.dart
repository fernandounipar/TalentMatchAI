import 'package:flutter/material.dart';
import '../design_system/tm_tokens.dart';

/// Tela de Configurações inspirada no layout web
class ConfiguracoesTela extends StatefulWidget {
  const ConfiguracoesTela({super.key});

  @override
  State<ConfiguracoesTela> createState() => _ConfiguracoesTelaState();
}

class _ConfiguracoesTelaState extends State<ConfiguracoesTela> {
  late final TextEditingController _empresaNomeController;
  late final TextEditingController _empresaDocumentoController;
  late final TextEditingController _termoController;
  late final TextEditingController _corHexController;

  late final TextEditingController _perfilNomeController;
  late final TextEditingController _perfilEmailController;
  late final TextEditingController _perfilCargoController;

  late final TextEditingController _senhaAtualController;
  late final TextEditingController _novaSenhaController;
  late final TextEditingController _confirmarSenhaController;

  late final TextEditingController _githubTokenController;
  late final TextEditingController _webhookUrlController;

  Color _corPrimaria = const Color(0xFF2B6CB0);
  bool _retencaoCurriculos = true;
  bool _anonimizacaoDados = false;

  bool _emailNovoCandidato = true;
  bool _emailAnaliseConcluida = true;
  bool _emailLembreteEntrevista = true;
  bool _pushTempoReal = false;

  bool _doisFatoresAtivo = false;
  bool _analiseGithubAtiva = true;

  bool _eventoWebhookNovo = true;
  bool _eventoWebhookAnalise = true;
  bool _eventoWebhookEntrevista = false;

  final List<Map<String, String>> _usuariosEquipe = const [
    {
      'nome': 'Patrícia Almeida',
      'email': 'patricia@talentmatch.com',
      'papel': 'Admin',
      'iniciais': 'PA',
    },
    {
      'nome': 'João Mendes',
      'email': 'joao.mendes@empresa.com',
      'papel': 'Recrutador',
      'iniciais': 'JM',
    },
    {
      'nome': 'Mariana Costa',
      'email': 'mariana.costa@empresa.com',
      'papel': 'Recrutador',
      'iniciais': 'MC',
    },
  ];

  @override
  void initState() {
    super.initState();
    _empresaNomeController = TextEditingController(text: 'TalentMatch IA');
    _empresaDocumentoController = TextEditingController(text: '12.345.678/0001-90');
    _termoController = TextEditingController(
      text: 'Ao prosseguir com sua candidatura, você autoriza o uso dos seus dados '
          'para fins de recrutamento e seleção pela TalentMatch IA.',
    );
    _corHexController = TextEditingController(text: _colorToHex(_corPrimaria));

    _perfilNomeController = TextEditingController(text: 'Patrícia Almeida');
    _perfilEmailController = TextEditingController(text: 'patricia@talentmatch.com');
    _perfilCargoController = TextEditingController(text: 'Recrutadora Senior');

    _senhaAtualController = TextEditingController();
    _novaSenhaController = TextEditingController();
    _confirmarSenhaController = TextEditingController();

    _githubTokenController = TextEditingController();
    _webhookUrlController = TextEditingController(text: 'https://seu-sistema.com/webhook');
  }

  @override
  void dispose() {
    _empresaNomeController.dispose();
    _empresaDocumentoController.dispose();
    _termoController.dispose();
    _corHexController.dispose();
    _perfilNomeController.dispose();
    _perfilEmailController.dispose();
    _perfilCargoController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    _githubTokenController.dispose();
    _webhookUrlController.dispose();
    super.dispose();
  }

  static String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${value.substring(2)}';
  }

  void _atualizarCorPorHex(String value) {
    final cleaned = value.replaceAll('#', '');
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) {
        setState(() {
          _corPrimaria = Color(parsed);
        });
      }
    }
  }

  Future<void> _selecionarCorPrimaria() async {
    final palette = [
      const Color(0xFF2B6CB0),
      const Color(0xFF4338CA),
      const Color(0xFF0EA5E9),
      const Color(0xFF047857),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
      const Color(0xFFF97316),
    ];

    final selecionada = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecione a cor primária'),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: palette
                  .map(
                    (color) => GestureDetector(
                      onTap: () => Navigator.of(context).pop(color),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selecionada != null) {
      setState(() {
        _corPrimaria = selecionada;
        _corHexController.text = _colorToHex(selecionada);
      });
    }
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const destaque = TMTokens.primary;

    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: destaque,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie as configurações da empresa e do usuário',
            style: TextStyle(fontSize: 14, color: TMTokens.textMuted),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: TMTokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TMTokens.border),
            ),
            child: TabBar(
              labelColor: destaque,
              unselectedLabelColor: TMTokens.textMuted,
              indicator: BoxDecoration(
                color: destaque.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(icon: Icon(Icons.apartment_outlined, size: 18), text: 'Empresa'),
                Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Perfil'),
                Tab(icon: Icon(Icons.notifications_none, size: 18), text: 'Notificações'),
                Tab(icon: Icon(Icons.lock_outline, size: 18), text: 'Segurança'),
                Tab(icon: Icon(Icons.integration_instructions_outlined, size: 18), text: 'Integrações'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildEmpresaTab(),
                _buildPerfilTab(),
                _buildNotificacoesTab(),
                _buildSegurancaTab(),
                _buildIntegracoesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpresaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _buildSectionCard(
            icon: Icons.apartment,
            title: 'Informações da Empresa',
            description: 'Dados cadastrais e identificação',
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 640;
                  final fields = [
                    Expanded(child: _buildLabeledField('Nome da Empresa', _empresaNomeController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('CNPJ', _empresaDocumentoController)),
                  ];

                  if (isWide) {
                    return Row(children: fields);
                  }

                  return Column(
                    children: [
                      _buildLabeledField('Nome da Empresa', _empresaNomeController),
                      const SizedBox(height: 16),
                      _buildLabeledField('CNPJ', _empresaDocumentoController),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarSnack('Informações da empresa atualizadas!'),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.palette_outlined,
            title: 'Identidade Visual',
            description: 'Personalize a aparência do sistema',
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logo da Empresa',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TMTokens.text),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TMTokens.border, style: BorderStyle.solid, width: 2),
                          color: TMTokens.bg,
                        ),
                        child: const Icon(Icons.apartment, size: 36, color: TMTokens.textMuted),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => _mostrarSnack('Upload de logo em breve!'),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload de Logo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Cor Primária',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TMTokens.text),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: _selecionarCorPrimaria,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _corPrimaria,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TMTokens.border),
                      ),
                      child: const Icon(Icons.colorize, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLabeledField(
                      'Código HEX',
                      _corHexController,
                      onChanged: _atualizarCorPorHex,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _selecionarCorPrimaria,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Selecionar cor'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _mostrarSnack('Identidade visual atualizada!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Aplicar Alterações'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.verified_user_outlined,
            title: 'LGPD & Privacidade',
            description: 'Configurações de conformidade e retenção de dados',
            children: [
              _buildSwitchTile(
                title: 'Retenção automática de currículos',
                subtitle: 'Manter currículos por até 90 dias após o processo seletivo',
                value: _retencaoCurriculos,
                onChanged: (value) => setState(() => _retencaoCurriculos = value),
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                title: 'Anonimização de dados rejeitados',
                subtitle: 'Anonimizar dados de candidatos reprovados automaticamente',
                value: _anonimizacaoDados,
                onChanged: (value) => setState(() => _anonimizacaoDados = value),
              ),
              const SizedBox(height: 24),
              _buildLabeledField(
                'Termo de Consentimento LGPD',
                _termoController,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _mostrarSnack('Configurações de privacidade salvas!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Configurações'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.group_outlined,
            title: 'Gerenciamento de Usuários',
            description: 'Convide e gerencie membros da equipe',
            children: [
              Column(
                children: _usuariosEquipe
                    .map(
                      (usuario) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TMTokens.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: TMTokens.primary.withOpacity(0.12),
                              child: Text(
                                usuario['iniciais']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: TMTokens.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    usuario['nome']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    usuario['email']!,
                                    style: const TextStyle(fontSize: 12, color: TMTokens.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            _buildBadge(usuario['papel']!),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              OutlinedButton.icon(
                onPressed: () => _mostrarSnack('Convite enviado!'),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('+ Convidar Membro'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _buildSectionCard(
            icon: Icons.person_outline,
            title: 'Informações Pessoais',
            description: 'Atualize seus dados pessoais',
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: TMTokens.primary.withOpacity(0.12),
                    child: const Icon(Icons.person, size: 44, color: TMTokens.primary),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarSnack('Funcionalidade de alterar foto em breve!'),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Alterar Foto'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 640;
                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: _buildLabeledField('Nome Completo', _perfilNomeController)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLabeledField(
                            'Email',
                            _perfilEmailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildLabeledField('Nome Completo', _perfilNomeController),
                      const SizedBox(height: 16),
                      _buildLabeledField(
                        'Email',
                        _perfilEmailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildLabeledField('Cargo', _perfilCargoController),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarSnack('Perfil atualizado com sucesso!'),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacoesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _buildSectionCard(
            icon: Icons.notifications_outlined,
            title: 'Preferências de Notificação',
            description: 'Escolha como deseja receber atualizações',
            children: [
              const Text(
                'Email',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TMTokens.text),
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                title: 'Novo candidato',
                subtitle: 'Quando um novo currículo é enviado',
                value: _emailNovoCandidato,
                onChanged: (value) => setState(() => _emailNovoCandidato = value),
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                title: 'Análise concluída',
                subtitle: 'Quando a IA termina de analisar um currículo',
                value: _emailAnaliseConcluida,
                onChanged: (value) => setState(() => _emailAnaliseConcluida = value),
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                title: 'Lembrete de entrevista',
                subtitle: '24h antes de uma entrevista agendada',
                value: _emailLembreteEntrevista,
                onChanged: (value) => setState(() => _emailLembreteEntrevista = value),
              ),
              const SizedBox(height: 24),
              const Text(
                'Push (Navegador)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TMTokens.text),
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                title: 'Notificações em tempo real',
                subtitle: 'Receber notificações push no navegador',
                value: _pushTempoReal,
                onChanged: (value) => setState(() => _pushTempoReal = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegurancaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _buildSectionCard(
            icon: Icons.lock_reset,
            title: 'Alterar Senha',
            description: 'Mantenha sua conta segura',
            children: [
              _buildLabeledField('Senha Atual', _senhaAtualController, obscureText: true),
              const SizedBox(height: 16),
              _buildLabeledField('Nova Senha', _novaSenhaController, obscureText: true),
              const SizedBox(height: 16),
              _buildLabeledField('Confirmar Nova Senha', _confirmarSenhaController, obscureText: true),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _mostrarSnack('Senha atualizada com sucesso!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Atualizar Senha'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.verified_user_outlined,
            title: 'Autenticação de Dois Fatores',
            description: 'Adicione uma camada extra de segurança',
            children: [
              _buildSwitchTile(
                title: 'Habilitar 2FA',
                subtitle: 'Requer código de verificação ao fazer login',
                value: _doisFatoresAtivo,
                onChanged: (value) => setState(() => _doisFatoresAtivo = value),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _mostrarSnack('Configuração de 2FA em breve!'),
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text('Configurar 2FA'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.devices_other_outlined,
            title: 'Sessões Ativas',
            description: 'Gerencie seus dispositivos conectados',
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TMTokens.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.laptop_mac, color: TMTokens.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chrome • Windows',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'São Paulo, SP • Sessão atual',
                            style: const TextStyle(fontSize: 12, color: TMTokens.textMuted),
                          ),
                        ],
                      ),
                    ),
                    _buildBadge('Ativo', filled: false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _mostrarSnack('Sessões encerradas com sucesso!'),
                icon: const Icon(Icons.logout),
                label: const Text('Encerrar Todas as Outras Sessões'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntegracoesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _buildSectionCard(
            icon: Icons.vpn_key_outlined,
            title: 'API Keys',
            description: 'Tokens para integração com sistemas externos',
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TMTokens.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TMTokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OpenAI API Key',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        _buildBadge('Configurada'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'sk-...•••••••••••••••••••••••••••',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: TMTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _mostrarSnack('Nova API Key cadastrada!'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('+ Adicionar Nova API Key'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.code_outlined,
            title: 'Integração GitHub',
            description: 'Analise repositórios dos candidatos automaticamente',
            children: [
              _buildSwitchTile(
                title: 'Habilitar análise de GitHub',
                subtitle: 'Buscar repositórios e analisar contribuições',
                value: _analiseGithubAtiva,
                onChanged: (value) => setState(() => _analiseGithubAtiva = value),
              ),
              const SizedBox(height: 16),
              _buildLabeledField(
                'GitHub Token (opcional)',
                _githubTokenController,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _mostrarSnack('Integração GitHub atualizada!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Configuração'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.webhook_outlined,
            title: 'Webhooks',
            description: 'Receba notificações em seus sistemas',
            children: [
              _buildLabeledField('URL do Webhook', _webhookUrlController),
              const SizedBox(height: 24),
              const Text(
                'Eventos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TMTokens.text),
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                title: 'Novo candidato',
                subtitle: 'Acionado quando um novo currículo é recebido',
                value: _eventoWebhookNovo,
                onChanged: (value) => setState(() => _eventoWebhookNovo = value),
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                title: 'Análise concluída',
                subtitle: 'Aviso assim que o relatório de IA ficar pronto',
                value: _eventoWebhookAnalise,
                onChanged: (value) => setState(() => _eventoWebhookAnalise = value),
              ),
              const Divider(height: 32),
              _buildSwitchTile(
                title: 'Entrevista agendada',
                subtitle: 'Confirmação do agendamento de entrevistas',
                value: _eventoWebhookEntrevista,
                onChanged: (value) => setState(() => _eventoWebhookEntrevista = value),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _mostrarSnack('Webhook salvo com sucesso!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: TMTokens.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Webhook'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TMTokens.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: TMTokens.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 13, color: TMTokens.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TMTokens.text),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: obscureText ? 1 : (maxLines > 1 ? maxLines : 1),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: TMTokens.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TMTokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TMTokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TMTokens.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: TMTokens.textMuted),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: TMTokens.primary,
    );
  }

  Widget _buildBadge(String label, {bool filled = true}) {
    final isAdmin = label.toLowerCase() == 'admin';
    final color = filled
        ? (isAdmin ? TMTokens.primary : TMTokens.success)
        : TMTokens.primary;
    final background = filled ? color.withOpacity(isAdmin ? 1 : 0.12) : Colors.transparent;
    final textColor = filled ? (isAdmin ? Colors.white : color) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
