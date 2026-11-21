import 'package:flutter/foundation.dart';

/// External addresses shown in the settings.
abstract final class AppLinks {
  /// The creator's support page.
  static const support = 'https://cuplink.to/szyszka_studio';

  /// Google Play and the App Store reject outside payment links in apps, so
  /// only the web demo shows the support page.
  static const String? supportInApp = kIsWeb ? support : null;

  /// The Android app in Google Play. The utm parameters tell the Play Console
  /// that the visit came from the banner in the web demo.
  static const androidApp =
      'https://play.google.com/store/apps/details'
      '?id=io.github.kurznamiotle.dziesiatka'
      '&utm_source=webapp&utm_medium=baner';
}
