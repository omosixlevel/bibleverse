import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../../core/models/user_profile.dart';

/// Bible Version Selector Screen
/// Choose from multiple Bible translations
class BibleVersionSelectorScreen extends StatefulWidget {
  final UserProfile profile;

  const BibleVersionSelectorScreen({super.key, required this.profile});

  @override
  State<BibleVersionSelectorScreen> createState() =>
      _BibleVersionSelectorScreenState();
}

class _BibleVersionSelectorScreenState
    extends State<BibleVersionSelectorScreen> {
  final ProfileService _profileService = ProfileService();
  late String _selectedVersion;

  final List<Map<String, String>> _bibleVersions = [
    {
      'code': 'KJV',
      'name': 'King James Version',
      'description': 'Traditional English translation from 1611',
    },
    {
      'code': 'NIV',
      'name': 'New International Version',
      'description': 'Modern, easy-to-read translation',
    },
    {
      'code': 'ESV',
      'name': 'English Standard Version',
      'description': 'Literal yet readable modern translation',
    },
    {
      'code': 'NLT',
      'name': 'New Living Translation',
      'description': 'Thought-for-thought contemporary translation',
    },
    {
      'code': 'NKJV',
      'name': 'New King James Version',
      'description': 'Updated KJV with modern English',
    },
    {
      'code': 'MSG',
      'name': 'The Message',
      'description': 'Contemporary paraphrase',
    },
    {
      'code': 'LSG',
      'name': 'Louis Segond (French)',
      'description': 'French Protestant translation',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedVersion = widget.profile.preferences.bibleVersion;
  }

  Future<void> _saveSelection() async {
    final newPrefs = widget.profile.preferences.copyWith(
      bibleVersion: _selectedVersion,
    );

    await _profileService.updatePreferences(widget.profile.uid, newPrefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bible version changed to $_selectedVersion')),
      );
      Navigator.pop(context, _selectedVersion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Version'),
        actions: [
          TextButton(
            onPressed:
                _selectedVersion != widget.profile.preferences.bibleVersion
                ? _saveSelection
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select your preferred Bible translation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Version List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _bibleVersions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final version = _bibleVersions[index];
                final isSelected = _selectedVersion == version['code'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        version['code']!,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    version['name']!,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    version['description']!,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primaryContainer
                      .withOpacity(0.2),
                  onTap: () {
                    setState(() => _selectedVersion = version['code']!);
                  },
                );
              },
            ),
          ),

          // Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Currently only KJV is available offline. Other versions coming soon!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
