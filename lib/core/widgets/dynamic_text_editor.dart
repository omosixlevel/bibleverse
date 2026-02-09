import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

/// Text mode for DynamicTextEditor
enum TextMode { title, normal, prayerPoints, verseEmbed }

/// Rich text block for JSON output
class RichTextBlock {
  final TextMode mode;
  final String content;
  final Map<String, dynamic>? metadata;

  RichTextBlock({required this.mode, required this.content, this.metadata});

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'content': content,
    if (metadata != null) 'metadata': metadata,
  };

  factory RichTextBlock.fromJson(Map<String, dynamic> json) {
    return RichTextBlock(
      mode: TextMode.values.firstWhere((e) => e.name == json['mode']),
      content: json['content'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Verse suggestion from Gemini
class VerseSuggestion {
  final String reference;
  final String preview;
  final String fullText;

  const VerseSuggestion({
    required this.reference,
    required this.preview,
    required this.fullText,
  });
}

/// A reusable dynamic text editor widget with multiple modes
/// Used in Chat, Tasks, Notebook, Room planning, Announcements
class DynamicTextEditor extends StatefulWidget {
  final String? initialText;
  final TextMode initialMode;
  final ValueChanged<String>? onTextChanged;
  final ValueChanged<TextMode>? onModeChanged;
  final ValueChanged<List<RichTextBlock>>? onRichTextChanged;
  final ValueChanged<String>? onWordLookup; // New callback
  final bool showModeSelector;
  final bool showGeminiPanel;
  final bool isOnline;
  final String? placeholder;
  final int? maxLines;
  final bool autofocus;

  const DynamicTextEditor({
    super.key,
    this.initialText,
    this.initialMode = TextMode.normal,
    this.onTextChanged,
    this.onModeChanged,
    this.onRichTextChanged,
    this.onWordLookup,
    this.showModeSelector = true,
    this.showGeminiPanel = false,
    this.isOnline = true,
    this.placeholder,
    this.maxLines,
    this.autofocus = false,
  });

  @override
  State<DynamicTextEditor> createState() => DynamicTextEditorState();
}

class DynamicTextEditorState extends State<DynamicTextEditor> {
  List<RichTextBlock> _blocks =
      []; // Remove final to allow reset, or just clear list
  List<RichTextBlock> get blocks => List.unmodifiable(_blocks);
  int _activeBlockIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Suggestion State
  OverlayEntry? _suggestionOverlay;
  List<VerseSuggestion> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeBlocks();
  }

  void _initializeBlocks() {
    _blocks = [];
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      // TODO: Parse initial text if it was JSON, for now treat as one text block
      _blocks.add(
        RichTextBlock(mode: TextMode.normal, content: widget.initialText!),
      );
    } else {
      _blocks.add(RichTextBlock(mode: widget.initialMode, content: ''));
    }
  }

  void clear() {
    setState(() {
      _initializeBlocks();
      _activeBlockIndex = 0;
    });
    _notifyChange();
  }

  @override
  void dispose() {
    _removeSuggestionOverlay();
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final plainText = _blocks.map((b) => b.content).join('\n');
    widget.onTextChanged?.call(plainText);
    widget.onRichTextChanged?.call(_blocks);
  }

  void _addNewBlock(TextMode mode) {
    setState(() {
      if (_blocks[_activeBlockIndex].content.isEmpty) {
        _blocks[_activeBlockIndex] = RichTextBlock(mode: mode, content: '');
      } else {
        _blocks.add(RichTextBlock(mode: mode, content: ''));
        _activeBlockIndex = _blocks.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    _notifyChange();
  }

  void _updateBlock(int index, String content) {
    setState(() {
      final oldBlock = _blocks[index];
      _blocks[index] = RichTextBlock(
        mode: oldBlock.mode,
        content: content,
        metadata: oldBlock.metadata,
      );
      _activeBlockIndex = index;
    });
    _checkForVerseSuggestions(content);
    _notifyChange();
  }

  // --- Bible Suggestions ---

  void _checkForVerseSuggestions(String text) {
    if (!widget.isOnline) return;
    final words = text.split(' ');
    if (words.isEmpty) return;
    final lastWord = words.last.toUpperCase();

    if (lastWord.length >= 3 && _isBibleBookStart(lastWord)) {
      _showSuggestions(lastWord);
    } else {
      _removeSuggestionOverlay();
    }
  }

  bool _isBibleBookStart(String query) {
    const books = ['GEN', 'EXO', 'PSA', 'MAT', 'JOH', 'ROM', 'REV'];
    return books.any((b) => b.startsWith(query));
  }

  void _showSuggestions(String query) {
    _filteredSuggestions = [
      if (query.startsWith('GEN'))
        const VerseSuggestion(
          reference: 'Genesis 1:1',
          preview: 'In the beginning...',
          fullText: 'In the beginning God created the heaven and the earth.',
        ),
      if (query.startsWith('PSA'))
        const VerseSuggestion(
          reference: 'Psalm 23:1',
          preview: 'The Lord is my shepherd...',
          fullText: 'The Lord is my shepherd; I shall not want.',
        ),
      if (query.startsWith('JOH'))
        const VerseSuggestion(
          reference: 'John 3:16',
          preview: 'For God so loved...',
          fullText: 'For God so loved the world...',
        ),
    ];

    if (_filteredSuggestions.isEmpty) {
      _removeSuggestionOverlay();
      return;
    }

    if (_suggestionOverlay == null) {
      _suggestionOverlay = _createOverlayEntry();
      Overlay.of(context).insert(_suggestionOverlay!);
    } else {
      _suggestionOverlay!.markNeedsBuild();
    }
  }

  void _removeSuggestionOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 120, // Simple hardcoded position for hackathon
        width: size.width,
        height: 120,
        child: Material(
          elevation: 4.0,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _filteredSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _filteredSuggestions[index];
              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(suggestion.reference),
                subtitle: Text(suggestion.preview),
                onTap: () {
                  _insertSuggestion(suggestion);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _insertSuggestion(VerseSuggestion suggestion) {
    final currentBlock = _blocks[_activeBlockIndex];
    final text = currentBlock.content;
    final lastSpace = text.trimRight().lastIndexOf(' ');
    // Handle single word text
    final prefix = lastSpace == -1 ? '' : text.substring(0, lastSpace);

    // We replace the last term (abbreviation) with the full verse block or text
    // BUT user wants structured blocks. Ideally, a verse should be its own block type if it's large.
    // For now, let's append it to text with notation.
    final newContent = '$prefix [${suggestion.reference}] ';

    _updateBlock(_activeBlockIndex, newContent);
    _removeSuggestionOverlay();
  }

  // --- Rendering ---

  String _getModeLabel(TextMode mode) {
    switch (mode) {
      case TextMode.title:
        return 'Heading';
      case TextMode.normal:
        return 'Text';
      case TextMode.prayerPoints:
        return 'List';
      case TextMode.verseEmbed:
        return 'Verse';
    }
  }

  IconData _getModeIcon(TextMode mode) {
    switch (mode) {
      case TextMode.title:
        return Icons.title;
      case TextMode.normal:
        return Icons.short_text;
      case TextMode.prayerPoints:
        return Icons.format_list_bulleted;
      case TextMode.verseEmbed:
        return Icons.format_quote;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showModeSelector)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TextMode.values.map((mode) {
                  final isActive =
                      _blocks.isNotEmpty &&
                      _blocks[_activeBlockIndex].mode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.3),
                          width: isActive ? 1.5 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.2,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _addNewBlock(mode),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getModeIcon(mode),
                                  size: 16,
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getModeLabel(mode),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        Flexible(
          fit: FlexFit.loose,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _blocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildBlockInput(context, index, _blocks[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockInput(
    BuildContext context,
    int index,
    RichTextBlock block,
  ) {
    final theme = Theme.of(context);
    final isActive = index == _activeBlockIndex;

    TextStyle style;
    InputDecoration decoration = const InputDecoration(
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    );

    Widget? prefixWidget;
    BoxDecoration? containerDecoration;
    EdgeInsets containerPadding = EdgeInsets.zero;

    switch (block.mode) {
      case TextMode.title:
        style = theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        );
        decoration = decoration.copyWith(
          hintText: 'Heading',
          hintStyle: style.copyWith(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        );
        break;
      case TextMode.prayerPoints:
        style = theme.textTheme.bodyLarge!.copyWith(
          color: AppTheme.prayerColor,
          height: 1.5,
        );
        decoration = decoration.copyWith(
          hintText: 'Prayer point...',
          hintStyle: style.copyWith(
            color: AppTheme.prayerColor.withOpacity(0.5),
          ),
        );
        prefixWidget = Padding(
          padding: const EdgeInsets.only(right: 12, top: 4),
          child: Icon(Icons.circle, size: 8, color: AppTheme.prayerColor),
        );
        break;
      case TextMode.verseEmbed:
        style = theme.textTheme.bodyMedium!.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.primary,
          height: 1.6,
        );
        decoration = decoration.copyWith(
          hintText: 'Paste scripture reference...',
        );
        containerDecoration = BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        );
        containerPadding = const EdgeInsets.fromLTRB(16, 8, 8, 8);
        break;
      case TextMode.normal:
      default:
        style = theme.textTheme.bodyLarge!.copyWith(height: 1.5);
        decoration = decoration.copyWith(
          hintText: widget.placeholder ?? 'Start typing...',
          hintStyle: style.copyWith(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        );
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeBlockIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration:
            containerDecoration ??
            BoxDecoration(
              color: isActive ? theme.colorScheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    )
                  : null,
            ),
        padding: containerPadding == EdgeInsets.zero
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
            : containerPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prefixWidget != null) prefixWidget,
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('block_$index'),
                child: TextFormField(
                  initialValue: block.content,
                  style: style,
                  decoration: decoration,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (val) => _updateBlock(index, val),
                  onTap: () {
                    setState(() {
                      _activeBlockIndex = index;
                    });
                  },
                  contextMenuBuilder: (context, editableTextState) {
                    final List<ContextMenuButtonItem> buttonItems =
                        editableTextState.contextMenuButtonItems;

                    // Add Gemini Analyze button
                    buttonItems.insert(
                      0,
                      ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          final text = editableTextState
                              .textEditingValue
                              .selection
                              .textInside(
                                editableTextState.textEditingValue.text,
                              );
                          if (text.isNotEmpty) {
                            widget.onWordLookup?.call(text);
                          }
                        },
                        label: 'Analyze',
                        type: ContextMenuButtonType.custom,
                      ),
                    );

                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: buttonItems,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
