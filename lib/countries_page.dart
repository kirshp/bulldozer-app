import 'package:flutter/material.dart';

import 'api.dart';
import 'charts_page.dart' show topicLabels, topicRank;
import 'compare_page.dart';
import 'flags.dart';
import 'theme.dart';
import 'widgets/choropleth.dart';
import 'widgets/trend_chart.dart';

class CountriesPage extends StatefulWidget {
  const CountriesPage({super.key});

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  static List<Country>? _cache; // survives tab switches
  List<Country>? _countries = _cache;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (_countries == null) _load();
  }

  Future<void> _load() async {
    try {
      final list = await fetchCountryIndex();
      list.sort((a, b) => a.name.compareTo(b.name));
      _cache = list;
      setState(() => _countries = list);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Couldn\'t load countries.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextDim)),
      ));
    }
    if (_countries == null) {
      return const Center(child: CircularProgressIndicator(color: kAmber));
    }
    final q = _query.toLowerCase();
    final shown = _countries!
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.region.toLowerCase().contains(q))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Countries', style: pageTitleStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search ${_countries!.length} countries…',
              hintStyle: const TextStyle(color: kTextDim, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: kTextDim, size: 20),
              isDense: true,
              filled: true,
              fillColor: kBgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorder, width: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: kAmber,
            backgroundColor: kBgCard,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final c = shown[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  leading: Text(flagFromIso(c.iso),
                      style: const TextStyle(fontSize: 22)),
                  title: Text(c.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.region} · ${c.items.length} indicators',
                      style: const TextStyle(fontSize: 12, color: kTextDim)),
                  trailing:
                      const Icon(Icons.chevron_right, color: kTextDim, size: 20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CountryPage(
                          country: c, allCountries: _countries ?? const []))),
                ),
              );
            },
            ),
          ),
        ),
      ],
    );
  }
}

class CountryPage extends StatefulWidget {
  final Country country;
  final List<Country> allCountries;
  const CountryPage(
      {super.key, required this.country, this.allCountries = const []});

  @override
  State<CountryPage> createState() => _CountryPageState();
}

// Headline macro indicators shown as KPI badges (first available slug wins).
const _headline = <(String, List<String>)>[
  ('GDP per capita', ['imf-gdp-per-capita-ppp', 'imf-gdp-per-capita', 'gapminder-income']),
  ('GDP growth', ['imf-gdp-growth', 'gapminder-gdp-growth']),
  ('Inflation', ['imf-inflation']),
  ('Unemployment', ['imf-unemployment']),
  ('Life expectancy', ['gapminder-life-expectancy']),
  ('Population', ['imf-population', 'gapminder-population']),
];

const _sectionMeta = [('macro', '📊 Statistics'), ('survey', '🗣️ Surveys')];

/// Indicators to feature (in order) when a topic group is collapsed; expanding
/// shows the full alphabetical list. Mirrors the site's CountryPanel PRIORITY:
/// each slot lists fallback slugs and the first available fills it, so the
/// collapsed top-3 stays economically meaningful even when a country is
/// missing a leader (e.g. no Big Mac price for many markets).
const _priority = <String, List<List<String>>>{
  'economy': [
    ['imf-gdp-usd', 'imf-gdp-ppp'],
    ['bigmac-dollar-price'],
    ['findex-digital-payments', 'wb-digital-payments'],
    ['imf-govt-debt'],
    ['imf-current-account'],
    ['imf-fiscal-balance'],
    ['gapminder-gini'],
    ['findex-account-ownership', 'wb-account-ownership'],
    ['imf-world-gdp-share'],
    ['owid-extreme-poverty'],
  ],
  'demographics': [
    ['gapminder-population', 'imf-population'],
    ['gapminder-median-age'],
    ['wb-sp-dyn-tfrt-in'],
    ['gapminder-urban'],
    ['gapminder-density'],
    ['unhcr-refugees'],
  ],
  // Remaining topics: top-3 by prominence in the research literature.
  'connectivity': [
    ['gapminder-internet'],
    ['wb-mobile-subscriptions'],
    ['owid-electricity'],
  ],
  'health': [
    ['gapminder-life-expectancy'],
    ['owid-child-mortality', 'qog-wdi-mortinf'],
    ['qog-wdi-chexppgdp'],
    ['who-obesity'],
    ['who-uhc'],
  ],
  'education': [
    ['owid-schooling'], // HDI component
    ['gapminder-literacy'],
    ['pisa-mathematics', 'qog-wdi-expedu'],
  ],
  'environment': [
    ['wb-en-ghg-co2-pc-ce-ar5'],
    ['owid-renewables'],
    ['gapminder-energy'],
  ],
  'governance': [
    ['v-dem-v2x-polyarchy'], // V-Dem headline index
    ['cpi-corruption-perceptions', 'qog-ti-cpi'],
    ['v-dem-v2x-rule'],
    ['v-dem-v2x-libdem'],
    ['fiw-freedom-score', 'qog-fh-status'],
  ],
  'safety': [
    ['gapminder-homicide'],
    ['who-road-deaths'],
  ],
  'risk': [
    ['inform-risk'],
    ['wri-risk'],
    ['wri-exposure'],
  ],
  'wellbeing': [
    ['gapminder-hdi'],
    ['whr-happiness'],
  ],
};

