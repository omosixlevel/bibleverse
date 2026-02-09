import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/firestore_service.dart';
import '../../models/activity_model.dart';
import 'create_activity_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const ActivitiesScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('$eventTitle - Activities'),
        actions: [
          // TODO: Real check for creator permission
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateActivityScreen(eventId: eventId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getActivities(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final activities =
              snapshot.data?.map((a) => Activity.fromMap(a)).toList() ?? [];

          if (activities.isEmpty) {
            return const Center(
              child: Text('No activities scheduled for this event yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ActivityCard(activity: activity);
            },
          );
        },
      ),
    );
  }
}

class ActivityCard extends StatefulWidget {
  final Activity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isConfirming = false;

  void _confirmAttendance(bool confirmed) async {
    setState(() => _isConfirming = true);
    final firestoreService = context.read<FirestoreService>();
    try {
      await firestoreService.confirmAttendance(
        widget.activity.id,
        'user_123',
        confirmed,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirmed ? 'Attendance confirmed!' : 'Attendance cancelled.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    final activity = widget.activity;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              activity.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(activity.startDateTime)} - ${dateFormat.format(activity.endDateTime)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      activity.locationName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: activity.costType == CostType.paid
                ? Text(
                    '\$${activity.price}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text('Free'),
            isThreeLine: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isConfirming)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _confirmAttendance(true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Attendance'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
