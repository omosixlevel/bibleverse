import 'package:cloud_firestore/cloud_firestore.dart';

enum CallScope { room, event }

enum CallMode { audio, video }

enum CallStatus { active, ended }

class Call {
  final String id;
  final CallScope scope;
  final String refId;
  final CallMode mode;
  final CallStatus status;
  final bool circleTalkingEnabled;
  final String? currentSpeakerId;
  final DateTime? speakerStartTime;
  final String startedBy;
  final DateTime createdAt;
  final String? moderatorMessage;

  const Call({
    required this.id,
    required this.scope,
    required this.refId,
    required this.mode,
    required this.status,
    required this.circleTalkingEnabled,
    this.currentSpeakerId,
    this.speakerStartTime,
    required this.startedBy,
    required this.createdAt,
    this.moderatorMessage,
  });

  factory Call.fromFirestore(DocumentSnapshot doc) {
    return Call.fromMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  factory Call.fromMap(Map<String, dynamic> data) {
    return Call(
      id: data['id'] ?? '',
      scope: _parseScope(data['scope']),
      refId: data['refId'] ?? '',
      mode: _parseMode(data['mode']),
      status: _parseStatus(data['status']),
      circleTalkingEnabled: data['circleTalkingEnabled'] ?? false,
      currentSpeakerId: data['currentSpeakerId'],
      speakerStartTime: data['speakerStartTime'] is Timestamp
          ? (data['speakerStartTime'] as Timestamp).toDate()
          : (data['speakerStartTime'] as DateTime?),
      startedBy: data['startedBy'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime? ?? DateTime.now()),
      moderatorMessage: data['moderatorMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scope': scope.name,
      'refId': refId,
      'mode': mode.name,
      'status': status.name,
      'circleTalkingEnabled': circleTalkingEnabled,
      'currentSpeakerId': currentSpeakerId,
      'speakerStartTime': speakerStartTime != null
          ? Timestamp.fromDate(speakerStartTime!)
          : null,
      'startedBy': startedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'moderatorMessage': moderatorMessage,
    };
  }

  static CallScope _parseScope(String? val) =>
      val == 'event' ? CallScope.event : CallScope.room;
  static CallMode _parseMode(String? val) =>
      val == 'video' ? CallMode.video : CallMode.audio;
  static CallStatus _parseStatus(String? val) =>
      val == 'ended' ? CallStatus.ended : CallStatus.active;
}

class CallParticipant {
  final String userId;
  final bool muted;
  final bool handRaised;
  final int? speakingOrder;
  final int? speakingTimeSeconds;

  const CallParticipant({
    required this.userId,
    required this.muted,
    required this.handRaised,
    this.speakingOrder,
    this.speakingTimeSeconds,
  });

  factory CallParticipant.fromFirestore(DocumentSnapshot doc) {
    return CallParticipant.fromMap(doc.data() as Map<String, dynamic>);
  }

  factory CallParticipant.fromMap(Map<String, dynamic> data) {
    return CallParticipant(
      userId: data['userId'] ?? '',
      muted: data['muted'] ?? true,
      handRaised: data['handRaised'] ?? false,
      speakingOrder: data['speakingOrder'],
      speakingTimeSeconds: data['speakingTimeSeconds'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'muted': muted,
      'handRaised': handRaised,
      'speakingOrder': speakingOrder,
      'speakingTimeSeconds': speakingTimeSeconds,
    };
  }
}
