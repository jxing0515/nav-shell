import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/page_item.dart';

class AppStore extends ChangeNotifier {
  static const _key = 'nav_pages';
  static const _activeKey = 'active_id';

  List<PageItem> pages = [];
  String? activeId;
  String? loadingId;
  bool landscape = true;
  int keepAlive = 3; // max pages kept alive (0 = off)
  String launchMode = 'first'; // 'first' = first sorted page, 'last' = last viewed

  static const _defaults = [
    ('工作台', 'https://example.com'),
    ('订单', 'https://www.wikipedia.org'),
    ('监控', 'https://news.ycombinator.com'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    keepAlive = prefs.getInt('keep_alive') ?? 3;
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        pages = list.map(PageItem.fromJson).toList();
      } catch (_) {
        pages = _seed();
      }
    } else {
      pages = _seed();
    }
    launchMode = prefs.getString('launch_mode') ?? 'first';
    final s = sorted;
    if (launchMode == 'last') {
      // Restore the last page the user was viewing.
      final savedActive = prefs.getString(_activeKey);
      final valid = savedActive != null && pages.any((p) => p.id == savedActive);
      activeId = valid ? savedActive : (s.isNotEmpty ? s.first.id : null);
    } else {
      // Open the first page in the current (sorted) order.
      activeId = s.isNotEmpty ? s.first.id : null;
    }
    notifyListeners();
  }

  List<PageItem> _seed() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      for (var i = 0; i < _defaults.length; i++)
        PageItem(
            id: '$now-$i', name: _defaults[i].$1, url: _defaults[i].$2, order: i, ua: 'mobile'),
    ];
  }

  List<PageItem> get sorted {
    final s = [...pages]..sort((a, b) => a.order.compareTo(b.order));
    return s;
  }

  PageItem? get active => pages.where((p) => p.id == activeId).firstOrNull;

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(pages.map((p) => p.toJson()).toList()));
  }

  void add(String name, String url, [String ua = 'mobile']) {
    pages.add(PageItem(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        url: url.trim(),
        order: pages.length,
        ua: ua));
    activeId ??= pages.last.id;
    _save();
    notifyListeners();
  }

  void delete(String id) {
    pages.removeWhere((p) => p.id == id);
    for (var i = 0; i < pages.length; i++) {
      pages[i].order = i;
    }
    if (activeId == id) {
      activeId = pages.isNotEmpty ? pages[0].id : null;
      _saveActive();
    }
    _save();
    notifyListeners();
  }

  void update(String id, String name, String url, String ua) {
    final p = pages.where((p) => p.id == id).firstOrNull;
    if (p == null) return;
    p.name = name.trim();
    p.url = url.trim();
    p.ua = ua;
    _save();
    notifyListeners();
  }

  void reorder(int start, int end) {
    final s = sorted;
    if (start < 0 || start >= s.length || end < 0 || end >= s.length) return;
    final moved = s.removeAt(start);
    s.insert(end, moved);
    for (var i = 0; i < s.length; i++) {
      s[i].order = i;
    }
    _save();
    notifyListeners();
  }

  /// Replace the whole page list (import/restore).
  void replacePages(List<PageItem> incoming) {
    final sorted = [...incoming]..sort((a, b) => a.order.compareTo(b.order));
    pages = sorted;
    for (var i = 0; i < pages.length; i++) {
      pages[i].order = i;
    }
    activeId = pages.isNotEmpty ? pages[0].id : null;
    _save();
    notifyListeners();
  }

  void setActive(String id) {
    activeId = id;
    _saveActive();
    notifyListeners();
  }

  void setLoading(String? id) {
    loadingId = id;
    notifyListeners();
  }

  void setUa(String id, String ua) {
    final p = pages.where((p) => p.id == id).firstOrNull;
    if (p == null || p.ua == ua) return;
    p.ua = ua;
    _save();
    notifyListeners();
  }

  void setLandscape(bool v) {
    if (landscape == v) return;
    landscape = v;
    notifyListeners();
  }

  void setKeepAlive(int n) {
    final v = n.clamp(-1, 10);
    if (keepAlive == v) return;
    keepAlive = v;
    _saveKeepAlive();
    notifyListeners();
  }

  void setLaunchMode(String m) {
    if (launchMode == m) return;
    launchMode = m == 'last' ? 'last' : 'first';
    _saveLaunchMode();
    notifyListeners();
  }

  Future<void> _saveLaunchMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('launch_mode', launchMode);
  }

  Future<void> _saveActive() async {
    final prefs = await SharedPreferences.getInstance();
    if (activeId != null) {
      await prefs.setString(_activeKey, activeId!);
    } else {
      await prefs.remove(_activeKey);
    }
  }

  Future<void> _saveKeepAlive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keep_alive', keepAlive);
  }
}
