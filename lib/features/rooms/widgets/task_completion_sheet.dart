import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/task_model.dart';

class TaskCompletionSheet extends StatefulWidget {
  final Task task;
  final Function(Map<String, dynamic>) onComplete;

  const TaskCompletionSheet({
    super.key,
    required this.task,
    required this.onComplete,
  });

  @override
  State<TaskCompletionSheet> createState() => _TaskCompletionSheetState();
}

class _TaskCompletionSheetState extends State<TaskCompletionSheet> {
  final Map<String, dynamic> _formData = {};
  bool _isSubmitting = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerActive = false;

  bool get _canSubmit {
    // If already completed, can't submit again (or just view mode)
    if (widget.task.status == TaskStatus.completed) return false;

    switch (widget.task.taskType) {
      case TaskType.tell_me:
        // Must answer at least one question with decent length
        return _formData.entries.any(
          (e) => e.key.startsWith('answer_') && e.value.length > 3,
        );

      case TaskType.prayer:
        // Must check at least one point OR write a reflection OR finish timer
        final hasPoint = _formData.entries.any(
          (e) => e.key.startsWith('point_') && e.value == true,
        );
        final hasReflection = (_formData['sessionComment'] ?? '').length > 3;
        final timerDone =
            _remainingSeconds == 0 && widget.task.durationMinutes != null;
        return hasPoint || hasReflection || timerDone;

      case TaskType.rhema:
        // Must write revelation
        return (_formData['revelation'] ?? '').length > 3;

      case TaskType.silence:
      case TaskType.worship:
        // Timer done OR experience recorded
        final timerDone = _remainingSeconds == 0;
        final hasRecord = (_formData['experienceRecord'] ?? '').length > 3;
        return timerDone || hasRecord;

      default:
        return (_formData['notes'] ?? '').length > 3;
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill form data if it exists
    if (widget.task.progressData != null) {
      _formData.addAll(widget.task.progressData!);
    }

    if (widget.task.taskType == TaskType.silence ||
        widget.task.taskType == TaskType.worship ||
        widget.task.taskType == TaskType.prayer) {
      // Default to 1 hour if not specified, or use durationMinutes
      int seconds = 3600;
      if (widget.task.durationMinutes != null) {
        seconds = widget.task.durationMinutes! * 60;
      } else if (widget.task.durationHours != null) {
        seconds = (widget.task.durationHours! * 3600).toInt();
      }
      _remainingSeconds = seconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_timerActive) {
      _timer?.cancel();
      setState(() => _timerActive = false);
    } else {
      _timerActive = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _timerActive = false);
        }
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isCompleted = widget.task.status == TaskStatus.completed;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTaskIcon(widget.task.taskType),
                  color: _getTaskColor(widget.task.taskType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                        color: _getTaskColor(widget.task.taskType),
                      ),
                    ),
                    Text(
                      widget.task.taskType.name
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (widget.task.description.isNotEmpty) ...[
            Text(
              widget.task.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: SingleChildScrollView(child: _buildSpecializedForm(theme)),
          ),

          const SizedBox(height: 24),
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getTaskColor(widget.task.taskType),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.colorScheme.onSurface
                      .withOpacity(0.12),
                  disabledForegroundColor: theme.colorScheme.onSurface
                      .withOpacity(0.38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'COMPLETE SACRED TASK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text(
                  'DONE',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  disabledBackgroundColor: Colors.green.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecializedForm(ThemeData theme) {
    switch (widget.task.taskType) {
      case TaskType.tell_me:
        return _buildTellMeForm(theme);
      case TaskType.prayer:
        return _buildPrayerForm(theme);
      case TaskType.rhema:
        return _buildRhemaForm(theme);
      case TaskType.silence:
      case TaskType.worship:
        return _buildExperienceForm(theme);
      default:
        return _buildDefaultForm(theme);
    }
  }

  Widget _buildTellMeForm(ThemeData theme) {
    final questions = widget.task.questions ?? [];
    final isCompleted = widget.task.status == TaskStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...questions.map((q) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 3,
                  enabled: !isCompleted,
                  controller: TextEditingController(
                    text:
                        _formData['answer_$q'] ??
                        (isCompleted ? 'Answer provided' : ''),
                  ),
                  onChanged: (val) =>
                      setState(() => _formData['answer_$q'] = val),
                  decoration: InputDecoration(
                    hintText: 'Your reflection...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPrayerForm(ThemeData theme) {
    final points = widget.task.prayerPoints ?? [];
    final isCompleted = widget.task.status == TaskStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompleted) ...[
          Center(
            child: Column(
              children: [
                Text(
                  _formatDuration(_remainingSeconds),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_timerActive ? Icons.pause : Icons.play_arrow),
                  label: Text(_timerActive ? 'PAUSE PRAYER' : 'START PRAYER'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
        if (points.isNotEmpty) ...[
          Text(
            'Prayer Foci',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map((p) {
            return CheckboxListTile(
              title: Text(p),
              value: _formData['point_$p'] ?? false,
              onChanged: isCompleted
                  ? null
                  : (val) => setState(() => _formData['point_$p'] = val),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }),
          const SizedBox(height: 24),
        ],
        Text(
          'Session Reflection',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 3,
          enabled: !isCompleted,
          controller: TextEditingController(
            text: _formData['sessionComment'] ?? '',
          ),
          onChanged: (val) => setState(() => _formData['sessionComment'] = val),
          decoration: InputDecoration(
            hintText: 'What did the Spirit reveal during prayer?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRhemaForm(ThemeData theme) {
    final isCompleted = widget.task.status == TaskStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.task.scripture != null) ...[
          Text(
            'SCRIPTURE MEDITATION',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: _getTaskColor(TaskType.rhema),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getTaskColor(TaskType.rhema).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getTaskColor(TaskType.rhema).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.task.scripture ?? 'No scripture provided',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _getTaskColor(TaskType.rhema).withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
        Text(
          'The Rhema (Revelation)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 4,
          enabled: !isCompleted,
          controller: TextEditingController(
            text: _formData['revelation'] ?? '',
          ),
          onChanged: (val) => setState(() => _formData['revelation'] = val),
          decoration: InputDecoration(
            hintText: 'What is the "now word" for your heart?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Inspired Prayer Points',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 2,
          enabled: !isCompleted,
          controller: TextEditingController(
            text: _formData['inspiredPrayerPoints'] ?? '',
          ),
          onChanged: (val) => _formData['inspiredPrayerPoints'] = val,
          decoration: InputDecoration(
            hintText: 'Points to carry into your day...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceForm(ThemeData theme) {
    final isCompleted = widget.task.status == TaskStatus.completed;
    final taskColor = _getTaskColor(widget.task.taskType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompleted) ...[
          Center(
            child: Column(
              children: [
                Text(
                  _formatDuration(_remainingSeconds),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: taskColor,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_timerActive ? Icons.pause : Icons.play_arrow),
                  label: Text(_timerActive ? 'PAUSE SESSION' : 'START SESSION'),
                  style: FilledButton.styleFrom(backgroundColor: taskColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
        Text(
          'Experience Record',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 5,
          enabled: !isCompleted,
          controller: TextEditingController(
            text: _formData['experienceRecord'] ?? '',
          ),
          onChanged: (val) =>
              setState(() => _formData['experienceRecord'] = val),
          decoration: InputDecoration(
            hintText:
                'Record your experience during this time of sacred ${widget.task.taskType.name}...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultForm(ThemeData theme) {
    final isCompleted = widget.task.status == TaskStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Notes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 3,
          enabled: !isCompleted,
          controller: TextEditingController(text: _formData['notes'] ?? ''),
          onChanged: (val) => setState(() => _formData['notes'] = val),
          decoration: InputDecoration(
            hintText: 'Any thoughts or proofs of completion...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
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

  void _submit() async {
    setState(() => _isSubmitting = true);
    // Simulate a small delay for "Sacred processing"
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete(_formData);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sacred Task Completed. Grace be with you.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
