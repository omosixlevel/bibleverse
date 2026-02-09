import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/event_model.dart';
import '../../models/room_model.dart';
import '../../core/widgets/sacred_pill_tab_bar.dart';
import 'chat_screen.dart';

class ChatsHubScreen extends StatefulWidget {
  const ChatsHubScreen({super.key});

  @override
  State<ChatsHubScreen> createState() => _ChatsHubScreenState();
}

class _ChatsHubScreenState extends State<ChatsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // Removed unused variable
    final repository = context.watch<Repository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SacredPillTabBar(
              controller: _tabController,
              tabs: const ['All', 'Rooms', 'Events'],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildCombinedList(repository),
              _buildRoomsList(repository),
              _buildEventsList(repository),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedList(Repository repository) {
    return StreamBuilder<List<Room>>(
      stream: repository.roomsStream,
      builder: (context, roomsSnapshot) {
        return StreamBuilder<List<Event>>(
          stream: repository.eventsStream,
          builder: (context, eventsSnapshot) {
            if (roomsSnapshot.connectionState == ConnectionState.waiting ||
                eventsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rooms = roomsSnapshot.data ?? [];
            final events = eventsSnapshot.data ?? [];

            final combined = [
              ...rooms.map(
                (r) => {
                  'id': r.id,
                  'name': r.title,
                  'chatId': r.id,
                  'type': 'room',
                },
              ),
              ...events.map(
                (e) => {
                  'id': e.id,
                  'title': e.title,
                  'chatId': e.id,
                  'type': 'event',
                },
              ),
            ];

            if (combined.isEmpty) {
              return const Center(child: Text('No active communities found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: combined.length,
              itemBuilder: (context, index) {
                final item = combined[index];
                return _buildChatTile(context, item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRoomsList(Repository repository) {
    return StreamBuilder<List<Room>>(
      stream: repository.roomsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _buildChatTile(context, {
              'id': room.id,
              'name': room.title,
              'chatId': room.id,
              'type': 'room',
            });
          },
        );
      },
    );
  }

  Widget _buildEventsList(Repository repository) {
    return StreamBuilder<List<Event>>(
      stream: repository.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildChatTile(context, {
              'id': event.id,
              'title': event.title,
              'chatId': event.id,
              'type': 'event',
            });
          },
        );
      },
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isRoom = item['type'] == 'room';
    final title = item[isRoom ? 'name' : 'title'] ?? 'Unknown';
    final subtitle = isRoom ? 'Room Community' : 'Event Chat';
    final chatId = item['chatId'] ?? 'global';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatId: chatId, title: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (isRoom
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary)
                          .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRoom ? Icons.groups : Icons.event,
                  color: isRoom
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
