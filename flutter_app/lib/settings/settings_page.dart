import 'package:flutter/material.dart';
import '../models/page_item.dart';
import '../store/app_store.dart';
import '../store/store_scope.dart';
import 'page_form.dart';
import 'backup_actions.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _add(BuildContext context) {
    showPageForm(context, onSave: (n, u, ua) => StoreScope.of(context).add(n, u, ua));
  }

  void _edit(BuildContext context, PageItem p) {
    final store = StoreScope.of(context);
    showPageForm(context, initial: p, onSave: (n, u, ua) => store.update(p.id, n, u, ua));
  }

  void _backup(BuildContext context, String action) {
    final store = StoreScope.of(context);
    switch (action) {
      case 'exportClipboard':
        exportToClipboard(context, store);
      case 'exportFile':
        exportToFile(context, store);
      case 'importText':
        importFromText(context, store);
      case 'importFile':
        importFromFile(context, store);
    }
  }

  Future<void> _delete(BuildContext context, PageItem p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除「${p.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true && context.mounted) StoreScope.of(context).delete(p.id);
  }

  Widget _launchTile(BuildContext context, AppStore store) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome),
        title: const Text('启动时打开'),
        subtitle: const Text('打开排序第一页，或上次查看的页面'),
        trailing: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'first', label: Text('第一页')),
            ButtonSegment(value: 'last', label: Text('上次')),
          ],
          selected: {store.launchMode},
          onSelectionChanged: (s) => store.setLaunchMode(s.first),
        ),
      ),
    );
  }

  Widget _keepAliveTile(BuildContext context, AppStore store) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ListTile(
        leading: const Icon(Icons.memory),
        title: const Text('页面保活'),
        subtitle: const Text('切换页面保留网页状态，-1 = 全部，0 = 不保活'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: '减少',
              onPressed: store.keepAlive > -1
                  ? () => store.setKeepAlive(store.keepAlive - 1)
                  : null,
            ),
            Text(store.keepAlive == -1 ? '全部' : '${store.keepAlive}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '增加',
              onPressed: store.keepAlive < 10
                  ? () => store.setKeepAlive(store.keepAlive + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _uaBadge(String ua) {
    final desktop = ua == 'desktop';
    final color = desktop ? Colors.blue : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(desktop ? Icons.desktop_windows : Icons.smartphone,
              size: 12, color: color),
          const SizedBox(width: 3),
          Text(desktop ? '桌面版' : '移动版',
              style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), tooltip: '返回'),
        title: const Text('页面管理'),
        actions: [
          IconButton(onPressed: () => _add(context), icon: const Icon(Icons.add), tooltip: '添加'),
          PopupMenuButton<String>(
            tooltip: '导入/导出',
            onSelected: (v) => _backup(context, v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'exportClipboard', child: Text('导出到剪贴板')),
              PopupMenuItem(value: 'exportFile', child: Text('导出到文件')),
              PopupMenuItem(value: 'importText', child: Text('粘贴 JSON 导入')),
              PopupMenuItem(value: 'importFile', child: Text('从文件导入')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final pages = store.sorted;
          return Column(children: [
            _launchTile(context, store),
            _keepAliveTile(context, store),
            Expanded(
              child: ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pages.length,
            onReorderItem: (a, b) => store.reorder(a, b),
            itemBuilder: (context, i) {
              final p = pages[i];
              return Card(
                key: ValueKey(p.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      _uaBadge(p.ua),
                    ],
                  ),
                  subtitle: Text(p.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), tooltip: '编辑', onPressed: () => _edit(context, p)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: '删除', onPressed: () => _delete(context, p)),
                    ],
                  ),
                ),
              );
            },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
