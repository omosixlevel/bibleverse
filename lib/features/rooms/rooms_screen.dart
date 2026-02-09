import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/event_model.dart';
import '../../models/room_model.dart';
import '../chats/chat_screen.dart';
import '../profile/governance_logs_screen.dart';
import 'room_detail_screen.dart';
import '../chats/chats_hub_screen.dart';

import '../../core/widgets/sacred_bottom_navigation.dart';
import 'widgets/sacred_task_config_sheet.dart';

/// Rooms Screen
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<Repository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROOMS HUB'),
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
        heroTag: 'create_room_fab',
        onPressed: () => showCreateRoomDialog(context),
        label: const Text('Create Room'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: const SacredFabLocation(),
      body: Column(
        children: [
          _buildOfflineBanner(context),
          Expanded(child: _buildRoomsList(repository, onlyJoined: true)),
        ],
      ),
    );
  }

  static void showCreateRoomDialog(
    BuildContext context, {
    String? initialEventId,
    String? initialEventTitle,
  }) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final objectiveController = TextEditingController();
    String selectedType = 'book_study';
    String privacy = 'public';
    Map<String, dynamic>? selectedEvent =
        (initialEventId != null && initialEventTitle != null)
        ? {'id': initialEventId, 'title': initialEventTitle}
        : null;
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 8));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final repository = context.read<Repository>();
          final theme = Theme.of(context);

          return AlertDialog(
            title: Text(
              'CREATE NEW SPACE',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Room Title',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'e.g., Early Morning Worship',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'The essence of this sacred room...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: objectiveController,
                      decoration: const InputDecoration(
                        labelText: 'Main Objective',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'What must be achieved here?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Room Type',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'book_study',
                          child: Text('Book Study'),
                        ),
                        DropdownMenuItem(
                          value: 'prayer_fasting',
                          child: Text('Prayer & Fasting'),
                        ),
                        DropdownMenuItem(
                          value: 'bible_study',
                          child: Text('Bible Study'),
                        ),
                        DropdownMenuItem(
                          value: 'retreat',
                          child: Text('Spiritual Retreat'),
                        ),
                        DropdownMenuItem(
                          value: 'worship',
                          child: Text('Worship Space'),
                        ),
                        DropdownMenuItem(
                          value: 'challenge',
                          child: Text('Spiritual Challenge'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (initialEventId != null && initialEventTitle != null)
                      TextField(
                        controller: TextEditingController(
                          text: initialEventTitle,
                        ),
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Sacred Event Context',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Icon(Icons.event_note),
                        ),
                      )
                    else
                      StreamBuilder<List<Event>>(
                        stream: repository.eventsStream,
                        builder: (context, snapshot) {
                          final events = snapshot.data ?? [];
                          return DropdownButtonFormField<String?>(
                            value: selectedEvent?['id'],
                            decoration: const InputDecoration(
                              labelText: 'Link to Event (Optional)',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              hintText: 'Select a parent event',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('None (Independent Room)'),
                              ),
                              ...events.map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.title),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == null) {
                                  selectedEvent = null;
                                } else {
                                  final e = events.firstWhere(
                                    (ev) => ev.id == val,
                                  );
                                  selectedEvent = {
                                    'id': e.id,
                                    'title': e.title,
                                  };
                                  privacy = 'public';
                                }
                              });
                            },
                          );
                        },
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
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null)
                                setDialogState(() => startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2030),
                              );
                              if (picked != null)
                                setDialogState(() => endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedEvent == null)
                      DropdownButtonFormField<String>(
                        value: privacy,
                        decoration: const InputDecoration(labelText: 'Privacy'),
                        items: const [
                          DropdownMenuItem(
                            value: 'public',
                            child: Text('Public (Visible to All)'),
                          ),
                          DropdownMenuItem(
                            value: 'private',
                            child: Text('Private (My Rooms Only)'),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => privacy = val!),
                      )
                    else
                      const ListTile(
                        leading: Icon(Icons.public),
                        title: Text('Automated Public Visibility'),
                        subtitle: Text(
                          'Rooms inside events are always public.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final roomId = await repository.createRoom({
                      'title': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'objective': objectiveController.text.trim(),
                      'roomType': selectedType,
                      'startDate': startDate.toIso8601String(),
                      'endDate': endDate.toIso8601String(),
                      'eventId': selectedEvent?['id'],
                      'privacy': privacy,
                    });

                    if (context.mounted) {
                      Navigator.pop(context); // Close creation dialog

                      if (roomId != null) {
                        // Immediately trigger Task Configuration
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SacredTaskConfigSheet(
                            roomStartDate: startDate,
                            roomEndDate: endDate,
                            onSave: (tasksData) async {
                              await repository.batchCreateTasks(
                                roomId,
                                List<Map<String, dynamic>>.from(tasksData),
                                startDate,
                                endDate,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sacred Schedule Generated: ${tasksData.length} Tasks Created.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('CREATE'),
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

  Widget _buildRoomsList(Repository repository, {required bool onlyJoined}) {
    return StreamBuilder<List<Room>>(
      stream: onlyJoined
          ? repository.myRoomsStream
          : repository.publicRoomsDiscoveryStream,
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 64,
                  color: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text('No rooms found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            final roomId = room.id;
            final title = room.title;

            return RoomCard(
              room: room,
              onJoin: () {
                repository.joinRoom(roomId, 'user'); // Fallback user id
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined "${room.title}"! 🙏')),
                );
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RoomDetailScreen(roomId: roomId, roomTitle: title),
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

/// Reusable Room Card Widget
class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const RoomCard({super.key, required this.room, this.onJoin, this.onTap});

  String _calculateFrequency() {
    if (room.initialTasks == null || room.initialTasks!.isEmpty) {
      // Fallback to total duration if no tasks
      final days = room.endDate.difference(room.startDate).inDays;
      return '$days Days Total';
    }

    // Check for Daily
    final hasDaily = room.initialTasks!.any((t) => t['rhythm'] == 'daily');
    if (hasDaily) return '30 Days / Month';

    // Check for Weekly
    final weeklyTasks = room.initialTasks!.where(
      (t) => t['rhythm'] == 'weekly',
    );
    if (weeklyTasks.isNotEmpty) {
      // Collect all unique weekdays
      final Set<int> allWeekdays = {};
      for (var t in weeklyTasks) {
        final days = List<int>.from(t['selectedWeekdays'] ?? []);
        allWeekdays.addAll(days);
      }
      final daysPerWeek = allWeekdays.length;
      final daysPerMonth = daysPerWeek * 4;
      return '$daysPerMonth Days / Month';
    }

    // Check for One-time / Sequential
    // If it's a short room (e.g. 7 days), maybe just show "7 Days"
    final duration = room.endDate.difference(room.startDate).inDays;
    if (duration < 30) {
      return '$duration Days / Month'; // Technically duration, but fits the slot
    }

    return 'Flexible Schedule';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'prayer_fasting':
        return Colors.indigo;
      case 'bible_study':
        return Colors.deepPurple;
      case 'book_reading':
      case 'book_study':
        return Colors.teal;
      case 'retreat':
        return Colors.amber[800]!;
      case 'worship':
        return Colors.pink[400]!;
      case 'challenge':
        return Colors.orange[800]!;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prayer_fasting':
        return Icons.self_improvement_outlined;
      case 'bible_study':
        return Icons.auto_stories_outlined;
      case 'book_reading':
      case 'book_study':
        return Icons.menu_book_outlined;
      case 'retreat':
        return Icons.landscape_outlined;
      case 'worship':
        return Icons.music_note_outlined;
      case 'challenge':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(room.roomType.name);
    final title = room.title;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: typeColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align to top
          children: [
            // Cover Image or Gradient
            Container(
              width: 100,
              height: 140, // Reduced height to prevent overflows
              decoration: BoxDecoration(color: typeColor.withOpacity(0.1)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor.withOpacity(0.5), typeColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getTypeIcon(room.roomType.name),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  Container(width: 4, color: typeColor),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: typeColor.withOpacity(0.9),
                            ),
                          ),
                        ),
                        _buildTypeBadge(theme, typeColor),
                      ],
                    ),
                    if (room.eventId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hub_outlined,
                              size: 10,
                              color: typeColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Linked Event',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: typeColor.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Frequency Badge (Days / Month)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: typeColor.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(room.startDate),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 10,
                          color: typeColor.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _calculateFrequency(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProgressSection(theme, typeColor, room.progress),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (room.isJoined) ...[
                          _buildCircleButton(
                            theme,
                            Icons.psychology_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GovernanceLogsScreen(
                                    scope: 'room',
                                    refId: room.id,
                                    title: title,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildCircleButton(
                            theme,
                            Icons.chat_bubble_outline_rounded,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatScreen(chatId: room.id, title: title),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (room.isJoined)
                          TextButton.icon(
                            onPressed: onTap,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('OPEN'),
                            style: TextButton.styleFrom(
                              foregroundColor: typeColor,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!room.isJoined)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: onJoin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: typeColor,
                              side: BorderSide(color: typeColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: const Text(
                              'JOIN ROOM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ThemeData theme, Color color) {
    String label = room.roomType.name.replaceAll('_', ' ').toUpperCase();
    if (label == 'PRAYER FASTING') label = 'PRAYER & FASTING';
    if (label == 'RETREAT') label = 'SPIRITUAL RETREAT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Journey Progress',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(
    ThemeData theme,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
    );
  }
}
