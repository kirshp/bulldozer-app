import 'package:flutter/material.dart';

/// Region colour palette — a 1:1 port of the site's `src/lib/palette.ts`, so
/// editorial charts (scatter, dot strips, group trends) read the same on the
/// app and the web. Bars and choropleths stay amber (ranking / scale); region
/// hues are only for grouping.
const Map<String, Color> regionColor = {
  'Europe & Central Asia': Color(0xFF60A5FA),
  'Americas': Color(0xFFF59E0B),
  'East Asia & Pacific': Color(0xFF34D399),
  'South Asia': Color(0xFFA78BFA),
  'Middle East & North Africa': Color(0xFFF472B6),
  'Sub-Saharan Africa': Color(0xFFFB923C),
  'Advanced / other': Color(0xFF94A3B8),
  // Gapminder 4-region names
  'Europe': Color(0xFF60A5FA),
  'Asia': Color(0xFF34D399),
  'Africa': Color(0xFFFB923C),
};

const Color kRegionOther = Color(0xFF94A3B8);

Color colorFor(String? region) =>
    (region != null ? regionColor[region] : null) ?? kRegionOther;

/// Regions present in [regions], in the site's canonical order, for a legend.
List<String> legendRegions(Iterable<String> regions) {
  const order = [
    'Europe & Central Asia',
    'Americas',
    'East Asia & Pacific',
    'South Asia',
    'Middle East & North Africa',
    'Sub-Saharan Africa',
    'Europe',
    'Asia',
    'Africa',
    'Advanced / other',
  ];
  final present = regions.toSet();
  return [
    for (final r in order)
      if (present.contains(r)) r,
  ];
}
