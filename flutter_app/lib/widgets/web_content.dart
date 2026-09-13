import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/page_item.dart';

const _mobileUA =
    'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
const _desktopUA =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

String _uaFor(PageItem page) => page.ua == 'desktop' ? _desktopUA : _mobileUA;

/// Page content backed by flutter_inappwebview (Android WebView / Windows WebView2).
class WebContent extends StatefulWidget {
  final PageItem page;
  final VoidCallback onLoaded;
  const WebContent({super.key, required this.page, required this.onLoaded});

  @override
  State<WebContent> createState() => WebContentState();
}

class WebContentState extends State<WebContent> {
  bool _loading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Stack(children: [
      Positioned.fill(child: ColoredBox(color: bg)), // opaque base
      InAppWebView(
        initialSettings: InAppWebViewSettings(
          userAgent: _uaFor(widget.page),
          javaScriptEnabled: true,
          supportZoom: false,
        ),
        initialUrlRequest: URLRequest(url: WebUri(widget.page.url)),
        onLoadStart: (c, u) {
          if (mounted) setState(() => _loading = true);
        },
        onLoadStop: (c, u) {
          widget.onLoaded();
          if (mounted) setState(() => _loading = false);
        },
        onReceivedError: (c, req, err) {
          if (mounted) setState(() => _error = err.description);
        },
      ),
      if (_loading)
        Positioned.fill(
          child: ColoredBox(
            color: bg,
            child: Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('加载失败：$_error', textAlign: TextAlign.center),
                      )),
          ),
        ),
    ]);
  }
}