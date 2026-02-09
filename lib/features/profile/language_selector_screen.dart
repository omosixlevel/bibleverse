import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/profile_service.dart';
import '../../core/models/user_profile.dart';

/// Language Selector Screen
/// Choose app language (English/Français)
class LanguageSelectorScreen extends StatefulWidget {
  final UserProfile profile;

  const LanguageSelectorScreen({super.key, required this.profile});

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  final ProfileService _profileService = ProfileService();
  late String _selectedLanguageCode;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize from provider, not just profile, to ensure sync
    final providerLocale = context.read<LocaleProvider>().locale.languageCode;
    _selectedLanguageCode = providerLocale;
  }

  Future<void> _saveSelection(String code) async {
    // 1. Update Provider (Applied immediately to detailed UI)
    await context.read<LocaleProvider>().setLocale(Locale(code));

    // 2. Update Profile Preferences (Persisted to backend)
    final newPrefs = widget.profile.preferences.copyWith(language: code);

    await _profileService.updatePreferences(widget.profile.uid, newPrefs);

    if (mounted) {
      setState(() => _selectedLanguageCode = code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 'fr'
                ? 'Langue changée en Français'
                : 'Language changed to English',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFrench = _selectedLanguageCode == 'fr';

    return Scaffold(
      appBar: AppBar(title: Text(isFrench ? 'Langue' : 'Language')),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.language, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFrench
                        ? 'Sélectionnez votre langue préférée'
                        : 'Select your preferred language',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Language List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _languages.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final language = _languages[index];
                final code = language['code']!;
                final isSelected = _selectedLanguageCode == code;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Text(
                    language['flag']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    language['nativeName']!,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    language['name']!,
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
                  onTap: () => _saveSelection(code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
