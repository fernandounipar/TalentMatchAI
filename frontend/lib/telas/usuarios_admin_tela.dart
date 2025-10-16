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
  String _perfil = 'RECRUTADOR';
  String _tipo = 'CNPJ';
  final _documento = TextEditingController();
  final _empresa = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _documento.dispose();
    _empresa.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    setState(() => _loading = true);
    try {
      final company = (_documento.text.trim().isEmpty)
          ? null
          : {
              'tipo': _tipo,
              'documento': _documento.text.trim(),
              'nome': _empresa.text.trim().isEmpty ? null : _empresa.text.trim(),
            };
      final u = await widget.api.criarUsuario(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
        perfil: _perfil,
        company: company,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuário criado: ${u['email']}')));
      _nome.clear();
      _email.clear();
      _senha.clear();
      setState(() => _perfil = 'RECRUTADOR');
      _documento.clear();
      _empresa.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 40, color: Colors.redAccent),
                SizedBox(height: 12),
                Text('Apenas administradores podem gerenciar usuários'),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gerenciar Usuários', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
            const SizedBox(height: 8),
            const Text('Crie novos usuários do sistema (ADMIN, GESTOR, RECRUTADOR).', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Novo Usuário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    const Text('Nome', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _nome, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const Text('E-mail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _email, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const Text('Senha', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const Text('Tipo de documento da empresa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      items: const [
                        DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                        DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ')),
                      ],
                      onChanged: (v) => setState(() => _tipo = v ?? 'CNPJ'),
                    ),
                    const SizedBox(height: 12),
                    const Text('CPF/CNPJ (opcional para criar/vincular empresa)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _documento, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Somente números')), 
                    const SizedBox(height: 12),
                    const Text('Nome da Empresa (opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(controller: _empresa, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    const Text('Perfil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _perfil,
                      items: const [
                        DropdownMenuItem(value: 'RECRUTADOR', child: Text('Recrutador')),
                        DropdownMenuItem(value: 'GESTOR', child: Text('Gestor')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() => _perfil = v ?? 'RECRUTADOR'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _criar,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(_loading ? 'Criando...' : 'Criar Usuário'),
                      ),
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
