import 'dart:convert';

import 'package:dziesiatka/models/fact_report.dart';
import 'package:dziesiatka/services/supabase_config.dart';
import 'package:http/http.dart' as http;

/// Sends a report of a mistake in a fact. It carries no id of the reader. See
/// `supabase/reports.sql`.
class FactReportService {
  FactReportService({
    required String url,
    required String publishableKey,
    http.Client? client,
  }) : _url = url,
       _publishableKey = publishableKey,
       _client = client ?? http.Client();

  factory FactReportService.fromConfig() {
    return FactReportService(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  static const _timeout = Duration(seconds: 15);

  final String _url;
  final String _publishableKey;
  final http.Client _client;

  /// Answers whether the report was saved, so the reader can try again.
  Future<bool> send(
    String factId,
    FactReportReason reason,
    String comment,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_url/rest/v1/rpc/report_fact'),
            headers: {
              'apikey': _publishableKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'p_fact_id': factId,
              'p_reason': reason.code,
              'p_comment': comment.trim(),
            }),
          )
          .timeout(_timeout);
      return response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
