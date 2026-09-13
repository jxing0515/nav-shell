import 'dart:convert';
import '../models/page_item.dart';
import 'validators.dart';

const _appTag = 'nav_shell';
const _version = 1;

/// Serialize pages to a JSON backup string.
String encodePages(List<PageItem> pages) => jsonEncode({
      'app': _appTag,
      'version': _version,
      'pages': pages.map((p) => p.toJson()).toList(),
    });

/// Parse a backup JSON string (either the wrapped format or a bare array).
/// Throws [FormatException] on invalid content.
List<PageItem> decodePages(String raw) {
  final dynamic data = jsonDecode(raw);
  final List<dynamic>? list = data is Map ? data['pages'] : data is List ? data : null;
  if (list == null) throw const FormatException('不是有效的导航备份');
  final pages = <PageItem>[];
  for (final e in list) {
    if (e is! Map) throw const FormatException('页面数据格式错误');
    final p = PageItem.fromJson(Map<String, dynamic>.from(e));
    if (p.name.trim().isEmpty || !isValidUrl(p.url)) {
      throw FormatException('包含非法页面：「${p.name}」');
    }
    pages.add(p);
  }
  return pages;
}
