import 'package:flutter/material.dart';
import '../../../models/task_model.dart';

class SacredTaskConfigSheet extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSave;
  final TaskType? initialType;
  final DateTime roomStartDate;
  final DateTime roomEndDate;

  const SacredTaskConfigSheet({
    super.key,
    required this.onSave,
    this.initialType,
    required this.roomStartDate,
    required this.roomEndDate,
  });

  @override
  State<SacredTaskConfigSheet> createState() => _SacredTaskConfigSheetState();
}

class _SacredTaskConfigSheetState extends State<SacredTaskConfigSheet> {
  late TaskType _selectedType;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _meetingNameController = TextEditingController();
  final _scriptureController = TextEditingController();

  // Rhythm for current entry
  String _rhythm = 'once'; // once, daily, weekly
  List<int> _selectedWeekdays = []; // 1=Mon, 7=Sun
  int _dayOffset = 0; // 0 = Day 1 (Start Date)

  // Tell Me / Questions for current entry
  List<String> _questions = [''];

  // Prayer Points for current entry
  List<String> _prayerPoints = [''];

  int _startHour = 10;
  int _durationMinutes = 60;
  bool _isMandatory = true;

  // List of configured task templates
  final List<Map<String, dynamic>> _configuredTemplates = [];

  bool _isAddingNew = true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TaskType.tell_me;
    _titleController.text = _getDefaultTitle(_selectedType);
  }

  String _getDefaultTitle(TaskType type) {
    switch (type) {
      case TaskType.tell_me:
        return 'Spiritual Reflection';
      case TaskType.prayer:
        return 'Corporate Intercession';
      case TaskType.worship:
        return 'Sacred Worship';
      case TaskType.silence:
        return 'Solitude & Silence';
      case TaskType.rhema:
        return 'Scripture Meditation';
      case TaskType.action:
        return 'Kingdom Action';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _meetingNameController.dispose();
    _scriptureController.dispose();
    super.dispose();
  }

  void _addCurrentTemplateToList() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the task')),
      );
      return;
    }

    final template = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'taskType': _selectedType.name,
      'rhythm': _rhythm,
      'selectedWeekdays': List<int>.from(_selectedWeekdays),
      'dayOffset': _dayOffset,
      'startHour': _startHour,
      'durationMinutes': _durationMinutes,
      'mandatory': _isMandatory,
      'questions': _questions.where((q) => q.isNotEmpty).toList(),
      'prayerPoints': _prayerPoints.where((p) => p.isNotEmpty).toList(),
      'scripture': _scriptureController.text.isEmpty
          ? null
          : _scriptureController.text.trim(),
      'meetingName': _meetingNameController.text.isEmpty
          ? null
          : _meetingNameController.text.trim(),
    };

    setState(() {
      _configuredTemplates.add(template);
      _isAddingNew = false;
      // Reset form to defaults
      _selectedType = TaskType.tell_me;
      _rhythm = 'once';
      _selectedWeekdays = [];
      _dayOffset = 0;
      _startHour = 10;
      _durationMinutes = 60;
      _titleController.text = _getDefaultTitle(_selectedType);
      _descController.clear();
      _meetingNameController.clear();
      _questions = [''];
      _prayerPoints = [''];
    });
  }

  void _submit() {
    if (_configuredTemplates.isEmpty && _titleController.text.isEmpty) return;

    // If there is current data in the form, add it first
    if (_isAddingNew && _titleController.text.isNotEmpty) {
      _addCurrentTemplateToList();
    }

    List<Map<String, dynamic>> allTasksToCreate = [];

    for (var template in _configuredTemplates) {
      final rhythm = template['rhythm'];
      final baseData = {
        'title': template['title'],
        'description': template['description'],
        'taskType': template['taskType'],
        'startHour': template['startHour'],
        'durationMinutes': template['durationMinutes'],
        'durationHours': (template['durationMinutes'] as int) / 60.0,
        'mandatory': template['mandatory'],
        'questions': template['questions'],
        'prayerPoints': template['prayerPoints'],
        'meetingName': template['meetingName'],
      };

      if (rhythm == 'once') {
        final offset = template['dayOffset'] as int? ?? 0;
        allTasksToCreate.add({
          ...baseData,
          'scheduledDate': widget.roomStartDate
              .add(Duration(days: offset))
              .toIso8601String(),
        });
      } else {
        DateTime current = widget.roomStartDate;
        while (current.isBefore(widget.roomEndDate) ||
            current.isAtSameMomentAs(widget.roomEndDate)) {
          bool shouldAdd = false;

          if (rhythm == 'daily') {
            shouldAdd = true;
          } else if (rhythm == 'weekly') {
            final List<int> weekdays = List<int>.from(
              template['selectedWeekdays'],
            );
            if (weekdays.contains(current.weekday)) {
              shouldAdd = true;
            }
          }

          if (shouldAdd) {
            allTasksToCreate.add({
              ...baseData,
              'scheduledDate': current.toIso8601String(),
            });
          }

          current = current.add(const Duration(days: 1));
        }
      }
    }

    widget.onSave(allTasksToCreate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SACRED TASK CONFIGURATION',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (!_isAddingNew)
                IconButton(
                  onPressed: () => setState(() => _isAddingNew = true),
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Add Another Task',
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_configuredTemplates.isNotEmpty) ...[
                    Text(
                      'CONSTRUCTED SCHEDULE PREVIEW',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._configuredTemplates.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final t = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTaskIcon(t['taskType']),
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            t['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            t['rhythm'] == 'once'
                                ? 'DAY ${(t['dayOffset'] ?? 0) + 1} @ ${t['startHour']}h'
                                : '${t['rhythm'].toString().toUpperCase()} @ ${t['startHour']}h',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => setState(() {
                              _configuredTemplates.removeAt(idx);
                              if (_configuredTemplates.isEmpty)
                                _isAddingNew = true;
                            }),
                          ),
                        ),
                      );
                    }),
                    const Divider(height: 32),
                  ],

                  if (_isAddingNew) ...[
                    _buildTypeSelector(theme),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Task Title',
                      hint: 'e.g., Morning Consecration',
                    ),
                    const SizedBox(height: 16),
                    _buildRhythmSelector(theme),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descController,
                      label: 'Description / Instructions',
                      hint: 'What should the participants do?',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    _buildTimeConfig(theme),
                    const SizedBox(height: 24),
                    if (_selectedType == TaskType.tell_me)
                      _buildQuestionsField(theme),
                    if (_selectedType == TaskType.prayer)
                      _buildPrayerPointsField(theme),
                    if (_selectedType == TaskType.prayer) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _meetingNameController,
                        label: 'Meeting Name (for Circle)',
                        hint: 'e.g., Upper Room Prayer',
                      ),
                    ],
                    if (_selectedType == TaskType.rhema) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _scriptureController,
                        label: 'Scripture Reference',
                        hint: 'e.g., Genesis 1:1, Joshua 1:8',
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _addCurrentTemplateToList,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('ADD TO SCHEDULE'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          if (_configuredTemplates.isNotEmpty ||
              (_isAddingNew && _titleController.text.isNotEmpty))
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'FINALIZE & GENERATE SCHEDULE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTaskIcon(String typeName) {
    switch (typeName) {
      case 'prayer':
        return Icons.auto_awesome;
      case 'silence':
        return Icons.do_not_disturb_on_total_silence;
      case 'worship':
        return Icons.queue_music;
      case 'rhema':
        return Icons.menu_book;
      case 'tell_me':
        return Icons.question_answer;
      default:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Type', style: theme.textTheme.labelMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: TaskType.values.map((type) {
              final isSelected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(type.name.replaceAll('_', ' ').toUpperCase()),
                  onSelected: (val) {
                    setState(() {
                      _selectedType = type;
                      _titleController.text = _getDefaultTitle(type);
                    });
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey[600],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRhythmSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sacred Rhythm', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _rhythm,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'once', child: Text('One-time Only')),
            DropdownMenuItem(value: 'daily', child: Text('Daily (Every Day)')),
            DropdownMenuItem(
              value: 'weekly',
              child: Text('Weekly Rhythm (Specific Days)'),
            ),
          ],
          onChanged: (val) => setState(() => _rhythm = val!),
        ),
        if (_rhythm == 'weekly') ...[
          const SizedBox(height: 12),
          Text('Select Specific Days:', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1; // 1 = Mon
              final isSelected = _selectedWeekdays.contains(day);
              final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return FilterChip(
                label: Text(labels[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected)
                      _selectedWeekdays.add(day);
                    else
                      _selectedWeekdays.remove(day);
                  });
                },
                showCheckmark: false,
                shape: const CircleBorder(),
                labelPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
        ],
        if (_rhythm == 'once') ...[
          const SizedBox(height: 12),
          _buildDaySelector(theme),
        ],
      ],
    );
  }

  Widget _buildDaySelector(ThemeData theme) {
    final totalDays =
        widget.roomEndDate.difference(widget.roomStartDate).inDays + 1;
    // Cap strictly at 30 to avoid UI clutter, or scrollable
    final displayDays = totalDays > 30 ? 30 : totalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sequential Day Step (D1..Dx)',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayDays,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _dayOffset == index;
              return ChoiceChip(
                label: Text('D${index + 1}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _dayOffset = index);
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTimeConfig(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildNumberCounter(
            label: 'Start Hour (0-23)',
            value: _startHour,
            onChanged: (val) => setState(() => _startHour = val.clamp(0, 23)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNumberCounter(
            label: 'Duration (Minutes)',
            value: _durationMinutes,
            step: 5,
            onChanged: (val) => setState(() {
              // Clamp between 5 minutes and 24 hours (1440 mins)
              _durationMinutes = (val as int).clamp(5, 1440);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberCounter({
    required String label,
    required dynamic value,
    required Function(dynamic) onChanged,
    int step = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => onChanged(value - step),
              ),
              Text(
                value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => onChanged(value + step),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inquiry Questions (Always Redundant/Recursive)',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 12),
        ..._questions.asMap().entries.map((entry) {
          int idx = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => _questions[idx] = val,
                    decoration: InputDecoration(
                      hintText: 'Question ${idx + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _questions.removeAt(idx)),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _questions.add('')),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Question'),
        ),
      ],
    );
  }

  Widget _buildPrayerPointsField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prayer Foci', style: theme.textTheme.labelMedium),
        const SizedBox(height: 12),
        ..._prayerPoints.asMap().entries.map((entry) {
          int idx = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => _prayerPoints[idx] = val,
                    decoration: InputDecoration(
                      hintText: 'Point ${idx + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _prayerPoints.removeAt(idx)),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _prayerPoints.add('')),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Point'),
        ),
      ],
    );
  }
}
