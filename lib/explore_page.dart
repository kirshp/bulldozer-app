import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'palette.dart';
import 'theme.dart';
import 'widgets/region_legend.dart';
import 'widgets/search_sheet.dart';

/// Explore — scatter one indicator against another across all countries.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  CatalogEntry? _x;
  CatalogEntry? _y;
  Dataset? _xDs;
  Dataset? _yDs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _x = _prefer(
        ['gapminder-income', 'imf-gdp-per-capita', 'maddison-gdp-per-capita'],
        0);
    _y = _prefer(['gapminder-life-expectancy', 'whr-happiness'], 1);
    _load();
  }

  CatalogEntry? _prefer(List<String> slugs, int fallback) {
    for (final s in slugs) {
      final e = catalogBySlug[s];
      if (e != null) return e;
    }
    return catalog.length > fallback ? catalog[fallback] : null;
  }

  Future<void> _load() async {
    if (_x == null || _y == null) return;
    setState(() => _loading = true);
    try {
      final r =
          await Future.wait([fetchDataset(_x!.slug), fetchDataset(_y!.slug)]);
      if (mounted) {
        setState(() {
          _xDs = r[0];
          _yDs = r[1];
        });
      }
    } catch (_) {
      // hints shown below
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Latest value + country name + region per ISO.
  Map<String, ({double value, String name, String region})> _latest(
      Dataset? ds) {
    final m =
        <String, ({String period, double value, String name, String region})>{};
    for (final o in ds?.data ?? const <Observation>[]) {
      if (o.iso.isEmpty) continue;
      final cur = m[o.iso];
      if (cur == null || o.period.compareTo(cur.period) > 0) {
        m[o.iso] =
            (period: o.period, value: o.value, name: o.entity, region: o.group);
      }
    }
    return {
      for (final e in m.entries)
        e.key: (value: e.value.value, name: e.value.name, region: e.value.region)
    };
  }

  void _pick(bool isX) {
    showSearchSheet<CatalogEntry>(
      context,
      title: isX ? 'X axis — pick an indicator' : 'Y axis — pick an indicator',
      items: catalog,
      label: (e) => e.title,
      sub: (e) => e.source,
      onPick: (e) {
        setState(() => isX ? _x = e : _y = e);
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final xv = _latest(_xDs);
    final yv = _latest(_yDs);
    // (name, x, y, region) for countries present in both indicators.
    final points = <(String, double, double, String)>[];
    for (final entry in xv.entries) {
      final y = yv[entry.key];
      if (y != null) {
        points.add(
            (entry.value.name, entry.value.value, y.value, entry.value.region));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _axisPicker('Y', _y, () => _pick(false)),
          const SizedBox(height: 8),
          _axisPicker('X', _x, () => _pick(true)),
          const SizedBox(height: 20),
          if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: kAmber)),
            )
          else if (points.length < 2)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                  child: Text('Not enough overlapping countries.',
                      style: TextStyle(color: kTextDim))),
            )
          else ...[
            AspectRatio(
              aspectRatio: 1,
              child: _scatter(points),
            ),
            RegionLegend(regions: points.map((p) => p.$4)),
            const SizedBox(height: 10),
            Text(
                '${points.length} countries · tap a dot for its name and values',
                style: TextStyle(fontSize: 11, color: kTextDim)),
          ],
        ],
      ),
    );
  }

  Widget _axisPicker(String axis, CatalogEntry? ind, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(axis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: kAmber)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(ind?.title ?? 'Pick an indicator',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.expand_more, color: kTextDim),
          ],
        ),
      ),
    );
  }

  Widget _scatter(List<(String, double, double, String)> points) {
    final xs = points.map((p) => p.$2).toList();
    final ys = points.map((p) => p.$3).toList();
    final minX = xs.reduce(min), maxX = xs.reduce(max);
    final minY = ys.reduce(min), maxY = ys.reduce(max);
    final padX = (maxX - minX) == 0 ? 1.0 : (maxX - minX) * 0.08;
    final padY = (maxY - minY) == 0 ? 1.0 : (maxY - minY) * 0.08;

    return ScatterChart(
      ScatterChartData(
        minX: minX - padX,
        maxX: maxX + padX,
        minY: minY - padY,
        maxY: maxY + padY,
        scatterSpots: [
          for (final p in points)
            ScatterSpot(
              p.$2,
              p.$3,
              dotPainter: FlDotCirclePainter(
                  radius: 4.5,
                  color: colorFor(p.$4).withValues(alpha: 0.82),
                  strokeColor: kBg,
                  strokeWidth: 0.6),
            ),
        ],
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: kBorder, strokeWidth: 0.4),
          getDrawingVerticalLine: (_) =>
              FlLine(color: kBorder, strokeWidth: 0.4),
        ),
        borderData: FlBorderData(
            show: true,
            border: Border(
                left: BorderSide(color: kBorder),
                bottom: BorderSide(color: kBorder))),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(formatValue(v),
                    style: TextStyle(fontSize: 9, color: kTextDim))),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) => Text(formatValue(v),
                    style: TextStyle(fontSize: 9, color: kTextDim))),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => kBgCard,
            getTooltipItems: (spot) {
              final match = points.firstWhere(
                  (p) => p.$2 == spot.x && p.$3 == spot.y,
                  orElse: () => ('', spot.x, spot.y, ''));
              return ScatterTooltipItem(
                match.$1,
                textStyle: TextStyle(
                    color: kText, fontSize: 12, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(
                    text:
                        '\n${formatValue(spot.x)} · ${formatValue(spot.y)}',
                    style: TextStyle(color: kTextDim, fontSize: 11),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
