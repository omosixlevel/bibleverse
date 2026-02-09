import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SacredActivityConfigSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const SacredActivityConfigSheet({super.key, required this.onSave});

  @override
  State<SacredActivityConfigSheet> createState() =>
      _SacredActivityConfigSheetState();
}

class _SacredActivityConfigSheetState extends State<SacredActivityConfigSheet> {
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'PHYSICAL GATHERING',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Activity Title',
                hintText: 'e.g., Morning Prayer Walk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Meeting Place',
                hintText: 'e.g., Central Park, Room 304',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hour',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _placeController.text.isNotEmpty) {
                  final DateTime activityDateTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );

                  widget.onSave({
                    'title': _titleController.text.trim(),
                    'place': _placeController.text.trim(),
                    'date': activityDateTime.toIso8601String(),
                    'hour':
                        '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    'type': 'physical_meeting',
                  });
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('SCHEDULE GATHERING'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
