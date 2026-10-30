import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/fact_source.dart';
import 'package:dziesiatka/services/supabase_config.dart';
import 'package:http/http.dart' as http;

/// Reads the `facts` table through Supabase's REST API.
class SupabaseFactSource implements FactSource {
  SupabaseFactSource({
    required String url,
    required String publishableKey,
    http.Client? client,
  }) : _url = url,
       _publishableKey = publishableKey,
       _client = client ?? http.Client();

  /// Returns null until the project is set up in [SupabaseConfig].
  static SupabaseFactSource? fromConfig() {
    final url = SupabaseConfig.url;
    final publishableKey = SupabaseConfig.publishableKey;
    if (url == null || publishableKey == null) return null;
    return SupabaseFactSource(url: url, publishableKey: publishableKey);
  }

  static const _pageSize = 500;
  static const _timeout = Duration(seconds: 15);

  final String _url;
  final String _publishableKey;
  final http.Client _client;

  /// Throws if a page fails, so a later attempt starts from the same point.
  @override
  Future<List<Fact>> loadFacts({DateTime? changedSince}) async {
    final facts = <Fact>[];
    while (true) {
      final page = await _loadPage(changedSince, offset: facts.length);
      facts.addAll(page);
      if (page.length < _pageSize) return facts;
    }
  }

  Future<List<Fact>> _loadPage(
    DateTime? changedSince, {
    required int offset,
  }) async {
    final uri = Uri.parse('$_url/rest/v1/facts').replace(
      queryParameters: {
        'select': '*',
        // Facts imported together share a time, so the id keeps pages stable.
        'order': 'updated_at,id',
        'limit': '$_pageSize',
        'offset': '$offset',
        if (changedSince != null)
          'updated_at': 'gte.${changedSince.toUtc().toIso8601String()}',
      },
    );
    final response = await _client
        .get(uri, headers: {'apikey': _publishableKey})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError('Supabase answered ${response.statusCode}.');
    }

    final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return rows
        .map((row) => Fact.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
