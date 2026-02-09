import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/notification_config.dart';

/// Notification settings screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _notificationService = NotificationService();
  late NotificationConfig _config;

  @override
  void initState() {
    super.initState();
    _config = _notificationService.config;
  }

  Future<void> _updateConfig(NotificationConfig newConfig) async {
    setState(() {
      _config = newConfig;
    });
    await _notificationService.updateConfig(newConfig);
  }

  Future<void> _showTestNotification() async {
    await _notificationService.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test notification sent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Types Section
          Text(
            'Notification Types',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Daily Reminders'),
            subtitle: const Text('Morning and evening devotionals'),
            value: _config.dailyRemindersEnabled,
            onChanged: (value) {
              _updateConfig(_config.copyWith(dailyRemindersEnabled: value));
            },
          ),

          SwitchListTile(
            title: const Text('Event Reminders'),
            subtitle: const Text('Notifications before events start'),
            value: _config.eventRemindersEnabled,
            onChanged: (value) {
              _updateConfig(_config.copyWith(eventRemindersEnabled: value));
            },
          ),

          SwitchListTile(
            title: const Text('Room Notifications'),
            subtitle: const Text('Task deadlines and room activities'),
            value: _config.roomNotificationsEnabled,
            onChanged: (value) {
              _updateConfig(_config.copyWith(roomNotificationsEnabled: value));
            },
          ),

          SwitchListTile(
            title: const Text('Reading Streak'),
            subtitle: const Text('Reminders to maintain reading streak'),
            value: _config.readingStreakEnabled,
            onChanged: (value) {
              _updateConfig(_config.copyWith(readingStreakEnabled: value));
            },
          ),

          const Divider(height: 32),

          // Daily Reminder Times
          if (_config.dailyRemindersEnabled) ...[
            Text(
              'Daily Reminder Times',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Morning Reminder'),
              subtitle: Text(
                '${_config.morningReminderHour.toString().padLeft(2, '0')}:${_config.morningReminderMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _config.morningReminderHour,
                    minute: _config.morningReminderMinute,
                  ),
                );
                if (time != null) {
                  _updateConfig(
                    _config.copyWith(
                      morningReminderHour: time.hour,
                      morningReminderMinute: time.minute,
                    ),
                  );
                }
              },
            ),

            ListTile(
              title: const Text('Evening Reminder'),
              subtitle: Text(
                '${_config.eveningReminderHour.toString().padLeft(2, '0')}:${_config.eveningReminderMinute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _config.eveningReminderHour,
                    minute: _config.eveningReminderMinute,
                  ),
                );
                if (time != null) {
                  _updateConfig(
                    _config.copyWith(
                      eveningReminderHour: time.hour,
                      eveningReminderMinute: time.minute,
                    ),
                  );
                }
              },
            ),

            const Divider(height: 32),
          ],

          // Quiet Hours
          Text(
            'Quiet Hours',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will not be sent during quiet hours',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Enable Quiet Hours'),
            value: _config.quietHoursEnabled,
            onChanged: (value) {
              _updateConfig(_config.copyWith(quietHoursEnabled: value));
            },
          ),

          if (_config.quietHoursEnabled) ...[
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(
                '${_config.quietHoursStart.toString().padLeft(2, '0')}:00',
              ),
              trailing: const Icon(Icons.bedtime),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _config.quietHoursStart,
                    minute: 0,
                  ),
                );
                if (time != null) {
                  _updateConfig(_config.copyWith(quietHoursStart: time.hour));
                }
              },
            ),

            ListTile(
              title: const Text('End Time'),
              subtitle: Text(
                '${_config.quietHoursEnd.toString().padLeft(2, '0')}:00',
              ),
              trailing: const Icon(Icons.wb_sunny),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _config.quietHoursEnd,
                    minute: 0,
                  ),
                );
                if (time != null) {
                  _updateConfig(_config.copyWith(quietHoursEnd: time.hour));
                }
              },
            ),
          ],

          const Divider(height: 32),

          // Test Notification Button
          ElevatedButton.icon(
            onPressed: _showTestNotification,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Test Notification'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }
}
