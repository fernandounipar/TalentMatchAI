import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

class CandidatosTela extends StatefulWidget {
  final ApiCliente api;
  const CandidatosTela({super.key, required this.api});

  @override
  State<CandidatosTela> createState() => _CandidatosTelaState();
}

class _CandidatosTelaState extends State<CandidatosTela> {
  List<dynamic>? _itens;
  bool _carregando = false;

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    _itens = await widget.api.candidatos();
    setState(() => _carregando = false);
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _itens?.length ?? 0,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = _itens![i];
                return ListTile(
                  title: Text(c['nome'] ?? ''),
                  subtitle: Text(c['email'] ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Chip(label: Text('CV: ${c['qtd_curriculos'] ?? 0}')),
                    const SizedBox(width: 6),
                    Chip(label: Text('Ent.: ${c['qtd_entrevistas'] ?? 0}')),
                  ]),
                );
              },
            ),
    );
  }
}

