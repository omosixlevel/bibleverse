import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import 'task_completion_animation.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TaskStatus status;
  final TaskType type;
  final bool isMandatory;
  final bool isPublished;
  final bool showPublishToggle;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final ValueChanged<bool>? onPublishChanged;
  final DateTime? dueDate;

  const TaskCard({
    super.key,
    required this.title,
    this.subtitle,
    this.status = TaskStatus.pending,
    this.type = TaskType.action,
    this.isMandatory = false,
    this.isPublished = false,
    this.showPublishToggle = false,
    this.onTap,
    this.onComplete,
    this.onPublishChanged,
    this.dueDate,
  });

  Color _getTypeColor() {
    switch (type) {
      case TaskType.prayer:
        return const Color(0xFF9C27B0);
      case TaskType.rhema:
        return const Color(0xFF2196F3);
      case TaskType.action:
        return const Color(0xFFFF5722);
      case TaskType.silence:
        return const Color(0xFF607D8B);
      case TaskType.worship:
        return const Color(0xFFE91E63);
      case TaskType.tell_me:
        return const Color(0xFF00BCD4);
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case TaskType.prayer:
        return Icons.favorite;
      case TaskType.rhema:
        return Icons.menu_book;
      case TaskType.action:
        return Icons.flash_on;
      case TaskType.silence:
        return Icons.self_improvement;
      case TaskType.worship:
        return Icons.music_note;
      case TaskType.tell_me:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = status == TaskStatus.completed;
    final color = _getTypeColor();

    return TaskCompletionAnimation(
      isCompleted: isCompleted,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? theme.colorScheme.surfaceContainerLow.withOpacity(0.7)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMandatory && !isCompleted
                ? color
                : theme.colorScheme.outline.withOpacity(0.1),
            width: isMandatory && !isCompleted ? 2 : 1,
          ),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isCompleted ? 0.1 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      size: 22,
                      color: isCompleted ? color.withOpacity(0.5) : color,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMandatory && !isCompleted)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REQUIRED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Contrast on colored chip
                              ),
                            ),
                          ),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? theme.colorScheme.outline
                                : null,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                          ),
                      ],
                    ),
                  ),
                  if (!isCompleted && onComplete != null)
                    GestureDetector(
                      onTap: onComplete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check, size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
