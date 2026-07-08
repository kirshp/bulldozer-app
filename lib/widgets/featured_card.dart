import 'package:flutter/material.dart';

import '../api.dart' show formatValue;
import '../theme.dart';

/// The featured-hero container: amber-tinted gradient card with kicker tag,
/// title, arbitrary [child] visual and a footer link. Each tab drops a
/// different visual in (map / trend line / dot strip / bars).
class HeroShell extends StatelessWidget {
  final String tag;
  final String title;
  final String footer;
  final VoidCallback? onTap;
  final Widget? child;

  const HeroShell(
      {super.key,
      required this.tag,
      required this.title,
      required this.footer,
      this.onTap,
      this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? [const Color(0xFFF3E3C0), const Color(0xFFFFFFFF)]
                : [const Color(0xFF3A2A00), const Color(0xFF1C1F23)],
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
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: kAmber)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, height: 1.2)),
            if (child != null) ...[const SizedBox(height: 12), child!],
            const SizedBox(height: 10),
            Text(footer,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kAmber)),
          ],
        ),
      ),
    );
  }
}

/// A one-axis dot distribution: every country is a dot placed by value, the
/// leader is highlighted and labelled. Distinct look for survey heroes.
class DotStrip extends StatelessWidget {
  final List<(String, double)> items; // (label, value), sorted desc
  const DotStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final top = items.first;
    final low = items.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          width: double.infinity,
          child: CustomPaint(
              painter:
                  _DotStripPainter([for (final i in items) i.$2], kAmber)),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${low.$1} · ${formatValue(low.$2)}',
                style: TextStyle(fontSize: 11, color: kTextDim)),
            Text('${top.$1} · ${formatValue(top.$2)}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: kAmber)),
          ],
        ),
      ],
    );
  }
}

class _DotStripPainter extends CustomPainter {
  final List<double> values;
  final Color accent;
  _DotStripPainter(this.values, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = maxV > minV ? maxV - minV : 1.0;
    final y = size.height * 0.62;
    canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = kBorder
          ..strokeWidth = 1.5);
    // jitter rows so dense clusters stay readable
    for (var i = values.length - 1; i >= 0; i--) {
      final x = (values[i] - minV) / span * (size.width - 12) + 6;
      final dy = y - 8.0 * (i % 3);
      canvas.drawCircle(Offset(x, dy), 4,
          Paint()..color = accent.withValues(alpha: i == 0 ? 1 : 0.45));
    }
    // leader ring
    final xTop = (values.first - minV) / span * (size.width - 12) + 6;
    canvas.drawCircle(
        Offset(xTop, y),
        7,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_DotStripPainter old) => old.values != values;
}

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
                style: TextStyle(
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
                                AlwaysStoppedAnimation<Color>(kAmber),
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
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kAmber)),
          ],
        ),
      ),
    );
  }
}
