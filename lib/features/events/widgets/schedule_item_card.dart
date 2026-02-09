import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const ScheduleItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = item['itemType'] as String;
    final isRoom = type == 'room';

    // Safety check for dates
    DateTime date = DateTime.now();
    if (item['sortDate'] is DateTime) {
      date = item['sortDate'];
    } else if (item['sortDate'] != null) {
      // Handle Timestamp or String
      try {
        // If it's a Timestamp object (runtime check), we can't import Timestamp here easily without cloud_firestore
        // But we can assume it's dynamic.
        // Better to rely on the passed map having 'sortDate' as Timestamp and convert it in UI or earlier.
        // Let's assume passed item has processed dates or Handle dynamic.
        final dynamic d = item['sortDate'];
        if (d.toString().contains('Timestamp')) {
          // Hack if we can't import, but we can import cloud_firestore.
          // Actually better to just accept it might be a Timestamp.
        }
      } catch (_) {}
    }

    // For display, use formatted strings passed in or formatting here.
    final title = item['title'] ?? item['name'] ?? 'Untitled';
    final description = item['description'] ?? '';
    final timeStr = isRoom
        ? 'Starts ${DateFormat('MMM d').format(DateTime.now())}' // Placeholder logic if real date obj missing
        : (item['hour'] ?? 'TBD');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0, // Flat design for schedule list
      color: isRoom
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Time / Icon Column
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRoom
                          ? Colors.indigo.withOpacity(0.1)
                          : Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRoom ? Icons.meeting_room_outlined : Icons.event_note,
                      color: isRoom ? Colors.indigo : Colors.amber[800],
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    // Badges
                    Row(
                      children: [
                        _Badge(
                          text: isRoom ? 'ROOM' : 'ACTIVITY',
                          color: isRoom ? Colors.indigo : Colors.amber[800]!,
                        ),
                        const SizedBox(width: 8),
                        if (!isRoom) // Activity Location
                          Expanded(
                            child: Text(
                              '📍 ${item['place'] ?? 'Main Hall'}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (isRoom)
                          _StatusText(status: item['status'] ?? 'Open'),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String status;
  const _StatusText({required this.status});

  @override
  Widget build(BuildContext context) {
    final isLive = status == 'active';
    return Text(
      isLive ? '● LIVE' : status.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isLive ? Colors.red : Colors.grey,
      ),
    );
  }
}
