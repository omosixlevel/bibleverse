import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../chats/chat_screen.dart';
import '../chats/chats_hub_screen.dart';
import '../../core/widgets/sacred_bottom_navigation.dart';
import 'event_management_screen.dart';
import '../../models/event_model.dart';

/// Events Screen with tabs for My Events and Public Events
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EVENTS HUB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Community Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatsHubScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_event_fab',
        onPressed: () => _showCreateEventDialog(context),
        label: const Text('New Event'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: const SacredFabLocation(),
      body: Column(
        children: [
          _buildOfflineBanner(context),
          Expanded(child: _buildEventsList(context, isMyEvents: true)),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Initiate New Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      hintText: 'e.g., 21 Days of Daniel Fast',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Objective/Vision',
                      hintText: 'What is the spiritual goal of this event?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(startDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('MMM dd, yyyy').format(endDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    final repository = context.read<Repository>();
                    await repository.createEvent({
                      'title': titleController.text.trim(),
                      'shortDescription': descriptionController.text.trim(),
                      'status': 'upcoming',
                      'startDate': startDate.toIso8601String(),
                      'endDate': endDate.toIso8601String(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Event "${titleController.text}" initiated! 🙏',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Initiate'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline Mode: Local Storage active',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, {required bool isMyEvents}) {
    final repository = context.read<Repository>();

    return StreamBuilder<List<Event>>(
      stream: isMyEvents
          ? repository.myEventsStream
          : repository.publicEventsDiscoveryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMyEvents ? Icons.event_available : Icons.event_note,
                  size: 64,
                  color: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  isMyEvents
                      ? 'You have no scheduled events.'
                      : 'No public events found.',
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100, // Space for FAB
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return EventCard(
              title: item.title,
              description: item.shortDescription,
              startDate: item.startDate,
              endDate: item.endDate,
              adminName: item.creatorId == 'admin_1'
                  ? 'Apostle Spirit'
                  : 'Admin',
              status: item.dynamicStatus,
              roomCount: item.numberOfRooms,
              activityCount: item.numberOfActivities,
              completionRate: item.aggregateProgress,
              chatId: item.id,
              isJoined: item.isJoined,
              onJoin: () {
                repository.joinEvent(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined "${item.title}"! 🙏')),
                );
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventManagementScreen(eventId: item.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Reusable Event Card Widget
class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String adminName;
  final String status;
  final int roomCount;
  final int activityCount;
  final double completionRate;
  final String? chatId;
  final bool isJoined;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.adminName,
    required this.status,
    this.roomCount = 0,
    this.activityCount = 0,
    this.completionRate = 0.0,
    this.chatId,
    this.isJoined = true,
    this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Cover Image with Gradient & Icon
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.colorScheme.tertiary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildStatusBadge(theme, status),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildProgressRing(theme),
                  ),
                ],
              ),
            ),
            if (!isJoined)
              Expanded(child: _buildCardContent(context, theme))
            else
              _buildCardContent(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (chatId != null)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(chatId: chatId!, title: title),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                theme,
                Icons.home_work_outlined,
                '$roomCount Rooms',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                theme,
                Icons.local_fire_department_outlined,
                '$activityCount Activities',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_pin,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                adminName.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Divider(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              if (isJoined) ...[
                const Spacer(),
                Text(
                  'CONTINUE',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          // Only show Spacer and bottom Join button if NOT joined (Discovery mode)
          if (!isJoined) const Spacer(),
          if (!isJoined) ...[
            const Divider(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('JOIN THIS EVENT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressRing(ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: completionRate,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          Text(
            '${(completionRate * 100).toInt()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color badgeColor;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'ongoing':
        badgeColor = Colors.orange[800]!;
        break;
      case 'upcoming':
        badgeColor = theme.colorScheme.primary;
        break;
      case 'completed':
        badgeColor = Colors.teal;
        break;
      default:
        badgeColor = theme.colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.toLowerCase() == 'ongoing')
            Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
