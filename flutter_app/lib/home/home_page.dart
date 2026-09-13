import 'package:flutter/material.dart';
import '../store/app_store.dart';
import '../store/store_scope.dart';
import '../widgets/nav_bar.dart';
import '../widgets/web_content.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenSettings;
  const HomePage({super.key, required this.onOpenSettings});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final List<String> _liveIds = []; // kept-alive page ids (LRU order)
  final Map<String, int> _reloads = {}; // pageId -> reload counter
  final Map<String, WebContent> _widgets = {}; // reused widget per pageId
  String? _prevLoading;
  double? _bottomInset; // fixed system bottom inset (white bar)

  AppStore get _store => StoreScope.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StoreScope.of(context).addListener(_onStore);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    StoreScope.of(context).removeListener(_onStore);
    super.dispose();
  }

  // On Windows, minimizing fires `hidden` and restoring fires `resumed`.
  // Only pause on real `hidden` (minimize) — NOT on `inactive`, because
  // clicking into the WebView2 child briefly fires `inactive`, which would
  // pause the webview and cause a black screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden) {
      setAllWebviewsSuspended(true);
    } else if (state == AppLifecycleState.resumed) {
      setAllWebviewsSuspended(false);
    }
  }

  void _onStore() {
    final store = _store;
    final l = store.loadingId;
    if (l != null && l == store.activeId && _prevLoading == null) {
      setState(() => _reloads[l] = (_reloads[l] ?? 0) + 1);
    }
    _prevLoading = l;
  }

  void _evict(String id) {
    _liveIds.remove(id);
    _reloads.remove(id);
    _widgets.remove(id); // disposes the WebContent (frees the webview)
  }

  // Keep the active page in the live set, applying the keep-alive limit (LRU).
  // keepAlive: -1 = keep all, 0 = off (only active), n>0 = keep up to n.
  void _ensureActive() {
    final store = _store;
    final active = store.activeId;
    if (active == null) return;
    _liveIds.remove(active);
    _liveIds.add(active);
    final n = store.keepAlive;
    if (n == 0) {
      while (_liveIds.length > 1) {
        _evict(_liveIds.first);
      }
    } else if (n > 0) {
      while (_liveIds.length > n) {
        _evict(_liveIds.first);
      }
    } // n == -1 => keep all
    _reloads[active] ??= 0;
  }

  Widget _buildContent(AppStore store, String id) {
    final page = store.pages.where((p) => p.id == id).firstOrNull;
    if (page == null) return const SizedBox.shrink();
    final desiredKey = ValueKey('$id-${_reloads[id] ?? 0}-${page.ua}');
    final existing = _widgets[id];
    if (existing == null || existing.key != desiredKey) {
      _widgets[id] = WebContent(
        key: desiredKey,
        page: page,
        onLoaded: () => store.setLoading(null),
      );
    }
    return _widgets[id]!;
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return LayoutBuilder(
      builder: (context, constraints) {
        store.setLandscape(constraints.maxWidth >= constraints.maxHeight);
        _ensureActive();
        final active = store.active;

        final Widget content;
        if (active == null) {
          content = const Center(
              child: Text('请添加一个页面', style: TextStyle(color: Colors.grey)));
        } else {
          final children = <Widget>[
            for (final id in _liveIds)
              Positioned.fill(
                key: ValueKey('wrap-$id'),
                child: IgnorePointer(
                  ignoring: id != active.id,
                  child: _buildContent(store, id),
                ),
              ),
          ];
          content = Stack(children: children);
        }

        _bottomInset ??= MediaQuery.paddingOf(context).bottom;
        final nav = NavBar(onOpenSettings: widget.onOpenSettings);
        const sidebarW = 84.0;
        final Widget contentArea;
        if (store.landscape) {
          contentArea = SafeArea(
            top: true, bottom: true, left: true, right: true,
            child: Padding(
              padding: const EdgeInsets.only(left: sidebarW),
              child: content,
            ),
          );
        } else {
          contentArea = SafeArea(
            top: true, bottom: false, left: true, right: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: 64 + _bottomInset!),
              child: content,
            ),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(children: [
            Positioned.fill(child: contentArea),
            if (store.landscape)
              Positioned(
                  left: 0, top: 0, bottom: 0, width: sidebarW,
                  child: SafeArea(top: true, bottom: true, child: nav))
            else
              Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: _bottomInset!),
                      child: nav)),
          ]),
        );
      },
    );
  }
}