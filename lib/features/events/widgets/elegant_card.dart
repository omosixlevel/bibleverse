import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ElegantCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime? date;
  final DateTime? endDate;
  final double progress;
  final String status;
  final String? imageUrl;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  const ElegantCard({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.endDate,
    this.progress = 0.0,
    required this.status,
    this.imageUrl,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = progress >= 1.0 || status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? theme.colorScheme.primary).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null)
                Stack(
                  children: [
                    Image.network(
                      imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: (accentColor ?? theme.colorScheme.primary)
                            .withOpacity(0.1),
                        child: Icon(
                          icon ?? Icons.event,
                          size: 40,
                          color: accentColor ?? theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (icon != null && imageUrl == null) ...[
                          Icon(
                            icon,
                            size: 20,
                            color: accentColor ?? theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateRange(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accentColor ?? theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver
                              ? Colors.green
                              : (accentColor ?? theme.colorScheme.primary),
                        ),
                        minHeight: 6,
                      ),
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

  String _formatDateRange() {
    if (date == null) return 'No date';
    final startStr = DateFormat('MMM dd').format(date!);
    if (endDate == null) return startStr;
    final endStr = DateFormat('MMM dd').format(endDate!);
    return '$startStr - $endStr';
  }
}
