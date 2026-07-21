import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme.dart';

/// Wrapping row of region swatches — mirrors the site's `.legend-regions`
/// under scatter / bubble / group-trend charts.
class RegionLegend extends StatelessWidget {
  final Iterable<String> regions; // regions actually present in the chart
  const RegionLegend({super.key, required this.regions});

  @override
  Widget build(BuildContext context) {
    final items = legendRegions(regions);
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final r in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: colorFor(r), shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(r,
                    style: TextStyle(fontSize: 11, color: kTextDim)),
              ],
            ),
        ],
      ),
    );
  }
}
