import 'package:flutter/material.dart';

import '../api.dart' show formatValue;
import '../theme.dart';

/// A rich featured block: amber-tinted gradient card with a kicker tag, title,
/// a mini ranked bar chart, and a footer link. Used on Home and atop each list.
class FeaturedCard extends StatelessWidget {
  final String tag;
  final String title;
  final List<(String, double)> bars; // (label, value), pre-sorted desc
  final String footer;
  final VoidCallback? onTap;

  const FeaturedCard({
    super.key,
    required this.tag,
    required this.title,
    this.bars = const [],
    required this.footer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = bars.isEmpty
        ? 1.0
        : bars.map((b) => b.$2.abs()).reduce((a, b) => a > b ? a : b);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3A2A00), Color(0xFF1C1F23)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tag.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: kAmber)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, height: 1.2)),
            if (bars.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final b in bars)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 118,
                        child: Text(b.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value:
                                (maxV == 0 ? 0.0 : b.$2.abs() / maxV)
                                    .clamp(0.02, 1.0),
                            minHeight: 7,
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(kAmber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        child: Text(formatValue(b.$2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 10),
            Text(footer,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kAmber)),
          ],
        ),
      ),
    );
  }
}
