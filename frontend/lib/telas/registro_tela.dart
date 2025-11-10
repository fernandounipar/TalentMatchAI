import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

class RegistroTela extends StatefulWidget {
  final ApiCliente api;
  final VoidCallback onCancel;
  final void Function(Map<String, dynamic> resp) onSuccess;

  const RegistroTela({
    super.key,
    required this.api,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<RegistroTela> createState() => _RegistroTelaState();
}

class _RegistroTelaState extends State<RegistroTela> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCompleto = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nomeCompleto.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final resp = await widget.api.registrar(
        nomeCompleto: _nomeCompleto.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
      );
      if (!mounted) return;
      widget.onSuccess(resp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no cadastro: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onCancel),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Criar sua conta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Preencha os dados abaixo para começar', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeCompleto,
                        decoration: const InputDecoration(
                          labelText: 'Nome de usuário',
                          hintText: 'Como você gostaria de ser chamado',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Seu email',
                          hintText: 'seu@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Informe um email válido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senha,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Mínimo 6 caracteres',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Senha deve ter no mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: _loading ? null : widget.onCancel, child: const Text('Cancelar')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            child: Text(_loading ? 'Criando...' : 'Criar conta'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

