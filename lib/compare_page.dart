import 'package:flutter/material.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'theme.dart';

const _maxCountries = 5;

/// Compare up to 5 countries on one indicator — ranked bars of their latest
/// values. Reached from a country profile (that country is pre-selected).
class ComparePage extends StatefulWidget {
  final Country? initial;
  final List<Country> allCountries;
  const ComparePage({super.key, this.initial, this.allCountries = const []});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final List<Country> _selected = [];
  CatalogEntry? _indicator;
  Dataset? _ds;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _selected.add(widget.initial!);
    // Default indicator: the first one on the initial country, else catalog[0].
    final slug = widget.initial?.items.isNotEmpty == true
        ? widget.initial!.items.first.slug
        : (catalog.isNotEmpty ? catalog.first.slug : null);
    _indicator = slug != null ? catalogBySlug[slug] : null;
    if (_indicator != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ds = await fetchDataset(_indicator!.slug);
      if (mounted) setState(() => _ds = ds);
    } catch (_) {
      // leave _ds null — the body shows a hint
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _latest(String iso) {
    final rows = (_ds?.data ?? []).where((o) => o.iso == iso).toList();
    if (rows.isEmpty) return null;
    rows.sort((a, b) => a.period.compareTo(b.period));
    return rows.last.value;
  }

  void _pickIndicator() {
    _showSearchSheet<CatalogEntry>(
      title: 'Choose an indicator',
      items: catalog,
      label: (e) => e.title,
      sub: (e) => e.source,
      onPick: (e) {
        setState(() => _indicator = e);
        _load();
      },
    );
  }

  void _addCountry() {
    final pool = widget.allCountries
        .where((c) => !_selected.any((s) => s.iso == c.iso))
        .toList();
    _showSearchSheet<Country>(
      title: 'Add a country',
      items: pool,
      label: (c) => c.name,
      sub: (c) => c.region,
      onPick: (c) => setState(() => _selected.add(c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rows sorted by value desc; countries without data go last.
    final rows = _selected
        .map((c) => (c, _latest(c.iso)))
        .toList()
      ..sort((a, b) => (b.$2 ?? -1e30).compareTo(a.$2 ?? -1e30));
    final maxAbs = rows
        .map((r) => (r.$2 ?? 0).abs())
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Indicator selector
          InkWell(
            onTap: _pickIndicator,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: kAmber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_indicator?.title ?? 'Choose an indicator',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        if (_indicator != null)
                          Text('${_indicator!.source} · ${_indicator!.unit}',
                              style: const TextStyle(
                                  fontSize: 11, color: kTextDim)),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more, color: kTextDim),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Country chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _selected)
                InputChip(
                  label: Text(c.name, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => _selected.remove(c)),
                  deleteIconColor: kTextDim,
                ),
              if (_selected.length < _maxCountries &&
                  widget.allCountries.isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: kAmber),
                  label: const Text('Add country',
                      style: TextStyle(fontSize: 12)),
                  onPressed: _addCountry,
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: kAmber)),
            )
          else if (_indicator == null)
            const _Hint('Pick an indicator to compare.')
          else if (_ds == null)
            const _Hint('Couldn\'t load this indicator.')
          else if (_selected.isEmpty)
            const _Hint('Add countries to compare.')
          else
            for (final r in rows)
              _CompareBar(
                name: r.$1.name,
                value: r.$2,
                unit: _indicator!.unit,
                fraction: maxAbs == 0 || r.$2 == null
                    ? 0
                    : (r.$2!.abs() / maxAbs),
                negative: (r.$2 ?? 0) < 0,
              ),
        ],
      ),
    );
  }

  void _showSearchSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required String Function(T) sub,
    required void Function(T) onPick,
  }) {
    String query = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgElev,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = query.toLowerCase();
          final shown = items
              .where((e) => q.isEmpty || label(e).toLowerCase().contains(q))
              .take(80)
              .toList();
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: kTextDim),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setSheet(() => query = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search…',
                        hintStyle:
                            const TextStyle(color: kTextDim, fontSize: 14),
                        prefixIcon:
                            const Icon(Icons.search, color: kTextDim, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: kBgCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: kBorder, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: kBorder, width: 0.5),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(label(shown[i]),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(sub(shown[i]),
                            style: const TextStyle(
                                fontSize: 12, color: kTextDim)),
                        onTap: () {
                          Navigator.pop(ctx);
                          onPick(shown[i]);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompareBar extends StatelessWidget {
  final String name;
  final double? value;
  final String unit;
  final double fraction;
  final bool negative;
  const _CompareBar({
    required this.name,
    required this.value,
    required this.unit,
    required this.fraction,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(value == null ? 'no data' : formatValue(value!),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value == null ? kTextDim : kText)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: negative ? kDown : kAmber,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: Text(text,
                style: const TextStyle(color: kTextDim), textAlign: TextAlign.center)),
      );
}
