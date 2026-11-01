/// The platform's notification system, kept behind an interface so the rules
/// in `ReminderService` can be tested without a device.
abstract interface class ReminderScheduler {
  /// Browsers cannot schedule notifications for later.
  bool get isSupported;

  /// Returns whether the user allows notifications.
  Future<bool> requestPermission();

  /// Replaces all planned reminders with one at each of [times].
  Future<void> replaceAll(List<DateTime> times);
}
