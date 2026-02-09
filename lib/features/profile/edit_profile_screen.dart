import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../../core/models/user_profile.dart';

/// Edit Profile Screen
/// Allows users to edit their display name and avatar
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile(
        uid: widget.profile.uid,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveProfile, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: widget.profile.avatarUrl != null
                          ? NetworkImage(widget.profile.avatarUrl!)
                          : null,
                      child: widget.profile.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          // TODO: Implement avatar picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avatar picker coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Display Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a display name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Name must be less than 50 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),

            // User ID (Read-only)
            TextFormField(
              initialValue: widget.profile.uid,
              decoration: InputDecoration(
                labelText: 'User ID',
                prefixIcon: const Icon(Icons.fingerprint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              enabled: false,
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your display name is visible to other members in rooms and events.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
