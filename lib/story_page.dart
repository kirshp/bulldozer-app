import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'flags.dart';
import 'palette.dart';
import 'theme.dart';
import 'widgets/choropleth.dart';
import 'widgets/region_legend.dart';

/// Declarative spec for a native data story. The two flagship stories are
/// data-backed, so we render them natively from their datasets (ranking +
/// a scatter or a map) rather than opening the web page.
class StorySpec {
  final String slug; // story slug (for the "full story on web" link)
  final String kicker;
  final String title;
  final String intro;
  final String mainSlug; // the ranked indicator
  final bool higherIsBetter; // medal / colour direction
  final String secondary; // 'scatter' | 'map'
  final String? xSlug; // scatter X (main indicator is Y)
  final String xLabel;
  final String yLabel;
  const StorySpec({
    required this.slug,
    required this.kicker,
    required this.title,
    required this.intro,
    required this.mainSlug,
    this.higherIsBetter = true,
    this.secondary = 'scatter',
    this.xSlug,
    this.xLabel = '',
    this.yLabel = '',
  });
}

/// The two flagship stories rendered natively. Others stay in the web view.
const nativeStories = <String, StorySpec>{
  'happiest-countries': StorySpec(
    slug: 'happiest-countries',
    kicker: 'World Happiness Report',
    title: 'The world’s happiest countries',
    intro:
        'Every year the World Happiness Report asks people to rate their lives '
        '0–10. The leaders cluster in the Nordics — and happiness tracks '
        'wealth, but only up to a point.',
    mainSlug: 'whr-happiness',
    secondary: 'scatter',
    xSlug: 'imf-gdp-per-capita-ppp',
    xLabel: 'GDP per capita (PPP)',
    yLabel: 'Happiness (0–10)',
  ),
  'strongest-democracies': StorySpec(
    slug: 'strongest-democracies',
    kicker: 'V-Dem Institute',
    title: 'The world’s strongest democracies',
    intro:
        'V-Dem’s liberal-democracy index scores countries 0–1 on free '
        'elections, rule of law and checks on power. The map shows where '
        'liberal democracy is strong — and where it is thin.',
    mainSlug: 'v-dem-v2x-libdem',
    secondary: 'map',
  ),
};

