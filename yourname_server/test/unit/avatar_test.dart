import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:yourname_server/src/game/account_endpoint.dart';
import 'package:yourname_server/src/generated/protocol.dart';

void main() {
  test('uploaded photo is re-encoded to a small square JPEG', () {
    final source = img.Image(width: 200, height: 100);
    final normalized = AccountEndpoint.normalizePhoto(
      base64Encode(img.encodePng(source)),
    )!;
    final decoded = img.decodeJpg(base64Decode(normalized))!;
    expect(decoded.width, 96);
    expect(decoded.height, 96);
  });
  test('rejects invalid, oversized and unsupported avatar payloads', () {
    for (final value in [
      'not base64!',
      base64Encode(utf8.encode('<svg/>')),
      'A' * 1400001,
    ]) {
      expect(
        () => AccountEndpoint.normalizePhoto(value),
        throwsA(isA<GameException>()),
      );
    }
    expect(AccountEndpoint.normalizePhoto(null), isNull);
  });
}
