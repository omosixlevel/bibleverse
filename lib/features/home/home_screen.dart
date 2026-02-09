import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../core/providers/app_navigation_provider.dart';
import '../../core/services/gemini_service.dart'; // Import GeminiService
import '../events/event_detail_screen.dart';
import '../rooms/room_detail_screen.dart';
import '../../models/event_model.dart';
import '../../models/room_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getSacredGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return strings.morningPrayer;
    if (hour >= 12 && hour < 17) return strings.noonIntercession;
    if (hour >= 17 && hour < 21) return strings.eveningReflection;
    return strings.nightWatch;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final repository = context.read<Repository>();
    final navProvider = context.read<AppNavigationProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getSacredGreeting(strings).toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Event>>(
                        stream: repository.myEventsStream,
                        builder: (context, snapshot) {
                          final events = snapshot.data ?? [];
                          final avgProgress = events.isEmpty
                              ? 0.0
                              : events
                                        .map((e) => e.aggregateProgress)
                                        .reduce((a, b) => a + b) /
                                    events.length;

                          return Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      value: avgProgress,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.white12,
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(avgProgress * 100).toInt()}%',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                strings.overallProgression,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Commitment Grid ---
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              navProvider.setPageIndex(2), // Events tab
                          child: _buildCommitmentTile(
                            context,
                            strings.navEvents,
                            repository.myEventsStream.map(
                              (l) => l.length.toString(),
                            ),
                            Icons.event_available,
                            theme.colorScheme.primaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => navProvider.setPageIndex(3), // Rooms tab
                          child: _buildCommitmentTile(
                            context,
                            strings.navRooms,
                            repository.myRoomsStream.map(
                              (l) => l.length.toString(),
                            ),
                            Icons.groups_outlined,
                            theme.colorScheme.secondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Active Focus ---
                  Text(
                    strings.activeFocus,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  _buildActiveFocusCard(context, repository, strings),

                  const SizedBox(height: 24),

                  // --- Sacred Pulse (Dynamic Feed) ---
                  Text(
                    strings.sacredPulse,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  _buildSacredPulse(context, repository, strings),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentTile(
    BuildContext context,
    String label,
    Stream<String> countStream,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          StreamBuilder<String>(
            stream: countStream,
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '0',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildActiveFocusCard(
    BuildContext context,
    Repository repository,
    AppStrings strings,
  ) {
    final theme = Theme.of(context);
    final navProvider = context.read<AppNavigationProvider>();

    return StreamBuilder<List<Room>>(
      stream: repository.myRoomsStream,
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(strings.discoverSpaces),
              subtitle: Text(strings.joinRoomPrompt),
              onTap: () => navProvider.setPageIndex(1), // Discovery tab
            ),
          );
        }

        // Just take the first one as "Focus" for now
        final room = rooms.first;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RoomDetailScreen(roomId: room.id, roomTitle: room.title),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              strings.ongoingFocus,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: GeminiService().proposeSpiritualPath([
                      'Psalm 23',
                      'John 1',
                    ]), // Context for demo
                    builder: (context, snapshot) {
                      String text = strings.geminiSuggestion;
                      if (snapshot.hasData) {
                        final data = snapshot.data!;
                        if (data.containsKey('insight')) {
                          text = data['insight'];
                        } else if (data.containsKey('result')) {
                          final jsonStr = data['result'] as String;
                          final match = RegExp(
                            r'"insight":\s*"(.*?)"',
                          ).firstMatch(jsonStr);
                          if (match != null) text = match.group(1) ?? text;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "GEMINI COACH",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              text,
                              key: ValueKey(text),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoomDetailScreen(
                              roomId: room.id,
                              roomTitle: room.title,
                            ),
                          ),
                        );
                      },
                      child: Text(strings.resumeDevotion),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSacredPulse(
    BuildContext context,
    Repository repository,
    AppStrings strings,
  ) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Event>>(
      stream: repository.myEventsStream,
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                strings.joinEventsPrompt,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: events.take(3).map((event) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(
                        eventId: event.id,
                        eventTitle: event.title,
                      ),
                    ),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event, color: theme.colorScheme.primary),
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${strings.ends} ${DateFormat('MMM dd', strings.languageCode).format(event.endDate)}',
                ),
                trailing: CircularProgressIndicator(
                  value: event.aggregateProgress,
                  strokeWidth: 3,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
