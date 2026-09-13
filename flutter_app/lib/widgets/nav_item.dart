import 'package:flutter/material.dart';
import '../models/page_item.dart';
import '../store/store_scope.dart';

class NavItem extends StatelessWidget {
  final PageItem page;
  final bool active;
  final bool loading;
  const NavItem({super.key, required this.page, required this.active, required this.loading});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: active ? null : () => store.setActive(page.id),
      onDoubleTap: (active && !loading) ? () => store.setLoading(page.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 48,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? scheme.primary : Colors.transparent),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)] : null,
        ),
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(page.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? scheme.primary : scheme.onSurface,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                )),
      ),
    );
  }
}
