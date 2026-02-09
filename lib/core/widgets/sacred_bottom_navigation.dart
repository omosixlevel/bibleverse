import 'dart:ui';
import 'package:flutter/material.dart';

class SacredBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<SacredNavItem> items;

  const SacredBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final index = items.indexOf(item);
                final isSelected = selectedIndex == index;

                return Flexible(
                  child: _SacredNavItemWidget(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onItemSelected(index),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SacredNavItemWidget extends StatelessWidget {
  final SacredNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SacredNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: Icon(
                isSelected ? item.activeIcon : item.inactiveIcon,
                color: isSelected ? activeColor : theme.colorScheme.outline,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: activeColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SacredNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  SacredNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

class SacredFabLocation extends FloatingActionButtonLocation {
  const SacredFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Center horizontally, and shift up to clear bottom nav (100px)
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    final double fabY =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        100;
    return Offset(fabX, fabY);
  }
}
