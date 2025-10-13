import 'package:flutter/material.dart';
import '../servicos/api_cliente.dart';

class HistoricoTela extends StatefulWidget {
  final ApiCliente api;
  const HistoricoTela({super.key, required this.api});

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela> {
  List<dynamic>? _itens;
  bool _carregando = false;

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    _itens = await widget.api.historico();
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

