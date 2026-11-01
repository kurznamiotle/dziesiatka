import 'dart:convert';

import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/usage_row.dart';
import 'package:dziesiatka/services/admin_auth_service.dart';
import 'package:dziesiatka/services/supabase_config.dart';
import 'package:http/http.dart' as http;

/// Reads and changes data as the signed-in administrator. It holds no secret
/// key: `supabase/admin.sql` decides what this account may do.
class AdminService {
  AdminService(
    this._auth, {
    String url = SupabaseConfig.url,
    String publishableKey = SupabaseConfig.publishableKey,
    http.Client? client,
  }) : _url = url,
       _publishableKey = publishableKey,
       _client = client ?? http.Client();

  static const _pageSize = 1000;
  static const _timeout = Duration(seconds: 20);

  final AdminAuthService _auth;
  final String _url;
  final String _publishableKey;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    return {
      'apikey': _publishableKey,
      'Authorization': 'Bearer ${await _auth.accessToken()}',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_url/rest/v1/$path').replace(queryParameters: query);
  }

  void _check(http.Response response) {
    if (response.statusCode >= 300) {
      throw StateError('Supabase odpowiedział ${response.statusCode}.');
    }
  }

  Future<bool> isAdmin() async {
    final response = await _client
        .post(_uri('rpc/is_admin'), headers: await _headers())
        .timeout(_timeout);
    _check(response);
    return jsonDecode(response.body) == true;
  }

  Future<List<AdminFact>> loadFacts() async {
    final rows = await _loadAll('facts', {
      'select': '*',
      'order': 'created_at,id',
    });
    return rows.map(AdminFact.fromRow).toList();
  }

  Future<Set<String>> loadCategories() async {
    final rows = await _loadAll('categories', {
      'select': 'name',
      'order': 'name',
    });
    return {for (final row in rows) row['name'] as String};
  }

  Future<List<UsageRow>> loadUsage() async {
    final rows = await _loadAll('usage_days', {
      'select': '*',
      'order': 'day,install_id',
    });
    return rows.map(UsageRow.fromRow).toList();
  }

  Future<Map<String, FactUsage>> loadFactUsage() async {
    final rows = await _loadAll('fact_stats', {
      'select': '*',
      'order': 'fact_id',
    });
    return {
      for (final row in rows) row['fact_id'] as String: FactUsage.fromJson(row),
    };
  }

  Future<void> insertFacts(List<AdminFact> facts) async {
    final response = await _client
        .post(
          _uri('facts'),
          headers: {...await _headers(), 'Prefer': 'return=minimal'},
          body: jsonEncode(facts.map((fact) => fact.toRow()).toList()),
        )
        .timeout(_timeout);
    _check(response);
  }

  Future<void> updateFact(AdminFact fact) async {
    final response = await _client
        .patch(
          _uri('facts', {'id': 'eq.${fact.id}'}),
          headers: {...await _headers(), 'Prefer': 'return=minimal'},
          body: jsonEncode(fact.toRow()),
        )
        .timeout(_timeout);
    _check(response);
  }

  /// Publishing clears the review note, because the app can read published
  /// rows and the note is meant only for the panel.
  Future<void> setStatus(List<String> ids, String status) async {
    if (ids.isEmpty) return;

    final response = await _client
        .patch(
          _uri('facts', {'id': 'in.(${ids.map(jsonEncode).join(',')})'}),
          headers: {...await _headers(), 'Prefer': 'return=minimal'},
          body: jsonEncode({
            'status': status,
            if (status == AdminFact.published) 'review_note': null,
          }),
        )
        .timeout(_timeout);
    _check(response);
  }

  Future<List<Map<String, dynamic>>> _loadAll(
    String table,
    Map<String, String> query,
  ) async {
    final rows = <Map<String, dynamic>>[];
    while (true) {
      final response = await _client
          .get(
            _uri(table, {
              ...query,
              'limit': '$_pageSize',
              'offset': '${rows.length}',
            }),
            headers: await _headers(),
          )
          .timeout(_timeout);
      _check(response);

      final page = (jsonDecode(utf8.decode(response.bodyBytes)) as List)
          .cast<Map<String, dynamic>>();
      rows.addAll(page);
      if (page.length < _pageSize) return rows;
    }
  }
}
