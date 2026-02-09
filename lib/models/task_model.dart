import 'package:cloud_firestore/cloud_firestore.dart';
import 'dynamic_text.dart';

enum TaskType { tell_me, prayer, rhema, action, silence, worship }

enum TaskStatus { pending, completed, archived }

class Task {
  final String id;
  final String roomId;
  final String title;
  final String description;
  final TaskType taskType;
  final int dayIndex;
  final DateTime? deadline;
  final bool mandatory;
  final String createdBy; // 'user' | 'gemini'
  final TaskStatus status;
  final DateTime createdAt;

  // Specialized fields
  final List<String>? questions; // for tell_me
  final List<String>? prayerPoints; // for prayer
  final String? scripture; // for rhema
  final int? durationMinutes; // for silence/worship/meeting
  final DateTime? scheduledStartTime; // for prayer/scheduled events
  final String? actionType; // for action tasks
  final List<String>? meetingObjectives; // for scheduled meetings
  final String? meetingDay; // for scheduled meetings
  final List<String>? videoUrls; // for worship tasks
  final int? startHour; // 0-23
  final double? durationHours;
  final String? meetingName;
  final Map<String, dynamic>? progressData;

  const Task({
    required this.id,
    required this.roomId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.dayIndex,
    this.deadline,
    this.mandatory = false,
    required this.createdBy,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.questions,
    this.prayerPoints,
    this.scripture,
    this.durationMinutes,
    this.scheduledStartTime,
    this.actionType,
    this.meetingObjectives,
    this.meetingDay,
    this.videoUrls,
    this.startHour,
    this.durationHours,
    this.meetingName,
    this.progressData,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      roomId: data['roomId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      taskType: _parseType(data['taskType']),
      dayIndex: data['dayIndex'] ?? 1,
      deadline: _parseDate(data['deadline']),
      mandatory: data['mandatory'] ?? false,
      createdBy: data['createdBy'] ?? 'user',
      status: _parseStatus(data['status']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      questions: data['questions'] != null
          ? List<String>.from(data['questions'])
          : null,
      prayerPoints: data['prayerPoints'] != null
          ? List<String>.from(data['prayerPoints'])
          : null,
      scripture: data['scripture'],
      durationMinutes: data['durationMinutes'],
      scheduledStartTime: _parseDate(data['scheduledStartTime']),
      actionType: data['actionType'],
      meetingObjectives: data['meetingObjectives'] != null
          ? List<String>.from(data['meetingObjectives'])
          : null,
      meetingDay: data['meetingDay'],
      videoUrls: data['videoUrls'] != null
          ? List<String>.from(data['videoUrls'])
          : null,
      startHour: data['startHour'],
      durationHours: (data['durationHours'] as num?)?.toDouble(),
      meetingName: data['meetingName'],
      progressData: data['progressData'] != null
          ? Map<String, dynamic>.from(data['progressData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'title': title,
      'description': description,
      'taskType': taskType.name,
      'dayIndex': dayIndex,
      'deadline': deadline?.toIso8601String(),
      'mandatory': mandatory,
      'createdBy': createdBy,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (questions != null) 'questions': questions,
      if (prayerPoints != null) 'prayerPoints': prayerPoints,
      if (scripture != null) 'scripture': scripture,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (scheduledStartTime != null)
        'scheduledStartTime': scheduledStartTime!.toIso8601String(),
      if (actionType != null) 'actionType': actionType,
      if (meetingObjectives != null) 'meetingObjectives': meetingObjectives,
      if (meetingDay != null) 'meetingDay': meetingDay,
      if (videoUrls != null) 'videoUrls': videoUrls,
      if (startHour != null) 'startHour': startHour,
      if (durationHours != null) 'durationHours': durationHours,
      if (meetingName != null) 'meetingName': meetingName,
      if (progressData != null) 'progressData': progressData,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'title': title,
      'description': description,
      'taskType': taskType.name,
      'dayIndex': dayIndex,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'mandatory': mandatory,
      'createdBy': createdBy,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (questions != null) 'questions': questions,
      if (prayerPoints != null) 'prayerPoints': prayerPoints,
      if (scripture != null) 'scripture': scripture,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (scheduledStartTime != null)
        'scheduledStartTime': Timestamp.fromDate(scheduledStartTime!),
      if (actionType != null) 'actionType': actionType,
      if (meetingObjectives != null) 'meetingObjectives': meetingObjectives,
      if (meetingDay != null) 'meetingDay': meetingDay,
      if (videoUrls != null) 'videoUrls': videoUrls,
      if (startHour != null) 'startHour': startHour,
      if (durationHours != null) 'durationHours': durationHours,
      if (meetingName != null) 'meetingName': meetingName,
      if (progressData != null) 'progressData': progressData,
    };
  }

  static TaskType _parseType(String? val) {
    switch (val) {
      case 'tell_me':
        return TaskType.tell_me;
      case 'prayer':
        return TaskType.prayer;
      case 'rhema':
        return TaskType.rhema;
      case 'action':
        return TaskType.action;
      case 'silence':
        return TaskType.silence;
      case 'worship':
        return TaskType.worship;
      default:
        return TaskType.action;
    }
  }

  static TaskStatus _parseStatus(String? val) {
    switch (val) {
      case 'completed':
        return TaskStatus.completed;
      case 'archived':
        return TaskStatus.archived;
      default:
        return TaskStatus.pending;
    }
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}

class TaskProgress {
  final String userId;
  final String taskId;
  final bool completed;
  final DateTime? completedAt;
  final DynamicText? responseRichText;
  final String? proofUrl;
  final bool published;

  // Specialized progress fields
  final Map<String, String>? questionAnswers; // for tell_me
  final String? userReflection; // for rhema
  final List<String>? inspiredPrayerPoints; // for rhema
  final String? experienceRecord; // for silence/worship
  final String? sessionComment; // for prayer/rema
  final String? revelation; // for rema

  String get id => '${userId}_$taskId';

  const TaskProgress({
    required this.userId,
    required this.taskId,
    required this.completed,
    this.completedAt,
    this.responseRichText,
    this.proofUrl,
    this.published = false,
    this.questionAnswers,
    this.userReflection,
    this.inspiredPrayerPoints,
    this.experienceRecord,
    this.sessionComment,
    this.revelation,
  });

  factory TaskProgress.fromFirestore(DocumentSnapshot doc) {
    return TaskProgress.fromMap(doc.data() as Map<String, dynamic>);
  }

  factory TaskProgress.fromMap(Map<String, dynamic> data) {
    return TaskProgress(
      userId: data['userId'] ?? '',
      taskId: data['taskId'] ?? '',
      completed: data['completed'] ?? false,
      completedAt: Task._parseDate(data['completedAt']),
      responseRichText: data['responseRichText'] != null
          ? DynamicText.fromJson(data['responseRichText'])
          : null,
      proofUrl: data['proofUrl'],
      published: data['published'] ?? false,
      questionAnswers: data['questionAnswers'] != null
          ? Map<String, String>.from(data['questionAnswers'])
          : null,
      userReflection: data['userReflection'],
      inspiredPrayerPoints: data['inspiredPrayerPoints'] != null
          ? List<String>.from(data['inspiredPrayerPoints'])
          : null,
      experienceRecord: data['experienceRecord'],
      sessionComment: data['sessionComment'],
      revelation: data['revelation'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'taskId': taskId,
      'completed': completed,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'responseRichText': responseRichText?.toJson(),
      'proofUrl': proofUrl,
      'published': published,
      if (questionAnswers != null) 'questionAnswers': questionAnswers,
      if (userReflection != null) 'userReflection': userReflection,
      if (inspiredPrayerPoints != null)
        'inspiredPrayerPoints': inspiredPrayerPoints,
      if (experienceRecord != null) 'experienceRecord': experienceRecord,
      if (sessionComment != null) 'sessionComment': sessionComment,
      if (revelation != null) 'revelation': revelation,
    };
  }
}
