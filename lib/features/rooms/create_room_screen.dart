import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart' as model;
import '../../models/task_model.dart' as task_model;
import '../../core/services/firestore_service.dart';

class CreateRoomScreen extends StatefulWidget {
  final String? eventId;
  const CreateRoomScreen({super.key, this.eventId});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _covenantController = TextEditingController(
    text:
        'I agree to respect the values of this room and participate with love and dedication.',
  );

  // Specialized fields
  model.RoomType _roomType = model.RoomType.prayer_fasting;
  final _pdfUrlController = TextEditingController();
  final _fastingController = TextEditingController();
  final List<String> _selectedStudyObjectives = [];

  // Scheduling
  final List<Map<String, dynamic>> _initialTasks = [];
  final List<Map<String, dynamic>> _initialMeetings = [];

  bool _acceptedCovenant = false;
  String _privacy = 'public';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedCovenant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the covenant to create a room'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.createRoom({
        'title': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'roomType': _roomType.name,
        'covenant': _covenantController.text.trim(),
        'privacy': _privacy,
        'creatorId': 'user_123', // TODO: Get from Auth
        'pdfUrl': _pdfUrlController.text.isNotEmpty
            ? _pdfUrlController.text
            : null,
        'fastingInstructions': _fastingController.text.isNotEmpty
            ? _fastingController.text
            : null,
        'studyObjectives': _roomType == model.RoomType.bible_study
            ? _selectedStudyObjectives
            : null,
        'initialMeetings': _initialMeetings,
        'eventId': widget.eventId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Room Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<model.RoomType>(
                      value: _roomType,
                      decoration: const InputDecoration(labelText: 'Room Type'),
                      items: model.RoomType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.name.replaceAll('_', ' ').toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _roomType = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),

                    if (_roomType == model.RoomType.book_reading) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pdfUrlController,
                        decoration: const InputDecoration(labelText: 'PDF URL'),
                      ),
                    ],

                    if (_roomType == model.RoomType.retreat) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fastingController,
                        decoration: const InputDecoration(
                          labelText: 'Fasting Instructions',
                        ),
                        maxLines: 3,
                      ),
                    ],

                    if (_roomType == model.RoomType.bible_study) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Study Objectives',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 8,
                        children:
                            [
                              'Historical',
                              'Thematic',
                              'Archaeological',
                              'Spiritual',
                            ].map((obj) {
                              final isSelected = _selectedStudyObjectives
                                  .contains(obj);
                              return FilterChip(
                                label: Text(obj),
                                selected: isSelected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val)
                                      _selectedStudyObjectives.add(obj);
                                    else
                                      _selectedStudyObjectives.remove(obj);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),
                    _buildSchedulingSection(),

                    const SizedBox(height: 24),
                    const Text(
                      'Covenant',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _covenantController,
                      decoration: const InputDecoration(
                        hintText: 'Define the covenant for this room...',
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text(
                        'I accept the covenant and will uphold it',
                      ),
                      value: _acceptedCovenant,
                      onChanged: (val) =>
                          setState(() => _acceptedCovenant = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _privacy,
                      decoration: const InputDecoration(labelText: 'Privacy'),
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _privacy = val!),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Room'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSchedulingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Tasks & Objectives',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addTaskTemplate,
            ),
          ],
        ),
        if (_initialTasks.isEmpty)
          const Text(
            'No initial tasks added',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ..._initialTasks.map(
          (task) => ListTile(
            title: Text(task['title']),
            subtitle: Text(
              task['isRepetitive'] ? 'Daily' : 'Day ${task['dayIndex']}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _initialTasks.remove(task)),
            ),
          ),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scheduled Meetings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_alarm),
              onPressed: _addMeetingTemplate,
            ),
          ],
        ),
        if (_initialMeetings.isEmpty)
          const Text(
            'No meetings scheduled',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ..._initialMeetings.map(
          (meeting) => ListTile(
            title: Text(meeting['title']),
            subtitle: Text('${meeting['duration']} mins'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _initialMeetings.remove(meeting)),
            ),
          ),
        ),
      ],
    );
  }

  void _addTaskTemplate() {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        final dayCtrl = TextEditingController(text: '1');
        bool isRepetitive = false;
        task_model.TaskType type = task_model.TaskType.prayer;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task Template'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<task_model.TaskType>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Task Type'),
                      items: task_model.TaskType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => type = val!),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Daily Repetitive'),
                      value: isRepetitive,
                      onChanged: (val) =>
                          setDialogState(() => isRepetitive = val),
                    ),
                    if (!isRepetitive)
                      TextField(
                        controller: dayCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Day Index (1, 2, ...)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      setState(() {
                        _initialTasks.add({
                          'title': titleCtrl.text,
                          'taskType': type.name,
                          'isRepetitive': isRepetitive,
                          'dayIndex': isRepetitive
                              ? -1
                              : int.tryParse(dayCtrl.text) ?? 1,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMeetingTemplate() {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        final durationCtrl = TextEditingController(text: '30');
        return AlertDialog(
          title: const Text('Schedule Meeting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Meeting Title'),
              ),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(labelText: 'Duration (mins)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _initialMeetings.add({
                      'title': titleCtrl.text,
                      'duration': int.tryParse(durationCtrl.text) ?? 30,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        );
      },
    );
  }
}
