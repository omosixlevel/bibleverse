import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity_model.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = activity.endDateTime.isBefore(DateTime.now());
    final isOngoing =
        activity.startDateTime.isBefore(DateTime.now()) && !isOver;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, theme, isOngoing, isOver),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(theme, isOngoing, isOver),
                  const SizedBox(height: 16),
                  Text(
                    activity.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.activityType.name.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Divider(height: 48),
                  _buildSectionTitle(theme, 'ABOUT THIS GATHERING'),
                  const SizedBox(height: 12),
                  Text(
                    activity.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(theme, 'TIME & LOGISTICS'),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    theme,
                    Icons.calendar_today_rounded,
                    'Date & Time',
                    '${DateFormat('EEEE, MMM dd').format(activity.startDateTime)}\n${DateFormat('HH:mm').format(activity.startDateTime)} - ${DateFormat('HH:mm').format(activity.endDateTime)}',
                  ),
                  _buildInfoTile(
                    theme,
                    Icons.place_outlined,
                    'Location',
                    activity.locationName,
                    trailing: activity.mapLink.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.map_outlined),
                            onPressed: () {},
                          )
                        : null,
                  ),
                  _buildInfoTile(
                    theme,
                    Icons.contact_mail_outlined,
                    'Organizer Contact',
                    activity.organizerContact,
                  ),
                  const SizedBox(height: 32),
                  if (activity.config != null) ...[
                    _buildSectionTitle(theme, 'DIVINE CONFIGURATION'),
                    const SizedBox(height: 16),
                    _buildConfigSections(theme),
                  ],
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(
        context,
        theme,
        isOngoing,
        isOver,
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isOngoing,
    bool isOver,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
            ),
          ),
          child: Center(
            child: Icon(
              _getActivityIcon(),
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, bool isOngoing, bool isOver) {
    Color color = Colors.blue;
    String label = 'UPCOMING';

    if (isOver) {
      color = Colors.grey;
      label = 'COMPLETED';
    } else if (isOngoing) {
      color = Colors.orange;
      label = 'ONGOING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: theme.colorScheme.outline,
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildConfigSections(ThemeData theme) {
    final config = activity.config!;
    List<Widget> children = [];

    if (config['scripture'] != null && config['scripture'].isNotEmpty) {
      children.add(
        _buildConfigItem(
          theme,
          Icons.menu_book_rounded,
          'Scripture Reference',
          config['scripture'],
        ),
      );
    }

    if (config['meetingObjectives'] != null &&
        (config['meetingObjectives'] as List).isNotEmpty) {
      children.add(
        _buildConfigItem(
          theme,
          Icons.flag_rounded,
          'Meeting Objectives',
          (config['meetingObjectives'] as List).join('\n• '),
          isList: true,
        ),
      );
    }

    if (config['videoUrls'] != null &&
        (config['videoUrls'] as List).isNotEmpty) {
      children.add(
        _buildConfigItem(
          theme,
          Icons.video_library_rounded,
          'Watch Resources',
          (config['videoUrls'] as List).join('\n'),
          isLink: true,
        ),
      );
    }

    return Column(children: children);
  }

  Widget _buildConfigItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool isList = false,
    bool isLink = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isList ? '• $value' : value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: isLink ? FontStyle.italic : FontStyle.normal,
                    color: isLink ? Colors.blue[700] : null,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomAction(
    BuildContext context,
    ThemeData theme,
    bool isOngoing,
    bool isOver,
  ) {
    if (isOver) return null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: isOngoing
                ? Colors.orange
                : theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: (isOngoing ? Colors.orange : theme.colorScheme.primary)
                .withOpacity(0.4),
          ),
          child: Text(
            isOngoing ? 'JOIN GATHERING' : 'SET REMINDER',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (activity.activityType) {
      case ActivityType.prayer:
        return Icons.front_hand_rounded;
      case ActivityType.worship:
        return Icons.music_note_rounded;
      case ActivityType.rhema:
        return Icons.auto_stories_rounded;
      case ActivityType.evangelism:
        return Icons.campaign_rounded;
      case ActivityType.meeting:
        return Icons.groups_rounded;
      default:
        return Icons.event_available_rounded;
    }
  }
}
