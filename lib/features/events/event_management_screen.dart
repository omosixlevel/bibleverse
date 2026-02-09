import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/event_model.dart';
import '../../models/room_model.dart';
import '../../models/activity_model.dart';
import '../rooms/room_detail_screen.dart';
import '../rooms/rooms_screen.dart';
import './create_activity_screen.dart';
import './activity_detail_screen.dart';
import './widgets/elegant_card.dart';

class EventManagementScreen extends StatelessWidget {
  final String eventId;

  const EventManagementScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.watch<Repository>();

    return StreamBuilder<Event?>(
      stream: repository.getEvent(eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data!;

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, event, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressSection(context, event, repository, theme),
                      const SizedBox(height: 40),
                      _buildRoomsAndActivitiesList(
                        context,
                        event,
                        repository,
                        theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOptions(context, event),
            label: const Text('ADD COMPONENT'),
            icon: const Icon(Icons.add),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Event event, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        title: Text(
          event.title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              event.coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: theme.colorScheme.primary),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    Event event,
    Repository repository,
    ThemeData theme,
  ) {
    return StreamBuilder<List<Room>>(
      stream: repository.getEventRooms(event.id),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OVERALL PROGRESSION',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: event.aggregateProgress,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(event.aggregateProgress * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your spiritual journey across all rooms and activities.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoomsAndActivitiesList(
    BuildContext context,
    Event event,
    Repository repository,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ROOMS & ACTIVITIES',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sort, size: 16),
              label: const Text('SORT BY DATE'),
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<dynamic>>(
          stream: Rx.combineLatest2<List<Room>, List<Activity>, List<dynamic>>(
            repository.getEventRooms(event.id),
            repository.getEventActivities(event.id),
            (rooms, activities) {
              final combined = [...rooms, ...activities];
              combined.sort((a, b) {
                final dateA = a is Room
                    ? a.startDate
                    : (a as Activity).startDateTime;
                final dateB = b is Room
                    ? b.startDate
                    : (b as Activity).startDateTime;

                // Sorting logic: Current month first, then future
                final now = DateTime.now();
                final sameMonthA =
                    dateA.year == now.year && dateA.month == now.month;
                final sameMonthB =
                    dateB.year == now.year && dateB.month == now.month;

                if (sameMonthA && !sameMonthB) return -1;
                if (!sameMonthA && sameMonthB) return 1;
                return dateA.compareTo(dateB);
              });
              return combined;
            },
          ),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No rooms or activities yet.',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              );
            }

            return Column(
              children: items.map((item) {
                if (item is Room) {
                  return ElegantCard(
                    title: item.title,
                    subtitle: item.description,
                    date: item.startDate,
                    endDate: item.endDate,
                    status: item.status.name,
                    icon: Icons.meeting_room,
                    accentColor: Colors.teal, // Room color
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailScreen(
                            roomId: item.id,
                            roomTitle: item.title,
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  final activity = item as Activity;
                  final isOver = activity.endDateTime.isBefore(DateTime.now());
                  return ElegantCard(
                    title: activity.title,
                    subtitle: activity.description,
                    date: activity.startDateTime,
                    endDate: activity.endDateTime,
                    status: isOver ? 'Completed' : 'Upcoming',
                    progress: isOver ? 1.0 : 0.0,
                    icon: Icons.local_fire_department,
                    accentColor: Colors.orange[700], // Activity color
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityDetailScreen(activity: activity),
                        ),
                      );
                    },
                  );
                }
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showAddOptions(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('Add Room'),
              onTap: () {
                Navigator.pop(context);
                RoomsScreen.showCreateRoomDialog(
                  context,
                  initialEventId: event.id,
                  initialEventTitle: event.title,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_activity_outlined),
              title: const Text('Add Activity'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateActivityScreen(eventId: event.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
