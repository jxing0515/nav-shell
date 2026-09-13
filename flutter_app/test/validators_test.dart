import 'package:flutter_test/flutter_test.dart';
import 'package:nav_shell/utils/validators.dart';

void main() {
  test('validateUrl accepts http/https full urls', () {
    expect(isValidUrl('https://example.com'), isTrue);
    expect(isValidUrl('http://a.io/path?q=1'), isTrue);
    expect(isValidUrl('ftp://x.com'), isFalse);
    expect(isValidUrl('not a url'), isFalse);
  });

  test('validateName 1-20 chars', () {
    expect(isValidName('工作台'), isTrue);
    expect(isValidName(''), isFalse);
    expect(isValidName('a' * 20), isTrue);
    expect(isValidName('a' * 21), isFalse);
  });
}
