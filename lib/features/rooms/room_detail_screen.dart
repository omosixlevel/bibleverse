import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './widgets/task_completion_sheet.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/task_model.dart';
import '../../models/room_model.dart';
import '../../core/widgets/task_completion_animation.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.watch<Repository>();

    return StreamBuilder<Room?>(
      stream: repository.getRoom(widget.roomId),
      builder: (context, roomSnapshot) {
        final room = roomSnapshot.data;
        final roomType = room?.roomType;
        final typeColor = _getTypeColor(roomType);

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: typeColor.withOpacity(0.9),
            elevation: 0,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.roomTitle.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                if (roomType != null)
                  Text(
                    roomType.name.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                  tabs: const [
                    Tab(text: 'TASKS'),
                    Tab(text: 'INSIGHTS'),
                  ],
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<Task>>(
            stream: repository.getTasksStream(widget.roomId),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              final totalDays = tasks.isNotEmpty
                  ? tasks.map((t) => t.dayIndex).reduce((a, b) => a > b ? a : b)
                  : 1;

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksTab(context, tasks, totalDays, repository, theme),
                  _buildInsightsTab(context, tasks, theme),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _getTypeColor(RoomType? type) {
    if (type == null) return Colors.indigo;
    switch (type) {
      case RoomType.prayer_fasting:
        return Colors.indigo;
      case RoomType.bible_study:
        return Colors.deepPurple;
      case RoomType.book_reading:
        return Colors.teal;
      case RoomType.retreat:
        return Colors.amber[800]!;
    }
  }

  Widget _buildTasksTab(
    BuildContext context,
    List<Task> tasks,
    int totalDays,
    Repository repository,
    ThemeData theme,
  ) {
    if (tasks.isEmpty) return _buildEmptyState(theme);

    // Group tasks by day
    final Map<int, List<Task>> tasksByDay = {};
    for (var t in tasks) {
      tasksByDay.putIfAbsent(t.dayIndex, () => []).add(t);
    }

    final sortedDays = tasksByDay.keys.toList()..sort();

    return Column(
      children: [
        _buildProgressHeader(tasks, theme),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: sortedDays.length,
            itemBuilder: (context, dayIdx) {
              final day = sortedDays[dayIdx];
              final dayTasks = tasksByDay[day]!;
              dayTasks.sort(
                (a, b) => (a.startHour ?? 0).compareTo(b.startHour ?? 0),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'DAY $day',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...dayTasks.map(
                    (task) => _buildTaskItem(task, repository, theme),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(List<Task> tasks, ThemeData theme) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final completed = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final progress = completed / tasks.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROOM PROGRESS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, Repository repository, ThemeData theme) {
    final isCompleted = task.status == TaskStatus.completed;

    return TaskCompletionAnimation(
      key: ValueKey(task.id),
      isCompleted: isCompleted,
      child: InkWell(
        onTap: () => _showTaskCompletionSheet(context, task, repository),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : _getTaskColor(task.taskType).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Icon(
              _getTaskIcon(task.taskType),
              color: isCompleted ? Colors.green : _getTaskColor(task.taskType),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskType.name.replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 1.2,
                    color: isCompleted
                        ? Colors.grey
                        : _getTaskColor(task.taskType),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? Colors.grey
                        : _getTaskColor(task.taskType),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      task.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 10,
                      color: theme.colorScheme.outline.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.startHour ?? 0}h',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.outline.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer,
                      size: 10,
                      color: theme.colorScheme.outline.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.durationHours ?? 1}h',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.outline.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              isCompleted ? Icons.check_circle : Icons.chevron_right,
              color: isCompleted
                  ? Colors.green
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskCompletionSheet(
    BuildContext context,
    Task task,
    Repository repository,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskCompletionSheet(
        task: task,
        onComplete: (data) async {
          await repository.completeTask(task.id, widget.roomId, data);
        },
      ),
    );
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.prayer:
        return Icons.auto_awesome;
      case TaskType.silence:
        return Icons.do_not_disturb_on_total_silence;
      case TaskType.worship:
        return Icons.queue_music;
      case TaskType.rhema:
        return Icons.menu_book;
      case TaskType.tell_me:
        return Icons.question_answer;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _getTaskColor(TaskType type) {
    switch (type) {
      case TaskType.prayer:
        return Colors.indigo;
      case TaskType.rhema:
        return const Color(0xFFB71C1C); // Deep Red
      case TaskType.silence:
        return Colors.teal;
      case TaskType.worship:
        return Colors.amber[800]!;
      case TaskType.tell_me:
        return Colors.blue[700]!;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 64,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Quiet day for spiritual growth.',
            style: TextStyle(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(
    BuildContext context,
    List<Task> tasks,
    ThemeData theme,
  ) {
    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (completedTasks.isEmpty)
            _buildInsightCard(
              'Awaiting Revelation',
              'Complete your first sacred task to begin generating spiritual insights.',
              Icons.auto_fix_high,
              theme,
            )
          else ...[
            ...completedTasks.map((task) {
              // Extract meaningful content based on task type
              String title = 'Sacred Insight';
              String content = 'Reflection recorded.';
              IconData icon = _getTaskIcon(task.taskType);
              final progress = task.progressData ?? {};

              if (task.taskType == TaskType.rhema) {
                title = 'Rhema Revelation';
                content =
                    progress['revelation'] ?? 'A "now word" was received.';
                icon = Icons.psychology;
              } else if (task.taskType == TaskType.prayer) {
                title = 'Prayer Reflection';
                content =
                    progress['sessionComment'] ??
                    'Deep communion with the Spirit.';
                icon = Icons.volunteer_activism;
              } else if (task.taskType == TaskType.tell_me) {
                title = 'Self-Reflection';
                final answers = progress.keys.where(
                  (k) => k.startsWith('answer_'),
                );
                if (answers.isNotEmpty) {
                  content = progress[answers.first];
                }
              } else if (task.taskType == TaskType.silence ||
                  task.taskType == TaskType.worship) {
                title = 'Sacred Experience';
                content =
                    progress['experienceRecord'] ??
                    'A moment of profound connection.';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildInsightCard(title, content, icon, theme),
              );
            }),
          ],
          const Divider(height: 48),
          _buildInsightCard(
            'Consistency',
            'You have a ${completedTasks.length} task streak in this room.',
            Icons.trending_up,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String content,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(content, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
