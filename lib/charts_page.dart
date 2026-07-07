import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'flags.dart';
import 'theme.dart';
import 'widgets/choropleth.dart';
import 'widgets/featured_card.dart';
import 'widgets/trend_chart.dart';

// Topic taxonomy mirrors the site's lib/topics.ts
/// Alphabetical key for a topic — the display label without its emoji prefix.
String topicSortKey(String t) =>
    (topicLabels[t] ?? t).replaceFirst(RegExp(r'^\S+\s'), '');

const topicLabels = {
  'attitudes': '🧭 Attitudes & values',
  'connectivity': '🌐 Connectivity',
  'demographics': '👥 Demographics',
  'economy': '📈 Economy',
  'education': '🎓 Education',
  'environment': '🌱 Environment',
  'governance': '🏛️ Governance',
  'health': '🫀 Health',
  'media': '📰 Media & news',
  'risk': '⚠️ Risk & resilience',
  'safety': '🛡️ Safety',
  'wellbeing': '😊 Wellbeing',
};

/// The site's Biz section (/markets): markets + financial-access indicators.
const bizSlugs = [
  'wb-market-cap',
  'forbes-global-2000',
  'brandz-value',
  'brandz-count',
  'wb-stocks-traded',
  'wb-listed-companies',
  'wb-account-ownership',
  'wb-digital-payments',
  'wb-mobile-money',
  'wb-debit-card',
  'wb-bank-branches',
];

/// One dataset list tab. Mirrors the site's sections: kind 'macro' →
/// Statistics (/macro), kind 'survey' → Polls (/surveys), or an explicit
/// curated [slugs] list → Biz (/markets).
class ChartsPage extends StatefulWidget {
  final String title;
  final String? kind; // 'macro' | 'survey'
  final List<String>? slugs; // curated set, overrides kind (Biz)
  final String? featuredSlug; // dataset shown as a featured hero on top
  const ChartsPage(
      {super.key,
      required this.title,
      this.kind,
      this.slugs,
      this.featuredSlug});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String _query = '';
  String _topic = 'all';
  List<Observation> _featTop = [];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final slug = widget.featuredSlug;
    if (slug == null) return;
    try {
      final ds = await fetchDataset(slug);
      final last = ds.periods.last;
      final rows = ds.data.where((o) => o.period == last).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (mounted) setState(() => _featTop = rows.take(6).toList());
    } catch (_) {
      // hero is decorative
    }
  }

  @override
  Widget build(BuildContext context) {
    final pool = widget.slugs != null
        ? widget.slugs!
            .map((s) => catalogBySlug[s])
            .whereType<CatalogEntry>()
            .toList()
        : catalog.where((e) => e.kind == widget.kind).toList();
    final q = _query.toLowerCase();
    final shown = pool
        .where((e) => _topic == 'all' || e.topic == _topic)
        .where((e) =>
            q.isEmpty ||
            e.title.toLowerCase().contains(q) ||
            e.source.toLowerCase().contains(q))
        .toList();
    final topics = {for (final e in pool) e.topic}.toList()
      ..sort((a, b) => topicSortKey(a).compareTo(topicSortKey(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(widget.title, style: pageTitleStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search ${pool.length} indicators…',
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
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (final t in ['all', ...topics])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(t == 'all' ? 'All' : topicLabels[t] ?? t),
                    selected: _topic == t,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _topic == t ? kBg : kText),
                    onSelected: (_) => setState(() => _topic = t),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            final featEntry = widget.featuredSlug != null
                ? catalogBySlug[widget.featuredSlug]
                : null;
            final showFeatured = featEntry != null &&
                _featTop.isNotEmpty &&
                _query.isEmpty &&
                _topic == 'all';
            final headers = showFeatured ? 1 : 0;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: shown.length + headers,
              itemBuilder: (_, idx) {
                if (showFeatured && idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: FeaturedCard(
                      tag: 'Featured · ${featEntry.source}',
                      title: '${_featTop.first.entity} tops ${featEntry.title}',
                      bars: [
                        for (final o in _featTop)
                          ('${flagFromIso(o.iso)} ${o.entity}', o.value)
                      ],
                      footer: 'See the full ranking →',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => DatasetPage(entry: featEntry))),
                    ),
                  );
                }
                final e = shown[idx - headers];
                return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  title: Text(e.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${topicLabels[e.topic] ?? e.topic} · ${e.source}',
                    style: const TextStyle(fontSize: 12, color: kTextDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: kTextDim, size: 20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DatasetPage(entry: e))),
                ),
              );
              },
            );
          }),
        ),
      ],
    );
  }
}

