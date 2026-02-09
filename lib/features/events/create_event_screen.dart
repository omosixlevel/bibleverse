import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/data/repository.dart'; // Use Repository
import './event_management_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _fullDescController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _verseSummaryController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  final String _visibility = 'public'; // Enforced Public
  bool _isLoading = false;
  String? _generatedImageUrl;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = context.read<Repository>();
    try {
      // Simulation of Image Generation
      _generatedImageUrl =
          "https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?q=80&w=2070&auto=format&fit=crop";

      final eventId = await repository.createEvent({
        'title': _titleController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'fullDescription': _fullDescController.text.trim(),
        'objectiveStatement': _objectiveController.text.trim(),
        'thematicVerseSummary': _verseSummaryController.text.trim(),
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'visibility': _visibility,
        'creatorId': 'user_offline',
        'status': 'active',
        'coverImageUrl': _generatedImageUrl,
      });

      if (mounted && eventId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Event created successfully! Navigating to your dashboard.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventManagementScreen(eventId: eventId),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create event. Please try again.'),
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
          'CREATE DIVINE EVENT',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(
                      theme,
                      'Basic Information',
                      Icons.info_outline,
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
                              controller: _titleController,
                              label: 'Event Title',
                              hint: 'Enter a catchy title',
                              icon: Icons.title,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _shortDescController,
                              label: 'Short Catchphrase',
                              hint: 'A quick summary for the cards',
                              icon: Icons.short_text,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      theme,
                      'Detailed Description',
                      Icons.description_outlined,
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
                        child: _buildTextField(
                          controller: _fullDescController,
                          label: 'Full Description',
                          hint: 'Tell the world more about this event...',
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      theme,
                      'Vision & Scripture',
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
                              controller: _objectiveController,
                              label: 'Objective Statement',
                              hint: 'The core purpose of this gathering',
                              icon: Icons.flag_outlined,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'REQUIRED' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _verseSummaryController,
                              label: 'Thematic Verse Summary',
                              hint: 'Main Bible reference or theme',
                              icon: Icons.menu_book,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      theme,
                      'Schedule & Visibility',
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
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDatePicker(
                                    context,
                                    label: 'Start Date',
                                    date: _startDate,
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDatePicker(
                                    context,
                                    label: 'End Date',
                                    date: _endDate,
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ListTile(
                              leading: Icon(
                                Icons.public,
                                color: theme.colorScheme.primary,
                              ),
                              title: const Text(
                                'Publicly Visible',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'This event will be discoverable by everyone.',
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              ),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'INITIALIZE DIVINE SETUP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
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
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
            ? Icon(icon, color: Colors.indigo.withOpacity(0.5))
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd').format(date),
                  style: theme.textTheme.bodyMedium?.copyWith(
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
}
