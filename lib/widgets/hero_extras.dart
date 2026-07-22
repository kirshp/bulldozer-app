import 'dart:math';

import 'package:flutter/material.dart';

import '../api.dart';
import '../flags.dart';
import '../theme.dart';

/// Biz hero: a 1-2-3 podium of the most valuable brands, real logos on white
/// chips — replaces the generic bar rows.
class BrandPodium extends StatelessWidget {
  final List<Brand> top3; // ranks 1..3, in rank order
  const BrandPodium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    if (top3.length < 3) return const SizedBox.shrink();
    // visual order: silver, gold, bronze
    final order = [top3[1], top3[0], top3[2]];
    final heights = [64.0, 88.0, 48.0];
    final medals = ['🥈', '🥇', '🥉'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: order[i].logo.isEmpty
                      ? const Icon(Icons.business, color: Colors.black26)
                      : Image.network(order[i].logoUrl(96),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.business,
                              color: Colors.black26,
                              size: 20)),
                ),
                const SizedBox(height: 4),
                Text(order[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text('\$${_bn(order[i].valueBn)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kAmber)),
                const SizedBox(height: 4),
                Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          kAmber.withValues(alpha: i == 1 ? 0.95 : 0.55),
                          kOrange.withValues(alpha: i == 1 ? 0.85 : 0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(medals[i], style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _bn(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}T' : '${v.round()}B';
}

/// Polls hero: a half-donut gauge of the world average for a survey share,
/// with the top and bottom countries as chips — "the world says X%".
class GaugeHero extends StatelessWidget {
  final double avg; // 0..100 (survey %)
  final Observation top;
  final Observation low;
  final String unit;
  const GaugeHero(
      {super.key,
      required this.avg,
      required this.top,
      required this.low,
      this.unit = '%'});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          width: 200,
          child: CustomPaint(
            painter: _GaugePainter(avg / 100),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${avg.toStringAsFixed(0)}$unit',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: kAmber,
                          height: 1.0)),
                  Text('world average',
                      style: TextStyle(fontSize: 10, color: kTextDim)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _chip('${flagFromIso(low.iso)} ${low.entity}',
                formatValue(low.value), kDown),
            _chip('${flagFromIso(top.iso)} ${top.entity}',
                formatValue(top.value), kUp),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, String value, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double t; // 0..1
  _GaugePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height);
    final r = min(size.width / 2, size.height) - 6;
    final track = Paint()
      ..color = kBgCard
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = SweepGradient(
        colors: [kOrange, kAmber],
        startAngle: pi,
        endAngle: 2 * pi,
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), pi, pi, false, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi,
        pi * t.clamp(0.0, 1.0), false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.t != t;
}

/// Stats hero: "world records" — three tappable fact rows, each the extreme
/// of a different indicator (longest life, fastest growth, most people…).
/// The pool rotates per app launch, so the hero reads fresh every time.
class RecordsHero extends StatelessWidget {
  final List<RecordFact> facts;
  final void Function(RecordFact) onTapFact;
  const RecordsHero({super.key, required this.facts, required this.onTapFact});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in facts) ...[
          InkWell(
            onTap: () => onTapFact(f),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
              child: Row(
                children: [
                  Text(f.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${flagFromIso(f.iso)} ${f.country}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        Text(f.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 11, color: kTextDim)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(f.value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: kAmber)),
                ],
              ),
            ),
          ),
          if (f != facts.last)
            Divider(color: kBorder, height: 1, thickness: 0.5),
        ],
      ],
    );
  }
}

class RecordFact {
  final String emoji, country, iso, caption, value, slug;
  const RecordFact(
      {required this.emoji,
      required this.country,
      required this.iso,
      required this.caption,
      required this.value,
      required this.slug});
}
