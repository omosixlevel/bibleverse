import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/inspired_alert_service.dart';

class SacredAlert extends StatelessWidget {
  final InspiredAlert alert;
  final VoidCallback onDismiss;

  const SacredAlert({super.key, required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getIntentColor(alert.intent);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -100, end: 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(0, value), child: child);
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: alert.onTap != null
                        ? () {
                            alert.onTap!();
                            onDismiss();
                          }
                        : null,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIntentIcon(alert.intent),
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                alert.message,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.2,
                                ),
                              ),
                              if (alert.subMessage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  alert.subMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          onPressed: onDismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getIntentColor(AlertIntent intent) {
    switch (intent) {
      case AlertIntent.revelation:
        return Colors.indigo;
      case AlertIntent.prayer:
        return Colors.blue;
      case AlertIntent.mission:
        return Colors.amber[700]!;
      case AlertIntent.warning:
        return Colors.redAccent;
    }
  }

  IconData _getIntentIcon(AlertIntent intent) {
    switch (intent) {
      case AlertIntent.revelation:
        return Icons.auto_awesome_rounded;
      case AlertIntent.prayer:
        return Icons.volunteer_activism_rounded;
      case AlertIntent.mission:
        return Icons.military_tech_rounded;
      case AlertIntent.warning:
        return Icons.priority_high_rounded;
    }
  }
}
