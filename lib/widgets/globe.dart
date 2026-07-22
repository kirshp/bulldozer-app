import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme.dart';

/// A spinning, draggable orthographic globe — countries coloured by [values]
/// with the same amber ramp as the flat Choropleth. Auto-rotates; drag to
/// spin, tap a country to open it. Geometry: assets/globe.json (raw lon/lat).
class Globe extends StatefulWidget {
  final Map<String, double> values; // iso3 → value
  final void Function(String iso, String name)? onTap;
  final double height;
  const Globe({super.key, required this.values, this.onTap, this.height = 240});

  @override
  State<Globe> createState() => _GlobeState();
}

class _GlobeCountry {
  final String iso, name;
  final List<List<Offset>> rings; // (lonRad, latRad) packed in Offset
  const _GlobeCountry(this.iso, this.name, this.rings);
}

List<_GlobeCountry>? _geoCache;
Future<List<_GlobeCountry>> _loadGlobeGeo() async {
  if (_geoCache != null) return _geoCache!;
  final raw = jsonDecode(await rootBundle.loadString('assets/globe.json'));
  const d2r = pi / 180;
  _geoCache = [
    for (final c in (raw['countries'] as List))
      _GlobeCountry(
        c['iso'] ?? '',
        c['name'] ?? '',
        [
          for (final ring in (c['rings'] as List))
            [
              for (final p in (ring as List))
                Offset((p[0] as num) * d2r, (p[1] as num) * d2r)
            ]
        ],
      )
  ];
  return _geoCache!;
}

class _GlobeState extends State<Globe> with SingleTickerProviderStateMixin {
  List<_GlobeCountry>? _geo;
  late final AnimationController _spin;
  double _lon = 0.35; // rotation (radians); drag adjusts it
  double _lat = -0.45; // view latitude (tilt), drag adjusts, clamped
  DateTime _lastDrag = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadGlobeGeo().then((g) {
      if (mounted) setState(() => _geo = g);
    });
    _spin = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() {
        // gentle auto-spin, paused for a few seconds after a drag
        if (DateTime.now().difference(_lastDrag).inSeconds >= 3) {
          setState(() => _lon += 0.0035);
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _onTap(Offset p, Size size) {
    final geo = _geo;
    if (geo == null || widget.onTap == null) return;
    final proj = _Proj(_lon, _lat, size);
    for (final c in geo) {
      for (final ring in c.rings) {
        final path = proj.ringPath(ring);
        if (path != null && path.contains(p)) {
          widget.onTap!(c.iso, c.name);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: _geo == null
          ? const SizedBox.shrink()
          : LayoutBuilder(builder: (context, box) {
              return GestureDetector(
                onPanUpdate: (d) {
                  _lastDrag = DateTime.now();
                  setState(() {
                    _lon += d.delta.dx / 120;
                    _lat = (_lat + d.delta.dy / 160).clamp(-1.2, 1.2);
                  });
                },
                onTapUp: (d) => _onTap(d.localPosition, box.biggest),
                child: CustomPaint(
                  painter: _GlobePainter(_geo!, widget.values, _lon, _lat),
                  child: const SizedBox.expand(),
                ),
              );
            }),
    );
  }
}

/// Orthographic projection at view (lon0, lat0), fit to the widget box.
class _Proj {
  final double lon0, lat0, r;
  final Offset c;
  final double sinLat0, cosLat0;
  _Proj(this.lon0, this.lat0, Size size)
      : r = min(size.width, size.height) / 2 - 6,
        c = Offset(size.width / 2, size.height / 2),
        sinLat0 = sin(lat0),
        cosLat0 = cos(lat0);

  /// Screen point, or null if on the far hemisphere.
  Offset? point(Offset lonLat) {
    final lam = lonLat.dx - lon0, phi = lonLat.dy;
    final sinPhi = sin(phi), cosPhi = cos(phi), cosLam = cos(lam);
    final cosC = sinLat0 * sinPhi + cosLat0 * cosPhi * cosLam;
    if (cosC < 0) return null; // back side
    final x = cosPhi * sin(lam);
    final y = cosLat0 * sinPhi - sinLat0 * cosPhi * cosLam;
    return Offset(c.dx + r * x, c.dy - r * y);
  }

  /// Path of a ring's visible part (null if fully hidden).
  Path? ringPath(List<Offset> ring) {
    Path? path;
    var open = false;
    for (final ll in ring) {
      final p = point(ll);
      if (p == null) {
        open = false;
        continue;
      }
      if (!open) {
        path ??= Path();
        path.moveTo(p.dx, p.dy);
        open = true;
      } else {
        path!.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }
}

class _GlobePainter extends CustomPainter {
  final List<_GlobeCountry> geo;
  final Map<String, double> values;
  final double lon, lat;
  _GlobePainter(this.geo, this.values, this.lon, this.lat);

  // Same three-stop ramp as the flat Choropleth.
  Color get _lo => isLight ? const Color(0xFFF3E3C0) : const Color(0xFF7A5200);
  Color get _mid => isLight ? const Color(0xFFE08900) : const Color(0xFFC96A00);
  Color get _hi => isLight ? const Color(0xFF7A3E00) : const Color(0xFFFFDE6B);
  Color _ramp(double t) => t < 0.5
      ? Color.lerp(_lo, _mid, t * 2)!
      : Color.lerp(_mid, _hi, (t - 0.5) * 2)!;

  @override
  void paint(Canvas canvas, Size size) {
    final proj = _Proj(lon, lat, size);

    // ocean disk with a soft top-left highlight for depth
    canvas.drawCircle(
        proj.c,
        proj.r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.15,
            colors: isLight
                ? [const Color(0xFFEDE7DA), const Color(0xFFD9D2C2)]
                : [const Color(0xFF232A33), const Color(0xFF12151A)],
          ).createShader(Rect.fromCircle(center: proj.c, radius: proj.r)));

    double minV = double.infinity, maxV = -double.infinity;
    for (final v in values.values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final noData = isLight ? const Color(0xFFCEC7B6) : const Color(0xFF3A414B);
    final border = Paint()
      ..color = isLight ? const Color(0x33000000) : const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (final country in geo) {
      final v = values[country.iso];
      final fill = Paint()
        ..color = v == null || maxV <= minV
            ? noData
            : _ramp(((v - minV) / (maxV - minV)).clamp(0.0, 1.0));
      for (final ring in country.rings) {
        final path = proj.ringPath(ring);
        if (path == null) continue;
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
      }
    }

    // rim: crisp edge + faint atmosphere glow
    canvas.drawCircle(
        proj.c,
        proj.r,
        Paint()
          ..color = kAmber.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.lon != lon || old.lat != lat || old.values != values;
}
