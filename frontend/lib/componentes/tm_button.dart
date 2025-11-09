import 'package:flutter/material.dart';
import '../design_system/tm_tokens.dart';

enum TMButtonVariant { primary, secondary, tonal, ghost }

class TMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TMButtonVariant variant;
  final bool loading;
  final IconData? icon;

  const TMButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = TMButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = loading ? 'Carregando...' : label;
    final leading = loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : (icon != null ? Icon(icon, size: 18) : null);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 8)],
        Text(text),
      ],
    );

    switch (variant) {
      case TMButtonVariant.primary:
        return FilledButton(onPressed: onPressed, child: child);
      case TMButtonVariant.secondary:
        return OutlinedButton(onPressed: onPressed, child: child);
      case TMButtonVariant.tonal:
        return FilledButton.tonal(onPressed: onPressed, child: child);
      case TMButtonVariant.ghost:
        return TextButton(onPressed: onPressed, child: child);
    }
  }
}

class TMIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  const TMIconButton({super.key, required this.icon, this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = IconButton(icon: Icon(icon), onPressed: onPressed);
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

class TMButtons {
  static ButtonStyle dangerOutlined() => OutlinedButton.styleFrom(
        foregroundColor: TMTokens.error,
        side: const BorderSide(color: TMTokens.error),
      );
}

