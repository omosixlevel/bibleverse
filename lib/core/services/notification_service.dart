import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import '../models/notification_config.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationConfig _config = NotificationConfig();
  static const String _configKey = 'notification_config';

  // Notification IDs
  static const int morningReminderId = 1;
  static const int eveningReminderId = 2;
  static const int readingStreakId = 3;
  static const int eventReminderBaseId = 1000;
  static const int roomNotificationBaseId = 2000;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Load config
    await _loadConfig();

    // Initialize plugin
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions
    await _requestPermissions();

    // Schedule daily reminders if enabled
    if (_config.dailyRemindersEnabled) {
      await scheduleDailyReminders();
    }
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate
      // Format: "type:id" e.g., "event:123", "room:456", "reading"
      print('Notification tapped: $payload');
      // TODO: Implement navigation logic
    }
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        _config = NotificationConfig.fromJson(json.decode(configJson));
      }
    } catch (e) {
      print('Error loading notification config: $e');
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, json.encode(_config.toJson()));
    } catch (e) {
      print('Error saving notification config: $e');
    }
  }

  /// Get current configuration
  NotificationConfig get config => _config;

  /// Update configuration
  Future<void> updateConfig(NotificationConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();

    // Reschedule notifications based on new config
    await cancelAllNotifications();
    if (_config.dailyRemindersEnabled) {
      await scheduleDailyReminders();
    }
  }

  /// Schedule daily morning and evening reminders
  Future<void> scheduleDailyReminders() async {
    if (!_config.dailyRemindersEnabled) return;

    // Morning reminder
    await _scheduleDailyNotification(
      id: morningReminderId,
      hour: _config.morningReminderHour,
      minute: _config.morningReminderMinute,
      title: '🌅 Morning Devotional',
      body: 'Start your day with God\'s Word',
      payload: 'daily:morning',
    );

    // Evening reminder
    await _scheduleDailyNotification(
      id: eveningReminderId,
      hour: _config.eveningReminderHour,
      minute: _config.eveningReminderMinute,
      title: '🌙 Evening Reflection',
      body: 'End your day in prayer and meditation',
      payload: 'daily:evening',
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Check quiet hours
    if (_config.isQuietHours(scheduledDate)) {
      return; // Skip if in quiet hours
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily spiritual reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedule event reminder
  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
  }) async {
    if (!_config.eventRemindersEnabled) return;

    final reminderTime = eventTime.subtract(
      Duration(minutes: _config.eventReminderMinutes),
    );

    // Don't schedule if in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    // Check quiet hours
    if (_config.isQuietHours(reminderTime)) return;

    final id = eventReminderBaseId + eventId.hashCode % 1000;

    await _notifications.zonedSchedule(
      id,
      '📅 Event Starting Soon',
      '$eventTitle starts in ${_config.eventReminderMinutes} minutes',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Event Reminders',
          channelDescription: 'Reminders for upcoming events',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'event:$eventId',
    );
  }

  /// Schedule room task deadline notification
  Future<void> scheduleRoomTaskDeadline({
    required String roomId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    if (!_config.roomNotificationsEnabled) return;

    // Notify 1 hour before deadline
    final reminderTime = deadline.subtract(const Duration(hours: 1));

    // Don't schedule if in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    // Check quiet hours
    if (_config.isQuietHours(reminderTime)) return;

    final id = roomNotificationBaseId + roomId.hashCode % 1000;

    await _notifications.zonedSchedule(
      id,
      '⏰ Task Deadline Approaching',
      '$taskTitle is due in 1 hour',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'room_notifications',
          'Room Notifications',
          channelDescription: 'Notifications for room activities',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'room:$roomId',
    );
  }

  /// Schedule reading streak reminder
  Future<void> scheduleReadingStreakReminder() async {
    if (!_config.readingStreakEnabled) return;

    // Schedule for 8 PM if user hasn't read today
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 20, 0);

    // If it's past 8 PM, schedule for tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    // Check quiet hours
    if (_config.isQuietHours(reminderTime)) return;

    await _notifications.zonedSchedule(
      readingStreakId,
      '📖 Keep Your Streak Alive',
      'You haven\'t read the Bible today. Take a moment to connect with God\'s Word.',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_streak',
          'Reading Streak',
          channelDescription: 'Reminders to maintain reading streak',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reading',
    );
  }

  /// Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      '✨ Test Notification',
      'Notifications are working correctly!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test Notifications',
          channelDescription: 'Test notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'test',
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
