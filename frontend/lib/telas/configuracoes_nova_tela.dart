import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/tm_tokens.dart';
import '../servicos/api_cliente.dart';

/// Tela de Configurações com dados reais do backend
class ConfiguracoesNovaTela extends StatefulWidget {
  final ApiCliente api;
  final Future<void> Function()? onCompanyUpdated;

  const ConfiguracoesNovaTela({
    super.key,
    required this.api,
    this.onCompanyUpdated,
  });

  @override
  State<ConfiguracoesNovaTela> createState() => _ConfiguracoesNovaTelaState();
}

class _ConfiguracoesNovaTelaState extends State<ConfiguracoesNovaTela> {
  bool _carregando = true;
  Map<String, dynamic>? _dadosUsuario;
  String? _erro;

  // Controladores para empresa
  String? _empresaTipoSelecionado; // 'CPF' ou 'CNPJ'
  late final TextEditingController _empresaDocumentoController;
  late final TextEditingController _empresaNomeController;
  bool _salvandoEmpresa = false;

  // Identidade visual
  Color _corPrimaria = TMTokens.primary;
  late final TextEditingController _corHexController;

  // LGPD & Privacidade
  bool _retencaoCurriculos = true;
  bool _anonimizacaoDados = false;
  late final TextEditingController _termoLgpdController;

  // Perfil do usuário
  late final TextEditingController _perfilNomeController;
  late final TextEditingController _perfilEmailController;
  late final TextEditingController _perfilCargoController;
  String? _cargoSelecionado;
  bool _salvando = false;

  // Segurança
  late final TextEditingController _senhaAtualController;
  late final TextEditingController _novaSenhaController;
  late final TextEditingController _confirmarSenhaController;

  // Integrações
  late final TextEditingController _githubTokenController;
  late final TextEditingController _webhookUrlController;
  bool _analiseGithubAtiva = true;
  bool _eventoWebhookNovo = true;
  bool _eventoWebhookAnalise = true;
  bool _eventoWebhookEntrevista = false;

  // API Keys
  List<Map<String, dynamic>> _apiKeys = [];
  bool _carregandoApiKeys = false;


  final List<Map<String, String>> _usuariosEquipeMock = const [
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
    _empresaDocumentoController = TextEditingController();
    _empresaNomeController = TextEditingController();
    _corHexController = TextEditingController();
    _termoLgpdController = TextEditingController(
      text:
          'Ao prosseguir com sua candidatura, você autoriza o uso dos seus dados para fins de recrutamento e seleção.',
    );
    _perfilNomeController = TextEditingController();
    _perfilEmailController = TextEditingController();
    _perfilCargoController = TextEditingController();
    _senhaAtualController = TextEditingController();
    _novaSenhaController = TextEditingController();
    _confirmarSenhaController = TextEditingController();
    _githubTokenController = TextEditingController();
    _webhookUrlController = TextEditingController(
      text: 'https://seu-sistema.com/webhook',
    );
    _corHexController.text = _colorToHex(_corPrimaria);
    _carregarDados();
  }

