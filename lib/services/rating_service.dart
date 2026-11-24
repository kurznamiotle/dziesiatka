import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides when to call the Google Play review flow, and calls it.
///
/// Google Play rules: no own question before the system dialog, no reward and
/// no asking only happy users. So the flow is only started, without a word,
/// and Google decides whether a dialog shows at all. The API does not tell
/// whether it showed or whether the user rated, so every call counts as an
/// attempt.
class RatingService {
  RatingService(
    this._streakService, {
    DateTime Function()? now,
    bool? isSupported,
    Future<bool> Function()? isAvailable,
    Future<void> Function()? requestReview,
    Future<void> Function()? openStoreListing,
  }) : _now = now ?? DateTime.now,
       isSupported =
           isSupported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
       _isAvailable = isAvailable ?? InAppReview.instance.isAvailable,
       _requestReview = requestReview ?? InAppReview.instance.requestReview,
       _openStoreListing =
           openStoreListing ?? InAppReview.instance.openStoreListing;

  /// Days finished with Dziesiątka before the first request.
  static const minCompletedDays = 3;

  /// The share of correct quiz answers that counts as a good day.
  static const minQuizShare = 0.75;

  /// Days between two requests.
  static const daysBetweenRequests = 60;

  /// Requests in total, since the API cannot tell whether one was answered.
  static const maxRequests = 3;

  static const _firstStartKey = 'ratingFirstStart';
  static const _quietDayKey = 'ratingQuietDay';
  static const _requestsKey = 'ratingRequests';

  final StreakService _streakService;
  final DateTime Function() _now;
  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _requestReview;
  final Future<void> Function() _openStoreListing;

  /// Only the Android app is in Google Play, so the web version shows neither
  /// the review dialog nor the button.
  final bool isSupported;

  /// Remembers the first start, so the first session never asks.
  Future<void> recordAppStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_firstStartKey) != null) return;
      await prefs.setString(_firstStartKey, _today);
    } catch (_) {}
  }

  /// Keeps today free of the review request, because something else already
  /// asked for the user's attention, such as a celebrated achievement.
  Future<void> recordOtherPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_quietDayKey, _today);
    } catch (_) {}
  }

  /// Whether a finished day with this quiz result may start the review flow.
  Future<bool> isReviewDue({
    required int? quizCorrect,
    required int quizTotal,
  }) async {
    if (!isSupported) return false;
    if (quizTotal <= 0 || (quizCorrect ?? 0) < quizTotal * minQuizShare) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = _today;
    final firstStart = prefs.getString(_firstStartKey);
    if (firstStart == null || firstStart == today) return false;
    if (prefs.getString(_quietDayKey) == today) return false;

    final requests = prefs.getStringList(_requestsKey) ?? const [];
    if (requests.length >= maxRequests) return false;
    if (requests.isNotEmpty &&
        _daysSince(requests.last) < daysBetweenRequests) {
      return false;
    }

    final days = await _streakService.getCompletedDays();
    return days.contains(today) && days.length >= minCompletedDays;
  }

  /// Starts the review flow when [isReviewDue] allows it. Returns whether the
  /// flow was started, not whether a dialog showed.
  Future<bool> requestReviewIfDue({
    required int? quizCorrect,
    required int quizTotal,
  }) async {
    try {
      if (!await isReviewDue(quizCorrect: quizCorrect, quizTotal: quizTotal)) {
        return false;
      }
      if (!await _isAvailable()) return false;

      final prefs = await SharedPreferences.getInstance();
      final requests = prefs.getStringList(_requestsKey) ?? const [];
      await prefs.setStringList(_requestsKey, [...requests, _today]);
      await _requestReview();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's page in Google Play. Returns false when it failed.
  Future<bool> openStoreListing() async {
    if (!isSupported) return false;
    try {
      await _openStoreListing();
      return true;
    } catch (_) {
      return false;
    }
  }

  String get _today => DailyDeck.dateKey(_now());

  int _daysSince(String dateKey) {
    final date = DateTime.parse(dateKey);
    final today = _now();
    return DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
  }
}
