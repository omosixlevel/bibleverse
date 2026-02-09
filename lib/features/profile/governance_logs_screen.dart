import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/data/repository.dart'; // Use Repository
import '../../models/governance_model.dart';

class GovernanceLogsScreen extends StatelessWidget {
  final String scope;
  final String refId;
  final String title;

  const GovernanceLogsScreen({
    super.key,
    required this.scope,
    required this.refId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.read<Repository>();

    return Scaffold(
      appBar: AppBar(title: Text('AI Governance - $title')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repository.getGovernanceLogs(scope, refId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs =
              snapshot.data?.map((m) => GovernanceLog.fromMap(m)).toList() ??
              [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No AI actions recorded yet.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return LogCard(log: log);
            },
          );
        },
      ),
    );
  }
}

class LogCard extends StatelessWidget {
  final GovernanceLog log;

  const LogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.psychology,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          _formatAction(log.action.toString().split('.').last),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (log.targetUserId != null)
              Text(
                'Applied to: ${log.targetUserId}',
                style: theme.textTheme.bodySmall,
              ),
            Text(
              dateFormat.format(log.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            log.executedBy.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  String _formatAction(String action) {
    // Splits camelCase into "Words With Spaces"
    final result = action.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}
