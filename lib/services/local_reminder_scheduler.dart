import 'package:dziesiatka/services/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'daily_reminder';
const _channelName = 'Codzienne przypomnienie';
const _channelDescription = 'Przypomina o nieukończonej talii ciekawostek.';
const _title = 'Twoja dziesiątka czeka';
const _bodies = [
  'Kilka minut i dzisiejsze ciekawostki są Twoje.',
  'Nie trać serii! Dzisiejsza talia wciąż czeka.',
  'Dziesięć nowych ciekawostek na dziś. Sprawdzisz?',
];

/// Schedules reminders with the phone's notification system.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  bool get isSupported => !kIsWeb;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permissions are requested later, after the welcome screen explains
        // the app, and not on the first launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> replaceAll(List<DateTime> times) async {
    await _initialize();
    await _plugin.cancelAll();
    for (final (index, time) in times.indexed) {
      await _plugin.zonedSchedule(
        id: index,
        // Built from the calendar fields, so the hour stays the same across a
        // daylight saving change.
        scheduledDate: tz.TZDateTime(
          tz.local,
          time.year,
          time.month,
          time.day,
          time.hour,
        ),
        title: _title,
        body: _bodies[time.day % _bodies.length],
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Exact alarms need a special permission that a reminder does not
        // justify, so the system may deliver this a little late.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
