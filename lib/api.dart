import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// The Flutter app is a thin client over the BullDozer site's JSON endpoints,
/// same pattern as the Ativa app over shpara.com/madeira/events.json.
const kBaseUrl = 'https://shpara.com/bulldozer';

Directory? _cacheDir;

Future<File?> _cacheFile(String path) async {
  if (kIsWeb) return null; // no filesystem cache on web
  try {
    _cacheDir ??= await getApplicationCacheDirectory();
    final safe = path.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File('${_cacheDir!.path}/bd_$safe');
  } catch (_) {
    return null;
  }
}

/// Fetches JSON with a read-through file cache: network-first, falling back to
/// the last cached copy when offline. Fresh responses are cached for next time.
Future<dynamic> fetchJson(String path) async {
  final file = await _cacheFile(path);
  try {
    final r = await http
        .get(Uri.parse('$kBaseUrl$path'))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode} for $path');
    }
    final body = utf8.decode(r.bodyBytes);
    if (file != null) {
      file.writeAsString(body).ignore(); // cache for offline, fire-and-forget
    }
    return jsonDecode(body);
  } catch (e) {
    if (file != null && await file.exists()) {
      return jsonDecode(await file.readAsString()); // offline fallback
    }
    rethrow;
  }
}

/// One-paragraph Wikipedia summary for a place name (REST API). Returns null on
/// any miss (unmatched title, offline) — the caller just omits the blurb.
Future<String?> fetchWikipediaSummary(String name) async {
  try {
    final r = await http
        .get(Uri.parse(
            'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(name)}'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    final extract = j['extract'];
    return (extract is String && extract.isNotEmpty) ? extract : null;
  } catch (_) {
    return null;
  }
}

class Observation {
  final String entity;
  final String group;
  final String period;
  final double value;
  final String iso;

  Observation.fromJson(Map<String, dynamic> j)
      : entity = j['entity'] ?? '',
        group = j['group'] ?? '',
        period = '${j['period'] ?? ''}',
        value = (j['value'] as num?)?.toDouble() ?? 0,
        iso = j['iso'] ?? '';
}

class Dataset {
  final String slug;
  final String title;
  final String summary;
  final String unit;
  final String source;
  final String license;
  final List<Observation> data;

  Dataset.fromJson(Map<String, dynamic> j)
      : slug = j['slug'] ?? '',
        title = j['title'] ?? '',
        summary = j['summary'] ?? '',
        unit = j['unit'] ?? '',
        source = j['source'] ?? '',
        license = j['license'] ?? '',
        data = [
          for (final o in (j['data'] as List? ?? [])) Observation.fromJson(o)
        ];

  List<String> get periods =>
      {for (final o in data) o.period}.toList()..sort();
}

Future<Dataset> fetchDataset(String slug) async =>
    Dataset.fromJson(await fetchJson('/data/$slug.json') as Map<String, dynamic>);

class CountryItem {
  final String slug;
  final String title;
  final String topic;
  final String kind; // 'macro' | 'survey'
  final String unit;
  final double value;
  final String period;
  final int rank;
  final int total;

  CountryItem.fromJson(Map<String, dynamic> j)
      : slug = j['slug'] ?? '',
        title = j['title'] ?? '',
        topic = j['topic'] ?? '',
        kind = j['kind'] ?? 'macro',
        unit = j['unit'] ?? '',
        value = (j['value'] as num?)?.toDouble() ?? 0,
        period = '${j['period'] ?? ''}',
        rank = j['rank'] ?? 0,
        total = j['total'] ?? 0;
}

class Country {
  final String iso;
  final String name;
  final String region;
  final List<CountryItem> items;

  Country.fromJson(Map<String, dynamic> j)
      : iso = j['iso'] ?? '',
        name = j['name'] ?? '',
        region = j['region'] ?? '',
        items = [
          for (final i in (j['items'] as List? ?? [])) CountryItem.fromJson(i)
        ];
}

Future<List<Country>> fetchCountryIndex() async => [
      for (final c in await fetchJson('/data/country-index.json') as List)
        Country.fromJson(c)
    ];

class Story {
  final String slug;
  final String tag;
  final String title;
  final String dek;

  Story.fromJson(Map<String, dynamic> j)
      : slug = j['slug'] ?? '',
        tag = j['tag'] ?? '',
        title = j['title'] ?? '',
        dek = j['dek'] ?? '';

  String get url => '$kBaseUrl/stories/$slug';
}

Future<List<Story>> fetchStories() async => [
      for (final s in await fetchJson('/data/stories.json') as List)
        Story.fromJson(s)
    ];

class QuizCountry {
  final String name;
  final String region;
  final String flag;
  final List<String> facts;

  QuizCountry.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        region = j['region'] ?? '',
        flag = j['flag'] ?? '',
        facts = [for (final f in (j['facts'] as List? ?? [])) '$f'];
}

Future<List<QuizCountry>> fetchQuizPool() async => [
      for (final c in await fetchJson('/data/quiz-pool.json') as List)
        QuizCountry.fromJson(c)
    ];

String formatValue(double v) {
  final abs = v.abs();
  if (abs >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
  if (abs >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (abs >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  if (abs >= 100) return v.toStringAsFixed(0);
  if (abs >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}
