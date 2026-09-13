import 'package:flutter/material.dart';
import '../models/page_item.dart';
import '../utils/validators.dart';

Future<void> showPageForm(
  BuildContext context, {
  PageItem? initial,
  required void Function(String name, String url, String ua) onSave,
}) {
  final nameCtrl = TextEditingController(text: initial?.name ?? '');
  final urlCtrl = TextEditingController(text: initial?.url ?? '');
  // Persist across StatefulBuilder rebuilds so the selection doesn't reset.
  String ua = initial?.ua ?? 'mobile';
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        String error = '';
        void submit() {
          final name = nameCtrl.text;
          final url = urlCtrl.text;
          setState(() {
            if (!isValidName(name)) {
              error = '名称需为 1-20 个字符';
            } else if (!isValidUrl(url)) {
              error = 'URL 非法，需为 http/https 开头的完整地址';
            } else {
              error = '';
            }
          });
          if (error.isEmpty) {
            onSave(name, url, ua);
            Navigator.pop(ctx);
          }
        }

        return AlertDialog(
          title: Text(initial == null ? '添加页面' : '编辑页面'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('显示模式',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'mobile', label: Text('移动版')),
                  ButtonSegment(value: 'desktop', label: Text('桌面版')),
                ],
                selected: {ua},
                onSelectionChanged: (s) => setState(() => ua = s.first),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(onPressed: submit, child: const Text('保存')),
          ],
        );
      },
    ),
  );
}
