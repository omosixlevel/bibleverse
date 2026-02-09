import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomType { prayer_fasting, bible_study, book_reading, retreat }

enum RoomVisibility { public, private }

enum RoomStatus { open, closed, archived }

class Room {
  final String id;
  final String title;
  final String description;
  final String objective;
  final RoomType roomType;
  final RoomVisibility visibility;
  final String? eventId;
  final DateTime startDate;
  final DateTime endDate;
  final RoomStatus status;
  final String creatorId;
  final DateTime createdAt;
  final bool isJoined;
  final double progress;

  // Reading Room fields
  final String? pdfUrl;
  final Map<String, String>? readingObjectives; // dayIndex -> objective

  // Retreat Room fields
  final String? fastingInstructions;

  // Bible Study fields
  final List<String>? studyObjectives; // historical, thematic, etc.

  // Task & Schedule Templates (set by admin at creation)
  final List<Map<String, dynamic>>?
  initialTasks; // Template for tasks to be auto-generated
  final List<Map<String, dynamic>>? initialMeetings; // Template for meetings

  const Room({
    required this.id,
    required this.title,
    required this.description,
    required this.roomType,
    required this.visibility,
    this.eventId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.creatorId,
    required this.createdAt,
    this.objective = '',
    this.pdfUrl,
    this.readingObjectives,
    this.fastingInstructions,
    this.studyObjectives,
    this.initialTasks,
    this.initialMeetings,
    this.isJoined = false,
    this.progress = 0.0,
  });

