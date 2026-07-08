import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'catalog_store.dart';
import 'charts_page.dart';
import 'edu_page.dart';
import 'explore_page.dart';
import 'favorites_store.dart';
import 'flags.dart';
import 'notify.dart';
import 'widgets/choropleth.dart';
import 'widgets/featured_card.dart';
import 'countries_page.dart';
import 'quiz_page.dart';
import 'search_page.dart';
import 'theme.dart';

void main() {
  runApp(const BulldozerApp());
  loadCatalog(); // refresh the dataset catalog from the site (cached, non-blocking)
  loadFavorites(); // starred countries/indicators from disk
  initNotify(); // local release reminders (Ativa-style, no push server)
  loadTheme(); // light/dark preference from disk
}

class BulldozerApp extends StatelessWidget {
  const BulldozerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole tree on theme toggle — the k-colors are getters
    // backed by themeNotifier, same palettes as the site.
    return ValueListenableBuilder(
      valueListenable: themeNotifier,
      builder: (_, _, _) => MaterialApp(
        title: 'BullDozer',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // new key on toggle → the whole tree rebuilds with the new palette
        home: HomeShell(key: ValueKey(isLight)),
      ),
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
                  featuredSlug: 'gapminder-life-expectancy',
                  featuredStyle: 'trend'),
              ChartsPage(
                  key: ValueKey('biz${catalog.length}'),
                  title: 'Business & markets',
                  slugs: bizSlugs,
                  featuredSlug: 'wb-market-cap'),
              ChartsPage(
                  key: ValueKey('polls${catalog.length}'),
                  title: 'Polls',
                  kind: 'survey',
                  featuredSlug: 'afro-democracy-support',
                  featuredStyle: 'dots'),
              const CountriesPage(),
              const EduPage(),
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
              icon: Icon(Icons.school_outlined), label: 'Edu'),
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
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: brandTagline,
            ),
            Divider(color: kBorder, height: 1),
            _menuItem(context, Icons.home_outlined, 'Home', 0),
            _menuItem(context, Icons.bar_chart_outlined, 'Statistics', 1),
            _menuItem(
                context, Icons.business_center_outlined, 'Business & markets', 2),
            _menuItem(context, Icons.how_to_vote_outlined, 'Polls', 3),
            _menuItem(context, Icons.public_outlined, 'Countries', 4),
            _menuItem(context, Icons.school_outlined, 'Edu', 5),
            Divider(color: kBorder, height: 1),
            ListTile(
              leading: Text(isLight ? '🌙' : '☀️',
                  style: const TextStyle(fontSize: 18)),
              title: Text(isLight ? 'Dark theme' : 'Light theme',
                  style: TextStyle(fontSize: 15, color: kText)),
              onTap: () {
                Navigator.pop(context);
                toggleTheme();
              },
            ),
            ListTile(
              leading: Icon(Icons.scatter_plot_outlined,
                  color: kAmber, size: 22),
              title: Text('Explore — X vs Y',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ExplorePage()));
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.extension_outlined, color: kAmber, size: 22),
              title: Text('Country Quiz',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: kText)),
              onTap: () {
                Navigator.pop(context);
                openQuiz(context);
              },
            ),
            _linkItem(context, Icons.menu_book_outlined,
                'Glossary — metric reference', '/glossary'),
            _linkItem(
                context, Icons.open_in_new, 'Open full website', '/'),
            ListTile(
              leading: Icon(Icons.code, color: kTextDim, size: 22),
              title: Text('GitHub — app source',
                  style: TextStyle(fontSize: 15, color: kText)),
              trailing: Icon(Icons.north_east, color: kTextDim, size: 15),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('https://github.com/kirshp/bulldozer-app'),
                    mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: Icon(Icons.mail_outline, color: kTextDim, size: 22),
              title: Text('Contact developer',
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
              leading: Icon(Icons.info_outline, color: kTextDim, size: 22),
              title: Text('About',
                  style: TextStyle(fontSize: 15, color: kText)),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'BullDozer Stats',
                  applicationVersion: '1.13.0',
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
      title: Text(label, style: TextStyle(fontSize: 15, color: kText)),
      trailing: Icon(Icons.north_east, color: kTextDim, size: 15),
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

/// Opens the country quiz as its own screen (it used to be a tab, so it has
/// no Scaffold of its own).
void openQuiz(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(
          title: const Text('Country Quiz',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
      body: const SafeArea(child: QuizPage()),
    ),
  ));
}

class HomePage extends StatefulWidget {
  final void Function(int) onGoToTab;
  const HomePage({super.key, required this.onGoToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Observation> _happyTop = [];
  Map<String, double> _happyValues = {}; // full map for the choropleth hero
  List<Story> _stories = [];
  List<Release> _releases = [];
  List<Country> _countries = []; // resolves starred ISOs to country objects

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadStories();
    _loadReleases();
    favoritesNotifier.addListener(_maybeLoadCountries);
    _maybeLoadCountries();
  }

  Future<void> _loadReleases() async {
    try {
      final r = await fetchReleases();
      // soonest upcoming release month first
      int dist(Release x) => x.months.isEmpty
          ? 99
          : x.months
              .map((m) => (m - DateTime.now().month + 12) % 12)
              .reduce((a, b) => a < b ? a : b);
      r.sort((a, b) => dist(a).compareTo(dist(b)));
      if (mounted) setState(() => _releases = r);
    } catch (_) {
      // calendar is best-effort
    }
  }

  /// Bell tap: schedule or cancel a local reminder for this release.
  Future<void> _toggleReminder(Release r) async {
    final messenger = ScaffoldMessenger.of(context);
    if (hasReminder(r.name)) {
      await cancelReminder(r.name);
      messenger.showSnackBar(
          SnackBar(content: Text('Reminder off — ${r.name}')));
    } else {
      final ok = await setReminder(r.name, r.months);
      messenger.showSnackBar(SnackBar(
          content: Text(ok
              ? 'Will remind when ${r.name} is due (${r.window})'
              : 'Couldn\'t set a reminder — check notification permission')));
    }
  }

  @override
  void dispose() {
    favoritesNotifier.removeListener(_maybeLoadCountries);
    super.dispose();
  }

  /// The country index is only needed to render starred-country chips —
  /// fetch it lazily the first time a country is starred.
  void _maybeLoadCountries() {
    if (favoritesNotifier.value.countries.isEmpty || _countries.isNotEmpty) {
      return;
    }
    fetchCountryIndex().then((list) {
      list.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() => _countries = list);
    }).catchError((_) {});
  }

  Future<void> _loadFeatured() async {
    try {
      final ds = await fetchDataset('whr-happiness');
      final last = ds.periods.last;
      final rows = ds.data.where((o) => o.period == last).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (mounted) {
        setState(() {
          _happyTop = rows.take(6).toList();
          _happyValues = {
            for (final o in rows)
              if (o.iso.isNotEmpty) o.iso: o.value
          };
        });
      }
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

  /// Pull-to-refresh: re-fetch everything this screen shows (network-first,
  /// so a pull picks up new stories/datasets published on the site).
  Future<void> _refresh() =>
      Future.wait(
          [loadCatalog(), _loadFeatured(), _loadStories(), _loadReleases()]);

  @override
  Widget build(BuildContext context) {
    final topics = {for (final e in catalog) e.topic}.length;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: kAmber,
      backgroundColor: kBgCard,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
              child: Text('beta',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kAmber)),
            ),
            // Light/dark toggle — same sun as the site header.
            IconButton(
              onPressed: toggleTheme,
              icon: Text(isLight ? '🌙' : '☀️',
                  style: const TextStyle(fontSize: 18)),
              tooltip: 'Toggle light/dark theme',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            // Global search — countries and indicators from one field.
            IconButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchPage())),
              icon: Icon(Icons.search, color: kText),
              tooltip: 'Search',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            // Hamburger — opens the menu drawer from the right.
            IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: Icon(Icons.menu, color: kText),
              tooltip: 'Menu',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),
        brandTagline,
        const SizedBox(height: 16),
        // Featured data story — the happiness ranking as a world map.
        HeroShell(
          tag: 'Featured · World Happiness Report',
          title: _happyTop.isEmpty
              ? 'The world’s happiest countries'
              : '${_happyTop.first.entity} leads the happiness ranking',
          footer: 'Read the story →',
          onTap: () => _openStory('happiest-countries'),
          child: _happyValues.isEmpty
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Choropleth(values: _happyValues),
                ),
        ),
        const SizedBox(height: 10),
        // Country quiz entry — a bright amber strip so it pops off the feed.
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => openQuiz(context),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [kAmber, kOrange],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Text('🧩', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Country Quiz',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: kBg)),
                          Text('Guess the country from its data',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xB3000000))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Play',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: kAmber)),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        // Starred countries & indicators — shown once anything is starred.
        ValueListenableBuilder(
          valueListenable: favoritesNotifier,
          builder: (_, favs, _) {
            if (favs.countries.isEmpty && favs.datasets.isEmpty) {
              return const SizedBox.shrink();
            }
            final favCountries = [
              for (final c in _countries)
                if (favs.countries.contains(c.iso)) c
            ];
            final favDatasets = [
              for (final slug in favs.datasets)
                if (catalogBySlug[slug] != null) catalogBySlug[slug]!
            ]..sort((a, b) => a.title.compareTo(b.title));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Text('⭐ ', style: TextStyle(fontSize: 15)),
                    Text('Favorites',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                if (favCountries.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in favCountries)
                        ActionChip(
                          label: Text('${flagFromIso(c.iso)} ${c.name}',
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => CountryPage(
                                      country: c,
                                      allCountries: _countries))),
                        ),
                    ],
                  ),
                if (favDatasets.isNotEmpty) ...[
                  if (favCountries.isNotEmpty) const SizedBox(height: 8),
                  for (final e in favDatasets)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        dense: true,
                        leading:
                            Icon(Icons.star, color: kAmber, size: 18),
                        title: Text(e.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        trailing: Icon(Icons.chevron_right,
                            color: kTextDim, size: 20),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => DatasetPage(entry: e))),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
        // Upcoming data releases — bell schedules a local reminder (like
        // Ativa's event reminders; no push server needed).
        if (_releases.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Row(
            children: [
              Text('📅 ', style: TextStyle(fontSize: 15)),
              Text('Data releases',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Tap the bell to get a reminder when new data is due.',
              style: TextStyle(fontSize: 12, color: kTextDim)),
          const SizedBox(height: 8),
          ValueListenableBuilder(
            valueListenable: reminders,
            builder: (_, rems, _) => Column(
              children: [
                for (final r in _releases.take(4))
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      dense: true,
                      title: Text(r.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${r.window} · ${r.kind == 'survey' ? 'survey' : 'macro'}',
                          style: TextStyle(
                              fontSize: 11, color: kTextDim)),
                      trailing: IconButton(
                        icon: Icon(
                            rems.contains(r.name)
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: rems.contains(r.name) ? kAmber : kTextDim,
                            size: 22),
                        onPressed: () => _toggleReminder(r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Row(
          children: [
            Text('📰 ', style: TextStyle(fontSize: 15)),
            Text('Data stories',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Visual stories built on public data.',
            style: TextStyle(fontSize: 12, color: kTextDim)),
        const SizedBox(height: 10),
        if (_stories.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(color: kAmber, strokeWidth: 2)),
          )
        else
          for (final s in _stories.where((s) => s.slug != 'happiest-countries'))
            _StoryCard(story: s, onTap: () => _openStory(s.slug)),
        const SizedBox(height: 16),
        Center(
          child: Text('Open data · full site at shpara.com/bulldozer',
              style: TextStyle(fontSize: 11, color: kTextDim)),
        ),
      ],
      ),
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
                  style: TextStyle(
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
                  style: TextStyle(
                      fontSize: 12, color: kTextDim, height: 1.35)),
              const SizedBox(height: 8),
              Text('Read on the site ↗',
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
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: kAmber)),
            Text(label,
                style: TextStyle(fontSize: 11, color: kTextDim)),
          ],
        ),
      ),
    );
  }
}

