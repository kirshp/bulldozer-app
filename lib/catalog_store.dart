import 'package:flutter/foundation.dart';

import 'api.dart';
import 'catalog.dart';

export 'catalog.dart' show CatalogEntry;

/// The active dataset catalog. Starts from the baked offline fallback and is
/// replaced by the live `/data/catalog.json` once loaded — so new datasets
/// added on the site show up without rebuilding the app.
final catalogNotifier = ValueNotifier<List<CatalogEntry>>(bakedCatalog);

List<CatalogEntry> get catalog => catalogNotifier.value;

Map<String, CatalogEntry> get catalogBySlug =>
    {for (final e in catalog) e.slug: e};

/// Site discovery manifest — freshest parse date + resource counts. Lets the
/// app show "data updated …" and auto-know what the site offers.
class Manifest {
  final String freshestParse;
  final Map<String, int> counts;
  const Manifest(this.freshestParse, this.counts);
}

final manifestNotifier = ValueNotifier<Manifest?>(null);

Future<void> loadManifest() async {
  try {
    final data = await fetchJson('/data/manifest.json');
    if (data is Map) {
      manifestNotifier.value = Manifest(
        data['freshestParse'] ?? '',
        {
          for (final e in (data['counts'] as Map? ?? {}).entries)
            '${e.key}': (e.value is num) ? (e.value as num).toInt() : 0
        },
      );
    }
  } catch (_) {
    // manifest is best-effort — the app works without it
  }
}

/// Loads the live catalog (cached by [fetchJson]); keeps the baked/cached list
/// on any failure.
Future<void> loadCatalog() async {
  try {
    final data = await fetchJson('/data/catalog.json');
    if (data is List && data.isNotEmpty) {
      catalogNotifier.value = [
        for (final e in data)
          CatalogEntry(
            e['slug'] ?? '',
            e['title'] ?? '',
            e['unit'] ?? '',
            e['kind'] ?? 'macro',
            e['topic'] ?? 'economy',
            e['source'] ?? '',
            e['parsedAt'] ?? '',
            e['latest'] ?? '',
          ),
      ];
    }
  } catch (_) {
    // offline or endpoint missing — keep the baked/cached catalog
  }
}
