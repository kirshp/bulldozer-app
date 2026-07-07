import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../api.dart' show formatValue;
import '../theme.dart';

/// A compact line chart of a value over time (periods). Amber line with a soft
/// area fill; the current/selected period gets a larger dot.
class TrendChart extends StatelessWidget {
  final List<(String, double)> points; // (period, value), sorted by period
  final String? highlightPeriod;
  final double height;

  const TrendChart({
    super.key,
    required this.points,
    this.highlightPeriod,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            points.isEmpty ? '—' : formatValue(points.first.$2),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: kAmber),
          ),
        ),
      );
    }
    final values = points.map((p) => p.$2).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV);
    final pad = span == 0 ? (maxV.abs() * 0.1 + 1) : span * 0.15;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minV - pad,
          maxY: maxV + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: kBorder, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, meta) => Text(formatValue(v),
                    style: const TextStyle(fontSize: 10, color: kTextDim)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Thin out labels when there are many periods.
                  if (points.length > 6 &&
                      i % 2 != 0 &&
                      i != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(points[i].$1,
                        style:
                            const TextStyle(fontSize: 10, color: kTextDim)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => kBgCard,
              getTooltipItems: (touched) => touched.map((s) {
                final i = s.x.toInt();
                final label = (i >= 0 && i < points.length) ? points[i].$1 : '';
                return LineTooltipItem(
                  '$label\n${formatValue(s.y)}',
                  const TextStyle(
                      color: kText, fontSize: 12, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].$2)
              ],
              isCurved: true,
              curveSmoothness: 0.2,
              color: kAmber,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                  radius: points[i].$1 == highlightPeriod ? 4 : 2.5,
                  color: points[i].$1 == highlightPeriod ? kAmber : kBgElev,
                  strokeColor: kAmber,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    kAmber.withValues(alpha: 0.25),
                    kAmber.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
