import 'package:url_launcher/url_launcher.dart';

class LinkService {
  const LinkService();

  bool isWebLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  bool _isMailLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.isScheme('mailto') && uri.path.isNotEmpty;
  }

  /// Opens only web and mail links, so a mistake in stored text can never
  /// reach an arbitrary scheme such as `javascript:`.
  Future<bool> open(String url) async {
    if (!isWebLink(url) && !_isMailLink(url)) return false;

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
