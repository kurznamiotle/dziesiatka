import 'dart:convert';
import 'dart:math';

import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Counts active users with one anonymous note a day. The random id says only
/// that two notes came from the same installation, and nothing about the user
/// or their progress. See `supabase/usage.sql`.
class UsageService {
  UsageService({
    required String url,
    required String publishableKey,
    http.Client? client,
    AppInfoService appInfoService = const AppInfoService(),
    DateTime Function()? now,
    Random? random,
  }) : _url = url,
       _publishableKey = publishableKey,
       _client = client ?? http.Client(),
       _appInfoService = appInfoService,
       _now = now ?? DateTime.now,
       _random = random ?? Random.secure();

  factory UsageService.fromConfig() {
    return UsageService(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  static const _enabledKey = 'usageStatsEnabled';
  static const _installIdKey = 'usageInstallId';
  static const _lastSentKey = 'usageLastSent';
  static const _timeout = Duration(seconds: 15);

  final String _url;
  final String _publishableKey;
  final http.Client _client;
  final AppInfoService _appInfoService;
  final DateTime Function() _now;
  final Random _random;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Turning this off also forgets the id, so turning it on later starts a
  /// new, unconnected one.
  Future<void> setEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, isEnabled);
    if (!isEnabled) await prefs.remove(_installIdKey);
  }

  /// Sends today's note once. A failure is retried on the next start, and the
  /// app must work the same without it.
  Future<void> recordToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DailyDeck.dateKey(_now());
      if (!await isEnabled() || prefs.getString(_lastSentKey) == today) return;

      final response = await _client
          .post(
            Uri.parse('$_url/rest/v1/rpc/record_usage'),
            headers: {
              'apikey': _publishableKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'p_install_id': await _installId(prefs),
              'p_platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
              'p_app_version': await _appInfoService.getVersion(),
            }),
          )
          .timeout(_timeout);
      if (response.statusCode < 300) {
        await prefs.setString(_lastSentKey, today);
      }
    } catch (_) {}
  }

  Future<String> _installId(SharedPreferences prefs) async {
    final stored = prefs.getString(_installIdKey);
    if (stored != null) return stored;

    final id = [
      for (var i = 0; i < 32; i++) _random.nextInt(16).toRadixString(16),
    ].join();
    await prefs.setString(_installIdKey, id);
    return id;
  }
}
