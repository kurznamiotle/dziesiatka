import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  const ShareService();

  /// Opens the system share sheet. Browsers without file sharing download the
  /// image instead. iPads need [origin] to anchor the share popover.
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required String text,
    Rect? origin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
