import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  donation,
  evangelism,
  meeting,
  service,
  prayer,
  rhema,
  special_action,
  silence,
  worship,
}

enum CostType { free, paid }

class Activity {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final ActivityType activityType;
  final String locationName;
  final String mapLink;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final CostType costType;
  final double? price;
  final String? flyerUrl;
  final String organizerContact;
  final Map<String, dynamic>?
  config; // New: For specialized task-like activities
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.activityType,
    required this.locationName,
    required this.mapLink,
    required this.startDateTime,
    required this.endDateTime,
    required this.costType,
    this.price,
    this.flyerUrl,
    required this.organizerContact,
    this.config,
    required this.createdAt,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    return Activity.fromMap({
      'id': doc.id,
      ...(doc.data() as Map<String, dynamic>),
    });
  }

  factory Activity.fromMap(Map<String, dynamic> data) {
    return Activity(
      id: data['id'] ?? '',
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      activityType: _parseType(data['activityType']),
      locationName: data['locationName'] ?? '',
      mapLink: data['mapLink'] ?? '',
      startDateTime: _parseDate(data['startDateTime']),
      endDateTime: _parseDate(data['endDateTime']),
      costType: _parseCostType(data['costType']),
      price: (data['price'] as num?)?.toDouble(),
      flyerUrl: data['flyerUrl'],
      organizerContact: data['organizerContact'] ?? '',
      config: data['config'],
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'activityType': activityType.name,
      'locationName': locationName,
      'mapLink': mapLink,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'costType': costType.name,
      'price': price,
      'flyerUrl': flyerUrl,
      'organizerContact': organizerContact,
      'config': config,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'activityType': activityType.name,
      'locationName': locationName,
      'mapLink': mapLink,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'costType': costType.name,
      'price': price,
      'flyerUrl': flyerUrl,
      'organizerContact': organizerContact,
      'config': config,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ActivityType _parseType(String? val) {
    return ActivityType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ActivityType.meeting,
    );
  }

  static CostType _parseCostType(String? val) =>
      val == 'paid' ? CostType.paid : CostType.free;

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}

class ActivityAttendance {
  final String userId;
  final bool confirmed;
  final bool? attended;

  const ActivityAttendance({
    required this.userId,
    required this.confirmed,
    this.attended,
  });

  factory ActivityAttendance.fromFirestore(DocumentSnapshot doc) {
    return ActivityAttendance.fromMap(doc.data() as Map<String, dynamic>);
  }

  factory ActivityAttendance.fromMap(Map<String, dynamic> data) {
    return ActivityAttendance(
      userId: data['userId'] ?? '',
      confirmed: data['confirmed'] ?? false,
      attended: data['attended'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'userId': userId, 'confirmed': confirmed, 'attended': attended};
  }
}
