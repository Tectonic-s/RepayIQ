import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Callback set by main.dart — called when user taps a notification
  static void Function(String route)? onNotificationTap;

  static Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && onNotificationTap != null) {
          onNotificationTap!(payload);
        }
      },
    );

    // Handle notification tap when app was terminated
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && onNotificationTap != null) {
        onNotificationTap!(payload);
      }
    }
  }

  /// Schedules reminder X days before due + payment check ON the due day
  static Future<void> scheduleLoanReminder({
    required String loanId,
    required String loanName,
    required int dueDay,
    required int reminderDays,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // 1. Reminder X days before due
    final reminderId = loanId.hashCode.abs() % 100000;
    var reminderDate = tz.TZDateTime(
        tz.local, now.year, now.month, dueDay - reminderDays, 9, 0);
    if (reminderDate.isBefore(now)) {
      reminderDate = tz.TZDateTime(
          tz.local, now.year, now.month + 1, dueDay - reminderDays, 9, 0);
    }

    await _plugin.zonedSchedule(
      reminderId,
      'EMI Due Soon',
      '$loanName EMI is due in $reminderDays day${reminderDays > 1 ? 's' : ''}',
      reminderDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_reminders', 'Loan Reminders',
          channelDescription: 'Reminders for upcoming EMI payments',
          importance: Importance.high, priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    // 2. Payment check ON the due day at 10am — deep links to confirm screen
    final paymentCheckId = (loanId.hashCode.abs() % 100000) + 2;
    var paymentCheckDate =
        tz.TZDateTime(tz.local, now.year, now.month, dueDay, 10, 0);
    if (paymentCheckDate.isBefore(now)) {
      paymentCheckDate = tz.TZDateTime(
          tz.local, now.year, now.month + 1, dueDay, 10, 0);
    }

    await _plugin.zonedSchedule(
      paymentCheckId,
      'Did you pay your EMI?',
      'Tap to confirm your $loanName payment for this month',
      paymentCheckDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_check', 'Payment Check',
          channelDescription: 'Monthly EMI payment confirmation',
          importance: Importance.high, priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            'Tap to confirm your $loanName payment for this month',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: '/payment-confirm/$loanId', // deep link route
    );
  }

  static Future<void> showOverdueNotification({
    required String loanId,
    required String loanName,
  }) async {
    final id = (loanId.hashCode.abs() % 100000) + 1;
    await _plugin.show(
      id,
      'EMI Overdue',
      '$loanName EMI payment is overdue. Tap to confirm.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_overdue', 'Overdue Loans',
          channelDescription: 'Alerts for overdue EMI payments',
          importance: Importance.max, priority: Priority.max,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: '/payment-confirm/$loanId',
    );
  }

  static Future<void> cancelLoanNotifications(String loanId) async {
    final base = loanId.hashCode.abs() % 100000;
    await _plugin.cancel(base);
    await _plugin.cancel(base + 1);
    await _plugin.cancel(base + 2);
  }

  /// Weekly AI nudge — every Sunday 10am, surfaces highest-interest loan.
  /// Call this whenever loans change (add/delete).
  static Future<void> scheduleWeeklyAiNudge({
    required String loanType,
    required double estimatedSavings,
  }) async {
    await _plugin.cancel(999001); // cancel previous
    final now = tz.TZDateTime.now(tz.local);
    // Next Sunday at 10:00
    final daysUntilSunday = (7 - now.weekday) % 7 == 0 ? 7 : (7 - now.weekday) % 7;
    final nextSunday = tz.TZDateTime(
      tz.local, now.year, now.month, now.day + daysUntilSunday, 10, 0,
    );
    await _plugin.zonedSchedule(
      999001,
      'RepayIQ Tip 💡',
      'Paying off your $loanType first could save you ₹${estimatedSavings.toStringAsFixed(0)}. Tap to see your strategy.',
      nextSunday,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ai_nudge', 'AI Tips',
          channelDescription: 'Weekly AI repayment tips',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '/ai',
    );
  }

  /// Weekly digest — every Sunday 9am, on-device summary.
  static Future<void> scheduleWeeklyDigest({
    required double totalEmiPaid,
    required double totalOutstanding,
    required int scoreDelta, // positive = improved, negative = dropped
  }) async {
    await _plugin.cancel(999002);
    final now = tz.TZDateTime.now(tz.local);
    final daysUntilSunday = (7 - now.weekday) % 7 == 0 ? 7 : (7 - now.weekday) % 7;
    final nextSunday = tz.TZDateTime(
      tz.local, now.year, now.month, now.day + daysUntilSunday, 9, 0,
    );
    final scoreText = scoreDelta > 0
        ? 'Score improved +$scoreDelta ⬆️'
        : scoreDelta < 0
            ? 'Score dropped $scoreDelta ⬇️'
            : 'Score unchanged';
    await _plugin.zonedSchedule(
      999002,
      'Your Weekly RepayIQ Digest',
      'EMI paid: ₹${totalEmiPaid.toStringAsFixed(0)} · Outstanding: ₹${totalOutstanding.toStringAsFixed(0)} · $scoreText',
      nextSunday,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_digest', 'Weekly Digest',
          channelDescription: 'Weekly loan summary',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(
            'EMI paid this week: ₹${totalEmiPaid.toStringAsFixed(0)}\nTotal outstanding: ₹${totalOutstanding.toStringAsFixed(0)}\n$scoreText',
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '/home',
    );
  }
}
