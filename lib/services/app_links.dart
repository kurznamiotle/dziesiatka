import 'package:flutter/foundation.dart';

/// External addresses shown in the settings.
abstract final class AppLinks {
  /// The creator's support page.
  static const buyCoffee = 'https://buycoffee.to/bunu';

  /// Google Play and the App Store reject outside payment links in apps, so
  /// only the web demo shows the support page.
  static const String? buyCoffeeInApp = kIsWeb ? buyCoffee : null;

  /// The Android app in the newest GitHub release. The file must keep this
  /// name in every release, or the link breaks.
  static const androidApp =
      'https://github.com/kurznamiotle/dziesiatka/releases/latest/download/dziesiatka.apk';
}