class _CountryPageState extends State<CountryPage> {
  String? _wiki;
  bool _wikiOpen = false; // Wikipedia blurb collapsed to a few lines
  CountryMeta? _meta; // capital / coat of arms / currency / ISO-2
  final Set<String> _expanded = {}; // 'kind:topic' groups shown in full

  @override
  void initState() {
    super.initState();
    _loadWiki();
    _loadMeta();
  }

  Future<void> _loadWiki() async {
    final s = await fetchWikipediaSummary(widget.country.name);
    if (mounted) setState(() => _wiki = s);
  }

  Future<void> _loadMeta() async {
    try {
      final all = await fetchCountryMeta();
      if (mounted) setState(() => _meta = all[widget.country.iso]);
    } catch (_) {
      // header extras are decorative — the page works without them
    }
  }

  CountryItem? _find(Country c, String slug) {
    for (final it in c.items) {
      if (it.slug == slug) return it;
    }
    return null;
  }

  Widget _kpiBadge(String label, CountryItem it) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showIndicatorTrend(it),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10, color: kTextDim, height: 1.1)),
            const SizedBox(height: 2),
            Text(formatValue(it.value),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kAmber,
                    height: 1.1)),
            Text('#${it.rank} of ${it.total}',
                style: const TextStyle(
                    fontSize: 10, color: kTextDim, height: 1.2)),
          ],
        ),
      ),
    );
  }

  /// Collapsed view of a topic: one row per priority slot (first available
  /// slug wins), padded from the alphabetical list when slots run out.
  List<CountryItem> _collapsedRows(String topic, List<CountryItem> rows) {
    final bySlug = {for (final it in rows) it.slug: it};
    final featured = <CountryItem>[];
    for (final slot in _priority[topic] ?? const <List<String>>[]) {
      for (final s in slot) {
        final it = bySlug[s];
        if (it != null && !featured.contains(it)) {
          featured.add(it);
          break;
        }
      }
      if (featured.length >= 3) break;
    }
    for (final it in rows) {
      if (featured.length >= 3) break;
      if (!featured.contains(it)) featured.add(it);
    }
    return featured.take(3).toList();
  }

  /// Statistics then Surveys, each grouped by topic; every topic shows a
  /// curated top-3 with a "Show all" toggle revealing the full alphabetical
  /// list.
  List<Widget> _sections(List<CountryItem> rest) {
    final out = <Widget>[];
    for (final sec in _sectionMeta) {
      final secItems = rest.where((it) => it.kind == sec.$1).toList();
      if (secItems.isEmpty) continue;
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 2),
        child: Text(sec.$2,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ));
      final byTopic = <String, List<CountryItem>>{};
      for (final it in secItems) {
        byTopic.putIfAbsent(it.topic, () => []).add(it);
      }
      final topics = byTopic.keys.toList()
        ..sort((a, b) => topicRank(a).compareTo(topicRank(b)));
      for (final t in topics) {
        final rows = byTopic[t]!
          ..sort((a, b) => a.title.compareTo(b.title));
        final key = '${sec.$1}:$t';
        final expanded = _expanded.contains(key);
        final shown = expanded ? rows : _collapsedRows(t, rows);
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
          child: Text(topicLabels[t] ?? t,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kAmber,
                  letterSpacing: 0.5)),
        ));
        out.addAll(shown.map((it) =>
            _IndicatorRow(item: it, onTap: () => _showIndicatorTrend(it))));
        if (rows.length > 3) {
          out.add(Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() =>
                  expanded ? _expanded.remove(key) : _expanded.add(key)),
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: kAmber),
              label: Text(expanded ? 'Show less' : 'Show all ${rows.length}',
                  style: const TextStyle(fontSize: 12, color: kAmber)),
            ),
          ));
        }
      }
    }
    return out;
  }

  Widget _codeBadge(String text, {String? tooltip}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }

  /// Coat of arms + official name + ISO/currency badges, like the site's
  /// country card. Renders progressively as [_meta] arrives.
  Widget _header(Country country) {
    final m = _meta;
    final coa = m != null && m.coa.isNotEmpty
        ? Image.network(
            '${m.coa}?width=120',
            width: 52,
            headers: const {'User-Agent': 'BullDozerStats/1.0'},
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coa != null) ...[coa, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (country.official.isNotEmpty &&
                  country.official != country.name)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(country.official,
                      style: const TextStyle(
                          fontSize: 13,
                          color: kTextDim,
                          fontStyle: FontStyle.italic)),
                ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _codeBadge(country.iso, tooltip: 'ISO 3166-1 alpha-3'),
                  if (m != null && m.a2.isNotEmpty)
                    _codeBadge(m.a2, tooltip: 'ISO 3166-1 alpha-2'),
                  if (m != null && m.curCode.isNotEmpty)
                    _codeBadge(
                        '${m.curSymbol.isNotEmpty ? '${m.curSymbol} ' : ''}'
                        '${m.curName} (${m.curCode})',
                        tooltip: 'Currency'),
                  if (m != null && m.capital.isNotEmpty)
                    _codeBadge('🏛️ ${m.capital}', tooltip: 'Capital'),
                ],
              ),
              const SizedBox(height: 6),
              Text('${country.region} · ${country.items.length} indicators',
                  style: const TextStyle(fontSize: 12, color: kTextDim)),
            ],
          ),
        ),
      ],
    );
  }

  /// Time series for this country in [item]'s dataset, shown as a line chart.
  void _showIndicatorTrend(CountryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgElev,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => FutureBuilder<Dataset>(
        future: fetchDataset(item.slug),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator(color: kAmber)));
          }
          final series = (snap.data?.data ?? [])
              .where((o) => o.iso == widget.country.iso)
              .toList()
            ..sort((a, b) => a.period.compareTo(b.period));
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${widget.country.name} · ${item.unit}',
                    style: const TextStyle(fontSize: 12, color: kTextDim)),
                const SizedBox(height: 16),
                if (series.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: Text('No time series available.',
                            style: TextStyle(color: kTextDim))),
                  )
                else
                  TrendChart(
                    points: [for (final o in series) (o.period, o.value)],
                    highlightPeriod: series.last.period,
                  ),
                const SizedBox(height: 12),
                Text('#${item.rank} of ${item.total} · latest ${item.period}',
                    style: const TextStyle(fontSize: 12, color: kTextDim)),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final country = widget.country;
    // Headline macro KPIs (first available slug per row), like the site.
    final headline = <(String, CountryItem)>[];
    final headlineSlugs = <String>{};
    for (final h in _headline) {
      for (final s in h.$2) {
        final it = _find(country, s);
        if (it != null) {
          headline.add((h.$1, it));
          headlineSlugs.add(it.slug);
          break;
        }
      }
    }
    final rest =
        country.items.where((it) => !headlineSlugs.contains(it.slug)).toList();
    final similar = widget.allCountries
        .where((c) => c.region == country.region && c.iso != country.iso)
        .take(12)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${flagFromIso(country.iso)}  ${country.name}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ComparePage(
                    initial: country, allCountries: widget.allCountries))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Map zoomed to and highlighting the country, capital marked.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Choropleth(
              values: {country.iso: 1},
              highlightIso: country.iso,
              zoomIso: country.iso,
              capital: _meta?.capX != null
                  ? CapitalMarker(_meta!.capital, _meta!.capX!, _meta!.capY!)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          _header(country),
          if (headline.isNotEmpty) ...[
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.85, // compact: label + value + rank, no air
              children: [for (final h in headline) _kpiBadge(h.$1, h.$2)],
            ),
          ],
          if (_wiki != null) ...[
            const SizedBox(height: 12),
            // Collapsed to a few lines; the chevron reveals the full blurb.
            InkWell(
              onTap: () => setState(() => _wikiOpen = !_wikiOpen),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_wiki!,
                        maxLines: _wikiOpen ? null : 4,
                        overflow: _wikiOpen ? null : TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.45)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Wikipedia',
                            style: TextStyle(fontSize: 10, color: kTextDim)),
                        const Spacer(),
                        Icon(
                            _wikiOpen
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                            color: kAmber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          ..._sections(rest),
          if (similar.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 18, 0, 8),
              child: Text('More countries',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kAmber)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in similar)
                  ActionChip(
                    label: Text('${flagFromIso(c.iso)} ${c.name}',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => CountryPage(
                                country: c,
                                allCountries: widget.allCountries))),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final CountryItem item;
  final VoidCallback? onTap;
  const _IndicatorRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final topThird = item.total > 0 && item.rank <= item.total / 3;
    final bottomThird = item.total > 0 && item.rank > item.total * 2 / 3;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${item.period} · ${item.unit}',
                      style: const TextStyle(fontSize: 11, color: kTextDim)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatValue(item.value),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text('#${item.rank} of ${item.total}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: topThird
                            ? kUp
                            : bottomThird
                                ? kDown
                                : kTextDim)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.show_chart, size: 16, color: kTextDim),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
