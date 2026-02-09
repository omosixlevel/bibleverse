import 'package:cloud_firestore/cloud_firestore.dart';
import 'dynamic_text.dart';

enum ChatType { direct, room, event }

class Chat {
  final String id;
  final ChatType type;
  final String refId;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.type,
    required this.refId,
    required this.createdAt,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    return Chat.fromMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  factory Chat.fromMap(Map<String, dynamic> data) {
    return Chat(
      id: data['id'] ?? '',
      type: _parseType(data['type']),
      refId: data['refId'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'refId': refId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ChatType _parseType(String? val) {
    return ChatType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ChatType.room,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final DynamicText contentRichText;
  final Map<String, dynamic>? attachedVerse;
  final String? attachedRoomId;
  final String? attachedEventId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.contentRichText,
    this.attachedVerse,
    this.attachedRoomId,
    this.attachedEventId,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    return ChatMessage.fromMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      contentRichText: DynamicText.fromJson(data['contentRichText'] ?? {}),
      attachedVerse: data['attachedVerse'],
      attachedRoomId: data['attachedRoomId'],
      attachedEventId: data['attachedEventId'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'contentRichText': contentRichText.toJson(),
      'attachedVerse': attachedVerse,
      'attachedRoomId': attachedRoomId,
      'attachedEventId': attachedEventId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
