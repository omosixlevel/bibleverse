import 'package:cloud_firestore/cloud_firestore.dart';

/// User Profile Model
/// Represents a user's profile with spiritual interests, stats, and preferences
class UserProfile {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final List<String> spiritualInterests;
  final UserStats stats;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.spiritualInterests,
    required this.stats,
    required this.preferences,
    required this.createdAt,
    this.lastActiveAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      spiritualInterests: List<String>.from(map['spiritualInterests'] ?? []),
      stats: UserStats.fromMap(map['stats'] ?? {}),
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime,
      lastActiveAt: map['lastActiveAt'] != null
          ? (map['lastActiveAt'] is Timestamp
                ? (map['lastActiveAt'] as Timestamp).toDate()
                : map['lastActiveAt'] as DateTime)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'spiritualInterests': spiritualInterests,
      'stats': stats.toMap(),
      'preferences': preferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    List<String>? spiritualInterests,
    UserStats? stats,
    UserPreferences? preferences,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      spiritualInterests: spiritualInterests ?? this.spiritualInterests,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

/// User Statistics
class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int tasksCompleted;
  final int tasksCompletedThisWeek;
  final double hoursThisWeek;
  final int bibleChaptersRead;
  final int eventsJoined;
  final int roomsJoined;
  final int highlightsCreated;
  final int notesCreated;

  UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.tasksCompleted = 0,
    this.tasksCompletedThisWeek = 0,
    this.hoursThisWeek = 0.0,
    this.bibleChaptersRead = 0,
    this.eventsJoined = 0,
    this.roomsJoined = 0,
    this.highlightsCreated = 0,
    this.notesCreated = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      tasksCompleted: map['tasksCompleted'] ?? 0,
      tasksCompletedThisWeek: map['tasksCompletedThisWeek'] ?? 0,
      hoursThisWeek: (map['hoursThisWeek'] ?? 0.0).toDouble(),
      bibleChaptersRead: map['bibleChaptersRead'] ?? 0,
      eventsJoined: map['eventsJoined'] ?? 0,
      roomsJoined: map['roomsJoined'] ?? 0,
      highlightsCreated: map['highlightsCreated'] ?? 0,
      notesCreated: map['notesCreated'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'tasksCompleted': tasksCompleted,
      'tasksCompletedThisWeek': tasksCompletedThisWeek,
      'hoursThisWeek': hoursThisWeek,
      'bibleChaptersRead': bibleChaptersRead,
      'eventsJoined': eventsJoined,
      'roomsJoined': roomsJoined,
      'highlightsCreated': highlightsCreated,
      'notesCreated': notesCreated,
    };
  }

  UserStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? tasksCompleted,
    int? tasksCompletedThisWeek,
    double? hoursThisWeek,
    int? bibleChaptersRead,
    int? eventsJoined,
    int? roomsJoined,
    int? highlightsCreated,
    int? notesCreated,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksCompletedThisWeek:
          tasksCompletedThisWeek ?? this.tasksCompletedThisWeek,
      hoursThisWeek: hoursThisWeek ?? this.hoursThisWeek,
      bibleChaptersRead: bibleChaptersRead ?? this.bibleChaptersRead,
      eventsJoined: eventsJoined ?? this.eventsJoined,
      roomsJoined: roomsJoined ?? this.roomsJoined,
      highlightsCreated: highlightsCreated ?? this.highlightsCreated,
      notesCreated: notesCreated ?? this.notesCreated,
    );
  }
}

/// User Preferences
class UserPreferences {
  final bool darkMode;
  final bool notificationsEnabled;
  final String language;
  final String bibleVersion;

  UserPreferences({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.bibleVersion = 'KJV',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      darkMode: map['darkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      language: map['language'] ?? 'en',
      bibleVersion: map['bibleVersion'] ?? 'KJV',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'bibleVersion': bibleVersion,
    };
  }

  UserPreferences copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    String? language,
    String? bibleVersion,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      bibleVersion: bibleVersion ?? this.bibleVersion,
    );
  }
}

/// Activity Item for Activity Feed
class ActivityItem {
  final String id;
  final String type; // 'bible_read', 'task_completed', 'room_joined', etc.
  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityItem.fromMap(Map<String, dynamic> map) {
    return ActivityItem(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : map['timestamp'] as DateTime,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Insight Item for Gemini generated content
class InsightItem {
  final String id;
  final String title;
  final String description;
  final String type; // 'pattern', 'growth', 'encouragement', 'challenge'
  final String? iconName;
  final String? colorHex;
  final DateTime generatedAt;

  InsightItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.iconName,
    this.colorHex,
    required this.generatedAt,
  });

  factory InsightItem.fromMap(Map<String, dynamic> map) {
    return InsightItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? 'Insight',
      description: map['description'] ?? '',
      type: map['type'] ?? 'encouragement',
      iconName: map['iconName'],
      colorHex: map['colorHex'],
      generatedAt: map['generatedAt'] != null
          ? (map['generatedAt'] is Timestamp
                ? (map['generatedAt'] as Timestamp).toDate()
                : map['generatedAt'] as DateTime)
          : DateTime.now(),
    );
  }
}
