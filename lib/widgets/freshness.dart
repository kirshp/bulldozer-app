import 'package:flutter/material.dart';

import '../theme.dart';

/// A small "updated …" chip from an ISO date (dataset's parsedAt). Green when
/// fresh (≤60d), dim otherwise — so a screenshot / glance shows data is live.
class FreshnessBadge extends StatelessWidget {
  final String parsedAt; // ISO yyyy-mm-dd
  final String latest; // latest data period, e.g. "2024"
  final bool compact; // dot-only, for dense list rows
  const FreshnessBadge(
      {super.key, required this.parsedAt, this.latest = '', this.compact = false});

  @override
  Widget build(BuildContext context) {
    final days = _daysSince(parsedAt);
    if (days == null) return const SizedBox.shrink();
    final fresh = days <= 60;
    final color = fresh ? kUp : kTextDim;
    final label = _ago(days);

    if (compact) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            latest.isNotEmpty ? 'data $latest · updated $label' : 'updated $label',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

int? _daysSince(String iso) {
  if (iso.isEmpty) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  return DateTime.now().difference(d).inDays;
}

String _ago(int days) {
  if (days <= 1) return 'today';
  if (days < 30) return '${days}d ago';
  final m = (days / 30).round();
  if (m < 12) return '${m}mo ago';
  final y = (days / 365).round();
  return '${y}y ago';
}
