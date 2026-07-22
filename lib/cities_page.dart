import 'package:flutter/material.dart';

import 'api.dart';
import 'flags.dart';
import 'theme.dart';

/// City-livability rankings (mirrors the site's /cities). One metric at a
/// time, switchable via chips; ranked bar list of cities.
class CitiesPage extends StatefulWidget {
  const CitiesPage({super.key});
  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  CitiesData? _data;
  String? _error;
  int _metric = 0;

  @override
  void initState() {
    super.initState();
    fetchCities().then((d) {
      if (mounted) setState(() => _data = d);
    }).catchError((e) {
      if (mounted) setState(() => _error = '$e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Best cities',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Couldn\'t load cities.\n$_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextDim))))
          : _data == null
              ? Center(child: CircularProgressIndicator(color: kAmber))
              : _body(_data!),
    );
  }

  Widget _body(CitiesData d) {
    if (d.metrics.isEmpty) {
      return Center(
          child: Text('No city data.', style: TextStyle(color: kTextDim)));
    }
    final m = d.metrics[_metric.clamp(0, d.metrics.length - 1)];
    final rows = [...m.data]..sort((a, b) => b.value.compareTo(a.value));
    final maxV = rows.isEmpty
        ? 1.0
        : rows.map((c) => c.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // metric chips
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (var i = 0; i < d.metrics.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(d.metrics[i].label),
                    selected: _metric == i,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _metric == i ? kBg : kText),
                    onSelected: (_) => setState(() => _metric = i),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(m.summary,
              style: TextStyle(fontSize: 12, color: kTextDim, height: 1.35)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final c = rows[i];
              final frac = maxV == 0 ? 0.0 : c.value / maxV;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                        width: 24,
                        child: Text('${i + 1}',
                            style: TextStyle(fontSize: 11, color: kTextDim))),
                    SizedBox(
                      width: 120,
                      child: Text('${flagFromIso2(c.cc)} ${c.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                            color: kBgCard,
                            borderRadius: BorderRadius.circular(5)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: frac.clamp(0.03, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                                color: kAmber,
                                borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 44,
                        child: Text(c.value.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
