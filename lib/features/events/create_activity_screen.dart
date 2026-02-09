import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/activity_model.dart';
import '../../models/event_model.dart';

class CreateActivityScreen extends StatefulWidget {
  final String eventId;

  const CreateActivityScreen({super.key, required this.eventId});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _contactController = TextEditingController();
  final _priceController = TextEditingController();

  // New configuration controllers
  final _startHourController = TextEditingController(text: '08');
  final _durationController = TextEditingController(text: '1');
  final _scriptureController = TextEditingController();
  final _actionTypeController = TextEditingController();
  final _meetingObjectivesController = TextEditingController();
  final _videoUrlsController = TextEditingController();
  final _dayIndexController = TextEditingController(text: '1');
  final _dayNameController = TextEditingController();

  ActivityType _type = ActivityType.meeting;
  CostType _costType = CostType.free;
  DateTime _startDateTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 2));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _mapLinkController.dispose();
    _contactController.dispose();
    _priceController.dispose();
    _startHourController.dispose();
    _durationController.dispose();
    _scriptureController.dispose();
    _actionTypeController.dispose();
    _meetingObjectivesController.dispose();
    _videoUrlsController.dispose();
    _dayIndexController.dispose();
    _dayNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDateTime : _endDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStart ? _startDateTime : _endDateTime,
        ),
      );

      if (time != null) {
        setState(() {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startDateTime = dt;
            if (_endDateTime.isBefore(_startDateTime)) {
              _endDateTime = _startDateTime.add(const Duration(hours: 1));
            }
          } else {
            _endDateTime = dt;
          }
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repository = context.read<Repository>();

    try {
      await repository.createActivity({
        'eventId': widget.eventId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'activityType': _type.name,
        'locationName': _locationController.text.trim(),
        'mapLink': _mapLinkController.text.trim(),
        'startDateTime': _startDateTime.toIso8601String(),
        'endDateTime': _endDateTime.toIso8601String(),
        'costType': _costType.name,
        'price': _costType == CostType.paid
            ? double.tryParse(_priceController.text) ?? 0.0
            : 0.0,
        'organizerContact': _contactController.text.trim(),
        'config': {
          'startHour': int.tryParse(_startHourController.text),
          'durationHours': int.tryParse(_durationController.text),
          'scripture': _scriptureController.text.trim(),
          'actionType': _actionTypeController.text.trim(),
          'meetingObjectives': _meetingObjectivesController.text
              .split('\n')
              .where((s) => s.isNotEmpty)
              .toList(),
          'videoUrls': _videoUrlsController.text
              .split('\n')
              .where((s) => s.isNotEmpty)
              .toList(),
          'dayIndex': int.tryParse(_dayIndexController.text),
          'dayName': _dayNameController.text.trim(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity created successfully')),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          'INITIATE ACTIVITY',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(
                      theme,
                      'Divine Context',
                      Icons.event_note,
                    ),
                    StreamBuilder<Event?>(
                      stream: context.read<Repository>().getEvent(
                        widget.eventId,
                      ),
                      builder: (context, snapshot) {
                        final eventName =
                            snapshot.data?.title ?? 'Loading event...';
                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hub_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PARENT EVENT',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                      Text(
                                        eventName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      theme,
                      'Activity Essence',
                      Icons.auto_awesome_outlined,
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              theme: theme,
                              controller: _titleController,
                              label: 'Activity Title',
                              hint: 'e.g. Morning Fire Worship',
                              icon: Icons.title,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              theme: theme,
                              controller: _descController,
                              label: 'Description',
                              hint: 'What is the essence of this gathering?',
                              icon: Icons.description_outlined,
                              maxLines: 2,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<ActivityType>(
                              value: _type,
                              decoration: InputDecoration(
                                labelText: 'Gathering Type',
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.5,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              items: ActivityType.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.name.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      theme,
                      'Configuration',
                      Icons.settings_outlined,
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildTaskConfigForm(theme),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      theme,
                      'Time & Logistics',
                      Icons.location_on_outlined,
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              theme: theme,
                              controller: _locationController,
                              label: 'Location Name',
                              hint: 'e.g. The Upper Room',
                              icon: Icons.place_outlined,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTimePickerTile(
                                    context,
                                    label: 'Starts',
                                    dateTime: _startDateTime,
                                    onTap: () => _selectDateTime(true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateTimePickerTile(
                                    context,
                                    label: 'Ends',
                                    dateTime: _endDateTime,
                                    onTap: () => _selectDateTime(false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'CREATE ACTIVITY',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: theme.colorScheme.primary.withOpacity(0.5))
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDateTimePickerTile(
    BuildContext context, {
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, HH:mm').format(dateTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskConfigForm(ThemeData theme) {
    switch (_type) {
      case ActivityType.prayer:
      case ActivityType.silence:
      case ActivityType.worship:
        return Column(
          children: [
            _buildTextField(
              theme: theme,
              controller: _startHourController,
              label: 'Start Hour (0-23)',
              icon: Icons.access_time,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              theme: theme,
              controller: _durationController,
              label: 'Duration (Hours)',
              icon: Icons.timelapse,
            ),
            if (_type == ActivityType.worship) ...[
              const SizedBox(height: 16),
              _buildTextField(
                theme: theme,
                controller: _videoUrlsController,
                label: 'Video Links',
                hint: 'YouTube/Twitch URLs',
                icon: Icons.video_library,
                maxLines: 3,
              ),
            ],
          ],
        );
      case ActivityType.rhema:
        return _buildTextField(
          theme: theme,
          controller: _scriptureController,
          label: 'Scripture Reference',
          hint: 'e.g. Genesis 1:1',
          icon: Icons.menu_book,
        );
      case ActivityType.meeting:
        return Column(
          children: [
            _buildTextField(
              theme: theme,
              controller: _dayNameController,
              label: 'Day Name',
              hint: 'e.g. Monday',
              icon: Icons.today,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              theme: theme,
              controller: _durationController,
              label: 'Duration (Hours)',
              icon: Icons.timelapse,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              theme: theme,
              controller: _meetingObjectivesController,
              label: 'Meeting Objectives',
              hint: 'One per line',
              icon: Icons.flag,
              maxLines: 3,
            ),
          ],
        );
      default:
        return const Center(child: Text('No specific configuration needed.'));
    }
  }
}
