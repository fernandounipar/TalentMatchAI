import 'package:flutter/material.dart';
import '../componentes/widgets.dart';

/// Tela de Upload de Currículo
class UploadCurriculoTela extends StatefulWidget {
  final String curriculoNome;
  final void Function(String) onFile;
  final VoidCallback onBack;

  const UploadCurriculoTela({
    super.key,
    required this.curriculoNome,
    required this.onFile,
    required this.onBack,
  });

  @override
  State<UploadCurriculoTela> createState() => _UploadCurriculoTelaState();
}

class _UploadCurriculoTelaState extends State<UploadCurriculoTela> {
  String? _arquivoSelecionado;
  String _vagaSelecionada = 'Desenvolvedor Full Stack';
  
  final List<String> _vagas = [
    'Desenvolvedor Full Stack',
    'UX/UI Designer',
    'DevOps Engineer',
    'Data Scientist',
    'Product Manager',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botão Voltar
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Voltar'),
        ),
        const SizedBox(height: 8),

        // Título
        const Text(
          'Upload de Currículo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Envie o currículo do candidato para análise com IA',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),

        // Card de Upload
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seleção de Vaga
                const Text('Selecione a vaga:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _vagaSelecionada,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: _vagas.map((vaga) => DropdownMenuItem(value: vaga, child: Text(vaga))).toList(),
                  onChanged: (value) => setState(() => _vagaSelecionada = value!),
                ),
                const SizedBox(height: 24),

                // Área de Upload
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.indigo.shade200, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.indigo.shade50.withOpacity(0.3),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.indigo.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Arraste o arquivo ou clique para selecionar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Formatos aceitos: PDF, DOCX, TXT (máx. 10MB)',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Simular seleção de arquivo
                          setState(() {
                            _arquivoSelecionado = 'curriculo_joao_silva.pdf';
                          });
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Selecionar Arquivo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      if (_arquivoSelecionado != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _arquivoSelecionado!,
                                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _arquivoSelecionado = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Informações adicionais
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'A IA analisará o currículo e identificará competências, experiências e compatibilidade com a vaga.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Botões de Ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    BotaoPrimario(
                      texto: 'Analisar com IA',
                      icone: Icons.psychology,
                      onPressed: _arquivoSelecionado != null
                          ? () => widget.onFile(_arquivoSelecionado!)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
