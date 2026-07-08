import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'countries_page.dart';
import 'flags.dart';
import 'theme.dart';

/// Global search — one field that matches both countries and indicators,
/// reachable from the Home header.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _q = '';
  List<Country> _countries = [];

  @override
  void initState() {
    super.initState();
    fetchCountryIndex().then((list) {
      list.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() => _countries = list);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase().trim();
    final countries = q.isEmpty
        ? const <Country>[]
        : _countries
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.region.toLowerCase().contains(q))
            .take(8)
            .toList();
    final datasets = q.isEmpty
        ? const <CatalogEntry>[]
        : catalog
            .where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.source.toLowerCase().contains(q))
            .take(12)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Country or indicator…',
            hintStyle: TextStyle(color: kTextDim),
            border: InputBorder.none,
          ),
        ),
      ),
      body: q.isEmpty
          ? const Center(
              child: Text('Search countries and indicators',
                  style: TextStyle(color: kTextDim, fontSize: 13)))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (countries.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 6),
                    child: Text('COUNTRIES',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: kAmber)),
                  ),
                  for (final c in countries)
                    ListTile(
                      dense: true,
                      leading: Text(flagFromIso(c.iso),
                          style: const TextStyle(fontSize: 20)),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(c.region,
                          style:
                              const TextStyle(fontSize: 11, color: kTextDim)),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => CountryPage(
                                  country: c, allCountries: _countries))),
                    ),
                ],
                if (datasets.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 12, 4, 6),
                    child: Text('INDICATORS',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: kAmber)),
                  ),
                  for (final e in datasets)
                    ListTile(
                      dense: true,
                      leading: Text(
                          (topicLabels[e.topic] ?? '📊').split(' ').first,
                          style: const TextStyle(fontSize: 18)),
                      title: Text(e.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(e.source,
                          style:
                              const TextStyle(fontSize: 11, color: kTextDim)),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => DatasetPage(entry: e))),
                    ),
                ],
                if (countries.isEmpty && datasets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('Nothing found.',
                            style: TextStyle(color: kTextDim))),
                  ),
              ],
            ),
    );
  }
}
