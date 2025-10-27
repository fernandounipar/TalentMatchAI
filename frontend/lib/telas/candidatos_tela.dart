import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

class CandidatosTela extends StatefulWidget {
  final ApiCliente api;
  const CandidatosTela({super.key, required this.api});

  @override
  State<CandidatosTela> createState() => _CandidatosTelaState();
}

class _CandidatosTelaState extends State<CandidatosTela> {
  static const List<Map<String, dynamic>> _mockCandidatos = [
    {
      'id': '1',
      'nome': 'João Silva',
      'email': 'joao.silva@talentmatch.com',
      'qtd_curriculos': 3,
      'qtd_entrevistas': 1,
    },
    {
      'id': '2',
      'nome': 'Maria Souza',
      'email': 'maria.souza@talentmatch.com',
      'qtd_curriculos': 2,
      'qtd_entrevistas': 2,
    },
    {
      'id': '3',
      'nome': 'Carlos Lima',
      'email': 'carlos.lima@talentmatch.com',
      'qtd_curriculos': 1,
      'qtd_entrevistas': 0,
    },
    {
      'id': '4',
      'nome': 'Ana Paula',
      'email': 'ana.paula@talentmatch.com',
      'qtd_curriculos': 4,
      'qtd_entrevistas': 3,
    },
  ];

  List<dynamic>? _itens;
  bool _carregando = false;

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    List<dynamic> itens;
    try {
      itens = await widget.api.candidatos();
    } catch (_) {
      itens = _mockCandidatos;
    }
    if (!mounted) return;
    setState(() {
      _itens = itens;
      _carregando = false;
    });
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

