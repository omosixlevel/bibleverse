import '../models/user_profile.dart';
import 'mock_data.dart';
import 'gemini_service.dart';

/// Profile Service
/// Handles user profile operations, statistics, and activity tracking
class ProfileService {
  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  UserProfile? _cachedProfile;
  final GeminiService _geminiService =
      GeminiService(); // Direct instance for now

  /// Get current user profile
  Future<UserProfile> getUserProfile(String uid) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (_cachedProfile != null) {
      return _cachedProfile!;
    }

    final profileData = MockData.userProfile;
    _cachedProfile = UserProfile.fromMap(profileData);
    return _cachedProfile!;
  }

  /// Update spiritual interests
  Future<void> updateSpiritualInterests(
    String uid,
    List<String> interests,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(spiritualInterests: interests);
    }

    print('✅ Updated spiritual interests: $interests');
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
    }

    print('✅ Updated profile: $displayName');
  }

  /// Update user preferences
  Future<void> updatePreferences(
    String uid,
    UserPreferences preferences,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(preferences: preferences);
    }

    print('✅ Updated preferences');
  }

  /// Get activity history
  Future<List<ActivityItem>> getActivityHistory({
    int limit = 50,
    DateTime? before,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final activities = MockData.activityHistory
        .map((data) => ActivityItem.fromMap(data))
        .toList();

    // Sort by timestamp descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Filter by before date if provided
    if (before != null) {
      return activities
          .where((activity) => activity.timestamp.isBefore(before))
          .take(limit)
          .toList();
    }

    return activities.take(limit).toList();
  }

  /// Calculate statistics from activities
  Future<UserStats> calculateStats(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final activities = await getActivityHistory();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Calculate tasks completed this week
    final tasksThisWeek = activities.where((activity) {
      return activity.type == 'task_completed' &&
          activity.timestamp.isAfter(weekStart);
    }).length;

    // Calculate hours this week (estimate: 30 min per task, 30 min per chapter)
    double hoursThisWeek = 0;
    for (final activity in activities) {
      if (activity.timestamp.isAfter(weekStart)) {
        if (activity.type == 'task_completed') {
          hoursThisWeek += 0.5;
        } else if (activity.type == 'bible_read') {
          final chapters =
              activity.metadata?['chapters'] as List<dynamic>? ?? [];
          hoursThisWeek += chapters.length * 0.5;
        }
      }
    }

    // Calculate current streak
    int currentStreak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 30; i++) {
      final hasActivity = activities.any((activity) {
        final activityDate = DateTime(
          activity.timestamp.year,
          activity.timestamp.month,
          activity.timestamp.day,
        );
        return activityDate.isAtSameMomentAs(checkDate);
      });

      if (hasActivity) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Count various activities
    final tasksCompleted = activities
        .where((a) => a.type == 'task_completed')
        .length;
    final bibleReads = activities.where((a) => a.type == 'bible_read').length;
    final highlights = activities
        .where((a) => a.type == 'highlight_created')
        .length;
    final notes = activities.where((a) => a.type == 'note_created').length;
    final roomsJoined = activities.where((a) => a.type == 'room_joined').length;
    final eventsJoined = activities
        .where((a) => a.type == 'event_registered')
        .length;

    return UserStats(
      currentStreak: currentStreak,
      longestStreak: currentStreak, // Simplified for now
      tasksCompleted: tasksCompleted,
      tasksCompletedThisWeek: tasksThisWeek,
      hoursThisWeek: hoursThisWeek,
      bibleChaptersRead: bibleReads * 3, // Estimate
      eventsJoined: eventsJoined,
      roomsJoined: roomsJoined,
      highlightsCreated: highlights,
      notesCreated: notes,
    );
  }

  /// Record a new activity
  Future<void> recordActivity(ActivityItem activity) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // In a real app, this would save to the database
    print('📝 Recorded activity: ${activity.title}');

    // Invalidate cache to force recalculation
    _cachedProfile = null;
  }

  /// Clear cached profile (useful for logout)
  void clearCache() {
    _cachedProfile = null;
  }

  /// Get insights for profile
  Future<List<InsightItem>> getInsights(String uid) async {
    final profile = await getUserProfile(uid);
    final activities = await getActivityHistory();
    return _geminiService.generateProfileInsights(
      profile: profile,
      recentActivities: activities,
    );
  }
}
