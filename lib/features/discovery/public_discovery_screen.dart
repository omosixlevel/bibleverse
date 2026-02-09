import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../events/events_screen.dart';
import '../rooms/rooms_screen.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/event_model.dart';
import '../../models/room_model.dart';

class PublicDiscoveryScreen extends StatefulWidget {
  const PublicDiscoveryScreen({super.key});

  @override
  State<PublicDiscoveryScreen> createState() => _PublicDiscoveryScreenState();
}

class _PublicDiscoveryScreenState extends State<PublicDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<Repository>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DISCOVER SACRED HUBS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search for events or rooms...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Events
            _buildSectionHeader(theme, 'Featured Events', Icons.event),
            StreamBuilder<List<Event>>(
              stream: repository.publicEventsDiscoveryStream,
              builder: (context, snapshot) {
                final events = (snapshot.data ?? [])
                    .where((e) => e.title.toLowerCase().contains(_searchQuery))
                    .toList();

                if (events.isEmpty) return _buildEmptyState('No events found');

                return SizedBox(
                  height: 500, // Increased to comfortably fit EventCard
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final item = events[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 300,
                          child: EventCard(
                            title: item.title,
                            description: item.shortDescription,
                            startDate: item.startDate,
                            endDate: item.endDate,
                            status: item.status.name,
                            adminName: 'Hub Admin',
                            roomCount: item.numberOfRooms,
                            activityCount: item.numberOfActivities,
                            completionRate: item.aggregateProgress,
                            isJoined: false,
                            onJoin: () => _joinEvent(context, repository, item),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section: Rooms
            _buildSectionHeader(theme, 'Trending Rooms', Icons.meeting_room),
            StreamBuilder<List<Room>>(
              stream: repository.publicRoomsDiscoveryStream,
              builder: (context, snapshot) {
                final rooms = (snapshot.data ?? [])
                    .where((r) => r.title.toLowerCase().contains(_searchQuery))
                    .toList();

                if (rooms.isEmpty) return _buildEmptyState('No rooms found');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return RoomCard(
                      room: room,
                      onJoin: () => _joinRoom(context, repository, room),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  void _joinEvent(BuildContext context, Repository repository, Event event) {
    repository.joinEvent(event.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined "${event.title}"! 🙏 Check your Events Hub.'),
        action: SnackBarAction(
          label: 'GO',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _joinRoom(BuildContext context, Repository repository, Room room) {
    // Pass 'user_offline' or similar since Repository handles offline fallback ignoring userId for MockStorage
    repository.joinRoom(room.id, 'user_offline');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined Room "${room.title}"! 🙏 Check your Rooms Hub.'),
        action: SnackBarAction(
          label: 'GO',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
