import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/page_item.dart';
import '../store/app_store.dart';
import '../utils/backup.dart';

Future<void> exportToClipboard(BuildContext context, AppStore store) async {
  await Clipboard.setData(ClipboardData(text: encodePages(store.sorted)));
  if (context.mounted) {
    _toast(context, '已复制 ${store.pages.length} 个页面到剪贴板');
  }
}

Future<void> exportToFile(BuildContext context, AppStore store) async {
  final bytes = Uint8List.fromList(utf8.encode(encodePages(store.sorted)));
  final path = await FilePicker.platform.saveFile(
    dialogTitle: '导出页面备份',
    fileName: 'nav_pages.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: bytes,
  );
  if (path != null && context.mounted) {
    _toast(context, '已导出到 $path');
  }
}

Future<void> importFromText(BuildContext context, AppStore store) async {
  final controller = TextEditingController();
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('粘贴 JSON 导入'),
      content: TextField(
        controller: controller,
        maxLines: 8,
        minLines: 4,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '粘贴备份 JSON 内容…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('导入')),
      ],
    ),
  );
  controller.dispose();
  if (text == null || text.trim().isEmpty) return;
  if (!context.mounted) return;
  await _applyImport(context, store, text);
}

Future<void> importFromFile(BuildContext context, AppStore store) async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  final f = (res == null || res.files.isEmpty) ? null : res.files.first;
  if (f == null) return;
  final text = utf8.decode(f.bytes ?? Uint8List(0));
  if (!context.mounted) return;
  await _applyImport(context, store, text);
}

Future<void> _applyImport(
    BuildContext context, AppStore store, String raw) async {
  List<PageItem>? pages;
  String error = '';
  try {
    pages = decodePages(raw);
  } catch (e) {
    error = e is FormatException ? e.message : '解析失败';
  }
  if (!context.mounted) return;
  if (pages == null) {
    _toast(context, '导入失败：$error');
    return;
  }
  if (pages.isEmpty) {
    _toast(context, '备份中没有页面');
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认导入'),
      content: Text('将导入 ${pages!.length} 个页面，替换当前 ${store.pages.length} 个。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('导入')),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    store.replacePages(pages);
    _toast(context, '已导入 ${pages.length} 个页面');
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}
