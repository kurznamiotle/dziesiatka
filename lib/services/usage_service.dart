import 'dart:convert';
import 'dart:math';

import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/usage_day.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps anonymous statistics on the device and sends them at the start of the
/// app and when a day is finished. The random id says only that two days came
/// from the same installation. Facts are counted apart from it, so nothing on
/// the server shows who read what. See `supabase/usage_02.sql`.
class UsageService {
  UsageService({
    required String url,
    required String publishableKey,
    http.Client? client,
    AppInfoService appInfoService = const AppInfoService(),
    DateTime Function()? now,
    Random? random,
    bool asksForConsent = false,
  }) : _url = url,
       _publishableKey = publishableKey,
       _client = client ?? http.Client(),
       _appInfoService = appInfoService,
       _now = now ?? DateTime.now,
       _random = random ?? Random.secure(),
       _asksForConsent = asksForConsent;

  /// The public web demo stays silent until its visitor agrees.
  factory UsageService.fromConfig() {
    return UsageService(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      asksForConsent: kIsWeb,
    );
  }

  static const _enabledKey = 'usageStatsEnabled';
  static const _installIdKey = 'usageInstallId';
  static const _daysKey = 'usageDays';
  static const _factsKey = 'usageFacts';
  static const _timeout = Duration(seconds: 15);

  /// Older days are dropped. The server rejects them anyway.
  static const _maxDaysKept = 14;

  final String _url;
  final String _publishableKey;
  final http.Client _client;
  final AppInfoService _appInfoService;
  final DateTime Function() _now;
  final Random _random;
  final bool _asksForConsent;

  /// Runs saves one after another, so two quick events cannot overwrite each
  /// other's numbers.
  Future<void> _queue = Future.value();

