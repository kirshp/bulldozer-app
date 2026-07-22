import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'palette.dart';
import 'theme.dart';
import 'widgets/region_legend.dart';
import 'widgets/search_sheet.dart';

/// Gapminder-style animated bubble chart — a native port of the site's
/// BubbleChart: three indicators merged on iso+year (X, Y, bubble size),
/// coloured by region, played over the years. The site's signature view.
class BubblePage extends StatefulWidget {
  const BubblePage({super.key});
  @override
  State<BubblePage> createState() => _BubblePageState();
}

class _Bubble {
  final String name, region;
  final double x, y, s;
  const _Bubble(this.name, this.region, this.x, this.y, this.s);
}

class _BubblePageState extends State<BubblePage> {
  // sensible defaults, same as the site
  String _xSlug = 'gapminder-income';
  String _ySlug = 'gapminder-life-expectancy';
  String _sSlug = 'gapminder-population';
  bool _logX = true;

  Dataset? _xd, _yd, _sd;
  List<String> _years = [];
  int _yi = 0;
  bool _playing = false;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _xd = _yd = _sd = null;
    });
    try {
      final res = await Future.wait(
          [fetchDataset(_xSlug), fetchDataset(_ySlug), fetchDataset(_sSlug)]);
      final xd = res[0], yd = res[1], sd = res[2];
      // years present in all three
      final ys = xd.periods.toSet()
        ..retainAll(yd.periods.toSet())
        ..retainAll(sd.periods.toSet());
      final years = ys.toList()..sort();
      setState(() {
        _xd = xd;
        _yd = yd;
        _sd = sd;
        _years = years;
        _yi = years.isEmpty ? 0 : years.length - 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_years.isEmpty) return;
    if (_yi >= _years.length - 1) _yi = 0; // restart from the beginning
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 550), (t) {
      if (_yi >= _years.length - 1) {
        t.cancel();
        setState(() => _playing = false);
      } else {
        setState(() => _yi++);
      }
    });
  }

  void _pick(String which) {
    showSearchSheet<CatalogEntry>(
      context,
      title: 'Pick indicator ($which)',
      items: catalog,
      label: (e) => e.title,
      sub: (e) => e.source,
      onPick: (e) {
        _timer?.cancel();
        setState(() {
          _playing = false;
          if (which == 'X') _xSlug = e.slug;
          if (which == 'Y') _ySlug = e.slug;
          if (which == 'size') _sSlug = e.slug;
        });
        _load();
      },
    );
  }

  // Merge the three datasets on iso for the current year.
  ({List<_Bubble> pts, double minX, double maxX, double minY, double maxY, double maxS})
      _frame() {
    final xd = _xd!, yd = _yd!, sd = _sd!;
    final year = _years[_yi];
    Map<String, Observation> byIso(Dataset d) => {
          for (final o in d.data)
            if (o.period == year && o.iso.isNotEmpty) o.iso: o
        };
    final xm = byIso(xd), ym = byIso(yd), sm = byIso(sd);
    final pts = <_Bubble>[];
    for (final iso in xm.keys) {
      final yo = ym[iso], so = sm[iso];
      if (yo == null || so == null) continue;
      final xo = xm[iso]!;
      pts.add(_Bubble(xo.entity, xo.group, xo.value, yo.value, so.value));
    }
    // fixed domains across ALL years so bubbles don't jump between frames
    double lo(Dataset d, num Function(Observation) f) =>
        d.data.map((o) => f(o).toDouble()).fold(double.infinity, min);
    double hi(Dataset d, num Function(Observation) f) =>
        d.data.map((o) => f(o).toDouble()).fold(-double.infinity, max);
    return (
      pts: pts,
      minX: lo(xd, (o) => o.value),
      maxX: hi(xd, (o) => o.value),
      minY: lo(yd, (o) => o.value),
      maxY: hi(yd, (o) => o.value),
      maxS: hi(sd, (o) => o.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated bubbles',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Couldn\'t load.\n$_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextDim))))
          : (_xd == null || _yd == null || _sd == null)
              ? Center(child: CircularProgressIndicator(color: kAmber))
              : _body(),
    );
  }

  Widget _body() {
    if (_years.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('These three indicators share no common years.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextDim))));
    }
    final f = _frame();
    final xTitle = catalogBySlug[_xSlug]?.title ?? _xSlug;
    final yTitle = catalogBySlug[_ySlug]?.title ?? _ySlug;
    final sTitle = catalogBySlug[_sSlug]?.title ?? _sSlug;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // indicator pickers
        _pickRow('X →', xTitle, () => _pick('X')),
        _pickRow('Y ↑', yTitle, () => _pick('Y')),
        _pickRow('Size', sTitle, () => _pick('size')),
        Row(
          children: [
            Checkbox(
              value: _logX,
              onChanged: (v) => setState(() => _logX = v ?? false),
              activeColor: kAmber,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text('log X', style: TextStyle(fontSize: 13, color: kText)),
          ],
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1.05,
          child: CustomPaint(
            painter: _BubblePainter(
                pts: f.pts,
                minX: f.minX,
                maxX: f.maxX,
                minY: f.minY,
                maxY: f.maxY,
                maxS: f.maxS,
                logX: _logX),
            child: const SizedBox.expand(),
          ),
        ),
        RegionLegend(regions: f.pts.map((p) => p.region)),
        const SizedBox(height: 12),
        // player: play button + year slider + big year label
        Row(
          children: [
            InkWell(
              onTap: _togglePlay,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: kAmber, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_playing ? Icons.pause : Icons.play_arrow,
                      size: 18, color: kBg),
                  const SizedBox(width: 4),
                  Text(_playing ? 'Pause' : 'Play',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kBg)),
                ]),
              ),
            ),
            Expanded(
              child: Slider(
                value: _yi.toDouble(),
                min: 0,
                max: (_years.length - 1).toDouble(),
                divisions: max(1, _years.length - 1),
                activeColor: kAmber,
                onChanged: (v) {
                  _timer?.cancel();
                  setState(() {
                    _playing = false;
                    _yi = v.round();
                  });
                },
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(_years[_yi],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kAmber)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('${f.pts.length} countries · bubble size = $sTitle',
            style: TextStyle(fontSize: 11, color: kTextDim)),
        chartWatermark,
      ],
    );
  }

  Widget _pickRow(String axis, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
                width: 42,
                child: Text(axis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kTextDim))),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.unfold_more, size: 18, color: kTextDim),
          ],
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> pts;
  final double minX, maxX, minY, maxY, maxS;
  final bool logX;
  _BubblePainter({
    required this.pts,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.maxS,
    required this.logX,
  });

  double _tx(double v) {
    if (logX) {
      final lo = log(max(minX, 1e-6)), hi = log(max(maxX, 1e-6));
      return hi > lo ? (log(max(v, 1e-6)) - lo) / (hi - lo) : 0.5;
    }
    return maxX > minX ? (v - minX) / (maxX - minX) : 0.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 8.0, padR = 8.0, padT = 8.0, padB = 8.0;
    final w = size.width - padL - padR, h = size.height - padT - padB;
    // gridlines
    final grid = Paint()
      ..color = kBorder
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 4; i++) {
      final y = padT + h * i / 4;
      canvas.drawLine(Offset(padL, y), Offset(padL + w, y), grid);
    }
    // bubbles: bigger first so small ones stay clickable/visible on top
    final sorted = [...pts]..sort((a, b) => b.s.compareTo(a.s));
    for (final b in sorted) {
      final px = padL + _tx(b.x) * w;
      final py = padT + (1 - (maxY > minY ? (b.y - minY) / (maxY - minY) : 0.5)) * h;
      final r = 3 + 22 * sqrt((b.s / (maxS <= 0 ? 1 : maxS)).clamp(0, 1));
      final c = colorFor(b.region);
      canvas.drawCircle(Offset(px, py), r, Paint()..color = c.withValues(alpha: 0.68));
      canvas.drawCircle(
          Offset(px, py),
          r,
          Paint()
            ..color = kBg.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.pts != pts || old.logX != logX;
}
