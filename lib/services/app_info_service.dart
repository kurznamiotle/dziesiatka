import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  const AppInfoService();

  Future<String> getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
