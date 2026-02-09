import 'package:cloud_firestore/cloud_firestore.dart';
import 'dynamic_text.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final List<String> spiritualInterests;
  final double disciplineScore; // private
  final int streakDays; // private
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.spiritualInterests,
    this.disciplineScore = 0.0,
    this.streakDays = 0,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      spiritualInterests: List<String>.from(data['spiritualInterests'] ?? []),
      disciplineScore: (data['disciplineScore'] ?? 0).toDouble(),
      streakDays: data['streakDays'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'spiritualInterests': spiritualInterests,
      'disciplineScore': disciplineScore,
      'streakDays': streakDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }
}

class UserNotebookEntry {
  final String id;
  final DynamicText contentRichText;
  final List<String> linkedVerses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  const UserNotebookEntry({
    required this.id,
    required this.contentRichText,
    required this.linkedVerses,
    required this.createdAt,
    required this.updatedAt,
    required this.synced,
  });

  factory UserNotebookEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserNotebookEntry(
      id: doc.id,
      contentRichText: DynamicText.fromJson(data['contentRichText'] ?? {}),
      linkedVerses: List<String>.from(data['linkedVerses'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      synced: data['synced'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contentRichText': contentRichText.toJson(),
      'linkedVerses': linkedVerses,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'synced': synced,
    };
  }
}

enum ActivityLogType { taskCompleted, joinedRoom, warned, removed, unknown }

class UserActivityLog {
  final String id;
  final ActivityLogType type;
  final String refId;
  final DateTime createdAt;

  const UserActivityLog({
    required this.id,
    required this.type,
    required this.refId,
    required this.createdAt,
  });

  factory UserActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserActivityLog(
      id: doc.id,
      type: _parseType(data['type']),
      refId: data['refId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': _typeToString(type),
      'refId': refId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ActivityLogType _parseType(String? type) {
    switch (type) {
      case 'task_completed':
        return ActivityLogType.taskCompleted;
      case 'joined_room':
        return ActivityLogType.joinedRoom;
      case 'warned':
        return ActivityLogType.warned;
      case 'removed':
        return ActivityLogType.removed;
      default:
        return ActivityLogType.unknown;
    }
  }

  static String _typeToString(ActivityLogType type) {
    switch (type) {
      case ActivityLogType.taskCompleted:
        return 'task_completed';
      case ActivityLogType.joinedRoom:
        return 'joined_room';
      case ActivityLogType.warned:
        return 'warned';
      case ActivityLogType.removed:
        return 'removed';
      default:
        return 'unknown';
    }
  }
}
