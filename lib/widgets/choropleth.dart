import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme.dart';

class GeoCountry {
  final String iso;
  final String name;
  final List<List<List<Offset>>> polys; // polygon -> ring -> points (geo space)
  GeoCountry(this.iso, this.name, this.polys);
}

class WorldGeo {
  final double w;
  final double h;
  final List<GeoCountry> countries;
  WorldGeo(this.w, this.h, this.countries);
}

WorldGeo? _cached;

/// Loads and caches the pre-projected world geometry (assets/world.json).
Future<WorldGeo> loadWorldGeo() async {
  if (_cached != null) return _cached!;
  final j = jsonDecode(await rootBundle.loadString('assets/world.json'));
  final countries = <GeoCountry>[];
  for (final c in (j['countries'] as List)) {
    final polys = <List<List<Offset>>>[];
    for (final poly in (c['polys'] as List)) {
      final rings = <List<Offset>>[];
      for (final ring in (poly as List)) {
        rings.add([
          for (final p in (ring as List))
            Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())
        ]);
      }
      polys.add(rings);
    }
    countries.add(GeoCountry(c['iso'] ?? '', c['name'] ?? '', polys));
  }
  return _cached = WorldGeo(
      (j['w'] as num).toDouble(), (j['h'] as num).toDouble(), countries);
}

/// A small gradient legend for choropleth maps: low label — ramp — high label.
class ChoroLegend extends StatelessWidget {
  final String low;
  final String high;
  const ChoroLegend({super.key, required this.low, required this.high});

  @override
  Widget build(BuildContext context) {
    final lowC = isLight ? const Color(0xFFF3E3C0) : const Color(0xFF7A5200);
    final midC = isLight ? const Color(0xFFE08900) : const Color(0xFFC96A00);
    final highC = isLight ? const Color(0xFF7A3E00) : const Color(0xFFFFDE6B);
    return Row(
      children: [
        Text(low, style: TextStyle(fontSize: 11, color: kTextDim)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: [lowC, midC, highC]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(high,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: kAmber)),
      ],
    );
  }
}

/// A labelled point in the map's geo space (pre-projected, like world.json) —
/// used to mark a country's capital on the locator map.
class CapitalMarker {
  final String name;
  final double x;
  final double y;
  const CapitalMarker(this.name, this.x, this.y);
}

/// A world choropleth: fills each country by [values] (ISO3 → value) on the
/// amber ramp; grey where there's no data. Tap a country to drill in.
class Choropleth extends StatefulWidget {
  final Map<String, double> values;
  final String? highlightIso;
  final String? zoomIso; // zoom the view to this country (locator map)
  final CapitalMarker? capital; // labelled dot, like the site's CountryPanel
  final void Function(String iso, String name)? onTap;
  const Choropleth(
      {super.key,
      required this.values,
      this.highlightIso,
      this.zoomIso,
      this.capital,
      this.onTap});

  @override
  State<Choropleth> createState() => _ChoroplethState();
}

class _ChoroplethState extends State<Choropleth> {
  WorldGeo? _geo;

  @override
  void initState() {
    super.initState();
    loadWorldGeo().then((g) {
      if (mounted) setState(() => _geo = g);
    });
  }

