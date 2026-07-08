import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Starred countries (ISO3) and indicators (dataset slugs), persisted as a
/// small JSON file in the app's support directory (same pattern as the
/// fetchJson cache — no extra dependency).
class Favorites {
  final Set<String> countries;
  final Set<String> datasets;
  const Favorites(this.countries, this.datasets);
}

final favoritesNotifier = ValueNotifier<Favorites>(const Favorites({}, {}));

bool isFavCountry(String iso) => favoritesNotifier.value.countries.contains(iso);
bool isFavDataset(String slug) => favoritesNotifier.value.datasets.contains(slug);

Future<File?> _favFile() async {
  if (kIsWeb) return null;
  try {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/bd_favorites.json');
  } catch (_) {
    return null;
  }
}

Future<void> loadFavorites() async {
  final f = await _favFile();
  if (f == null || !await f.exists()) return;
  try {
    final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    favoritesNotifier.value = Favorites(
      {for (final c in (j['countries'] as List? ?? [])) '$c'},
      {for (final d in (j['datasets'] as List? ?? [])) '$d'},
    );
  } catch (_) {
    // corrupt file — start fresh
  }
}

void _save() async {
  final f = await _favFile();
  if (f == null) return;
  final v = favoritesNotifier.value;
  f
      .writeAsString(jsonEncode({
        'countries': v.countries.toList(),
        'datasets': v.datasets.toList(),
      }))
      .ignore();
}

void toggleFavCountry(String iso) {
  final v = favoritesNotifier.value;
  final next = Set<String>.from(v.countries);
  next.contains(iso) ? next.remove(iso) : next.add(iso);
  favoritesNotifier.value = Favorites(next, v.datasets);
  _save();
}

void toggleFavDataset(String slug) {
  final v = favoritesNotifier.value;
  final next = Set<String>.from(v.datasets);
  next.contains(slug) ? next.remove(slug) : next.add(slug);
  favoritesNotifier.value = Favorites(v.countries, next);
  _save();
}
