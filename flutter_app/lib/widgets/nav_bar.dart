import 'package:flutter/gestures.dart' show PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/material.dart';
import '../store/store_scope.dart';
import 'nav_item.dart';

class NavBar extends StatefulWidget {
  final VoidCallback onOpenSettings;
  const NavBar({super.key, required this.onOpenSettings});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  void _onWheel(PointerSignalEvent signal) {
    // Bottom nav scrolls horizontally; map the vertical wheel delta to it.
    if (signal is! PointerScrollEvent || !_hCtrl.hasClients) return;
    final pos = _hCtrl.position;
    final next = (pos.pixels + signal.scrollDelta.dy).clamp(0.0, pos.maxScrollExtent);
    if (next != pos.pixels) _hCtrl.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final landscape = store.landscape;
    final pages = store.sorted;
    final activeId = store.activeId;
    final loadingId = store.loadingId;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final items = [
      for (final p in pages)
        NavItem(
          page: p,
          active: p.id == activeId,
          loading: p.id == loadingId,
        ),
    ];

    final scroll = landscape
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisSize: MainAxisSize.min, children: items),
          )
        : Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: _onWheel,
            child: SingleChildScrollView(
              controller: _hCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
          );

    final gear = IconButton(
      onPressed: widget.onOpenSettings,
      icon: const Icon(Icons.settings),
      tooltip: '设置',
    );

    if (landscape) {
      return Container(
        width: 84,
        decoration: BoxDecoration(color: bg, border: Border(right: BorderSide(color: Colors.black12))),
        child: Column(children: [Expanded(child: scroll), gear]),
      );
    }
    return Container(
      height: 64,
      decoration: BoxDecoration(color: bg, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(children: [Expanded(child: scroll), gear]),
    );
  }
}