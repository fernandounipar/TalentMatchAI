import 'package:flutter/material.dart';

// ============== Card de Estatística (Dashboard Stats) ==============
class CardEstatistica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? subtitulo;
  final IconData? icone;
  final Color? cor;

  const CardEstatistica({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    this.icone,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                if (icone != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (cor ?? Colors.indigo).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icone, size: 18, color: cor ?? Colors.indigo),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (subtitulo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FF),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subtitulo!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============== Row de Vaga (Tabela) ==============
class RowVaga extends StatelessWidget {
  final String titulo;
  final int candidatos;
  final String status;
  final String data;
  final VoidCallback? onDetalhes;

  const RowVaga({
    super.key,
    required this.titulo,
    required this.candidatos,
    required this.status,
    required this.data,
    this.onDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetalhes,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$candidatos',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                data,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: onDetalhes,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Detalhes', style: TextStyle(fontSize: 13)),
                    Icon(Icons.chevron_right, size: 16),
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

// ============== Card de Entrevista ==============
class CardEntrevista extends StatelessWidget {
  final String nome;
  final String cargo;
  final String status;
  final String tipo;
  final VoidCallback? onAbrir;

  const CardEntrevista({
    super.key,
    required this.nome,
    required this.cargo,
    required this.status,
    required this.tipo,
    this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cargo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildIcon(tipo),
              const SizedBox(width: 6),
              Text(
                status,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAbrir,
                child: const Row(
                  children: [
                    Text('Abrir', style: TextStyle(fontSize: 13)),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(String tipo) {
    IconData icon;
    Color color;
    switch (tipo) {
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green[600]!;
        break;
      case 'progress':
        icon = Icons.warning_amber;
        color = Colors.amber[600]!;
        break;
      default:
        icon = Icons.description;
        color = Colors.grey[500]!;
    }
    return Icon(icon, size: 16, color: color);
  }
}

// ============== Card de Vaga (lista) ==============
class CardVaga extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String status;
  final String? nivel;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;

  const CardVaga({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.status,
    this.nivel,
    this.onTap,
    this.onEditar,
    this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (nivel != null)
                Text('Nível: $nivel', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(
                descricao,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(onPressed: onEditar, icon: const Icon(Icons.edit, size: 16), label: const Text('Editar')),
                  const SizedBox(width: 8),
                  TextButton.icon(onPressed: onExcluir, icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== Card de Relatório ==============
class CardRelatorio extends StatelessWidget {
  final String titulo;
  final String data;
  final String status;
  final VoidCallback? onVer;

  const CardRelatorio({
    super.key,
    required this.titulo,
    required this.data,
    required this.status,
    this.onVer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onVer,
            child: const Row(
              children: [
                Text('Ver', style: TextStyle(fontSize: 13)),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Card de Insight (IA) ==============
class CardInsight extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;

  const CardInsight({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icone,
              size: 16,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Item de Candidato ==============
class ItemCandidato extends StatelessWidget {
  final String nome;
  final String cargo;
  final int score;

  const ItemCandidato({
    super.key,
    required this.nome,
    required this.cargo,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cargo,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              border: Border.all(color: const Color(0xFFE0E7FF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Score $score%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Item de Histórico ==============
class ItemHistorico extends StatelessWidget {
  final String titulo;
  final String data;
  final String status;

  const ItemHistorico({
    super.key,
    required this.titulo,
    required this.data,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== Card de Score ==============
class CardScore extends StatelessWidget {
  final String titulo;
  final String valor;

  const CardScore({
    super.key,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== Bolha de Chat ==============
class BolhaChat extends StatelessWidget {
  final String quem;
  final String texto;

  const BolhaChat({
    super.key,
    required this.quem,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    final isIA = quem == "IA";
    return Align(
      alignment: isIA ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isIA ? Colors.white : const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 14,
            color: isIA ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============== Badge de Pontuação ==============
class BadgePontuacao extends StatelessWidget {
  final num pontuacao;
  final double tamanho;

  const BadgePontuacao({
    super.key,
    required this.pontuacao,
    this.tamanho = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _coresGradiente(pontuacao),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _coresGradiente(pontuacao)[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$pontuacao%',
          style: TextStyle(
            color: Colors.white,
            fontSize: tamanho * 0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Color> _coresGradiente(num pontuacao) {
    if (pontuacao >= 80) {
      return [Colors.green, Colors.lightGreen];
    } else if (pontuacao >= 60) {
      return [Colors.orange, Colors.amber];
    } else {
      return [Colors.red, Colors.deepOrange];
    }
  }
}

// ============== Botão Primário ==============
class BotaoPrimario extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? icone;

  const BotaoPrimario({
    super.key,
    required this.texto,
    this.onPressed,
    this.carregando = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: carregando ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: carregando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(texto, style: const TextStyle(fontSize: 14)),
              ],
            ),
    );
  }
}

// ============== Ilustração Hero (Landing) ==============
class IlustracaoHero extends StatelessWidget {
  const IlustracaoHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFF5E6FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildPlaceholder(80),
            _buildPlaceholder(112),
            _buildPlaceholder(64),
            _buildPlaceholder(112, span: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double height, {int span = 1}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
