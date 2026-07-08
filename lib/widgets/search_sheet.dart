import 'package:flutter/material.dart';

import '../theme.dart';

/// A reusable searchable bottom-sheet picker. Calls [onPick] with the chosen item.
void showSearchSheet<T>(
  BuildContext context, {
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                        icon: Icon(Icons.close, color: kTextDim),
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
                      hintStyle: TextStyle(color: kTextDim, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search, color: kTextDim, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: kBgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kBorder, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kBorder, width: 0.5),
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
                          style:
                              TextStyle(fontSize: 12, color: kTextDim)),
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
