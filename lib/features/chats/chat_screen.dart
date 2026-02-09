import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/chat_model.dart';
import '../../models/dynamic_text.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/dynamic_text_editor.dart';
import '../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatScreen({super.key, required this.chatId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<DynamicTextEditorState> _editorKey =
      GlobalKey<DynamicTextEditorState>();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final repository = context.read<Repository>();
    final content = text; // Persist text so we can clear controller immediately

    // Capture blocks BEFORE clearing the editor!
    final finalBlocks =
        _editorKey.currentState?.blocks.map((b) => b.toJson()).toList() ??
        [
          {'mode': 'normal', 'content': content},
        ];

    _messageController.clear();
    _editorKey.currentState?.clear();
    // Keep focus (optional)

    try {
      await repository.sendMessage(widget.chatId, {
        'senderId': 'user_offline', // Mock user
        'content': content,
        'contentRichText': DynamicText.fromBlocks(finalBlocks).toJson(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<Repository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Gemini Study Assistant',
            onPressed: () => _showGeminiStudyAssistant(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repository.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final messages =
                        snapshot.data
                            ?.map((m) => ChatMessage.fromMap(m))
                            .toList() ??
                        [];

                    if (messages.isEmpty) {
                      return const Center(child: Text('No messages yet.'));
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        bottom: 160,
                      ), // Space for Command Bar
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe =
                            msg.senderId == 'user_123'; // TODO: Get from Auth

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.senderId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  _buildFormattedMessage(
                                    context,
                                    msg.contentRichText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Chat Input Area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: DynamicTextEditor(
                          key: _editorKey,
                          maxLines: null,
                          showModeSelector: true, // User wants to choose modes
                          placeholder: 'Share a revelation...',
                          onTextChanged: (text) {
                            _messageController.text = text;
                          },
                          onWordLookup: (word) => _analyzeWord(context, word),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _sendMessage,
                        tooltip: 'Send',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGeminiStudyAssistant(BuildContext context) {
    final theme = Theme.of(context);
    final geminiService = GeminiService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini Study Assistant',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Empowering community revelation',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildAssistantAction(
                      theme,
                      'Summarize Study Session',
                      Icons.summarize,
                      'Generate a key-point summary of the messages below.',
                      onTap: () async {
                        // Gather chat messages
                        final messages = await context
                            .read<Repository>()
                            .getMessages(widget.chatId)
                            .first;

                        final messageTexts = messages
                            .map(
                              (m) =>
                                  ChatMessage.fromMap(m).contentRichText.text,
                            )
                            .toList();

                        _showAssistantResult(
                          context,
                          'Study Summary',
                          geminiService.summarizeStudySession(messageTexts),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAssistantAction(
                      theme,
                      'Community Spiritual Memory',
                      Icons.psychology,
                      'Relate this chat to previous group revelations.',
                      onTap: () async {
                        _showAssistantResult(
                          context,
                          'Community Memory',
                          geminiService.recallCommunityMemory(
                            widget.title,
                            _messageController.text.isNotEmpty
                                ? _messageController.text
                                : 'General Discussion',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantAction(
    ThemeData theme,
    String title,
    IconData icon,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAssistantResult(
    BuildContext context,
    String title,
    Future<String> future,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: FutureBuilder<String>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return SingleChildScrollView(
              child: Text(snapshot.data ?? 'Error generating result.'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeWord(BuildContext context, String word) async {
    final theme = Theme.of(context);
    final geminiService = GeminiService();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await geminiService.analyzeBiblicalWord(word);

    // Hide loading
    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.toUpperCase(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Deep Linguistic Analysis',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (result.containsKey('error'))
                Text(
                  result['error']!,
                  style: const TextStyle(color: Colors.red),
                )
              else ...[
                _buildAnalysisRow(
                  theme,
                  'Original Root',
                  result['original'] ?? '',
                ),
                const Divider(height: 24),
                _buildAnalysisRow(
                  theme,
                  'Core Meaning',
                  result['meaning'] ?? '',
                ),
                const Divider(height: 24),
                _buildAnalysisRow(theme, 'Evolution', result['usage'] ?? ''),
                const Divider(height: 24),
                Text(
                  result['context'] ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAnalysisRow(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildFormattedMessage(BuildContext context, DynamicText richText) {
    final theme = Theme.of(context);
    final content = richText.content;

    // 1. Check for block-based content
    if (content.containsKey('blocks') && content['blocks'] is List) {
      final blocks = (content['blocks'] as List)
          .map((b) => RichTextBlock.fromJson(b))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((block) {
          switch (block.mode) {
            case TextMode.title:
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  block.content,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            case TextMode.prayerPoints:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppTheme.prayerColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        block.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.prayerColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            case TextMode.verseEmbed:
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  block.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            case TextMode.normal:
            default:
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(block.content, style: theme.textTheme.bodyMedium),
              );
          }
        }).toList(),
      );
    }

    // 2. Fallback to simple text
    return Text(richText.text);
  }
}
