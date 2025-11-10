import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/tm_tokens.dart';
import '../servicos/api_cliente.dart';

/// Tela de Configurações com dados reais do backend
class ConfiguracoesNovaTela extends StatefulWidget {
  final ApiCliente api;

  const ConfiguracoesNovaTela({
    super.key,
    required this.api,
  });

  @override
  State<ConfiguracoesNovaTela> createState() => _ConfiguracoesNovaTelaState();
}

class _ConfiguracoesNovaTelaState extends State<ConfiguracoesNovaTela> {
  bool _carregando = true;
  Map<String, dynamic>? _dadosUsuario;
  String? _erro;

  // Controladores para empresa
  late final TextEditingController _empresaTipoController;
  late final TextEditingController _empresaDocumentoController;
  late final TextEditingController _empresaNomeController;
  bool _salvandoEmpresa = false;

  @override
  void initState() {
    super.initState();
    _empresaTipoController = TextEditingController();
    _empresaDocumentoController = TextEditingController();
    _empresaNomeController = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _empresaTipoController.dispose();
    _empresaDocumentoController.dispose();
    _empresaNomeController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await widget.api.obterUsuario();
      setState(() {
        _dadosUsuario = dados;
        _carregando = false;

        // Se tem empresa, preenche os campos
        if (dados['company'] != null) {
          final empresa = dados['company'] as Map<String, dynamic>;
          _empresaTipoController.text = empresa['type'] ?? '';
          _empresaDocumentoController.text = empresa['document'] ?? '';
          _empresaNomeController.text = empresa['name'] ?? '';
        }
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar dados: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _salvarEmpresa() async {
    final tipo = _empresaTipoController.text.trim().toUpperCase();
    final documento = _empresaDocumentoController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    final nome = _empresaNomeController.text.trim();

    // Validações
    if (tipo.isEmpty || (tipo != 'CPF' && tipo != 'CNPJ')) {
      _mostrarMensagem('Tipo deve ser CPF ou CNPJ', erro: true);
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
    } catch (e) {
      _mostrarMensagem('Erro ao salvar empresa: $e', erro: true);
    } finally {
      setState(() => _salvandoEmpresa = false);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Configurações',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gerencie as configurações da empresa e do usuário',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),

        // Tab Bar
        DefaultTabController(
          length: 2,
          child: Expanded(
            child: Column(
              children: [
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
                    tabs: const [
                      Tab(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apartment_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Empresa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Tab(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Perfil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab Empresa
                      _buildEmpresaTab(empresa, temEmpresa),
                      // Tab Perfil
                      _buildPerfilTab(usuario),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                    child: _buildTextField(
                      'Tipo',
                      _empresaTipoController,
                      hintText: 'CPF ou CNPJ',
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(text: newValue.text.toUpperCase());
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      empresa?['type'] == 'CPF' ? 'CPF' : 'CNPJ / Documento',
                      _empresaDocumentoController,
                      hintText: 'Somente números',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                empresa?['type'] == 'CPF' ? 'Nome Completo' : 'Razão Social',
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
        subtitle: 'Dados do usuário logado',
        children: [
          _buildInfoRow('Nome Completo', usuario?['full_name'] ?? 'N/A'),
          const Divider(height: 32),
          _buildInfoRow('Email', usuario?['email'] ?? 'N/A'),
          const Divider(height: 32),
          _buildInfoRow('Perfil', _formatarRole(usuario?['role'])),
          const Divider(height: 32),
          _buildInfoRow(
            'Status',
            usuario?['is_active'] == true ? 'Ativo' : 'Inativo',
            valueColor: usuario?['is_active'] == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
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

  String _formatarRole(String? role) {
    if (role == null) return 'N/A';
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'SUPER_ADMIN':
        return 'Super Administrador';
      case 'USER':
      default:
        return 'Usuário';
    }
  }
}
