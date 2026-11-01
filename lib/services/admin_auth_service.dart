import 'dart:convert';

import 'package:dziesiatka/services/supabase_config.dart';
import 'package:http/http.dart' as http;

/// Signs the administrator in through Supabase Auth. Tokens stay in memory, so
/// closing the tab signs out and nothing is left in the browser.
class AdminAuthService {
  AdminAuthService({
    required String url,
    required String publishableKey,
    http.Client? client,
    DateTime Function()? now,
  }) : _url = url,
       _publishableKey = publishableKey,
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  factory AdminAuthService.fromConfig() {
    return AdminAuthService(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  static const _timeout = Duration(seconds: 15);

  /// A token this close to its end is renewed before use.
  static const _refreshMargin = Duration(minutes: 1);

  final String _url;
  final String _publishableKey;
  final http.Client _client;
  final DateTime Function() _now;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  bool get isSignedIn => _accessToken != null;

  /// Returns whether the address and password were accepted.
  Future<bool> signIn(String email, String password) async {
    return _requestToken('password', {'email': email, 'password': password});
  }

  void signOut() {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
  }

  /// Returns a token that is still valid. Throws [StateError] when the session
  /// has ended, and the user must sign in again.
  Future<String> accessToken() async {
    final token = _accessToken;
    final expiresAt = _expiresAt;
    final refreshToken = _refreshToken;
    if (token == null || expiresAt == null || refreshToken == null) {
      throw StateError('Nie zalogowano.');
    }
    if (expiresAt.isAfter(_now().add(_refreshMargin))) return token;

    final isRenewed = await _requestToken('refresh_token', {
      'refresh_token': refreshToken,
    });
    if (!isRenewed) {
      signOut();
      throw StateError('Sesja wygasła.');
    }
    return _accessToken!;
  }

  Future<bool> _requestToken(String grantType, Map<String, String> body) async {
    final response = await _client
        .post(
          Uri.parse('$_url/auth/v1/token?grant_type=$grantType'),
          headers: {
            'apikey': _publishableKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) return false;

    final session =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _accessToken = session['access_token'] as String;
    _refreshToken = session['refresh_token'] as String;
    _expiresAt = _now().add(Duration(seconds: session['expires_in'] as int));
    return true;
  }
}
