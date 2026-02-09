import 'dart:convert';

/// Represents the rich text structure used throughout the application.
/// Examples: Notebook entries, Messages, Announcements.
class DynamicText {
  final Map<String, dynamic> content;

  const DynamicText({required this.content});

  Map<String, dynamic> toJson() => content;

  /// Returns the plain text representation of the content.
  String get text => toPlainText();

  /// Creates a DynamicText instance from a raw JSON map.
  factory DynamicText.fromJson(Map<String, dynamic> json) {
    return DynamicText(content: json);
  }

  /// Helper to create a simple text-only DynamicText.
  factory DynamicText.fromString(String text) {
    return DynamicText(
      content: {
        'ops': [
          {'insert': '$text\n'},
        ],
      },
    );
  }

  /// Returns a plain text representation of the content.
  String toPlainText() {
    // 1. Check for new block-based structure (List)
    if (content.containsKey('blocks') && content['blocks'] is List) {
      final blocks = content['blocks'] as List;
      return blocks.map((b) => b['content'] as String? ?? '').join('\n');
    }

    // 2. Legacy/Simple Text check
    if (content.containsKey('text') && content['text'] is String) {
      return content['text'];
    }

    // 3. Fallback for Quill/Delta (if any legacy data remains)
    if (content.containsKey('ops') && content['ops'] is List) {
      final ops = content['ops'] as List;
      final buffer = StringBuffer();
      for (var op in ops) {
        if (op is Map && op.containsKey('insert')) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString().trim();
    }
    return '';
  }

  /// Creates a DynamicText instance from a list of blocks.
  factory DynamicText.fromBlocks(List<Map<String, dynamic>> blocks) {
    return DynamicText(content: {'blocks': blocks});
  }

  @override
  String toString() => jsonEncode(content);
}
