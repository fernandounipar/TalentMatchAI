import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

class HistoricoTela extends StatefulWidget {
  final ApiCliente api;
  const HistoricoTela({super.key, required this.api});

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela> {
  static const List<Map<String, dynamic>> _mockHistorico = [
    {
      'id': '1',
      'candidato': 'João Silva',
      'vaga': 'Desenvolvedor Full Stack',
      'criado_em': '2024-06-10T14:32:00Z',
      'tem_relatorio': true,
    },
    {
      'id': '2',
      'candidato': 'Maria Souza',
      'vaga': 'UX/UI Designer',
      'criado_em': '2024-06-09T10:15:00Z',
      'tem_relatorio': false,
    },
    {
      'id': '3',
      'candidato': 'Carlos Lima',
      'vaga': 'DevOps Engineer',
      'criado_em': '2024-06-05T18:45:00Z',
      'tem_relatorio': true,
    },
    {
      'id': '4',
      'candidato': 'Ana Paula',
      'vaga': 'Product Manager',
      'criado_em': '2024-05-30T09:00:00Z',
      'tem_relatorio': false,
    },
  ];

  List<dynamic>? _itens;
  bool _carregando = false;

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    List<dynamic> itens;
    try {
      itens = await widget.api.historico();
    } catch (_) {
      itens = _mockHistorico;
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
      appBar: AppBar(title: const Text('Histórico de Entrevistas')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _itens?.length ?? 0,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = _itens![i];
                final dt = DateTime.tryParse(e['criado_em']?.toString() ?? '') ?? DateTime.now();
                return ListTile(
                  title: Text('${e['candidato'] ?? ''} — ${e['vaga'] ?? ''}'),
                  subtitle: Text(dt.toLocal().toString()),
                  trailing: e['tem_relatorio'] == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.timelapse, color: Colors.amber),
                );
              },
            ),
    );
  }
}

