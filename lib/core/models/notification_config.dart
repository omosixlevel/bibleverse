/// Notification configuration model
class NotificationConfig {
  final bool dailyRemindersEnabled;
  final bool eventRemindersEnabled;
  final bool roomNotificationsEnabled;
  final bool readingStreakEnabled;
  final bool prayerRemindersEnabled;

  final int morningReminderHour; // 0-23
  final int morningReminderMinute; // 0-59
  final int eveningReminderHour;
  final int eveningReminderMinute;

  final int eventReminderMinutes; // Minutes before event (15, 30, 60)

  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour (0-23)
  final int quietHoursEnd; // Hour (0-23)

  NotificationConfig({
    this.dailyRemindersEnabled = true,
    this.eventRemindersEnabled = true,
    this.roomNotificationsEnabled = true,
    this.readingStreakEnabled = true,
    this.prayerRemindersEnabled = false,
    this.morningReminderHour = 8,
    this.morningReminderMinute = 0,
    this.eveningReminderHour = 20,
    this.eveningReminderMinute = 0,
    this.eventReminderMinutes = 30,
    this.quietHoursEnabled = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
  });

  Map<String, dynamic> toJson() => {
    'dailyRemindersEnabled': dailyRemindersEnabled,
    'eventRemindersEnabled': eventRemindersEnabled,
    'roomNotificationsEnabled': roomNotificationsEnabled,
    'readingStreakEnabled': readingStreakEnabled,
    'prayerRemindersEnabled': prayerRemindersEnabled,
    'morningReminderHour': morningReminderHour,
    'morningReminderMinute': morningReminderMinute,
    'eveningReminderHour': eveningReminderHour,
    'eveningReminderMinute': eveningReminderMinute,
    'eventReminderMinutes': eventReminderMinutes,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory NotificationConfig.fromJson(
    Map<String, dynamic> json,
  ) => NotificationConfig(
    dailyRemindersEnabled: json['dailyRemindersEnabled'] as bool? ?? true,
    eventRemindersEnabled: json['eventRemindersEnabled'] as bool? ?? true,
    roomNotificationsEnabled: json['roomNotificationsEnabled'] as bool? ?? true,
    readingStreakEnabled: json['readingStreakEnabled'] as bool? ?? true,
    prayerRemindersEnabled: json['prayerRemindersEnabled'] as bool? ?? false,
    morningReminderHour: json['morningReminderHour'] as int? ?? 8,
    morningReminderMinute: json['morningReminderMinute'] as int? ?? 0,
    eveningReminderHour: json['eveningReminderHour'] as int? ?? 20,
    eveningReminderMinute: json['eveningReminderMinute'] as int? ?? 0,
    eventReminderMinutes: json['eventReminderMinutes'] as int? ?? 30,
    quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
    quietHoursStart: json['quietHoursStart'] as int? ?? 22,
    quietHoursEnd: json['quietHoursEnd'] as int? ?? 7,
  );

  NotificationConfig copyWith({
    bool? dailyRemindersEnabled,
    bool? eventRemindersEnabled,
    bool? roomNotificationsEnabled,
    bool? readingStreakEnabled,
    bool? prayerRemindersEnabled,
    int? morningReminderHour,
    int? morningReminderMinute,
    int? eveningReminderHour,
    int? eveningReminderMinute,
    int? eventReminderMinutes,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
  }) => NotificationConfig(
    dailyRemindersEnabled: dailyRemindersEnabled ?? this.dailyRemindersEnabled,
    eventRemindersEnabled: eventRemindersEnabled ?? this.eventRemindersEnabled,
    roomNotificationsEnabled:
        roomNotificationsEnabled ?? this.roomNotificationsEnabled,
    readingStreakEnabled: readingStreakEnabled ?? this.readingStreakEnabled,
    prayerRemindersEnabled:
        prayerRemindersEnabled ?? this.prayerRemindersEnabled,
    morningReminderHour: morningReminderHour ?? this.morningReminderHour,
    morningReminderMinute: morningReminderMinute ?? this.morningReminderMinute,
    eveningReminderHour: eveningReminderHour ?? this.eveningReminderHour,
    eveningReminderMinute: eveningReminderMinute ?? this.eveningReminderMinute,
    eventReminderMinutes: eventReminderMinutes ?? this.eventReminderMinutes,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietHoursStart: quietHoursStart ?? this.quietHoursStart,
    quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
  );

  bool isQuietHours(DateTime time) {
    if (!quietHoursEnabled) return false;

    final hour = time.hour;
    if (quietHoursStart < quietHoursEnd) {
      // Normal case: e.g., 22:00 to 07:00
      return hour >= quietHoursStart || hour < quietHoursEnd;
    } else {
      // Wraps midnight: e.g., 22:00 to 07:00
      return hour >= quietHoursStart || hour < quietHoursEnd;
    }
  }
}
