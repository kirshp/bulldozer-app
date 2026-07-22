import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'flags.dart';
import 'theme.dart';

/// Most-valuable global brands with their logos — the Biz section's flagship
/// content (mirrors the site's /logos). Logos are Wikimedia Commons renders.
class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});
  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
  List<Brand>? _brands;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchBrands().then((b) {
      b.sort((x, y) => x.rank.compareTo(y.rank));
      if (mounted) setState(() => _brands = b);
    }).catchError((e) {
      if (mounted) setState(() => _error = '$e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top brands',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Couldn\'t load brands.\n$_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextDim))))
          : _brands == null
              ? Center(child: CircularProgressIndicator(color: kAmber))
              : _list(_brands!),
    );
  }

  Widget _list(List<Brand> brands) {
    final year = brands.isEmpty ? 0 : brands.first.year;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: brands.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
                'Most valuable global brands${year > 0 ? ' · $year' : ''} · brand value US\$ bn',
                style: TextStyle(fontSize: 12, color: kTextDim)),
          );
        }
        final b = brands[i - 1];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: InkWell(
            onTap: b.wiki.isEmpty
                ? null
                : () => launchUrl(Uri.parse(b.wiki),
                    mode: LaunchMode.inAppBrowserView),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                      width: 24,
                      child: Text('${b.rank}',
                          style:
                              TextStyle(fontSize: 12, color: kTextDim))),
                  // logo on a white chip — brand logos assume a light bg
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9)),
                    child: b.logo.isEmpty
                        ? const SizedBox.shrink()
                        : Image.network(b.logoUrl(96),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                                Icons.business,
                                color: Colors.black26,
                                size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${flagFromIso(b.iso)} ${b.name}',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(b.desc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: kTextDim)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('\$${_bn(b.valueBn)}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kAmber)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _bn(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(2)}T' : '${v.round()}B';
}
