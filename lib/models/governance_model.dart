import 'package:cloud_firestore/cloud_firestore.dart';

enum GovernanceScope { room, task, call }

enum GovernanceAction { warnUser, removeUser, suggestTask, summarizeCall }

class GovernanceLog {
  final String id;
  final GovernanceScope scope;
  final String refId;
  final GovernanceAction action;
  final String executedBy; // Always 'gemini'
  final String? targetUserId;
  final DateTime createdAt;

  const GovernanceLog({
    required this.id,
    required this.scope,
    required this.refId,
    required this.action,
    this.executedBy = 'gemini',
    this.targetUserId,
    required this.createdAt,
  });

  factory GovernanceLog.fromFirestore(DocumentSnapshot doc) {
    return GovernanceLog.fromMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  factory GovernanceLog.fromMap(Map<String, dynamic> data) {
    return GovernanceLog(
      id: data['id'] ?? '',
      scope: _parseScope(data['scope']),
      refId: data['refId'] ?? '',
      action: _parseAction(data['action']),
      executedBy: data['executedBy'] ?? 'gemini',
      targetUserId: data['targetUserId'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scope': scope.name,
      'refId': refId,
      'action': _actionToString(action),
      'executedBy': executedBy,
      'targetUserId': targetUserId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static GovernanceScope _parseScope(String? val) {
    switch (val) {
      case 'task':
        return GovernanceScope.task;
      case 'call':
        return GovernanceScope.call;
      default:
        return GovernanceScope.room;
    }
  }

  static GovernanceAction _parseAction(String? val) {
    switch (val) {
      case 'remove_user':
        return GovernanceAction.removeUser;
      case 'suggest_task':
        return GovernanceAction.suggestTask;
      case 'summarize_call':
        return GovernanceAction.summarizeCall;
      default:
        return GovernanceAction.warnUser;
    }
  }

  static String _actionToString(GovernanceAction action) {
    switch (action) {
      case GovernanceAction.removeUser:
        return 'remove_user';
      case GovernanceAction.suggestTask:
        return 'suggest_task';
      case GovernanceAction.summarizeCall:
        return 'summarize_call';
      case GovernanceAction.warnUser:
      // ignore: unreachable_switch_default
      default:
        return 'warn_user';
    }
  }
}
