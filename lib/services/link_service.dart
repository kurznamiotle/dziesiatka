import 'package:url_launcher/url_launcher.dart';

class LinkService {
  const LinkService();

  /// Only http and https count, because the text can come from an imported
  /// file and must not open arbitrary schemes such as `javascript:`.
  bool isWebLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  Future<bool> open(String url) async {
    if (!isWebLink(url)) return false;

    try {
      return await launchUrl(
        Uri.parse(url.trim()),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
