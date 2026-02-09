import 'package:flutter/material.dart';

class SacredPillTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<String> tabs;

  const SacredPillTabBar({super.key, this.controller, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final tabController = controller ?? DefaultTabController.of(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(), // Hide default indicator
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: tabs.map((tabText) {
          final index = tabs.indexOf(tabText);
          return AnimatedBuilder(
            animation: tabController,
            builder: (context, child) {
              return _SacredPillTab(
                text: tabText,
                isSelected: tabController.index == index,
                onTap: () {
                  tabController.animateTo(index);
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SacredPillTab extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _SacredPillTab({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SacredPillTab> createState() => _SacredPillTabState();
}

class _SacredPillTabState extends State<_SacredPillTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.outline,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
