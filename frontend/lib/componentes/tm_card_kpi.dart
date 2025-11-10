import 'package:flutter/material.dart';
import '../design_system/tm_tokens.dart';

class TMCardKPI extends StatelessWidget {
  final String title;
  final String value;
  final String? delta; // ex: "+12%" ou "Atualizado"
  final IconData? icon;
  final Color? accentColor;

  const TMCardKPI({
    super.key,
    required this.title,
    required this.value,
    this.delta,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? TMTokens.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TMTokens.textMuted),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(TMTokens.r8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: TMTokens.text),
                ),
                if (delta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                      borderRadius: BorderRadius.circular(TMTokens.r12),
                    ),
                    child: Text(
                      delta!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TMTokens.primary,
                        fontWeight: FontWeight.w600,
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

// (usa padding fixo de 20px para consistência visual)
