import 'package:flutter/material.dart';

import 'api.dart';
import 'charts_page.dart' show topicLabels, topicSortKey;
import 'theme.dart';

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
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: shown.length,
            itemBuilder: (_, i) {
              final c = shown[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  dense: true,
                  leading: Text(_flagFromIso(c.iso),
                      style: const TextStyle(fontSize: 22)),
                  title: Text(c.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.region} · ${c.items.length} indicators',
                      style: const TextStyle(fontSize: 12, color: kTextDim)),
                  trailing:
                      const Icon(Icons.chevron_right, color: kTextDim, size: 20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CountryPage(country: c))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Flag emoji from ISO alpha-3 via an alpha3→alpha2 map; unknown codes get 🌍.
String _flagFromIso(String iso3) {
  const special = {
    'ABW': 'AW', 'AIA': 'AI', 'ALB': 'AL', 'AND': 'AD', 'ARM': 'AM',
    'ASM': 'AS', 'AZE': 'AZ', 'BMU': 'BM', 'CYM': 'KY', 'COK': 'CK',
    'CUW': 'CW', 'ESH': 'EH', 'FRO': 'FO', 'GIB': 'GI', 'GLP': 'GP',
    'GRL': 'GL', 'GUF': 'GF', 'GUM': 'GU', 'IMN': 'IM', 'MAC': 'MO',
    'MAF': 'MF', 'MNP': 'MP', 'MSR': 'MS', 'MTQ': 'MQ', 'NCL': 'NC',
    'NIU': 'NU', 'PRI': 'PR', 'PYF': 'PF', 'REU': 'RE', 'SHN': 'SH',
    'SXM': 'SX', 'TCA': 'TC', 'TKL': 'TK', 'UVK': 'XK', 'VGB': 'VG',
    'VIR': 'VI', 'WLF': 'WF', 'XKX': 'XK',
    'AFG': 'AF', 'AGO': 'AO', 'ARE': 'AE', 'ARG': 'AR', 'ATG': 'AG',
    'AUS': 'AU', 'AUT': 'AT', 'BDI': 'BI', 'BEL': 'BE', 'BEN': 'BJ',
    'BFA': 'BF', 'BGD': 'BD', 'BGR': 'BG', 'BHR': 'BH', 'BHS': 'BS',
    'BIH': 'BA', 'BLR': 'BY', 'BLZ': 'BZ', 'BOL': 'BO', 'BRA': 'BR',
    'BRB': 'BB', 'BRN': 'BN', 'BTN': 'BT', 'BWA': 'BW', 'CAF': 'CF',
    'CAN': 'CA', 'CHE': 'CH', 'CHL': 'CL', 'CHN': 'CN', 'CIV': 'CI',
    'CMR': 'CM', 'COD': 'CD', 'COG': 'CG', 'COL': 'CO', 'COM': 'KM',
    'CPV': 'CV', 'CRI': 'CR', 'CUB': 'CU', 'CYP': 'CY', 'CZE': 'CZ',
    'DEU': 'DE', 'DJI': 'DJ', 'DMA': 'DM', 'DNK': 'DK', 'DOM': 'DO',
    'DZA': 'DZ', 'ECU': 'EC', 'EGY': 'EG', 'ERI': 'ER', 'ESP': 'ES',
    'EST': 'EE', 'ETH': 'ET', 'FIN': 'FI', 'FJI': 'FJ', 'FRA': 'FR',
    'FSM': 'FM', 'GAB': 'GA', 'GBR': 'GB', 'GEO': 'GE', 'GHA': 'GH',
    'GIN': 'GN', 'GMB': 'GM', 'GNB': 'GW', 'GNQ': 'GQ', 'GRC': 'GR',
    'GRD': 'GD', 'GTM': 'GT', 'GUY': 'GY', 'HKG': 'HK', 'HND': 'HN',
    'HRV': 'HR', 'HTI': 'HT', 'HUN': 'HU', 'IDN': 'ID', 'IND': 'IN',
    'IRL': 'IE', 'IRN': 'IR', 'IRQ': 'IQ', 'ISL': 'IS', 'ISR': 'IL',
    'ITA': 'IT', 'JAM': 'JM', 'JOR': 'JO', 'JPN': 'JP', 'KAZ': 'KZ',
    'KEN': 'KE', 'KGZ': 'KG', 'KHM': 'KH', 'KIR': 'KI', 'KNA': 'KN',
    'KOR': 'KR', 'KWT': 'KW', 'LAO': 'LA', 'LBN': 'LB', 'LBR': 'LR',
    'LBY': 'LY', 'LCA': 'LC', 'LIE': 'LI', 'LKA': 'LK', 'LSO': 'LS',
    'LTU': 'LT', 'LUX': 'LU', 'LVA': 'LV', 'MAR': 'MA', 'MCO': 'MC',
    'MDA': 'MD', 'MDG': 'MG', 'MDV': 'MV', 'MEX': 'MX', 'MHL': 'MH',
    'MKD': 'MK', 'MLI': 'ML', 'MLT': 'MT', 'MMR': 'MM', 'MNE': 'ME',
    'MNG': 'MN', 'MOZ': 'MZ', 'MRT': 'MR', 'MUS': 'MU', 'MWI': 'MW',
    'MYS': 'MY', 'NAM': 'NA', 'NER': 'NE', 'NGA': 'NG', 'NIC': 'NI',
    'NLD': 'NL', 'NOR': 'NO', 'NPL': 'NP', 'NRU': 'NR', 'NZL': 'NZ',
    'OMN': 'OM', 'PAK': 'PK', 'PAN': 'PA', 'PER': 'PE', 'PHL': 'PH',
    'PLW': 'PW', 'PNG': 'PG', 'POL': 'PL', 'PRK': 'KP', 'PRT': 'PT',
    'PRY': 'PY', 'PSE': 'PS', 'QAT': 'QA', 'ROU': 'RO', 'RUS': 'RU',
    'RWA': 'RW', 'SAU': 'SA', 'SDN': 'SD', 'SEN': 'SN', 'SGP': 'SG',
    'SLB': 'SB', 'SLE': 'SL', 'SLV': 'SV', 'SMR': 'SM', 'SOM': 'SO',
    'SRB': 'RS', 'SSD': 'SS', 'STP': 'ST', 'SUR': 'SR', 'SVK': 'SK',
    'SVN': 'SI', 'SWE': 'SE', 'SWZ': 'SZ', 'SYC': 'SC', 'SYR': 'SY',
    'TCD': 'TD', 'TGO': 'TG', 'THA': 'TH', 'TJK': 'TJ', 'TKM': 'TM',
    'TLS': 'TL', 'TON': 'TO', 'TTO': 'TT', 'TUN': 'TN', 'TUR': 'TR',
    'TUV': 'TV', 'TWN': 'TW', 'TZA': 'TZ', 'UGA': 'UG', 'UKR': 'UA',
    'URY': 'UY', 'USA': 'US', 'UZB': 'UZ', 'VCT': 'VC', 'VEN': 'VE',
    'VNM': 'VN', 'VUT': 'VU', 'WSM': 'WS', 'YEM': 'YE', 'ZAF': 'ZA',
    'ZMB': 'ZM', 'ZWE': 'ZW',
  };
  final a2 = special[iso3];
  if (a2 == null) return '🌍'; // Somaliland, Zanzibar and other non-ISO codes
  return String.fromCharCodes(a2.codeUnits.map((c) => 0x1F1E6 + c - 65));
}

class CountryPage extends StatelessWidget {
  final Country country;
  const CountryPage({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final byTopic = <String, List<CountryItem>>{};
    for (final it in country.items) {
      byTopic.putIfAbsent(it.topic, () => []).add(it);
    }
    final topics = byTopic.keys.toList()
      ..sort((a, b) => topicSortKey(a).compareTo(topicSortKey(b)));

    return Scaffold(
      appBar: AppBar(
        title: Text('${_flagFromIso(country.iso)}  ${country.name}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${country.region} · ${country.items.length} indicators',
              style: const TextStyle(fontSize: 12, color: kTextDim)),
          const SizedBox(height: 8),
          for (final t in topics) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
              child: Text(topicLabels[t] ?? t,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kAmber)),
            ),
            for (final it in byTopic[t]!) _IndicatorRow(item: it),
          ],
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final CountryItem item;
  const _IndicatorRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final topThird = item.total > 0 && item.rank <= item.total / 3;
    final bottomThird = item.total > 0 && item.rank > item.total * 2 / 3;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
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
          ],
        ),
      ),
    );
  }
}