  Room copyWith({
    String? title,
    String? description,
    String? objective,
    RoomType? roomType,
    RoomVisibility? visibility,
    RoomStatus? status,
    bool? isJoined,
    double? progress,
  }) {
    return Room(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      objective: objective ?? this.objective,
      roomType: roomType ?? this.roomType,
      visibility: visibility ?? this.visibility,
      eventId: eventId,
      startDate: startDate,
      endDate: endDate,
      status: status ?? this.status,
      creatorId: creatorId,
      createdAt: createdAt,
      pdfUrl: pdfUrl,
      readingObjectives: readingObjectives,
      fastingInstructions: fastingInstructions,
      studyObjectives: studyObjectives,
      initialTasks: initialTasks,
      initialMeetings: initialMeetings,
      isJoined: isJoined ?? this.isJoined,
      progress: progress ?? this.progress,
    );
  }

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      objective: data['objective'] ?? '',
      roomType: _parseType(data['roomType']),
      visibility: _parseVisibility(data['visibility']),
      eventId: data['eventId'],
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      status: _parseStatus(data['status']),
      creatorId: data['creatorId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      pdfUrl: data['pdfUrl'],
      readingObjectives: data['readingObjectives'] != null
          ? Map<String, String>.from(data['readingObjectives'])
          : null,
      fastingInstructions: data['fastingInstructions'],
      studyObjectives: data['studyObjectives'] != null
          ? List<String>.from(data['studyObjectives'])
          : null,
      initialTasks: data['initialTasks'] != null
          ? List<Map<String, dynamic>>.from(data['initialTasks'])
          : null,
      initialMeetings: data['initialMeetings'] != null
          ? List<Map<String, dynamic>>.from(data['initialMeetings'])
          : null,
      isJoined: data['isJoined'] ?? false,
      progress: (data['progress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'objective': objective,
      'roomType': roomType.name,
      'visibility': visibility.name,
      'eventId': eventId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'isJoined': isJoined,
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (readingObjectives != null) 'readingObjectives': readingObjectives,
      if (fastingInstructions != null)
        'fastingInstructions': fastingInstructions,
      if (studyObjectives != null) 'studyObjectives': studyObjectives,
      if (initialTasks != null) 'initialTasks': initialTasks,
      if (initialMeetings != null) 'initialMeetings': initialMeetings,
    };
  }

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      objective: data['objective'] ?? '',
      roomType: _parseType(data['roomType']),
      visibility: _parseVisibility(data['visibility']),
      eventId: data['eventId'],
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      status: _parseStatus(data['status']),
      creatorId: data['creatorId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      pdfUrl: data['pdfUrl'],
      readingObjectives: data['readingObjectives'] != null
          ? Map<String, String>.from(data['readingObjectives'])
          : null,
      fastingInstructions: data['fastingInstructions'],
      studyObjectives: data['studyObjectives'] != null
          ? List<String>.from(data['studyObjectives'])
          : null,
      initialTasks: data['initialTasks'] != null
          ? List<Map<String, dynamic>>.from(data['initialTasks'])
          : null,
      initialMeetings: data['initialMeetings'] != null
          ? List<Map<String, dynamic>>.from(data['initialMeetings'])
          : null,
      isJoined: data['isJoined'] ?? false,
      progress: (data['progress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'objective': objective,
      'roomType': roomType.name,
      'visibility': visibility.name,
      'eventId': eventId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (readingObjectives != null) 'readingObjectives': readingObjectives,
      if (fastingInstructions != null)
        'fastingInstructions': fastingInstructions,
      if (studyObjectives != null) 'studyObjectives': studyObjectives,
      if (initialTasks != null) 'initialTasks': initialTasks,
      if (initialMeetings != null) 'initialMeetings': initialMeetings,
    };
  }

  static RoomType _parseType(String? val) => RoomType.values.firstWhere(
    (e) => e.name == val,
    orElse: () => RoomType.book_reading,
  );

  static RoomVisibility _parseVisibility(String? val) => RoomVisibility.values
      .firstWhere((e) => e.name == val, orElse: () => RoomVisibility.public);

  static RoomStatus _parseStatus(String? val) => RoomStatus.values.firstWhere(
    (e) => e.name == val,
    orElse: () => RoomStatus.open,
  );

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}

class RoomCovenant {
  final String id;
  final String text;
  final int version;
  final DateTime createdAt;

  const RoomCovenant({
    required this.id,
    required this.text,
    required this.version,
    required this.createdAt,
  });

  factory RoomCovenant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomCovenant(
      id: doc.id,
      text: data['text'] ?? '',
      version: data['version'] ?? 1,
      createdAt: Room._parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum ParticipantRole { admin, member }

enum ParticipantState { active, warned, removed }

class RoomParticipant {
  final String userId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final int missedTasksCount;
  final int missedMeetingsCount;
  final ParticipantState state;

  const RoomParticipant({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.missedTasksCount = 0,
    this.missedMeetingsCount = 0,
    this.state = ParticipantState.active,
  });

  factory RoomParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomParticipant(
      userId: data['userId'] ?? '',
      role: _parseRole(data['role']),
      joinedAt: Room._parseDate(data['joinedAt']),
      missedTasksCount: data['missedTasksCount'] ?? 0,
      missedMeetingsCount: data['missedMeetingsCount'] ?? 0,
      state: _parseState(data['state']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'missedTasksCount': missedTasksCount,
      'missedMeetingsCount': missedMeetingsCount,
      'state': state.name,
    };
  }

  static ParticipantRole _parseRole(String? val) =>
      val == 'admin' ? ParticipantRole.admin : ParticipantRole.member;

  static ParticipantState _parseState(String? val) => ParticipantState.values
      .firstWhere((e) => e.name == val, orElse: () => ParticipantState.active);
}

class RoomScheduleMeeting {
  final String id;
  final String title;
  final DateTime startDateTime;
  final int durationMinutes;
  final bool mandatory;

  const RoomScheduleMeeting({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.durationMinutes,
    required this.mandatory,
  });

  factory RoomScheduleMeeting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomScheduleMeeting(
      id: doc.id,
      title: data['title'] ?? '',
      startDateTime: Room._parseDate(data['startDateTime']),
      durationMinutes: data['durationMinutes'] ?? 0,
      mandatory: data['mandatory'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'durationMinutes': durationMinutes,
      'mandatory': mandatory,
    };
  }
}
