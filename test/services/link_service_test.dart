import 'package:dziesiatka/services/link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LinkService();

  test('accepts http and https links', () {
    expect(service.isWebLink('https://science.nasa.gov/venus/'), isTrue);
    expect(service.isWebLink(' http://example.com '), isTrue);
  });

  test('rejects plain text and other schemes', () {
    expect(service.isWebLink('Soft Matter, 2021'), isFalse);
    expect(service.isWebLink('javascript:alert(1)'), isFalse);
    expect(service.isWebLink('file:///etc/passwd'), isFalse);
    expect(service.isWebLink('https://'), isFalse);
  });

  test('open refuses anything that is not a web link', () async {
    expect(await service.open('javascript:alert(1)'), isFalse);
  });
}
