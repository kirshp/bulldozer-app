import 'package:flutter/material.dart';

/// One-shot entrance: fade + a small upward slide. Wrap list items with an
/// increasing [delayMs] for a cascade. Animates only on first build — never
/// on rebuilds — so it reads polished, not busy.
class FadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const FadeIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
            offset: Offset(0, 14 * (1 - _a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// A number that counts up from 0 on first appearance (e.g. "156").
/// Non-numeric suffixes survive: pass value and suffix separately.
class CountUp extends StatelessWidget {
  final num value;
  final String suffix;
  final TextStyle? style;
  const CountUp({super.key, required this.value, this.suffix = '', this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}
