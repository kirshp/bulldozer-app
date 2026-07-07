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
          ),
      ];
    }
  } catch (_) {
    // offline or endpoint missing — keep the baked/cached catalog
  }
}
