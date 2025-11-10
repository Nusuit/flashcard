import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../models/app_settings.dart';
import 'storage_manager.dart';

/// Manages background reminders and notifications
class ReminderEngine {
  static final ReminderEngine _instance = ReminderEngine._internal();
  factory ReminderEngine() => _instance;
  ReminderEngine._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _taskName = 'knopQuizReminder';
  static const String _channelId = 'knop_quiz_channel';
  static const String _channelName = 'Quiz Reminders';
  static const String _channelDescription = 'Notifications for flashcard quizzes';

  /// Initialize notification system
  Future<void> initialize() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize WorkManager for background tasks
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to quiz screen
    // This will be handled by the main app
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule periodic reminders based on settings
  Future<void> scheduleReminders(AppSettings settings) async {
    // Cancel existing reminders
    await cancelReminders();

    // Schedule periodic task
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: Duration(hours: settings.reminderIntervalHours),
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
      inputData: {
        'active_hours_start': settings.activeHoursStart,
        'active_hours_end': settings.activeHoursEnd,
        'questions_per_session': settings.questionsPerSession,
      },
    );
  }

  /// Cancel all reminders
  Future<void> cancelReminders() async {
    await Workmanager().cancelByUniqueName(_taskName);
    await _notifications.cancelAll();
  }

  /// Show immediate notification (for testing or manual trigger)
  Future<void> showQuizNotification({
    String title = '🎴 Time for a Quiz!',
    String body = 'Ready to practice your flashcards?',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      details,
      payload: 'quiz_reminder',
    );
  }

  /// Check if it's appropriate time to show notification
  bool shouldShowNotification(int activeHoursStart, int activeHoursEnd) {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= activeHoursStart && hour < activeHoursEnd;
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android doesn't require runtime permission for notifications (before Android 13)
    return true;
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Check if within active hours
      final activeStart = inputData?['active_hours_start'] as int? ?? 8;
      final activeEnd = inputData?['active_hours_end'] as int? ?? 22;
      
      final now = DateTime.now();
      final hour = now.hour;

      if (hour >= activeStart && hour < activeEnd) {
        // Show notification
        final notifications = FlutterLocalNotificationsPlugin();
        
        const androidDetails = AndroidNotificationDetails(
          'knop_quiz_channel',
          'Quiz Reminders',
          channelDescription: 'Notifications for flashcard quizzes',
          importance: Importance.high,
          priority: Priority.high,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await notifications.show(
          0,
          '🎴 Time for a Quiz!',
          'Ready to practice? Tap to start learning.',
          details,
          payload: 'quiz_reminder',
        );
      }

      return Future.value(true);
    } catch (e) {
      print('Error in background task: $e');
      return Future.value(false);
    }
  });
}

/// Simple scheduler for immediate reminders (alternative approach)
class SimpleReminderScheduler {
  static Future<void> scheduleNextReminder(
    FlutterLocalNotificationsPlugin notifications,
    AppSettings settings,
  ) async {
    final now = DateTime.now();
    var nextReminder = now.add(Duration(hours: settings.reminderIntervalHours));

    // If next reminder is outside active hours, schedule for next day's start
    if (nextReminder.hour < settings.activeHoursStart) {
      nextReminder = DateTime(
        nextReminder.year,
        nextReminder.month,
        nextReminder.day,
        settings.activeHoursStart,
      );
    } else if (nextReminder.hour >= settings.activeHoursEnd) {
      nextReminder = DateTime(
        nextReminder.year,
        nextReminder.month,
        nextReminder.day + 1,
        settings.activeHoursStart,
      );
    }

    // Schedule notification
    await notifications.zonedSchedule(
      0,
      '🎴 Time for a Quiz!',
      'Ready to practice your flashcards?',
      _nextInstanceOfTime(nextReminder),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'knop_quiz_channel',
          'Quiz Reminders',
          channelDescription: 'Notifications for flashcard quizzes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static dynamic _nextInstanceOfTime(DateTime time) {
    // This requires timezone package
    // For simplicity, returning a basic implementation
    // In production, use timezone package and TZDateTime
    return time;
  }
}
