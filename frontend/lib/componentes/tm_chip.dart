import 'package:flutter/material.dart';
import '../design_system/tm_tokens.dart';

class TMChip extends StatelessWidget {
  final String label;
  final Color? fg;
  final Color? bg;
  final IconData? icon;
  const TMChip(this.label, {super.key, this.fg, this.bg, this.icon});

  factory TMChip.jobStatus(String status) {
    return TMChip(
      status,
      fg: TMStatusColors.jobFg[status] ?? TMTokens.text,
      bg: TMStatusColors.jobBg[status] ?? const Color(0xFFE5E7EB),
    );
  }

  factory TMChip.candidateStatus(String status) {
    return TMChip(
      status,
      fg: TMStatusColors.candidateFg[status] ?? TMTokens.text,
      bg: TMStatusColors.candidateBg[status] ?? const Color(0xFFE5E7EB),
    );
  }

  factory TMChip.interviewStatus(String status) {
    return TMChip(
      status,
      fg: TMStatusColors.interviewFg[status] ?? TMTokens.text,
      bg: TMStatusColors.interviewBg[status] ?? const Color(0xFFE5E7EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(TMTokens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg ?? TMTokens.text), const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(color: fg ?? TMTokens.text, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
