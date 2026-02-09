import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../rooms/rooms_screen.dart';
import '../rooms/widgets/sacred_task_config_sheet.dart';
import 'widgets/sacred_activity_config_sheet.dart';

class EventSetupScreen extends StatefulWidget {
  final String eventId;

  const EventSetupScreen({super.key, required this.eventId});

  @override
  State<EventSetupScreen> createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends State<EventSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: firestoreService.getEvent(widget.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = snapshot.data!;
          final theme = Theme.of(context);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    event['title'] ?? 'Setup Event',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event['coverImageUrl'] != null)
                        Image.network(event['coverImageUrl'], fit: BoxFit.cover)
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.tertiary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStepHeader(
                      context,
                      "Step 1",
                      "Sacred Rooms",
                      Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildDiscoveryCard(
                      context,
                      "Create a Study or Prayer Room",
                      "Rooms are where the community gathers for specific objectives.",
                      Icons.add_circle_outline,
                      onTap: () {
                        // Open rooms screen to show dialog contextually
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoomsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Dynamic Room List
                    _buildRoomList(firestoreService),
                    const SizedBox(height: 32),
                    _buildStepHeader(
                      context,
                      "Step 2",
                      "Divine Activities",
                      Icons.event_note_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildDiscoveryCard(
                      context,
                      "Add Timeline Activities",
                      "Schedule prayer sessions, worship hours, or group calls.",
                      Icons.calendar_month_outlined,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SacredActivityConfigSheet(
                            onSave: (activityData) async {
                              await firestoreService.createActivity({
                                ...activityData,
                                'eventId': widget.eventId,
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Physical Gathering Scheduled.",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: const Text("FINALIZE SETUP"),
        icon: const Icon(Icons.check),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStepHeader(
    BuildContext context,
    String step,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            step.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomList(FirestoreService firestoreService) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getEventRooms(widget.eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final rooms = snapshot.data!;
        return Column(
          children: rooms.map((room) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.room_preferences_outlined),
                title: Text(room['name'] ?? 'Room'),
                subtitle: const Text('Configure Tasks'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_task),
                  onPressed: () =>
                      _showTaskConfig(context, firestoreService, room),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showTaskConfig(
    BuildContext context,
    FirestoreService firestoreService,
    Map<String, dynamic> room,
  ) {
    final roomId = room['id'];
    final startDate = (room['startDate'] as Timestamp).toDate();
    final endDate = (room['endDate'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SacredTaskConfigSheet(
        roomStartDate: startDate,
        roomEndDate: endDate,
        onSave: (taskData) async {
          await firestoreService.batchCreateTasks(roomId, taskData);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sacred Tasks Instantiated.')),
            );
          }
        },
      ),
    );
  }
}
