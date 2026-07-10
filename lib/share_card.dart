import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api.dart';
import 'theme.dart';

/// A branded, share-ready card: BullDozer mark, a title, a mini ranked bar
/// chart and a source/footer line. Rendered on a preview screen and captured
/// to PNG for sharing — free marketing when a chart lands on social.
class ShareCard extends StatelessWidget {
  final String tag;
  final String title;
  final List<(String, double)> bars; // (label, value) desc
  final String footer;
  const ShareCard(
      {super.key,
      required this.tag,
      required this.title,
      required this.bars,
      required this.footer});

  @override
  Widget build(BuildContext context) {
    final maxV = bars.isEmpty
        ? 1.0
        : bars.map((b) => b.$2.abs()).reduce((a, b) => a > b ? a : b);
    // Always dark — the share card reads the same everywhere, theme aside.
    const bg = Color(0xFF0E0F11);
    const card = Color(0xFF1C1F23);
    const amber = Color(0xFFFFB000);
    const text = Color(0xFFE7E9EC);
    const dim = Color(0xFF9AA1A9);
    return Container(
      width: 400,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(color: bg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [amber, Color(0xFFFF7A00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: const Text('B',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1300))),
              ),
              const SizedBox(width: 8),
              const Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Bull',
                    style: TextStyle(
                        color: text, fontWeight: FontWeight.w800)),
                TextSpan(
                    text: 'Dozer',
                    style: TextStyle(
                        color: amber, fontWeight: FontWeight.w800)),
              ]), style: TextStyle(fontSize: 19)),
            ],
          ),
          const SizedBox(height: 16),
          Text(tag.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: amber)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: text)),
          const SizedBox(height: 16),
          for (final b in bars.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(b.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: text)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(4)),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            (maxV == 0 ? 0.0 : b.$2.abs() / maxV)
                                .clamp(0.03, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                              color: amber,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(formatValue(b.$2),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: text)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(footer,
              style: const TextStyle(fontSize: 11, color: dim)),
          const Text('shpara.com/bulldozer · open data',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: amber)),
        ],
      ),
    );
  }
}

/// Full-screen preview of a [ShareCard] with a Share button. The card is on
/// screen, so capturing it to PNG is a plain RepaintBoundary read.
class SharePreviewPage extends StatefulWidget {
  final String tag;
  final String title;
  final List<(String, double)> bars;
  final String footer;
  const SharePreviewPage(
      {super.key,
      required this.tag,
      required this.title,
      required this.bars,
      required this.footer});

  @override
  State<SharePreviewPage> createState() => _SharePreviewPageState();
}

class _SharePreviewPageState extends State<SharePreviewPage> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      final dir = await getTemporaryDirectory();
      final file = await _writeTemp(dir.path, bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file)],
        text: '${widget.title} — via BullDozer · shpara.com/bulldozer',
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Couldn\'t create the image.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _writeTemp(String dir, Uint8List bytes) async {
    final path = '$dir/bulldozer_share.png';
    await _FileWriter.write(path, bytes);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: ShareCard(
                      tag: widget.tag,
                      title: widget.title,
                      bars: widget.bars,
                      footer: widget.footer),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                style: FilledButton.styleFrom(
                    backgroundColor: kAmber, foregroundColor: kBg),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.share),
                label: const Text('Share image',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small dart:io wrapper kept apart so the rest of the file stays web-safe.
class _FileWriter {
  static Future<void> write(String path, Uint8List bytes) async {
    await File(path).writeAsBytes(bytes);
  }
}
