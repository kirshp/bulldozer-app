import 'package:flutter/material.dart';

import '../theme.dart';

/// A shimmering placeholder block — same idea as the site's `.skeleton`
/// (global.css): a moving highlight over an elevated surface while data loads.
class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const Skeleton(
      {super.key,
      this.width = double.infinity,
      this.height = 14,
      this.radius = 6});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final x = _c.value * 2 - 1; // -1 → 1 sweep
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: [kBgElev, kBgCard, kBgElev],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// A column of card-shaped skeleton rows for list screens.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const Skeleton(width: 26, height: 26, radius: 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120 + (i % 4) * 40, height: 13),
                      const SizedBox(height: 6),
                      const Skeleton(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
