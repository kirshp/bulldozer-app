import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'theme.dart';

/// Edu tab — mirrors the site's /edu section: a field guide to dashboards,
/// BI-tool comparison, how the pipeline works and curated places to learn.
/// Content lives on the site; cards deep-link into its anchored sections.
class EduPage extends StatelessWidget {
  const EduPage({super.key});

  void _open(String path) {
    launchUrl(Uri.parse('$kBaseUrl$path'), mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    const sections = <(String, String, String, String)>[
      (
        '📊',
        'A field guide to dashboards',
        'Six kinds of dashboard — KPI, operational, analytical, strategic, data story, geospatial — and when to use each.',
        '/edu/#types',
      ),
      (
        '🛠️',
        'BI tools, honestly compared',
        'Tableau, Power BI, Looker Studio, Metabase, Superset and friends — strengths, limits, pricing.',
        '/edu/#tools',
      ),
      (
        '⚙️',
        'How BullDozer is built',
        'Parse → normalise → publish: the open pipeline behind every chart in this app.',
        '/edu/#pipeline',
      ),
      (
        '🎓',
        'Free places to learn',
        'Dataviz craft, SQL practice, scraping and the best public data journalism, hand-picked.',
        '/edu/#learn',
      ),
      (
        '📖',
        'Glossary — metric reference',
        'What GDP PPP, Gini, HDI, polyarchy and every other metric in the app actually mean.',
        '/glossary',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Edu', style: pageTitleStyle),
        const SizedBox(height: 4),
        Text('Learn to read — and build — data like this.',
            style: TextStyle(fontSize: 12, color: kTextDim)),
        const SizedBox(height: 12),
        for (final s in sections)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => _open(s.$4),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2)),
                          const SizedBox(height: 4),
                          Text(s.$3,
                              style: TextStyle(
                                  fontSize: 12, color: kTextDim, height: 1.35)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 6, top: 2),
                      child: Icon(Icons.north_east, color: kTextDim, size: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: Text('Reads on the site · shpara.com/bulldozer/edu',
              style: TextStyle(fontSize: 11, color: kTextDim)),
        ),
      ],
    );
  }
}
