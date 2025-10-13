import 'package:flutter/material.dart';
import '../componentes/widgets.dart';

class VagasTela extends StatefulWidget {
  final VoidCallback? onNovaVaga;
  const VagasTela({super.key, this.onNovaVaga});

  @override
  State<VagasTela> createState() => _VagasTelaState();
}

class _VagasTelaState extends State<VagasTela> {
  String _filtroStatus = 'todas';
  String _buscaTexto = '';

  // Dados mockados de vagas
  final List<Map<String, dynamic>> _vagas = [
    {
      'id': '1',
      'titulo': 'Desenvolvedor Full Stack',
      'descricao': 'Desenvolver e manter aplicações web usando React, Node.js e PostgreSQL. Experiência com APIs RESTful.',
      'requisitos': 'React, Node.js, PostgreSQL, 3+ anos',
      'status': 'aberta',
      'nivel': 'Pleno',
      'tecnologias': 'React, Node.js, PostgreSQL, Docker',
      'candidatos': 25,
    },
    {
      'id': '2',
      'titulo': 'UX/UI Designer',
      'descricao': 'Criar interfaces intuitivas e experiências de usuário excepcionais. Trabalhar com Figma e prototipação.',
      'requisitos': 'Figma, Adobe XD, Portfólio, 2+ anos',
      'status': 'aberta',
      'nivel': 'Pleno',
      'tecnologias': 'Figma, Adobe XD, Sketch',
      'candidatos': 18,
    },
    {
      'id': '3',
      'titulo': 'DevOps Engineer',
      'descricao': 'Gerenciar infraestrutura cloud, CI/CD pipelines e automação de processos.',
      'requisitos': 'AWS, Docker, Kubernetes, Jenkins, 4+ anos',
      'status': 'aberta',
      'nivel': 'Senior',
      'tecnologias': 'AWS, Docker, Kubernetes, Terraform',
      'candidatos': 12,
    },
    {
      'id': '4',
      'titulo': 'Data Scientist',
      'descricao': 'Analisar dados, criar modelos de ML e gerar insights para tomada de decisão.',
      'requisitos': 'Python, Pandas, Scikit-learn, SQL, 3+ anos',
      'status': 'pausada',
      'nivel': 'Pleno',
      'tecnologias': 'Python, TensorFlow, Pandas, SQL',
      'candidatos': 8,
    },
    {
      'id': '5',
      'titulo': 'Product Manager',
      'descricao': 'Liderar roadmap de produto, definir prioridades e trabalhar com times multidisciplinares.',
      'requisitos': 'Gestão de produtos, Agile, 5+ anos',
      'status': 'aberta',
      'nivel': 'Senior',
      'tecnologias': 'Jira, Miro, Analytics',
      'candidatos': 15,
    },
    {
      'id': '6',
      'titulo': 'Desenvolvedor Mobile Flutter',
      'descricao': 'Desenvolver aplicativos móveis multiplataforma com Flutter e Dart.',
      'requisitos': 'Flutter, Dart, Firebase, 2+ anos',
      'status': 'fechada',
      'nivel': 'Pleno',
      'tecnologias': 'Flutter, Dart, Firebase, REST API',
      'candidatos': 30,
    },
  ];

  List<Map<String, dynamic>> get _vagasFiltradas {
    return _vagas.where((vaga) {
      final matchStatus = _filtroStatus == 'todas' || vaga['status'] == _filtroStatus;
      final matchBusca = _buscaTexto.isEmpty ||
          (vaga['titulo'] as String).toLowerCase().contains(_buscaTexto.toLowerCase()) ||
          (vaga['descricao'] as String).toLowerCase().contains(_buscaTexto.toLowerCase());
      return matchStatus && matchBusca;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerenciamento de Vagas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                ),
                SizedBox(height: 4),
                Text(
                  'Crie e gerencie as vagas abertas',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onNovaVaga != null) widget.onNovaVaga!();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova Vaga'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filtros
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                onChanged: (value) => setState(() => _buscaTexto = value),
                decoration: InputDecoration(
                  hintText: 'Buscar vagas...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _filtroStatus,
              items: const [
                DropdownMenuItem(value: 'todas', child: Text('Todas')),
                DropdownMenuItem(value: 'aberta', child: Text('Abertas')),
                DropdownMenuItem(value: 'pausada', child: Text('Pausadas')),
                DropdownMenuItem(value: 'fechada', child: Text('Fechadas')),
              ],
              onChanged: (value) => setState(() => _filtroStatus = value!),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Contador de resultados
        Text(
          '${_vagasFiltradas.length} vagas encontradas',
          style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),

        // Lista de vagas
        Expanded(
          child: ListView.builder(
            itemCount: _vagasFiltradas.length,
            itemBuilder: (context, i) {
              final vaga = _vagasFiltradas[i];
              return CardVaga(
                titulo: vaga['titulo'] as String,
                descricao: vaga['descricao'] as String,
                status: vaga['status'] as String,
                nivel: vaga['nivel'] as String?,
                onTap: () {
                  _mostrarDetalhesVaga(vaga);
                },
                onEditar: () {
                  // Editar vaga
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Editar: ${vaga['titulo']}')),
                  );
                },
                onExcluir: () {
                  _confirmarExclusao(vaga);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDetalhesVaga(Map<String, dynamic> vaga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaga['titulo'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Status', vaga['status'] as String),
              _buildInfoRow('Nível', vaga['nivel'] as String),
              _buildInfoRow('Candidatos', '${vaga['candidatos']}'),
              const SizedBox(height: 12),
              const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(vaga['descricao'] as String),
              const SizedBox(height: 12),
              const Text('Requisitos:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(vaga['requisitos'] as String),
              const SizedBox(height: 12),
              const Text('Tecnologias:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (vaga['tecnologias'] as String)
                    .split(', ')
                    .map((tech) => Chip(label: Text(tech), backgroundColor: Colors.indigo.shade50))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Ver candidatos
            },
            child: const Text('Ver Candidatos'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  void _confirmarExclusao(Map<String, dynamic> vaga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a vaga "${vaga['titulo']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _vagas.removeWhere((v) => v['id'] == vaga['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vaga excluída com sucesso')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