class DatasetPage extends StatefulWidget {
  final CatalogEntry entry;
  const DatasetPage({super.key, required this.entry});

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  Dataset? _ds;
  String? _error;
  String? _period;
  bool _mapView = false;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = await fetchDataset(widget.entry.slug);
      setState(() {
        _ds = ds;
        _period = ds.periods.isEmpty ? null : ds.periods.last;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Couldn\'t load data.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextDim)),
            ))
          : _ds == null
              ? const Center(child: CircularProgressIndicator(color: kAmber))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final ds = _ds!;
    final rows = ds.data.where((o) => o.period == _period).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = _showAll ? rows : rows.take(20).toList();
    final maxV = rows.isEmpty
        ? 1.0
        : rows.map((o) => o.value.abs()).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(ds.summary,
            style: const TextStyle(fontSize: 13, color: kTextDim, height: 1.4)),
        const SizedBox(height: 6),
        Text('${ds.source} · ${ds.license} · ${ds.unit}',
            style: const TextStyle(fontSize: 11, color: kTextDim)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [
            for (final p in ds.periods)
              ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                selected: _period == p,
                showCheckmark: false,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _period == p ? kBg : kText),
                onSelected: (_) => setState(() => _period = p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Bars / Map view toggle.
        Row(
          children: [
            _ViewToggle(
                icon: Icons.bar_chart,
                label: 'Bars',
                selected: !_mapView,
                onTap: () => setState(() => _mapView = false)),
            const SizedBox(width: 8),
            _ViewToggle(
                icon: Icons.public,
                label: 'Map',
                selected: _mapView,
                onTap: () => setState(() => _mapView = true)),
          ],
        ),
        const SizedBox(height: 12),
        if (_mapView) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Choropleth(
              values: {
                for (final o in rows)
                  if (o.iso.isNotEmpty) o.iso: o.value
              },
              onTap: (iso, name) {
                final match = rows.where((o) => o.iso == iso);
                if (match.isNotEmpty) _showTrend(match.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Tap a country for its trend · $_period · ${ds.unit}',
              style: const TextStyle(fontSize: 11, color: kTextDim)),
        ] else ...[
          for (var i = 0; i < shown.length; i++)
            _BarRow(
              rank: i + 1,
              obs: shown[i],
              fraction: maxV == 0 ? 0 : (shown[i].value.abs() / maxV),
              negative: shown[i].value < 0,
              onTap: () => _showTrend(shown[i]),
            ),
          if (!_showAll && rows.length > 20)
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text('Show all ${rows.length}',
                  style: const TextStyle(color: kAmber)),
            ),
        ],
      ],
    );
  }

  void _showTrend(Observation obs) {
    final ds = _ds!;
    final series = ds.data.where((o) => o.entity == obs.entity).toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgElev,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(obs.entity,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${ds.title} · ${ds.unit}',
                style: const TextStyle(fontSize: 12, color: kTextDim)),
            const SizedBox(height: 16),
            TrendChart(
              points: [for (final o in series) (o.period, o.value)],
              highlightPeriod: obs.period,
            ),
            const SizedBox(height: 12),
            if (series.length >= 2)
              _TrendSummary(first: series.first, last: series.last),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final int rank;
  final Observation obs;
  final double fraction;
  final bool negative;
  final VoidCallback onTap;
  const _BarRow(
      {required this.rank,
      required this.obs,
      required this.fraction,
      required this.negative,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 26,
                child: Text('$rank',
                    style: const TextStyle(fontSize: 11, color: kTextDim))),
            SizedBox(
              width: 110,
              child: Text(obs.entity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _Bar(fraction: fraction, color: negative ? kDown : kAmber)),
            const SizedBox(width: 8),
            SizedBox(
                width: 58,
                child: Text(formatValue(obs.value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double fraction;
  final Color color;
  const _Bar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.02, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}

/// First→last period with the net change, colour-coded up/down.
class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ViewToggle(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? kAmber : kBgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? kAmber : kBorder, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? kBg : kTextDim),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? kBg : kText)),
          ],
        ),
      ),
    );
  }
}

class _TrendSummary extends StatelessWidget {
  final Observation first;
  final Observation last;
  const _TrendSummary({required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    final change = last.value - first.value;
    final up = change >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${first.period} → ${last.period}',
            style: const TextStyle(fontSize: 12, color: kTextDim)),
        Row(
          children: [
            Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14, color: up ? kUp : kDown),
            const SizedBox(width: 2),
            Text('${up ? '+' : ''}${formatValue(change)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: up ? kUp : kDown)),
          ],
        ),
      ],
    );
  }
}
