import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'explore_page.dart';
import 'flags.dart';
import 'widgets/featured_card.dart';
import 'countries_page.dart';
import 'quiz_page.dart';
import 'theme.dart';

void main() {
  runApp(const BulldozerApp());
  loadCatalog(); // refresh the dataset catalog from the site (cached, non-blocking)
}

class BulldozerApp extends StatelessWidget {
  const BulldozerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BullDozer',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Tabs mirror the site's main sections: Stats (/macro), Biz (/markets),
    // Polls (/surveys), Geo (/geo, country profiles), quiz. Rebuilt when the
    // live catalog arrives (non-const) so new datasets show up.
    return Scaffold(
      endDrawer: _buildMenu(context),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: catalogNotifier,
          builder: (_, _, _) => IndexedStack(
            index: _tab,
            children: [
              HomePage(onGoToTab: (i) => setState(() => _tab = i)),
              ChartsPage(
                  key: ValueKey('stats${catalog.length}'),
                  title: 'Statistics',
                  kind: 'macro',
                  featuredSlug: 'gapminder-life-expectancy'),
              ChartsPage(
                  key: ValueKey('biz${catalog.length}'),
                  title: 'Business & markets',
                  slugs: bizSlugs,
                  featuredSlug: 'wb-market-cap'),
              ChartsPage(
                  key: ValueKey('polls${catalog.length}'),
                  title: 'Polls',
                  kind: 'survey',
                  featuredSlug: 'afro-democracy-support'),
              const CountriesPage(),
              const QuizPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.business_center_outlined), label: 'Biz'),
          NavigationDestination(
              icon: Icon(Icons.how_to_vote_outlined), label: 'Polls'),
          NavigationDestination(
              icon: Icon(Icons.public_outlined), label: 'Geo'),
          NavigationDestination(
              icon: Icon(Icons.extension_outlined), label: 'Quiz'),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Drawer(
      backgroundColor: kBgElev,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: Row(
                children: [
                  brandMark(36),
                  const SizedBox(width: 10),
                  brandWordmark,
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: brandTagline,
            ),
            const Divider(color: kBorder, height: 1),
            _menuItem(context, Icons.home_outlined, 'Home', 0),
            _menuItem(context, Icons.bar_chart_outlined, 'Statistics', 1),
            _menuItem(
                context, Icons.business_center_outlined, 'Business & markets', 2),
            _menuItem(context, Icons.how_to_vote_outlined, 'Polls', 3),
            _menuItem(context, Icons.public_outlined, 'Countries', 4),
            _menuItem(context, Icons.extension_outlined, 'Country Quiz', 5),
            const Divider(color: kBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.scatter_plot_outlined,
                  color: kAmber, size: 22),
              title: const Text('Explore — X vs Y',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ExplorePage()));
              },
            ),
            _linkItem(context, Icons.school_outlined,
                'Learn — data & BI tools', '/edu'),
            _linkItem(context, Icons.menu_book_outlined,
                'Glossary — metric reference', '/glossary'),
            _linkItem(
                context, Icons.open_in_new, 'Open full website', '/'),
            ListTile(
              leading: const Icon(Icons.mail_outline, color: kTextDim, size: 22),
              title: const Text('Contact developer',
                  style: TextStyle(fontSize: 15, color: kText)),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                    Uri.parse(
                        'mailto:azenha.agent@gmail.com?subject=BullDozer%20Stats'),
                    mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: kTextDim, size: 22),
              title: const Text('About',
                  style: TextStyle(fontSize: 15, color: kText)),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'BullDozer Stats',
                  applicationVersion: '1.4.0',
                  applicationIcon: brandMark(40),
                  children: const [
                    Text(
                        'The world in numbers — public, parsed datasets on economy, '
                        'markets, governance, wellbeing and more. '
                        'Data from shpara.com/bulldozer.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // A drawer row that opens a BullDozer website section in the browser.
  Widget _linkItem(
      BuildContext context, IconData icon, String label, String path) {
    return ListTile(
      leading: Icon(icon, color: kTextDim, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15, color: kText)),
      trailing: const Icon(Icons.north_east, color: kTextDim, size: 15),
      onTap: () {
        Navigator.pop(context);
        launchUrl(Uri.parse('$kBaseUrl$path'),
            mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, int tab) {
    final selected = _tab == tab;
    return ListTile(
      leading:
          Icon(icon, color: selected ? kAmber : kTextDim, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? kAmber : kText)),
      selected: selected,
      onTap: () {
        setState(() => _tab = tab);
        Navigator.pop(context);
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(int) onGoToTab;
  const HomePage({super.key, required this.onGoToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Observation> _happyTop = [];
  List<Story> _stories = [];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadStories();
  }

  Future<void> _loadFeatured() async {
    try {
      final ds = await fetchDataset('whr-happiness');
      final last = ds.periods.last;
      final rows = ds.data.where((o) => o.period == last).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (mounted) setState(() => _happyTop = rows.take(6).toList());
    } catch (_) {
      // featured bars are decorative — home works without them
    }
  }

  Future<void> _loadStories() async {
    try {
      final s = await fetchStories();
      if (mounted) setState(() => _stories = s);
    } catch (_) {
      // stories feed is best-effort
    }
  }

  void _openStory(String slug) {
    launchUrl(Uri.parse('$kBaseUrl/stories/$slug'),
        mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    final topics = {for (final e in catalog) e.topic}.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            // Brand mark + two-tone wordmark — same logo as the site and icon.
            brandMark(40),
            const SizedBox(width: 10),
            brandWordmark,
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('beta',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kAmber)),
            ),
            // Hamburger — opens the menu drawer from the right.
            IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.menu, color: kText),
              tooltip: 'Menu',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),
        brandTagline,
        const SizedBox(height: 16),
        // Featured data story — a rich block with a mini ranked chart.
        FeaturedCard(
          tag: 'Featured · World Happiness Report',
          title: _happyTop.isEmpty
              ? 'The world’s happiest countries'
              : '${_happyTop.first.entity} leads the happiness ranking',
          bars: [
            for (final o in _happyTop)
              ('${flagFromIso(o.iso)} ${o.entity}', o.value)
          ],
          footer: 'Read the story →',
          onTap: () => _openStory('happiest-countries'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatBox(value: '${catalog.length}', label: 'indicators'),
            const SizedBox(width: 8),
            _StatBox(value: '$topics', label: 'topics'),
            const SizedBox(width: 8),
            const _StatBox(value: '190+', label: 'countries'),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Text('📰 ', style: TextStyle(fontSize: 15)),
            Text('Data stories',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Visual stories built on public data.',
            style: TextStyle(fontSize: 12, color: kTextDim)),
        const SizedBox(height: 10),
        if (_stories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(color: kAmber, strokeWidth: 2)),
          )
        else
          for (final s in _stories.where((s) => s.slug != 'happiest-countries'))
            _StoryCard(story: s, onTap: () => _openStory(s.slug)),
        const SizedBox(height: 16),
        const Center(
          child: Text('Open data · full site at shpara.com/bulldozer',
              style: TextStyle(fontSize: 11, color: kTextDim)),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  const _StoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(story.tag.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: kAmber)),
              const SizedBox(height: 5),
              Text(story.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 4),
              Text(story.dek,
                  style: const TextStyle(
                      fontSize: 12, color: kTextDim, height: 1.35)),
              const SizedBox(height: 8),
              const Text('Read on the site ↗',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: kAmber)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: kAmber)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: kTextDim)),
          ],
        ),
      ),
    );
  }
}

