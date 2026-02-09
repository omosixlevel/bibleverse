import 'package:cloud_firestore/cloud_firestore.dart';
import 'dynamic_text.dart';

enum EventVisibility { public, private }

enum EventStatus { draft, active, closed, archived }

class Event {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String objectiveStatement;
  final String coverImageUrl;
  final String thematicVerseSummary;
  final DateTime startDate;
  final DateTime endDate;
  final EventVisibility visibility;
  final EventStatus status;
  final String creatorId;
  final DateTime createdAt;
  final List<String> roomIds;
  final List<String> activityIds;
  final int numberOfRooms;
  final int numberOfActivities;
  final double aggregateProgress;
  final bool isJoined;

  const Event({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.objectiveStatement,
    required this.coverImageUrl,
    required this.thematicVerseSummary,
    required this.startDate,
    required this.endDate,
    required this.visibility,
    required this.status,
    required this.creatorId,
    required this.createdAt,
    this.roomIds = const [],
    this.activityIds = const [],
    this.numberOfRooms = 0,
    this.numberOfActivities = 0,
    this.aggregateProgress = 0.0,
    this.isJoined = false,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      fullDescription: data['fullDescription'] ?? '',
      objectiveStatement: data['objectiveStatement'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      thematicVerseSummary: data['thematicVerseSummary'] ?? '',
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      visibility: _parseVisibility(data['visibility']),
      status: _parseStatus(data['status']),
      creatorId: data['creatorId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      roomIds: List<String>.from(data['roomIds'] ?? []),
      activityIds: List<String>.from(data['activityIds'] ?? []),
      numberOfRooms: data['numberOfRooms'] ?? 0,
      numberOfActivities: data['numberOfActivities'] ?? 0,
      aggregateProgress: (data['aggregateProgress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'objectiveStatement': objectiveStatement,
      'coverImageUrl': coverImageUrl,
      'thematicVerseSummary': thematicVerseSummary,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'visibility': visibility.name,
      'status': status.name,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'roomIds': roomIds,
      'activityIds': activityIds,
      'numberOfRooms': numberOfRooms,
      'numberOfActivities': numberOfActivities,
      'aggregateProgress': aggregateProgress,
      'isJoined': isJoined,
    };
  }

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      fullDescription: data['fullDescription'] ?? '',
      objectiveStatement: data['objectiveStatement'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      thematicVerseSummary: data['thematicVerseSummary'] ?? '',
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      visibility: _parseVisibility(data['visibility']),
      status: _parseStatus(data['status']),
      creatorId: data['creatorId'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      roomIds: List<String>.from(data['roomIds'] ?? []),
      activityIds: List<String>.from(data['activityIds'] ?? []),
      numberOfRooms: data['numberOfRooms'] ?? 0,
      numberOfActivities: data['numberOfActivities'] ?? 0,
      aggregateProgress: (data['aggregateProgress'] ?? 0.0).toDouble(),
      isJoined: data['isJoined'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'objectiveStatement': objectiveStatement,
      'coverImageUrl': coverImageUrl,
      'thematicVerseSummary': thematicVerseSummary,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'visibility': visibility.name,
      'status': status.name,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'roomIds': roomIds,
      'activityIds': activityIds,
      'numberOfRooms': numberOfRooms,
      'numberOfActivities': numberOfActivities,
      'aggregateProgress': aggregateProgress,
      // isJoined is NOT stored in Firestore typically, but for mock purposes we might
    };
  }

  static EventVisibility _parseVisibility(String? val) {
    return EventVisibility.values.firstWhere(
      (e) => e.name == val,
      orElse: () => EventVisibility.public,
    );
  }

  static EventStatus _parseStatus(String? val) {
    return EventStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => EventStatus.draft,
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  Event copyWith({
    String? title,
    String? shortDescription,
    String? fullDescription,
    String? objectiveStatement,
    String? coverImageUrl,
    String? thematicVerseSummary,
    DateTime? startDate,
    DateTime? endDate,
    EventVisibility? visibility,
    EventStatus? status,
    List<String>? roomIds,
    List<String>? activityIds,
    int? numberOfRooms,
    int? numberOfActivities,
    double? aggregateProgress,
    bool? isJoined,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      objectiveStatement: objectiveStatement ?? this.objectiveStatement,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      thematicVerseSummary: thematicVerseSummary ?? this.thematicVerseSummary,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      creatorId: creatorId,
      createdAt: createdAt,
      roomIds: roomIds ?? this.roomIds,
      activityIds: activityIds ?? this.activityIds,
      numberOfRooms: numberOfRooms ?? this.numberOfRooms,
      numberOfActivities: numberOfActivities ?? this.numberOfActivities,
      aggregateProgress: aggregateProgress ?? this.aggregateProgress,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  String get dynamicStatus {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return 'Upcoming';
    } else if (now.isAfter(endDate)) {
      return 'Completed';
    } else {
      return 'Ongoing';
    }
  }
}

class EventParticipant {
  final String userId;
  final String role; // 'admin' | 'participant'
  final DateTime joinedAt;

  const EventParticipant({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory EventParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventParticipant(
      userId: data['userId'] ?? '',
      role: data['role'] ?? 'participant',
      joinedAt: Event._parseDate(data['joinedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class EventAnnouncement {
  final String id;
  final String title;
  final DynamicText contentRichText;
  final DateTime createdAt;

  const EventAnnouncement({
    required this.id,
    required this.title,
    required this.contentRichText,
    required this.createdAt,
  });

  factory EventAnnouncement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventAnnouncement(
      id: doc.id,
      title: data['title'] ?? '',
      contentRichText: DynamicText.fromJson(data['contentRichText'] ?? {}),
      createdAt: Event._parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'contentRichText': contentRichText.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
