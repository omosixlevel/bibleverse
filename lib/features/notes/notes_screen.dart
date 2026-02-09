import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  void _addNote() {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Note'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Write something...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await firestoreService.addNote(userId, controller.text);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(title: const Text('Bloc Note'), centerTitle: true),
      body: userId == null
          ? const Center(child: Text('Please sign in to save notes.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestoreService.getNotes(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 80,
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your spiritual notes will appear here',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(note['content'] ?? ''),
                        subtitle: Text(
                          note['createdAt'] != null
                              ? (note['createdAt'] as dynamic)
                                    .toDate()
                                    .toString()
                                    .split('.')[0]
                              : 'Just now',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () =>
                              firestoreService.deleteNote(userId, note['id']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        label: const Text('NEW NOTE'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
