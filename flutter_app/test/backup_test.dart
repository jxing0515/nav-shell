import 'package:flutter_test/flutter_test.dart';
import 'package:nav_shell/models/page_item.dart';
import 'package:nav_shell/utils/backup.dart';

void main() {
  final pages = [
    PageItem(id: 'a', name: '工作台', url: 'https://example.com', order: 0),
    PageItem(id: 'b', name: '订单', url: 'https://www.wikipedia.org', order: 1),
  ];

  test('encode/decode round trip', () {
    final raw = encodePages(pages);
    final decoded = decodePages(raw);
    expect(decoded.length, 2);
    expect(decoded[0].name, '工作台');
    expect(decoded[1].url, 'https://www.wikipedia.org');
  });

  test('accepts bare array format', () {
    final raw = '[{"id":"x","name":"A","url":"https://a.com","order":0}]';
    final decoded = decodePages(raw);
    expect(decoded.single.name, 'A');
  });

  test('ua field round-trips and defaults', () {
    final raw = encodePages([
      PageItem(id: 'd', name: '桌面', url: 'https://d.com', order: 0, ua: 'desktop'),
    ]);
    final decoded = decodePages(raw);
    expect(decoded.single.ua, 'desktop');
    // legacy backup without ua -> defaults to mobile
    final legacy = decodePages('[{"id":"x","name":"A","url":"https://a.com","order":0}]');
    expect(legacy.single.ua, 'mobile');
  });

  test('rejects invalid content', () {
    expect(() => decodePages('not json'), throwsFormatException);
    expect(() => decodePages('{"pages": []}'), isNot(throwsFormatException));
    expect(
      () => decodePages('[{"id":"x","name":"bad","url":"ftp://x","order":0}]'),
      throwsFormatException,
    );
  });
}