class StoryPage extends StatefulWidget {
  final StorySpec spec;
  const StoryPage({super.key, required this.spec});
  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  Dataset? _main, _x;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final main = await fetchDataset(widget.spec.mainSlug);
      Dataset? x;
      if (widget.spec.xSlug != null) {
        try {
          x = await fetchDataset(widget.spec.xSlug!);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _main = main;
          _x = x;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  List<Observation> _latestRows(Dataset d) {
    final last = d.periods.isEmpty ? '' : d.periods.last;
    final rows = d.data.where((o) => o.period == last && o.iso.isNotEmpty).toList()
      ..sort((a, b) => widget.spec.higherIsBetter
          ? b.value.compareTo(a.value)
          : a.value.compareTo(b.value));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.kicker,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Couldn\'t load the story.\n$_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextDim))))
          : _main == null
              ? Center(child: CircularProgressIndicator(color: kAmber))
              : _body(),
    );
  }

  Widget _body() {
    final s = widget.spec;
    final rows = _latestRows(_main!);
    if (rows.isEmpty) {
      return Center(
          child: Text('No data.', style: TextStyle(color: kTextDim)));
    }
    final leader = rows.first;
    final top = rows.take(15).toList();
    final maxV = rows.map((o) => o.value.abs()).reduce(max);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.kicker.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: kAmber)),
        const SizedBox(height: 4),
        Text(s.title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 10),
        Text(s.intro,
            style: TextStyle(fontSize: 14, color: kTextDim, height: 1.5)),
        const SizedBox(height: 18),
        // Leader hero
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [kAmber.withValues(alpha: 0.22), kBgCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Text(flagFromIso(leader.iso),
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#1 · ${leader.entity}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(s.yLabel.isNotEmpty ? s.yLabel : _main!.title,
                        style: TextStyle(fontSize: 12, color: kTextDim)),
                  ],
                ),
              ),
              Text(formatValue(leader.value),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: kAmber)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Top 15', style: _h()),
        const SizedBox(height: 8),
        for (var i = 0; i < top.length; i++)
          _BarRow(
              rank: i + 1,
              obs: top[i],
              fraction: maxV == 0 ? 0 : top[i].value.abs() / maxV),
        const SizedBox(height: 20),
        // Secondary visual
        if (s.secondary == 'scatter' && _x != null) ...[
          Text('Does money buy happiness?', style: _h()),
          const SizedBox(height: 4),
          Text('${s.yLabel} vs ${s.xLabel} · each dot a country',
              style: TextStyle(fontSize: 12, color: kTextDim)),
          const SizedBox(height: 10),
          _scatter(),
        ] else if (s.secondary == 'map') ...[
          Text('The world map', style: _h()),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Choropleth(values: {
              for (final o in rows)
                if (o.iso.isNotEmpty) o.iso: o.value
            }),
          ),
          const SizedBox(height: 6),
          ChoroLegend(low: 'Weak', high: 'Strong'),
        ],
        const SizedBox(height: 22),
        // Bottom of the scale, for honesty
        Text('At the other end', style: _h()),
        const SizedBox(height: 8),
        for (final o in rows.reversed.take(3).toList().reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Text('${flagFromIso(o.iso)} ${o.entity}',
                    style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text(formatValue(o.value),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextDim)),
              ],
            ),
          ),
        const SizedBox(height: 22),
        // Link to the full editorial version on the web
        Center(
          child: TextButton.icon(
            onPressed: () => launchUrl(
                Uri.parse('$kBaseUrl/stories/${s.slug}'),
                mode: LaunchMode.inAppBrowserView),
            icon: Icon(Icons.article_outlined, size: 18, color: kAmber),
            label: Text('Read the full story on the web',
                style: TextStyle(color: kAmber, fontWeight: FontWeight.w600)),
          ),
        ),
        chartWatermark,
      ],
    );
  }

  TextStyle _h() =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

  Widget _scatter() {
    // merge main (Y) with x dataset (X) on iso, latest common values
    Map<String, Observation> latest(Dataset d) {
      final m = <String, Observation>{};
      for (final o in d.data) {
        if (o.iso.isEmpty) continue;
        final cur = m[o.iso];
        if (cur == null || o.period.compareTo(cur.period) > 0) m[o.iso] = o;
      }
      return m;
    }

    final ym = latest(_main!), xm = latest(_x!);
    final pts = <(String, double, double, String)>[]; // name,x,y,region
    for (final iso in ym.keys) {
      final xo = xm[iso];
      if (xo == null) continue;
      final yo = ym[iso]!;
      pts.add((yo.entity, xo.value, yo.value, yo.group));
    }
    if (pts.length < 3) {
      return Text('Not enough overlapping countries.',
          style: TextStyle(fontSize: 12, color: kTextDim));
    }
    final xs = pts.map((p) => p.$2).toList();
    final ys = pts.map((p) => p.$3).toList();
    final minX = xs.reduce(min), maxX = xs.reduce(max);
    final minY = ys.reduce(min), maxY = ys.reduce(max);
    final padX = (maxX - minX) * 0.06 + 1, padY = (maxY - minY) * 0.06 + 1;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: ScatterChart(ScatterChartData(
            minX: minX - padX,
            maxX: maxX + padX,
            minY: minY - padY,
            maxY: maxY + padY,
            scatterSpots: [
              for (final p in pts)
                ScatterSpot(p.$2, p.$3,
                    dotPainter: FlDotCirclePainter(
                        radius: 4.5,
                        color: colorFor(p.$4).withValues(alpha: 0.82),
                        strokeColor: kBg,
                        strokeWidth: 0.6)),
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
                      reservedSize: 34,
                      getTitlesWidget: (v, _) => Text(formatValue(v),
                          style: TextStyle(fontSize: 9, color: kTextDim)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Text(formatValue(v),
                          style: TextStyle(fontSize: 9, color: kTextDim)))),
            ),
            scatterTouchData: ScatterTouchData(
              enabled: true,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipColor: (_) => kBgCard,
                getTooltipItems: (spot) {
                  final m = pts.firstWhere(
                      (p) => p.$2 == spot.x && p.$3 == spot.y,
                      orElse: () => ('', spot.x, spot.y, ''));
                  return ScatterTooltipItem(m.$1,
                      textStyle: TextStyle(
                          color: kText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700));
                },
              ),
            ),
          )),
        ),
        RegionLegend(regions: pts.map((p) => p.$4)),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final int rank;
  final Observation obs;
  final double fraction;
  const _BarRow(
      {required this.rank, required this.obs, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 24,
              child: Text(medal.isNotEmpty ? medal : '$rank',
                  style: TextStyle(fontSize: 12, color: kTextDim))),
          SizedBox(
            width: 118,
            child: Text('${flagFromIso(obs.iso)} ${obs.entity}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                  color: kBgCard, borderRadius: BorderRadius.circular(5)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.03, 1.0),
                child: Container(
                    decoration: BoxDecoration(
                        color: kAmber,
                        borderRadius: BorderRadius.circular(5))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 46,
              child: Text(formatValue(obs.value),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
