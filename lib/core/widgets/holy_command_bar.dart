import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HolyCommandBar extends StatefulWidget {
  const HolyCommandBar({super.key});

  @override
  State<HolyCommandBar> createState() => _HolyCommandBarState();
}

class _HolyCommandBarState extends State<HolyCommandBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  final _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<CommandResult> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        _focusNode.requestFocus();
      } else {
        _controller.reverse();
        _focusNode.unfocus();
        _inputController.clear();
        _suggestions.clear();
      }
    });
  }

  void _onInputChanged(String val) {
    setState(() {
      _suggestions = _parseInput(val);
    });
  }

  List<CommandResult> _parseInput(String input) {
    if (input.isEmpty) return [];

    final suggestions = <CommandResult>[];
    final loweredInput = input.toLowerCase();

    // 1. Bible Verse Detection (Simple Regex)
    final verseRegex = RegExp(r'^([1-3]?\s?[a-zA-Z\s]+)\s(\d+):?(\d+)?$');
    if (verseRegex.hasMatch(input)) {
      suggestions.add(
        CommandResult(
          title: 'Open Verse: $input',
          icon: Icons.book,
          type: CommandType.verse,
          data: input,
        ),
      );
    }

    // 2. Action Keyword Detection
    if (loweredInput.contains('pray')) {
      suggestions.add(
        const CommandResult(
          title: 'Create Prayer Room',
          icon: Icons.auto_awesome,
          type: CommandType.action,
          data: 'create_prayer_room',
        ),
      );
    }
    if (loweredInput.contains('event') || loweredInput.contains('fast')) {
      suggestions.add(
        const CommandResult(
          title: 'Start New Fasting Event',
          icon: Icons.event,
          type: CommandType.action,
          data: 'create_event',
        ),
      );
    }
    if (loweredInput.contains('study')) {
      suggestions.add(
        const CommandResult(
          title: 'Start Bible Study Room',
          icon: Icons.menu_book,
          type: CommandType.action,
          data: 'create_study_room',
        ),
      );
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (_isExpanded)
              GestureDetector(
                onTap: _toggleExpansion,
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _expandAnimation.value),
                ),
              ),

            Padding(
              padding: EdgeInsets.only(
                bottom: 24 + (MediaQuery.of(context).viewInsets.bottom),
                left: 20,
                right: 20,
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: 100 + (300 * _expandAnimation.value),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundParchment.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isExpanded && _suggestions.isNotEmpty)
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              leading: Icon(
                                suggestion.icon,
                                color: AppTheme.primaryColor,
                              ),
                              title: Text(suggestion.title),
                              trailing: const Icon(Icons.north_west, size: 16),
                              onTap: () {
                                // Handle Action
                                _toggleExpansion();
                              },
                            );
                          },
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isExpanded ? Icons.close : Icons.auto_awesome,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: _toggleExpansion,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              focusNode: _focusNode,
                              onTap: () {
                                if (!_isExpanded) _toggleExpansion();
                              },
                              onChanged: _onInputChanged,
                              decoration: const InputDecoration(
                                hintText: 'Type a command or verse...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                          if (_isExpanded)
                            IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: AppTheme.accentColor,
                              ),
                              onPressed: () {},
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

enum CommandType { verse, action, search }

class CommandResult {
  final String title;
  final IconData icon;
  final CommandType type;
  final dynamic data;

  const CommandResult({
    required this.title,
    required this.icon,
    required this.type,
    required this.data,
  });
}
