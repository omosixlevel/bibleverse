import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/widgets/dynamic_text_editor.dart';

class Note {
  final String id;
  final String title;
  final List<RichTextBlock> content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  String get preview {
    if (content.isEmpty) return 'Empty note';
    final firstBlock = content.first;
    return firstBlock.content.length > 100
        ? '${firstBlock.content.substring(0, 100)}...'
        : firstBlock.content;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content.map((b) => b.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: (json['content'] as List)
        .map((b) => RichTextBlock.fromJson(b as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class NotebookScreen extends StatefulWidget {
  final TextMode? initialMode;

  const NotebookScreen({super.key, this.initialMode});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  List<Note> _notes = [];
  bool _isEditing = false;
  Note? _activeNote;
  final GlobalKey<DynamicTextEditorState> _editorKey = GlobalKey();
  bool _isLoading = true;

  static const String _notesKey = 'saved_notes';

  @override
  void initState() {
    super.initState();
    _loadNotes();
    // If initialMode is provided, open editor immediately
    if (widget.initialMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isEditing = true;
        });
      });
    }
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      if (notesJson != null) {
        final List<dynamic> decoded = json.decode(notesJson);
        setState(() {
          _notes = decoded.map((n) => Note.fromJson(n)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(_notes.map((n) => n.toJson()).toList());
      await prefs.setString(_notesKey, notesJson);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  void _createNewNote() {
    setState(() {
      _activeNote = null;
      _isEditing = true;
    });
  }

  void _editNote(Note note) {
    setState(() {
      _activeNote = note;
      _isEditing = true;
    });
  }

  void _saveNote(List<RichTextBlock> blocks) async {
    if (blocks.isEmpty) return;

    final title = blocks.first.content.isEmpty
        ? 'Untitled Note'
        : blocks.first.content.split('\n').first;

    setState(() {
      if (_activeNote == null) {
        // Create new note
        _notes.insert(
          0,
          Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            content: blocks,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Update existing note
        final index = _notes.indexWhere((n) => n.id == _activeNote!.id);
        if (index != -1) {
          _notes[index] = Note(
            id: _activeNote!.id,
            title: title,
            content: blocks,
            createdAt: _activeNote!.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      }
      _isEditing = false;
      _activeNote = null;
    });

    await _saveNotes();
  }

  void _deleteNote(Note note) async {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
    });
    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isEditing) {
      return _buildEditorView(context);
    }
    return _buildListView(context);
  }

  Widget _buildListView(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sacred Notebook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 64,
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first note',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return _buildNoteCard(context, note);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteNote(note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(note.updatedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorView(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isEditing = false;
              _activeNote = null;
            });
          },
        ),
        title: Text(_activeNote == null ? 'New Note' : 'Edit Note'),
        actions: [
          TextButton.icon(
            onPressed: () {
              final blocks = _editorKey.currentState?.blocks ?? [];
              _saveNote(blocks);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Note saved')));
            },
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24), // Top padding as requested
        child: DynamicTextEditor(
          key: _editorKey,
          placeholder: widget.initialMode == TextMode.prayerPoints
              ? 'Write your prayer points here...'
              : 'Write your revelations, prayers, and thoughts here...',
          showModeSelector: true,
          showGeminiPanel: true,
          maxLines: null,
          autofocus: true,
          initialMode: widget.initialMode ?? TextMode.normal,
          initialText: _activeNote?.content.first.content,
          onRichTextChanged: (blocks) {
            // Auto-save logic could go here
          },
          onWordLookup: (word) {
            // Word lookup functionality
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final blocks = _editorKey.currentState?.blocks ?? [];
          _saveNote(blocks);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note saved successfully')),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