  bool _pointInRing(List<Offset> ring, double x, double y) {
    bool inside = false;
    final n = ring.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring[i].dx, yi = ring[i].dy, xj = ring[j].dx, yj = ring[j].dy;
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  GeoCountry? _hitTest(double gx, double gy) {
    for (final c in _geo!.countries) {
      for (final poly in c.polys) {
        if (poly.isNotEmpty && _pointInRing(poly[0], gx, gy)) return c;
      }
    }
    return null;
  }

  GeoCountry? _byIso(String iso) {
    for (final c in _geo!.countries) {
      if (c.iso == iso) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geo;
    if (geo == null) {
      return AspectRatio(
        aspectRatio: 2,
        child: Center(child: CircularProgressIndicator(color: kAmber)),
      );
    }
    final vals =
        widget.values.values.where((v) => v.isFinite).toList(growable: false);
    final minV = vals.isEmpty ? 0.0 : vals.reduce(min);
    final maxV = vals.isEmpty ? 1.0 : vals.reduce(max);

    // View region in geo coords: whole world, or zoomed to one country.
    final aspect = geo.w / geo.h;
    double rx0 = 0, ry0 = 0, regionW = geo.w;
    if (widget.zoomIso != null) {
      final c = _byIso(widget.zoomIso!);
      if (c != null) {
        double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
        for (final poly in c.polys) {
          for (final ring in poly) {
            for (final p in ring) {
              if (p.dx < x0) x0 = p.dx;
              if (p.dy < y0) y0 = p.dy;
              if (p.dx > x1) x1 = p.dx;
              if (p.dy > y1) y1 = p.dy;
            }
          }
        }
        final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
        regionW = (max(x1 - x0, (y1 - y0) * aspect) * 2.4).clamp(70.0, geo.w);
        final rh = regionW / aspect;
        rx0 = (cx - regionW / 2).clamp(0.0, geo.w - regionW);
        ry0 = (cy - rh / 2).clamp(0.0, geo.h - rh);
      }
    }

    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final zs = cons.maxWidth / regionW;
          return GestureDetector(
            onTapUp: (d) {
              if (widget.onTap == null) return;
              final c = _hitTest(d.localPosition.dx / zs + rx0,
                  d.localPosition.dy / zs + ry0);
              if (c != null) widget.onTap!(c.iso, c.name);
            },
            child: CustomPaint(
              size: Size(cons.maxWidth, cons.maxHeight),
              painter: _MapPainter(geo, widget.values, minV, maxV,
                  widget.highlightIso, rx0, ry0, zs, widget.capital),
            ),
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final WorldGeo geo;
  final Map<String, double> values;
  final double minV;
  final double maxV;
  final String? highlight;
  final double rx0;
  final double ry0;
  final double zs;
  final CapitalMarker? capital;
  _MapPainter(this.geo, this.values, this.minV, this.maxV, this.highlight,
      this.rx0, this.ry0, this.zs, this.capital);

  // Visible "land" grey so countries read on the background even with no
  // data. Not static — the palette flips with the theme.
  final _noData = Paint()
    ..color = isLight ? const Color(0xFFDDD8CC) : const Color(0xFF2A2F36);
  final _border = Paint()
    ..color = isLight
        ? const Color(0x33000000) // dark hairline on the cream theme
        : const Color(0x66FFFFFF) // light hairline separates every country
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  // Three-stop ramp so mid values separate instead of blending into one
  // amber mass: dark → orange → bright (reversed lightness on light theme).
  Color get _low => isLight ? const Color(0xFFF3E3C0) : const Color(0xFF7A5200);
  Color get _mid => isLight ? const Color(0xFFE08900) : const Color(0xFFC96A00);
  Color get _high => isLight ? const Color(0xFF7A3E00) : const Color(0xFFFFDE6B);

  Color _ramp(double t) => t < 0.5
      ? Color.lerp(_low, _mid, t * 2)!
      : Color.lerp(_mid, _high, (t - 0.5) * 2)!;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in geo.countries) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final poly in c.polys) {
        for (final ring in poly) {
          if (ring.isEmpty) continue;
          // Split rings that wrap the antimeridian (Russia, Fiji): a jump of
          // half the map between neighbours would otherwise paint a streak
          // right across the world.
          path.moveTo((ring[0].dx - rx0) * zs, (ring[0].dy - ry0) * zs);
          for (int i = 1; i < ring.length; i++) {
            if ((ring[i].dx - ring[i - 1].dx).abs() > geo.w / 2) {
              path.close();
              path.moveTo((ring[i].dx - rx0) * zs, (ring[i].dy - ry0) * zs);
            } else {
              path.lineTo((ring[i].dx - rx0) * zs, (ring[i].dy - ry0) * zs);
            }
          }
          path.close();
        }
      }
      final v = values[c.iso];
      final Paint fill;
      if (c.iso == highlight) {
        fill = Paint()..color = kAmber; // selected country pops (locator map)
      } else if (v == null || !v.isFinite) {
        fill = _noData;
      } else {
        final t = maxV > minV ? (v - minV) / (maxV - minV) : 0.5;
        fill = Paint()..color = _ramp(t.clamp(0.0, 1.0));
      }
      canvas.drawPath(path, fill);
      canvas.drawPath(path, _border);
      if (c.iso == highlight) {
        canvas.drawPath(
            path,
            Paint()
              ..color = kText
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8);
      }
    }
    _paintCapital(canvas, size);
  }

  /// Halo + dot + name label on the capital, like the site's CountryPanel.
  void _paintCapital(Canvas canvas, Size size) {
    final cap = capital;
    if (cap == null) return;
    final cx = (cap.x - rx0) * zs, cy = (cap.y - ry0) * zs;
    if (cx < 0 || cy < 0 || cx > size.width || cy > size.height) return;
    final r = (size.width * 0.008).clamp(2.5, 5.0);
    canvas.drawCircle(
        Offset(cx, cy), r * 2.2, Paint()..color = kBg.withValues(alpha: 0.45));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = kText);
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = kBg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    if (cap.name.isEmpty) return;
    final fs = (size.width * 0.028).clamp(9.0, 13.0);
    final tp = TextPainter(
      text: TextSpan(
        text: cap.name,
        style: TextStyle(
          color: kText,
          fontSize: fs,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 3),
            Shadow(color: Colors.black, blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Label above the dot, nudged back inside the canvas near the edges.
    final lx = (cx - tp.width / 2).clamp(2.0, size.width - tp.width - 2);
    var ly = cy - r * 2.2 - tp.height - 2;
    if (ly < 2) ly = cy + r * 2.2 + 2;
    tp.paint(canvas, Offset(lx, ly));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.values != values ||
      old.highlight != highlight ||
      old.zs != zs ||
      old.rx0 != rx0 ||
      old.ry0 != ry0 ||
      old.capital != capital;
}