  /// Events from before the answer. They stay in memory, so nothing reaches
  /// the browser's storage until the visitor agrees.
  final _waitingForConsent = <Future<void> Function(SharedPreferences prefs)>[];

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? !_asksForConsent;
  }

  Future<bool> needsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return _asksForConsent && !prefs.containsKey(_enabledKey);
  }

  /// Turning this off also forgets the id and all unsent numbers, so turning
  /// it on later starts a new, unconnected history.
  Future<void> setEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, isEnabled);
    final waiting = [..._waitingForConsent];
    _waitingForConsent.clear();
    if (isEnabled) {
      await Future.wait(waiting.map(_record));
      return;
    }

    await prefs.remove(_installIdKey);
    await prefs.remove(_daysKey);
    await prefs.remove(_factsKey);
  }

  Future<void> cardCompleted(String factId, {required bool liked}) {
    return _record((prefs) async {
      await _updateToday(
        prefs,
        (day) => day.copyWith(cardsCompleted: day.cardsCompleted + 1),
      );
      await _addToFact(
        prefs,
        factId,
        FactUsage(shown: 1, liked: liked ? 1 : 0),
      );
    });
  }

  Future<void> factOpened(String factId) {
    return _record(
      (prefs) => _addToFact(prefs, factId, const FactUsage(opened: 1)),
    );
  }

  Future<void> factShared(String factId) {
    return _record(
      (prefs) => _addToFact(prefs, factId, const FactUsage(shared: 1)),
    );
  }

  Future<void> quizAnswered(String factId, {required bool isCorrect}) {
    return _record(
      (prefs) => _addToFact(
        prefs,
        factId,
        FactUsage(quizCorrect: isCorrect ? 1 : 0, quizWrong: isCorrect ? 0 : 1),
      ),
    );
  }

  Future<void> bonusRoundStarted() {
    return _record(
      (prefs) => _updateToday(
        prefs,
        (day) => day.copyWith(bonusRounds: day.bonusRounds + 1),
      ),
    );
  }

  Future<void> categoriesChanged() {
    return _record(
      (prefs) =>
          _updateToday(prefs, (day) => day.copyWith(categoriesChanged: true)),
    );
  }

  Future<void> remindersState({required bool isEnabled}) {
    return _record(
      (prefs) => _updateToday(
        prefs,
        (day) => day.copyWith(remindersEnabled: isEnabled),
      ),
    );
  }

  Future<void> instructionsLeft({required bool skipped}) {
    return _record(
      (prefs) => _updateToday(
        prefs,
        (day) => day.copyWith(instructions: skipped ? 'skipped' : 'finished'),
      ),
    );
  }

  Future<void> categoriesChosen({required bool choseAll}) {
    return _record(
      (prefs) => _updateToday(
        prefs,
        (day) => day.copyWith(choseAllCategories: choseAll),
      ),
    );
  }

  Future<void> notificationsAnswered({required bool isAllowed}) {
    return _record(
      (prefs) => _updateToday(
        prefs,
        (day) => day.copyWith(notificationsAllowed: isAllowed),
      ),
    );
  }

  /// Saves the finished day and sends it at once, as the app may not start
  /// again for a while.
  Future<void> dayFinished({
    required int streak,
    required int? quizCorrect,
    required int quizTotal,
  }) {
    return _record((prefs) async {
      await _updateToday(
        prefs,
        (day) => day.copyWith(
          deckFinished: true,
          quizCorrect: quizCorrect,
          quizTotal: quizTotal,
          streakBucket: UsageDay.bucketOf(streak),
        ),
      );
      await _send(prefs);
    });
  }

  /// Notes that the app was used today and sends what is waiting. A failure
  /// is retried on the next start, and the app works the same without it.
  Future<void> recordToday() {
    return _record((prefs) async {
      await _updateToday(prefs, (day) => day, keepSent: true);
      await _send(prefs);
    });
  }

  Future<void> _record(Future<void> Function(SharedPreferences prefs) action) {
    final result = _queue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (await needsConsent()) {
          _waitingForConsent.add(action);
        } else if (await isEnabled()) {
          await action(prefs);
        }
      } catch (_) {
        // Statistics must never disturb the app.
      }
    });
    _queue = result;
    return result;
  }

  Map<String, UsageDay> _readDays(SharedPreferences prefs) {
    final stored = prefs.getString(_daysKey);
    if (stored == null) return {};
    final items = jsonDecode(stored) as Map<String, dynamic>;
    return items.map(
      (date, item) =>
          MapEntry(date, UsageDay.fromJson(item as Map<String, dynamic>)),
    );
  }

  Future<void> _saveDays(
    SharedPreferences prefs,
    Map<String, UsageDay> days,
  ) async {
    await prefs.setString(
      _daysKey,
      jsonEncode(days.map((date, day) => MapEntry(date, day.toJson()))),
    );
  }

  Future<void> _updateToday(
    SharedPreferences prefs,
    UsageDay Function(UsageDay day) change, {
    bool keepSent = false,
  }) async {
    final today = DailyDeck.dateKey(_now());
    final days = _readDays(prefs);
    final known = days[today];
    if (known != null && keepSent) return;

    days[today] = change(known ?? UsageDay(date: today));
    await _saveDays(prefs, days);
  }

  Map<String, FactUsage> _readFacts(SharedPreferences prefs) {
    final stored = prefs.getString(_factsKey);
    if (stored == null) return {};
    final items = jsonDecode(stored) as Map<String, dynamic>;
    return items.map(
      (id, item) =>
          MapEntry(id, FactUsage.fromJson(item as Map<String, dynamic>)),
    );
  }

  Future<void> _addToFact(
    SharedPreferences prefs,
    String factId,
    FactUsage usage,
  ) async {
    final facts = _readFacts(prefs);
    facts[factId] = (facts[factId] ?? const FactUsage()) + usage;
    await prefs.setString(
      _factsKey,
      jsonEncode(facts.map((id, item) => MapEntry(id, item.toJson()))),
    );
  }

  Future<void> _send(SharedPreferences prefs) async {
    await _sendDays(prefs);
    await _sendFacts(prefs);
  }

  /// Today stays in storage after sending, because more of it may follow.
  Future<void> _sendDays(SharedPreferences prefs) async {
    final today = DailyDeck.dateKey(_now());
    final days = _readDays(prefs);
    final dates = days.keys.toList()..sort();
    for (final date in dates.reversed.skip(_maxDaysKept)) {
      days.remove(date);
    }

    for (final day in days.values.toList()) {
      if (day.isSent) {
        if (day.date != today) days.remove(day.date);
        continue;
      }

      final isSaved = await _post('record_usage_day', {
        'p_report': {
          ...day.toRow(),
          'install_id': await _installId(prefs),
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'app_version': await _appInfoService.getVersion(),
        },
      });
      if (!isSaved) break;

      if (day.date == today) {
        days[day.date] = day.asSent();
      } else {
        days.remove(day.date);
      }
      await _saveDays(prefs, days);
    }
    await _saveDays(prefs, days);
  }

  Future<void> _sendFacts(SharedPreferences prefs) async {
    final facts = _readFacts(prefs);
    if (facts.isEmpty) return;

    final isSaved = await _post('record_fact_stats', {
      'p_stats': [
        for (final MapEntry(key: id, value: usage) in facts.entries)
          {'id': id, ...usage.toJson()},
      ],
    });
    if (isSaved) await prefs.remove(_factsKey);
  }

  Future<bool> _post(String function, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse('$_url/rest/v1/rpc/$function'),
          headers: {
            'apikey': _publishableKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return response.statusCode < 300;
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
