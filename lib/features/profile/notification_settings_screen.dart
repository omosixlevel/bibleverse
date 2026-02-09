import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../../core/models/user_profile.dart';

/// Notification Settings Screen
/// Granular control over notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  final UserProfile profile;

  const NotificationSettingsScreen({super.key, required this.profile});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final ProfileService _profileService = ProfileService();
  late bool _allNotifications;
  late bool _eventReminders;
  late bool _taskReminders;
  late bool _roomActivity;
  late bool _dailyDevotional;
  late bool _weeklyDigest;

  @override
  void initState() {
    super.initState();
    _allNotifications = widget.profile.preferences.notificationsEnabled;
    // Initialize other settings (would come from expanded preferences model)
    _eventReminders = true;
    _taskReminders = true;
    _roomActivity = false;
    _dailyDevotional = true;
    _weeklyDigest = true;
  }

  Future<void> _updatePreferences() async {
    final newPrefs = widget.profile.preferences.copyWith(
      notificationsEnabled: _allNotifications,
    );

    await _profileService.updatePreferences(widget.profile.uid, newPrefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          // Master Toggle
          Container(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: SwitchListTile(
              title: const Text(
                'All Notifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Enable or disable all notifications'),
              value: _allNotifications,
              onChanged: (value) {
                setState(() => _allNotifications = value);
                _updatePreferences();
              },
            ),
          ),
          const Divider(height: 1),

          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'NOTIFICATION TYPES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Event Reminders
          SwitchListTile(
            title: const Text('Event Reminders'),
            subtitle: const Text('Get notified before events start'),
            value: _eventReminders && _allNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _eventReminders = value)
                : null,
            secondary: const Icon(Icons.event),
          ),

          // Task Reminders
          SwitchListTile(
            title: const Text('Task Reminders'),
            subtitle: const Text('Reminders for pending tasks'),
            value: _taskReminders && _allNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _taskReminders = value)
                : null,
            secondary: const Icon(Icons.task_alt),
          ),

          // Room Activity
          SwitchListTile(
            title: const Text('Room Activity'),
            subtitle: const Text('New messages and updates in your rooms'),
            value: _roomActivity && _allNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _roomActivity = value)
                : null,
            secondary: const Icon(Icons.groups),
          ),

          const Divider(height: 32),

          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'DAILY & WEEKLY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Daily Devotional
          SwitchListTile(
            title: const Text('Daily Devotional'),
            subtitle: const Text('Morning scripture and reflection'),
            value: _dailyDevotional && _allNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _dailyDevotional = value)
                : null,
            secondary: const Icon(Icons.wb_sunny),
          ),

          // Weekly Digest
          SwitchListTile(
            title: const Text('Weekly Digest'),
            subtitle: const Text('Summary of your spiritual journey'),
            value: _weeklyDigest && _allNotifications,
            onChanged: _allNotifications
                ? (value) => setState(() => _weeklyDigest = value)
                : null,
            secondary: const Icon(Icons.email),
          ),

          const SizedBox(height: 16),

          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications help you stay connected with your spiritual community and maintain consistency in your practices.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