  @override
  void dispose() {
    _empresaDocumentoController.dispose();
    _empresaNomeController.dispose();
    _corHexController.dispose();
    _termoLgpdController.dispose();
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

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await widget.api.obterUsuario();

      // Compatibilidade: backend pode retornar { user, company } ou { usuario: { company } }
      final rawUser = (dados['user'] ?? dados['usuario']) as Map<String, dynamic>?;
      final rawCompany = (dados['company'] ?? rawUser?['company']) as Map<String, dynamic>?;

      setState(() {
        _dadosUsuario = {
          'user': rawUser,
          'company': rawCompany,
        };
        _carregando = false;

        if (rawUser != null) {
          _perfilNomeController.text =
              (rawUser['full_name'] ?? rawUser['nome'] ?? '') as String;
          _perfilEmailController.text = (rawUser['email'] ?? '') as String;
          _perfilCargoController.text =
              (rawUser['cargo'] ?? 'Recrutador(a)') as String;
        }

        // Se tem empresa, preenche os campos
        if (rawCompany != null) {
          final empresa = rawCompany;
          _empresaTipoSelecionado =
              (empresa['type'] ?? empresa['tipo'] ?? '').toString().toUpperCase();
          _empresaDocumentoController.text =
              (empresa['document'] ?? empresa['documento'] ?? '') as String;
          _empresaNomeController.text = (empresa['name'] ?? empresa['nome'] ?? '') as String;
        }
      });

      if (rawCompany != null) {
        await _carregarApiKeys();
      } else {
        if (mounted) {
          setState(() {
            _apiKeys = [];
          });
        }
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar dados: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _salvarEmpresa() async {
    final tipo = (_empresaTipoSelecionado ?? '').toUpperCase();
    final documento = _empresaDocumentoController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final nome = _empresaNomeController.text.trim();

    // Validações
    if (tipo.isEmpty || (tipo != 'CPF' && tipo != 'CNPJ')) {
      _mostrarMensagem('Selecione se a empresa é CPF ou CNPJ', erro: true);
      return;
    }

    if (documento.isEmpty) {
      _mostrarMensagem('Documento é obrigatório', erro: true);
      return;
    }

    if (tipo == 'CPF' && documento.length != 11) {
      _mostrarMensagem('CPF deve ter 11 dígitos', erro: true);
      return;
    }

    if (tipo == 'CNPJ' && documento.length != 14) {
      _mostrarMensagem('CNPJ deve ter 14 dígitos', erro: true);
      return;
    }

    if (nome.isEmpty) {
      _mostrarMensagem('Nome é obrigatório', erro: true);
      return;
    }

    setState(() => _salvandoEmpresa = true);

    try {
      await widget.api.criarOuAtualizarEmpresa(
        tipo: tipo,
        documento: documento,
        nome: nome,
      );
      _mostrarMensagem('Empresa salva com sucesso!');
      // Recarrega os dados para atualizar o estado
      await _carregarDados();
      // Notifica o app para recarregar dados globais do usuário (onboarding)
      if (widget.onCompanyUpdated != null) {
        await widget.onCompanyUpdated!();
      }
      // Recarrega API Keys depois de atualizar empresa (se necessário)
      await _carregarApiKeys();
    } catch (e) {
      _mostrarMensagem('Erro ao salvar empresa: $e', erro: true);
    } finally {
      setState(() => _salvandoEmpresa = false);
    }
  }

  Future<void> _salvarPerfil() async {
    final fullName = _perfilNomeController.text.trim();
    final cargo = _cargoSelecionado;

    if (fullName.isEmpty) {
      _mostrarMensagem('Nome é obrigatório', erro: true);
      return;
    }

    setState(() => _salvando = true);

    try {
      await widget.api.atualizarPerfil(
        fullName: fullName,
        cargo: cargo,
      );
      _mostrarMensagem('Perfil atualizado com sucesso!');
      // Recarrega os dados
      await _carregarDados();
      // Notifica o app para atualizar sidebar
      if (widget.onCompanyUpdated != null) {
        await widget.onCompanyUpdated!();
      }
    } catch (e) {
      _mostrarMensagem('Erro ao atualizar perfil: $e', erro: true);
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarFoto() async {
    // Por enquanto, solicita URL da foto (simplificado)
    // TODO: Implementar upload real de arquivo
    final controller = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL da Foto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://exemplo.com/foto.jpg',
            labelText: 'URL da imagem',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (resultado != null && resultado.isNotEmpty) {
      try {
        await widget.api.atualizarAvatar(resultado);
        _mostrarMensagem('Foto atualizada com sucesso!');
        await _carregarDados();
        // Atualiza sidebar
        if (widget.onCompanyUpdated != null) {
          await widget.onCompanyUpdated!();
        }
      } catch (e) {
        _mostrarMensagem('Erro ao atualizar foto: $e', erro: true);
      }
    }
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatarDocumento(String doc) {
    if (doc.length == 11) {
      // CPF: 000.000.000-00
      return '${doc.substring(0, 3)}.${doc.substring(3, 6)}.${doc.substring(6, 9)}-${doc.substring(9)}';
    } else if (doc.length == 14) {
      // CNPJ: 00.000.000/0000-00
      return '${doc.substring(0, 2)}.${doc.substring(2, 5)}.${doc.substring(5, 8)}/${doc.substring(8, 12)}-${doc.substring(12)}';
    }
    return doc;
  }

  String _iniciais(String? nome) {
    if (nome == null || nome.trim().isEmpty) return '?';
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${value.substring(2)}';
  }

  void _atualizarCorPorHex(String value) {
    final cleaned = value.replaceAll('#', '');
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) {
        setState(() {
          _corPrimaria = Color(parsed);
          _corHexController.text = _colorToHex(_corPrimaria);
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
                              color: Colors.black.withValues(alpha: 0.1),
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

  Future<void> _carregarApiKeys() async {
    if (!mounted) return;
    // Somente carrega se já houver empresa vinculada
    final company = _dadosUsuario?['company'] as Map<String, dynamic>?;
    if (company == null) {
      setState(() {
        _apiKeys = [];
      });
      return;
    }

    setState(() {
      _carregandoApiKeys = true;
    });
    try {
      final lista = await widget.api.listarApiKeys();
      if (!mounted) return;
      setState(() {
        _apiKeys = lista.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      // Apenas loga; não bloqueia toda a tela
      debugPrint('Erro ao carregar API Keys: $e');
    } finally {
      if (mounted) {
        setState(() {
          _carregandoApiKeys = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_erro!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDados,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final usuario = _dadosUsuario?['user'] as Map<String, dynamic>?;
    final empresa = _dadosUsuario?['company'] as Map<String, dynamic>?;
    final temEmpresa = empresa != null;

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: TMTokens.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie as configurações da empresa e do usuário',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),

          // Tabs alinhadas ao layout web (Figma)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TabBar(
              labelColor: TMTokens.primary,
              unselectedLabelColor: const Color(0xFF6B7280),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(
                  height: 44,
                  icon: Icon(Icons.apartment_outlined, size: 18),
                  text: 'Empresa',
                ),
                Tab(
                  height: 44,
                  icon: Icon(Icons.person_outline, size: 18),
                  text: 'Perfil',
                ),
                Tab(
                  height: 44,
                  icon: Icon(Icons.lock_outline, size: 18),
                  text: 'Segurança',
                ),
                Tab(
                  height: 44,
                  icon: Icon(Icons.integration_instructions_outlined, size: 18),
                  text: 'Integrações',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              children: [
                // Tab Empresa
                _buildEmpresaTab(empresa, temEmpresa),
                // Tab Perfil
                _buildPerfilTab(usuario),
                // Tabs adicionais (layout básico alinhado ao Figma)
                _buildSegurancaTab(),
                _buildIntegracoesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpresaTab(Map<String, dynamic>? empresa, bool temEmpresa) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _buildCard(
            icon: Icons.apartment,
            titulo: 'Informações da Empresa',
            subtitle: 'Dados cadastrais e identificação',
            children: [
              if (temEmpresa) ...[
                _buildInfoRow('Tipo', empresa?['type'] == 'CPF' ? 'Pessoa Física' : 'Pessoa Jurídica'),
                const Divider(height: 32),
                _buildInfoRow(
                  empresa?['type'] == 'CPF' ? 'CPF' : 'CNPJ',
                  _formatarDocumento(empresa?['document'] ?? ''),
                ),
                const Divider(height: 32),
                _buildInfoRow('Nome', empresa?['name'] ?? 'N/A'),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Deseja atualizar os dados da empresa? Edite os campos abaixo.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: const Text(
                          'Você ainda não tem uma empresa cadastrada. Configure agora para desbloquear todas as funcionalidades!',
                          style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de cadastro',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Pessoa Física (CPF)'),
                              selected: _empresaTipoSelecionado == 'CPF',
                              onSelected: (v) {
                                if (!v) return;
                                setState(() => _empresaTipoSelecionado = 'CPF');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Pessoa Jurídica (CNPJ)'),
                              selected: _empresaTipoSelecionado == 'CNPJ',
                              onSelected: (v) {
                                if (!v) return;
                                setState(() => _empresaTipoSelecionado = 'CNPJ');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      (_empresaTipoSelecionado ?? empresa?['type']) == 'CPF'
                          ? 'CPF'
                          : 'CNPJ',
                      _empresaDocumentoController,
                      hintText: (_empresaTipoSelecionado ?? empresa?['type']) == 'CPF'
                          ? 'Informe o CPF (somente números)'
                          : 'Informe o CNPJ (somente números)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                (_empresaTipoSelecionado ?? empresa?['type']) == 'CPF'
                    ? 'Nome Completo'
                    : 'Razão Social',
                _empresaNomeController,
                hintText: 'Nome da empresa ou pessoa',
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _salvandoEmpresa ? null : _salvarEmpresa,
                  icon: _salvandoEmpresa
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_salvandoEmpresa ? 'Salvando...' : 'Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Identidade visual
          _buildCard(
            icon: Icons.palette_outlined,
            titulo: 'Identidade Visual',
            subtitle: 'Personalize a aparência do sistema',
            children: [
              const Text(
                'Logo da Empresa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: const Icon(Icons.apartment, size: 36, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarMensagem('Upload de logo em breve'),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Upload de Logo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Cor Primária',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
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
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.colorize, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
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
                  onPressed: () => _mostrarMensagem('Identidade visual atualizada (somente visual)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Aplicar Alterações'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // LGPD & Privacidade
          _buildCard(
            icon: Icons.verified_user_outlined,
            titulo: 'LGPD & Privacidade',
            subtitle: 'Configurações de conformidade e retenção de dados',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Retenção automática de currículos',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manter currículos por até 90 dias após o processo seletivo',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _retencaoCurriculos,
                    onChanged: (v) => setState(() => _retencaoCurriculos = v),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anonimização de dados rejeitados',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Anonimizar dados de candidatos reprovados automaticamente',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _anonimizacaoDados,
                    onChanged: (v) => setState(() => _anonimizacaoDados = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                'Termo de Consentimento LGPD',
                _termoLgpdController,
                hintText:
                    'Digite o termo de consentimento que será exibido aos candidatos...',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _mostrarMensagem('Configurações de privacidade salvas (somente visual)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Configurações'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gerenciamento de usuários
          _buildCard(
            icon: Icons.group_outlined,
            titulo: 'Gerenciamento de Usuários',
            subtitle: 'Convide e gerencie membros da equipe',
            children: [
              if (empresa != null && _dadosUsuario?['user'] != null) ...[
                _buildUsuarioEquipeItem(
                  nome: _dadosUsuario!['user']['full_name'] ??
                      _dadosUsuario!['user']['nome'] ??
                      'Usuário',
                  email: _dadosUsuario!['user']['email'] ?? '',
                  papel: 'Admin',
                  iniciais: _iniciais(
                    _dadosUsuario!['user']['full_name'] ??
                        _dadosUsuario!['user']['nome'],
                  ),
                  isPrimary: true,
                ),
                const SizedBox(height: 12),
              ],
              ..._usuariosEquipeMock.map((u) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUsuarioEquipeItem(
                    nome: u['nome'] ?? '',
                    email: u['email'] ?? '',
                    papel: u['papel'] ?? 'Recrutador',
                    iniciais: u['iniciais'] ?? '',
                    isPrimary: false,
                  ),
                );
              }),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _mostrarMensagem('Convite de membro ainda não implementado'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('+ Convidar Membro'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilTab(Map<String, dynamic>? usuario) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildCard(
        icon: Icons.person_outline,
        titulo: 'Informações Pessoais',
        subtitle: 'Atualize seus dados pessoais',
        children: [
          // Avatar com foto ou iniciais
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: usuario?['foto_url'] != null
                    ? NetworkImage(usuario!['foto_url'])
                    : null,
                backgroundColor: TMTokens.primary.withValues(alpha: 0.12),
                child: usuario?['foto_url'] == null
                    ? Text(
                        _iniciais(usuario?['full_name'] ?? usuario?['nome']),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: TMTokens.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selecionarFoto,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Alterar Foto'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG ou GIF (max. 2MB)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Nome Completo',
                  _perfilNomeController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Email',
                  _perfilEmailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dropdown de Cargo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cargo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cargoSelecionado,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Selecione um cargo')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Recrutador(a)', child: Text('Recrutador(a)')),
                  DropdownMenuItem(value: 'Gestor(a)', child: Text('Gestor(a)')),
                ],
                onChanged: (valor) {
                  setState(() {
                    _cargoSelecionado = valor;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: TMTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Salvar Alterações'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegurancaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildCard(
        icon: Icons.lock_outline,
        titulo: 'Alterar Senha',
        subtitle: 'Mantenha sua conta segura',
        children: [
          _buildTextField(
            'Senha Atual',
            _senhaAtualController,
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Nova Senha',
            _novaSenhaController,
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Confirmar Nova Senha',
            _confirmarSenhaController,
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (_novaSenhaController.text != _confirmarSenhaController.text) {
                  _mostrarMensagem('As senhas não conferem', erro: true);
                } else {
                  _mostrarMensagem('Alteração de senha ainda não implementada');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TMTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Atualizar Senha'),
            ),
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
          _buildCard(
            icon: Icons.vpn_key_outlined,
            titulo: 'API Keys',
            subtitle: 'Tokens para integração com sistemas externos',
            children: [
              if (_carregandoApiKeys) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 12),
              ],
              if (!_carregandoApiKeys && _apiKeys.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    color: const Color(0xFFF9FAFB),
                  ),
                  child: const Text(
                    'Nenhuma API Key cadastrada para este tenant.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!_carregandoApiKeys && _apiKeys.isNotEmpty) ...[
                for (final key in _apiKeys) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (key['provider'] ?? 'API').toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (key['label'] ?? '').toString().isNotEmpty
                                    ? key['label'].toString()
                                    : 'Key cadastrada',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              if (key['token_preview'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  key['token_preview'].toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: key['is_active'] == false
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF22C55E),
                                ),
                                color: key['is_active'] == false
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFDCFCE7),
                              ),
                              child: Text(
                                key['is_active'] == false ? 'Inativa' : 'Ativa',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: key['is_active'] == false
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                              tooltip: 'Excluir API Key',
                              onPressed: () => _confirmarExcluirApiKey(key['id']?.toString()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
              OutlinedButton(
                onPressed: _mostrarDialogNovaApiKey,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('+ Adicionar Nova API Key'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            icon: Icons.code_outlined,
            titulo: 'GitHub Integration',
            subtitle: 'Analise repositórios dos candidatos automaticamente',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habilitar análise de GitHub',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Buscar repositórios e analisar contribuições',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _analiseGithubAtiva,
                    onChanged: (v) => setState(() => _analiseGithubAtiva = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'GitHub Token (opcional)',
                _githubTokenController,
                hintText: 'ghp_••••••••••••••••••••',
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () =>
                      _mostrarMensagem('Configuração de GitHub salva (somente visual)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Configuração'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            icon: Icons.webhook_outlined,
            titulo: 'Webhooks',
            subtitle: 'Receba notificações em seus sistemas',
            children: [
              _buildTextField(
                'URL do Webhook',
                _webhookUrlController,
                hintText: 'https://seu-sistema.com/webhook',
              ),
              const SizedBox(height: 16),
              const Text(
                'Eventos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              _buildWebhookToggle(
                'Novo candidato',
                _eventoWebhookNovo,
                (v) => setState(() => _eventoWebhookNovo = v),
              ),
              const SizedBox(height: 8),
              _buildWebhookToggle(
                'Análise concluída',
                _eventoWebhookAnalise,
                (v) => setState(() => _eventoWebhookAnalise = v),
              ),
              const SizedBox(height: 8),
              _buildWebhookToggle(
                'Entrevista agendada',
                _eventoWebhookEntrevista,
                (v) => setState(() => _eventoWebhookEntrevista = v),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () =>
                      _mostrarMensagem('Configuração de webhook salva (somente visual)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TMTokens.primary,
                    foregroundColor: Colors.white,
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

  Widget _buildCard({
    required IconData icon,
    required String titulo,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: TMTokens.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildWebhookToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  Widget _buildUsuarioEquipeItem({
    required String nome,
    required String email,
    required String papel,
    required String iniciais,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: TMTokens.primary.withValues(alpha: 0.12),
                child: Text(
                  iniciais,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: TMTokens.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isPrimary ? const Color(0xFF4338CA) : const Color(0xFFE5E7EB),
              ),
              color: isPrimary ? const Color(0xFFE0E7FF) : Colors.white,
            ),
            child: Text(
              papel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary ? const Color(0xFF4338CA) : const Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogNovaApiKey() async {
    final labelController = TextEditingController();
    final tokenController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova API Key'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informe a chave da API para integrar serviços externos, como OpenAI.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    hintText: 'Ex.: OpenAI produção',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tokenController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Ex.: sk-...',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final token = tokenController.text.trim();
                if (token.isEmpty) {
                  _mostrarMensagem('API Key é obrigatória', erro: true);
                  return;
                }
                Navigator.of(context).pop({
                  'label': labelController.text.trim(),
                  'token': token,
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    labelController.dispose();
    tokenController.dispose();

    if (result == null) return;

    try {
      await widget.api.criarApiKey(
        provider: 'OPENAI',
        token: result['token']!,
        label: result['label']?.isNotEmpty == true ? result['label'] : null,
      );
      _mostrarMensagem('API Key cadastrada com sucesso!');
      await _carregarApiKeys();
    } catch (e) {
      _mostrarMensagem('Erro ao cadastrar API Key: $e', erro: true);
    }
  }

  Future<void> _confirmarExcluirApiKey(String? id) async {
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir API Key'),
          content: const Text(
            'Tem certeza que deseja excluir esta API Key? '
            'Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await widget.api.deletarApiKey(id);
      _mostrarMensagem('API Key excluída com sucesso!');
      await _carregarApiKeys();
    } catch (e) {
      _mostrarMensagem('Erro ao excluir API Key: $e', erro: true);
    }
  }
}
