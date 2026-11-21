import 'package:dziesiatka/services/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Android app link opens Google Play from the web banner', () {
    final uri = Uri.parse(AppLinks.androidApp);

    expect(uri.host, 'play.google.com');
    expect(uri.path, '/store/apps/details');
    expect(uri.queryParameters, {
      'id': 'io.github.kurznamiotle.dziesiatka',
      'utm_source': 'webapp',
      'utm_medium': 'baner',
    });
  });
}
