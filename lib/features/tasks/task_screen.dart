import 'package:flutter/material.dart';

/// Task View Screen with Task Card and Dynamic Text Editor
class TaskScreen extends StatefulWidget {
  final String taskTitle;
  final String taskType;
  final String description;

  const TaskScreen({
    super.key,
    this.taskTitle = 'Morning Prayer',
    this.taskType = 'prayer',
    this.description =
        'Spend time in focused prayer, lifting up your concerns and thanking God for His blessings.',
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isPublished = false;
  String _content = '';

  Color _getTaskTypeColor() {
    switch (widget.taskType) {
      case 'prayer':
        return const Color(0xFF9C27B0);
      case 'rhema':
        return const Color(0xFF2196F3);
      case 'action':
        return const Color(0xFFFF5722);
      case 'silence':
        return const Color(0xFF607D8B);
      case 'worship':
        return const Color(0xFFE91E63);
      case 'tell_me':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF6750A4);
    }
  }

  IconData _getTaskTypeIcon() {
    switch (widget.taskType) {
      case 'prayer':
        return Icons.favorite;
      case 'rhema':
        return Icons.menu_book;
      case 'action':
        return Icons.directions_run;
      case 'silence':
        return Icons.self_improvement;
      case 'worship':
        return Icons.music_note;
      case 'tell_me':
        return Icons.chat;
      default:
        return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskColor = _getTaskTypeColor();

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Task')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Task Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: taskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getTaskTypeIcon(), color: taskColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.taskTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: taskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.taskType.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: taskColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            widget.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),

          const SizedBox(height: 24),

          // Dynamic Text Editor
          Text(
            'Your Response',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter your reflection...',
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (text) {
              setState(() {
                _content = text;
              });
            },
          ),

          const SizedBox(height: 24),

          // Publish Toggle
          Card(
            child: SwitchListTile(
              title: const Text('Publish to Community'),
              subtitle: const Text('Share your reflection with room members'),
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          // Complete Button
          FilledButton.icon(
            onPressed: _content.isNotEmpty
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task completed!')),
                    );
                    Navigator.pop(context);
                  }
                : null,
            icon: const Icon(Icons.check),
            label: const Text('Complete Task'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
