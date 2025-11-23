import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

class UsuariosAdminTela extends StatefulWidget {
  final ApiCliente api;
  final bool isAdmin;
  const UsuariosAdminTela({super.key, required this.api, required this.isAdmin});

  @override
  State<UsuariosAdminTela> createState() => _UsuariosAdminTelaState();
}

class _UsuariosAdminTelaState extends State<UsuariosAdminTela> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String _perfil = 'USER';
  String _tipo = 'CNPJ';
  final _documento = TextEditingController();
  final _empresa = TextEditingController();
  bool _loading = false;
  
  // Listagem de usuários
  List<Map<String, dynamic>> _usuarios = [];
  bool _carregandoLista = false;
  String? _erroLista;
  int _paginaAtual = 1;
  final int _limiteporPagina = 20;
  int _totalPaginas = 1;
  String? _buscaTexto;
  String? _filtroRole;
  String? _filtroStatus;
  
  // Modo de visualização: 'lista' ou 'criar'
  String _modo = 'lista';
  
  // Edição de usuário
  String? _usuarioEditandoId;
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _jobTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _carregarUsuarios();
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _documento.dispose();
    _empresa.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }
  
  Future<void> _carregarUsuarios() async {
    setState(() {
      _carregandoLista = true;
      _erroLista = null;
    });
    
    try {
      final resultado = await widget.api.listarUsuarios(
        page: _paginaAtual,
        limit: _limiteporPagina,
        search: _buscaTexto,
        role: _filtroRole,
        status: _filtroStatus,
      );
      
      if (!mounted) return;
      
      final meta = resultado['meta'] ?? {};
      setState(() {
        _usuarios = (resultado['data'] as List).cast<Map<String, dynamic>>();
        _totalPaginas = meta['pages'] ?? 1;
        _carregandoLista = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoLista = false;
        _erroLista = _extrairMensagemErro(e.toString());
      });
    }
  }
  
  String _extrairMensagemErro(String erro) {
    // Extrai mensagem amigável dos códigos de erro do backend
    if (erro.contains('EMAIL_EXISTS')) {
      return 'Este email já está cadastrado no sistema';
    } else if (erro.contains('INVALID_ROLE')) {
      return 'Perfil de usuário inválido';
    } else if (erro.contains('USER_NOT_FOUND')) {
      return 'Usuário não encontrado';
    } else if (erro.contains('CANNOT_DELETE_SELF')) {
      return 'Você não pode excluir sua própria conta';
    } else if (erro.contains('MISSING_FIELDS')) {
      return 'Preencha todos os campos obrigatórios';
    } else if (erro.contains('INVALID_DOCUMENT')) {
      return 'Documento informado é inválido';
    } else if (erro.contains('NO_FIELDS')) {
      return 'Nenhuma alteração foi feita';
    } else if (erro.contains('INVALID_TOKEN')) {
      return 'Convite inválido ou expirado. Solicite um novo convite';
    }
    return 'Ocorreu um erro. Tente novamente mais tarde.';
  }

  Future<void> _criar() async {
    setState(() => _loading = true);
    try {
      final company = (_documento.text.trim().isEmpty)
          ? null
          : {
              'type': _tipo,
              'document': _documento.text.trim(),
              'name': _empresa.text.trim().isEmpty ? null : _empresa.text.trim(),
            };
      final u = await widget.api.criarUsuario(
        fullName: _nome.text.trim(),
        email: _email.text.trim(),
        role: _perfil,
        password: _senha.text.trim().isEmpty ? null : _senha.text.trim(),
        company: company,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário criado: ${u['email']}'),
          backgroundColor: Colors.green,
        ),
      );
      _nome.clear();
      _email.clear();
      _senha.clear();
      setState(() => _perfil = 'USER');
      _documento.clear();
      _empresa.clear();
      _modo = 'lista';
      _carregarUsuarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extrairMensagemErro(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  Future<void> _deletarUsuario(String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o usuário "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (confirmar != true) return;
    
    try {
      await widget.api.deletarUsuario(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
      _carregarUsuarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extrairMensagemErro(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _editarUsuario(Map<String, dynamic> usuario) {
    setState(() {
      _usuarioEditandoId = usuario['id'];
      _nome.text = usuario['full_name'] ?? '';
      _email.text = usuario['email'] ?? '';
      _perfil = usuario['role'] ?? 'USER';
      _phoneController.text = usuario['phone'] ?? '';
      _departmentController.text = usuario['department'] ?? '';
      _jobTitleController.text = usuario['job_title'] ?? '';
      _modo = 'editar';
    });
  }
  
  Future<void> _salvarEdicao() async {
    if (_usuarioEditandoId == null) return;
    
    setState(() => _loading = true);
    try {
      await widget.api.atualizarUsuario(
        _usuarioEditandoId!,
        fullName: _nome.text.trim(),
        email: _email.text.trim(),
        role: _perfil,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário atualizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
      _cancelarEdicao();
      _carregarUsuarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extrairMensagemErro(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _cancelarEdicao() {
    setState(() {
      _usuarioEditandoId = null;
      _nome.clear();
      _email.clear();
      _senha.clear();
      _perfil = 'USER';
      _phoneController.clear();
      _departmentController.clear();
      _jobTitleController.clear();
      _modo = 'lista';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 40, color: Colors.redAccent),
                SizedBox(height: 12),
                Text('Apenas administradores podem gerenciar usuários'),
              ],
            ),
          ),
        ),
      );
    }

    if (_modo == 'criar' || _modo == 'editar') {
      return _buildFormulario();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gerenciar Usuários', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                    SizedBox(height: 4),
                    Text('Gerencie os usuários do sistema (USER, RECRUITER, ADMIN, SUPER_ADMIN)', style: TextStyle(color: Colors.black54)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _modo = 'criar'),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Novo Usuário'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3730A3)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Filtros
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar',
                          hintText: 'Nome ou email...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (valor) {
                          setState(() => _buscaTexto = valor.trim().isEmpty ? null : valor.trim());
                          _carregarUsuarios();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        initialValue: _filtroRole,
                        decoration: const InputDecoration(
                          labelText: 'Perfil',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'USER', child: Text('User')),
                          DropdownMenuItem(value: 'RECRUITER', child: Text('Recruiter')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                          DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
                        ],
                        onChanged: (v) {
                          setState(() => _filtroRole = v);
                          _carregarUsuarios();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        initialValue: _filtroStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'active', child: Text('Ativo')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inativo')),
                        ],
                        onChanged: (v) {
                          setState(() => _filtroStatus = v);
                          _carregarUsuarios();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de usuários
            if (_carregandoLista)
              const Center(child: CircularProgressIndicator())
            else if (_erroLista != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_erroLista!, style: const TextStyle(color: Colors.red))),
                      TextButton(
                        onPressed: _carregarUsuarios,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_usuarios.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Nenhum usuário encontrado'),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Perfil')),
                      DataColumn(label: Text('Departamento')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Ações')),
                    ],
                    rows: _usuarios.map((u) {
                      final isActive = u['is_active'] ?? true;
                      return DataRow(cells: [
                        DataCell(Text(u['full_name'] ?? '-')),
                        DataCell(Text(u['email'] ?? '-')),
                        DataCell(_buildRoleChip(u['role'] ?? 'USER')),
                        DataCell(Text(u['department'] ?? '-')),
                        DataCell(
                          Chip(
                            label: Text(isActive ? 'Ativo' : 'Inativo'),
                            backgroundColor: isActive ? Colors.green.shade50 : Colors.grey.shade300,
                            labelStyle: TextStyle(
                              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editarUsuario(u),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _deletarUsuario(u['id'], u['full_name'] ?? u['email']),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            
            // Paginação
            if (!_carregandoLista && _usuarios.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _paginaAtual > 1
                        ? () {
                            setState(() => _paginaAtual--);
                            _carregarUsuarios();
                          }
                        : null,
                  ),
                  Text('Página $_paginaAtual de $_totalPaginas'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _paginaAtual < _totalPaginas
                        ? () {
                            setState(() => _paginaAtual++);
                            _carregarUsuarios();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRoleChip(String role) {
    MaterialColor cor;
    String label;
    
    switch (role) {
      case 'SUPER_ADMIN':
        cor = Colors.purple;
        label = 'Super Admin';
        break;
      case 'ADMIN':
        cor = Colors.indigo;
        label = 'Admin';
        break;
      case 'RECRUITER':
        cor = Colors.blue;
        label = 'Recruiter';
        break;
      default:
        cor = Colors.grey;
        label = 'User';
    }
    
    return Chip(
      label: Text(label),
      backgroundColor: cor.shade50,
      labelStyle: TextStyle(color: cor.shade700, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
  
  Widget _buildFormulario() {
    final isEdicao = _modo == 'editar';
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _cancelarEdicao,
                ),
                const SizedBox(width: 8),
                Text(
                  isEdicao ? 'Editar Usuário' : 'Novo Usuário',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nome Completo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _nome, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    
                    const Text('E-mail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _email, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    
                    const Text('Perfil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _perfil,
                      items: const [
                        DropdownMenuItem(value: 'USER', child: Text('User')),
                        DropdownMenuItem(value: 'RECRUITER', child: Text('Recruiter')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                        DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
                      ],
                      onChanged: (v) => setState(() => _perfil = v ?? 'USER'),
                    ),
                    const SizedBox(height: 12),
                    
                    const Text('Telefone (opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _phoneController, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    
                    const Text('Departamento (opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _departmentController, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    
                    const Text('Cargo (opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _jobTitleController, decoration: const InputDecoration(border: OutlineInputBorder())),
                    
                    if (!isEdicao) ...[
                      const SizedBox(height: 12),
                      const Text('Senha (opcional - se não informado, usuário deve aceitar convite)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _senha,
                        obscureText: true,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('Vincular/Criar Empresa (opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      
                      const Text('Tipo de documento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _tipo,
                        items: const [
                          DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                          DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ')),
                        ],
                        onChanged: (v) => setState(() => _tipo = v ?? 'CNPJ'),
                      ),
                      const SizedBox(height: 12),
                      
                      const Text('CPF/CNPJ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: _documento, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Somente números')),
                      const SizedBox(height: 12),
                      
                      const Text('Nome da Empresa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: _empresa, decoration: const InputDecoration(border: OutlineInputBorder())),
                    ],
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _cancelarEdicao,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : (isEdicao ? _salvarEdicao : _criar),
                          icon: Icon(isEdicao ? Icons.save : Icons.person_add_alt_1),
                          label: Text(_loading ? 'Salvando...' : (isEdicao ? 'Salvar' : 'Criar Usuário')),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3730A3)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
