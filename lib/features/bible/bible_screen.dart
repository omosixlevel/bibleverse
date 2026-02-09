import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/services/bible_service.dart';
import '../../core/widgets/sacred_pill_tab_bar.dart';
import '../../core/services/gemini_service.dart';
import '../../core/widgets/dynamic_text_editor.dart'; // For TextMode
import '../../features/notebook/notebook_screen.dart'; // Import
import '../chats/chats_hub_screen.dart';
import '../../core/localization/app_strings.dart';

/// Reading history entry
class ReadingHistoryEntry {
  final String book;
  final int chapter;
  final DateTime timestamp;

  ReadingHistoryEntry({
    required this.book,
    required this.chapter,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'book': book,
    'chapter': chapter,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ReadingHistoryEntry(
        book: json['book'] as String,
        chapter: json['chapter'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String get reference => '$book $chapter';
}

/// Verse model for Bible text
class Verse {
  final int number;
  final String text;
  final bool isHighlighted;
  final Color? highlightColor;

  const Verse({
    required this.number,
    required this.text,
    this.isHighlighted = false,
    this.highlightColor,
  });

  Verse copyWith({
    int? number,
    String? text,
    bool? isHighlighted,
    Color? highlightColor,
  }) {
    return Verse(
      number: number ?? this.number,
      text: text ?? this.text,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }
}

/// Highlight colors available for verses
class HighlightColors {
  static const Color yellow = Color(0xFFFFF59D);
  static const Color green = Color(0xFFA5D6A7);
  static const Color blue = Color(0xFF90CAF9);
  static const Color pink = Color(0xFFF48FB1);
  static const Color orange = Color(0xFFFFCC80);

  static List<Color> get all => [yellow, green, blue, pink, orange];
}

/// Bible Screen with Book/Chapter selector and verse actions
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen>
    with SingleTickerProviderStateMixin {
  String _selectedVersion = BibleService.VERSION_KJV;
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;
  final Set<int> _selectedVerses = {};
  bool _isOnline = true; // Simulated online status
  bool _showSplitView = false;

  late AnimationController _actionBarController;
  late Animation<Offset> _actionBarAnimation;

  final List<Verse> _verses = [];
  List<String> _books = [];
  bool _isLoading = true;
  List<ReadingHistoryEntry> _readingHistory = [];
  static const String _historyKey = 'reading_history';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBible());
    _loadHistory();
    _actionBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _actionBarAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _actionBarController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  Future<void> _initBible() async {
    final bibleService = context.read<BibleService>();
    await bibleService.loadBibles();
    setState(() {
      _books = bibleService.getBooks(_selectedVersion);
      if (_books.isNotEmpty && !_books.contains(_selectedBook)) {
        _selectedBook = _books.first;
      }
      _isLoading = false;
    });
    _loadVerses();
  }

  @override
  void dispose() {
    _actionBarController.dispose();
    super.dispose();
  }

  void _loadVerses() {
    final bibleService = context.read<BibleService>();
    final verses = bibleService.getChapterVerses(
      _selectedVersion,
      _selectedBook,
      _selectedChapter,
    );

    setState(() {
      _verses.clear();
      for (int i = 0; i < verses.length; i++) {
        _verses.add(Verse(number: i + 1, text: verses[i]));
      }
      _selectedVerses.clear();
      _actionBarController.reverse();
    });
  }

  void _toggleVerseSelection(int verseNumber) {
    setState(() {
      if (_selectedVerses.contains(verseNumber)) {
        _selectedVerses.remove(verseNumber);
      } else {
        _selectedVerses.add(verseNumber);
      }

      if (_selectedVerses.isNotEmpty) {
        _actionBarController.forward();
      } else {
        _actionBarController.reverse();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVerses.clear();
    });
    _actionBarController.reverse();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        setState(() {
          _readingHistory = decoded
              .map((h) => ReadingHistoryEntry.fromJson(h))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading reading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _readingHistory.map((h) => h.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error saving reading history: $e');
    }
  }

  void _trackReading() async {
    // Add or update reading history entry
    final newEntry = ReadingHistoryEntry(
      book: _selectedBook,
      chapter: _selectedChapter,
      timestamp: DateTime.now(),
    );

    setState(() {
      // Remove any existing entry for this book/chapter
      _readingHistory.removeWhere(
        (e) => e.book == _selectedBook && e.chapter == _selectedChapter,
      );
      // Add new entry at the beginning
      _readingHistory.insert(0, newEntry);
      // Keep only last 50 entries
      if (_readingHistory.length > 50) {
        _readingHistory = _readingHistory.sublist(0, 50);
      }
    });

    await _saveHistory();
  }

  void _highlightVerses(Color color) {
    setState(() {
      for (int i = 0; i < _verses.length; i++) {
        if (_selectedVerses.contains(_verses[i].number)) {
          _verses[i] = _verses[i].copyWith(
            isHighlighted: true,
            highlightColor: color,
          );
        }
      }
    });
    _clearSelection();
    _clearSelection();
    _showSnackBar(AppStrings.of(context, listen: false).versesHighlighted);
  }

  void _copyVerses() {
    final selectedTexts = _verses
        .where((v) => _selectedVerses.contains(v.number))
        .map((v) => '${v.number}. ${v.text}')
        .join('\n');

    Clipboard.setData(
      ClipboardData(text: '$_selectedBook $_selectedChapter\n$selectedTexts'),
    );
    _clearSelection();
    _showSnackBar(AppStrings.of(context, listen: false).copiedToClipboard);
  }

  void _addToNotebook() {
    _clearSelection();
    _showSnackBar(AppStrings.of(context, listen: false).addedToNotebook);
  }

  void _explainWithGemini() {
    if (!_isOnline) {
      _showSnackBar(AppStrings.of(context, listen: false).internetRequired);
      return;
    }
    _showGeminiExplanation();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showGeminiExplanation() {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context, listen: false);
    final geminiService = GeminiService();
    final selectedText = _selectedVerses
        .map((v) => _verses.firstWhere((verse) => verse.number == v).text)
        .join(' ');
    final reference =
        '$_selectedBook $_selectedChapter:${_selectedVerses.join(',')}';

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                              theme.colorScheme.tertiary,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.geminiEngine,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              reference,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
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
                      // 1. Linguistic Analysis
                      FutureBuilder<Map<String, String>>(
                        future: geminiService.analyzeBiblicalWord(
                          selectedText.split(' ').first,
                        ), // Example: analyze first word
                        builder: (context, snapshot) {
                          String content = 'Analyzing roots...';
                          if (snapshot.hasData) {
                            final data = snapshot.data!;
                            if (data.containsKey('result')) {
                              content = data['result']!;
                            } else {
                              content = data.entries
                                  .map(
                                    (e) => '${e.key.toUpperCase()}: ${e.value}',
                                  )
                                  .join('\n\n');
                            }
                          }
                          return _buildInsightSection(
                            theme,
                            strings.linguistics,
                            Icons.translate,
                            content,
                            isLoading: !snapshot.hasData,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Semantic Similarity
                      FutureBuilder<List<String>>(
                        future: geminiService.findSimilarVerses(selectedText),
                        builder: (context, snapshot) {
                          return _buildInsightSection(
                            theme,
                            strings.similarity,
                            Icons.psychology_alt,
                            snapshot.hasData
                                ? 'Verses with similar spirit:\n${snapshot.data!.join("\n")}'
                                : 'Finding intention-based parallels...',
                            isLoading: !snapshot.hasData,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 3. Prayer Points & Declarations
                      FutureBuilder<List<String>>(
                        future: geminiService.generatePrayerPoints(
                          reference,
                          selectedText,
                        ),
                        builder: (context, snapshot) {
                          return _buildInsightSection(
                            theme,
                            strings.prayerPoints,
                            Icons.favorite,
                            snapshot.hasData
                                ? snapshot.data!.join("\n")
                                : 'Generating strategic prayer points...',
                            isLoading: !snapshot.hasData,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 4. Tags
                      FutureBuilder<List<String>>(
                        future: geminiService.generateSpiritualTags(
                          selectedText,
                        ),
                        builder: (context, snapshot) {
                          return _buildInsightSection(
                            theme,
                            strings.tags,
                            Icons.sell,
                            snapshot.hasData
                                ? snapshot.data!.join(", ")
                                : 'Tagging spiritually...',
                            isLoading: !snapshot.hasData,
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
      _clearSelection();
    } catch (e) {
      debugPrint('Error showing Gemini explanation: $e');
      _showSnackBar('Unable to generate insights. Please try again.');
    }
  }

  void _showThematicAnalysis(String themeName) {
    final theme = Theme.of(context);
    final geminiService = GeminiService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.hub,
                        color: theme.colorScheme.onTertiaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.of(context, listen: false).thematicStudy}: $themeName',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppStrings.of(
                              context,
                              listen: false,
                            ).contextAnalysis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<String>(
                  future: geminiService.analyzeThematicProgression(themeName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildInsightSection(
                          theme,
                          'Study Results',
                          Icons.menu_book,
                          snapshot.data ?? 'No results found.',
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () {
                            _addToNotebook(); // Mock saving to notebook
                            Navigator.pop(context);
                            _showSnackBar(
                              AppStrings.of(context, listen: false).studySaved,
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: Text(
                            AppStrings.of(
                              context,
                              listen: false,
                            ).saveToNotebook,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightSection(
    ThemeData theme,
    String title,
    IconData icon,
    String content, {
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  width: 200,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ],
            )
          else
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
        ],
      ),
    );
  }

  void _showHighlightColorPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.of(context).chooseHighlightColor,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: HighlightColors.all.map((color) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _highlightVerses(color);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookSelector() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppStrings.of(context).selectBook,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    final isSelected = book == _selectedBook;
                    return ListTile(
                      title: Text(
                        book,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedBook = book;
                          _selectedChapter = 1;
                        });
                        Navigator.pop(context);
                        _loadVerses();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    Widget bibleContent = Column(
      children: [
        // Offline indicator
        if (!_isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: theme.colorScheme.tertiaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  strings.offlineMode,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),

        // Book & Chapter Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Book Selector Button
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _showBookSelector,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedBook,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Chapter Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Consumer<BibleService>(
                      builder: (context, bibleService, child) {
                        final chapterCount = bibleService.getChapterCount(
                          _selectedVersion,
                          _selectedBook,
                        );
                        if (_selectedChapter > chapterCount &&
                            chapterCount > 0) {
                          _selectedChapter = 1;
                        }
                        return DropdownButton<int>(
                          value:
                              _selectedChapter > 0 &&
                                  _selectedChapter <= chapterCount
                              ? _selectedChapter
                              : (chapterCount > 0 ? 1 : null),
                          isExpanded: true,
                          items: List.generate(
                            chapterCount,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('Ch. ${i + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedChapter = value;
                              });
                              _loadVerses();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bible Text
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 20, // Reduced from 100 for better reading experience
            ),
            itemCount: _verses.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    '$_selectedBook $_selectedChapter',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }

              final verse = _verses[index - 1];
              final isSelected = _selectedVerses.contains(verse.number);

              return GestureDetector(
                onTap: () => _toggleVerseSelection(verse.number),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                        : verse.isHighlighted
                        ? verse.highlightColor?.withOpacity(0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${verse.number} ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: verse.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.7,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Verse Action Bar
        SlideTransition(
          position: _actionBarAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedVerses.length} verse${_selectedVerses.length > 1 ? 's' : ''} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.brush,
                        label: 'Highlight',
                        onTap: _showHighlightColorPicker,
                        theme: theme,
                      ),
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: _copyVerses,
                        theme: theme,
                      ),
                      _buildActionButton(
                        icon: Icons.auto_awesome,
                        label: 'Explain',
                        onTap: _explainWithGemini,
                        theme: theme,
                        isOnlineOnly: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    // Split View Layout
    if (_showSplitView) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bible'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_add),
              tooltip: 'Track this chapter',
              onPressed: _trackReading,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _showSplitView = false),
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(child: bibleContent),
            VerticalDivider(width: 1, color: theme.colorScheme.outline),
            Expanded(child: _buildChatPanel(theme)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bible'),
          bottom: const SacredPillTabBar(tabs: ['READ', 'STUDY', 'HISTORY']),
          actions: [
            _buildVersionSelector(theme),
            IconButton(
              icon: const Icon(Icons.bookmark_add),
              tooltip: 'Track this chapter',
              onPressed: _trackReading,
            ),
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'split_chat':
                    setState(() {
                      _showSplitView = true;
                    });
                    break;
                  case 'toggle_online':
                    setState(() {
                      _isOnline = !_isOnline;
                    });
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'split_chat',
                  child: ListTile(
                    leading: Icon(Icons.forum_outlined),
                    title: Text('Split View: Community'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_online',
                  child: ListTile(
                    leading: Icon(_isOnline ? Icons.cloud_off : Icons.cloud),
                    title: Text(_isOnline ? 'Go Offline' : 'Go Online'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  bibleContent, // READ tab
                  _buildStudyTab(theme), // STUDY tab
                  _buildHistoryTab(theme), // HISTORY tab
                ],
              ),
        endDrawer: _buildGeminiDrawer(theme),
      ),
    );
  }

  Widget _buildStudyTab(ThemeData theme) {
    final geminiService = GeminiService();

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      children: [
        // Personalized Spiritual Path Card (Gemini 3)
        FutureBuilder<Map<String, dynamic>>(
          future: geminiService.proposeSpiritualPath([
            'Psalm 23',
            'John 3',
            'Genesis 1',
          ]),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            return InkWell(
              onTap: () {
                // Navigate to deep view
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.tertiary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Spiritual Path Today',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else ...[
                      Text(
                        data['verse'] ?? 'Seeking...',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily Focus: ${data['focus'] ?? 'Reflection'}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        // Quick Actions Row
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                theme,
                'Notebook',
                Icons.edit_note,
                'Open your sacred notes',
                Colors.orange.shade100,
                Colors.orange.shade900,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const NotebookScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                theme,
                'New Prayer',
                Icons.volunteer_activism,
                'Create a prayer point',
                Colors.blue.shade100,
                Colors.blue.shade900,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const NotebookScreen(
                        initialMode: TextMode.prayerPoints,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(theme, 'Recent Insights', Icons.lightbulb_outline),
        const SizedBox(height: 12),
        _buildNoteCard(
          theme,
          'Meditation on Psalm 23',
          'The Lord is my shepherd... This reminded me that I don\'t need to worry about the future because He is already there.',
          'Jan 28, 2026',
        ),

        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'Thematic Study (Gemini 3)', Icons.hub),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter a theme (e.g., "Covenant", "Grace")',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isEmpty) return;
                    _showThematicAnalysis(value);
                  },
                ),
                const Divider(),
                Text(
                  'Deep analysis across 1M+ tokens of scripture.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'Treasured Verses', Icons.auto_awesome),
        const SizedBox(height: 12),
        // Filter highlighted verses from the current state (mock logic)
        ..._verses
            .where((v) => v.isHighlighted)
            .map((v) => _buildHighlightedVerseCard(theme, v)),
        if (!_verses.any((v) => v.isHighlighted))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No verses highlighted yet.\nLong-press a verse to choose a color!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    ThemeData theme,
    String title,
    IconData icon,
    String subtitle,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: iconColor.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      children: [
        _buildSectionHeader(theme, 'Reading Journey', Icons.history),
        const SizedBox(height: 12),
        if (_readingHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reading history yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start reading to build your journey',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._readingHistory.map((entry) {
            final timeAgo = _getTimeAgo(entry.timestamp);
            return _buildHistoryItem(theme, entry.reference, timeAgo);
          }).toList(),
      ],
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(
    ThemeData theme,
    String title,
    String content,
    String date,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(date, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedVerseCard(ThemeData theme, Verse verse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: verse.highlightColor?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: verse.highlightColor ?? Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedBook $_selectedChapter:${verse.number}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(verse.text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, String title, String time) {
    return ListTile(
      leading: const Icon(Icons.menu_book_outlined, size: 20),
      title: Text(title),
      trailing: Text(time, style: theme.textTheme.labelSmall),
      onTap: () {
        // Handle jumping back to this chapter
      },
    );
  }

  Widget _buildVersionSelector(ThemeData theme) {
    return Consumer<BibleService>(
      builder: (context, bibleService, child) {
        final versions = bibleService.getVersions();
        return PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          tooltip: 'Select Bible Version',
          onSelected: (value) {
            setState(() {
              _selectedVersion = value;
              _books = bibleService.getBooks(value);
              if (_books.isNotEmpty && !_books.contains(_selectedBook)) {
                _selectedBook = _books.first;
              }
              _selectedChapter = 1;
            });
            _loadVerses();
          },
          itemBuilder: (context) => versions.map((v) {
            return PopupMenuItem(value: v['id'], child: Text(v['name']!));
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isOnlineOnly = false,
  }) {
    final isDisabled = isOnlineOnly && !_isOnline;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.labelSmall),
              if (isOnlineOnly && !_isOnline)
                Icon(
                  Icons.cloud_off,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeminiDrawer(ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.tertiaryContainer,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemini Insights',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Word Study'),
              subtitle: const Text('Hebrew/Greek analysis'),
              enabled: _isOnline,
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history_edu),
              title: const Text('Etymology'),
              subtitle: const Text('Word origins and roots'),
              enabled: _isOnline,
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Cross-References'),
              subtitle: const Text('Related passages'),
              enabled: _isOnline,
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Download for Offline'),
              subtitle: Text(_selectedBook),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(ThemeData theme) {
    return const ChatsHubScreen();
  }
}
