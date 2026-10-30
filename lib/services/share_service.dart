import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  const ShareService();

  static const _androidShare = MethodChannel('dziesiatka/share');

  /// Opens the system share sheet with only the image, because apps such as
  /// Instagram can drop an attachment that comes with text. Browsers without
  /// file sharing download it instead. iPads need [origin] to anchor the popup.
  /// Android has its own sheet, because only that one can leave out the Reels
  /// targets, which turn the image into a video.
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required String title,
    Rect? origin,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _androidShare.invokeMethod<void>('shareImage', {
        'bytes': png,
        'fileName': fileName,
        'title': title,
      });
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [_imageFile(png, fileName)],
        fileNameOverrides: [fileName],
        title: title,
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Saves the image to the gallery on mobile and downloads it on the web.
  /// Throws a [StateError] when access to the gallery is refused.
  Future<void> saveImage(Uint8List png, {required String fileName}) async {
    if (kIsWeb) {
      await _imageFile(png, fileName).saveTo(fileName);
      return;
    }

    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      throw StateError('Gallery access was refused.');
    }
    // Gal adds the extension itself.
    await Gal.putImageBytes(
      png,
      name: fileName.replaceFirst(RegExp(r'\.png$'), ''),
    );
  }

  XFile _imageFile(Uint8List png, String fileName) {
    return XFile.fromData(png, mimeType: 'image/png', name: fileName);
  }
}
