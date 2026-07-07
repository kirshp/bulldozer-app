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

/// A world choropleth: fills each country by [values] (ISO3 → value) on the
/// amber ramp; grey where there's no data. Tap a country to drill in.
class Choropleth extends StatefulWidget {
  final Map<String, double> values;
  final String? highlightIso;
  final void Function(String iso, String name)? onTap;
  const Choropleth(
      {super.key, required this.values, this.highlightIso, this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final geo = _geo;
    if (geo == null) {
      return const AspectRatio(
        aspectRatio: 2,
        child: Center(child: CircularProgressIndicator(color: kAmber)),
      );
    }
    final vals =
        widget.values.values.where((v) => v.isFinite).toList(growable: false);
    final minV = vals.isEmpty ? 0.0 : vals.reduce(min);
    final maxV = vals.isEmpty ? 1.0 : vals.reduce(max);

    return AspectRatio(
      aspectRatio: geo.w / geo.h,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final scale = cons.maxWidth / geo.w;
          return GestureDetector(
            onTapUp: (d) {
              if (widget.onTap == null) return;
              final c = _hitTest(
                  d.localPosition.dx / scale, d.localPosition.dy / scale);
              if (c != null) widget.onTap!(c.iso, c.name);
            },
            child: CustomPaint(
              size: Size(cons.maxWidth, cons.maxHeight),
              painter: _MapPainter(
                  geo, widget.values, minV, maxV, widget.highlightIso, scale),
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
  final double scale;
  _MapPainter(this.geo, this.values, this.minV, this.maxV, this.highlight,
      this.scale);

  // Visible "land" grey so countries read on the dark background even with no
  // data (e.g. the country-profile locator map, which highlights just one).
  static final _noData = Paint()..color = const Color(0xFF2A2F36);
  static final _border = Paint()
    ..color = kBg
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.4;
  static const _low = Color(0xFF3A2A00);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in geo.countries) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final poly in c.polys) {
        for (final ring in poly) {
          if (ring.isEmpty) continue;
          path.moveTo(ring[0].dx * scale, ring[0].dy * scale);
          for (int i = 1; i < ring.length; i++) {
            path.lineTo(ring[i].dx * scale, ring[i].dy * scale);
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
        fill = Paint()..color = Color.lerp(_low, kAmber, t.clamp(0.0, 1.0))!;
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
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.values != values ||
      old.highlight != highlight ||
      old.scale != scale;
}
