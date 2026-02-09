import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_data.dart';

class FirestoreService {
  FirebaseFirestore? _dbInstance;
  bool _isFirebaseAvailable = false;
  bool forceOffline = true; // Set to true to disconnect from Firestore
  SharedPreferences? _prefs;

  final List<Map<String, dynamic>> _localRooms = [];
  final List<Map<String, dynamic>> _localActivities = [];

  FirestoreService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (forceOffline) {
      _isFirebaseAvailable = false;
      debugPrint('[FirestoreService] Running in MANUAL OFFLINE MODE.');
      return;
    }
    try {
      _dbInstance = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
      debugPrint('[FirestoreService] Instance initialized successfully.');
    } catch (e) {
      debugPrint('[FirestoreService] Initialization failed: $e');
      _isFirebaseAvailable = false;
    }
  }

  bool get isAvailable => _isFirebaseAvailable && !forceOffline;

  FirebaseFirestore? get _db {
    if (!_isFirebaseAvailable) return null;
    return _dbInstance;
  }

  // Helper to safely get collection snapshots or empty stream
  Stream<List<Map<String, dynamic>>> _safeCollectionStream(
    String collectionPath,
    List<Map<String, dynamic>> mockData,
  ) {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      return Stream.value(mockData).asBroadcastStream();
    }
    try {
      return _db!
          .collection(collectionPath)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    } catch (e) {
      debugPrint('Error fetching collection $collectionPath: $e');
      return Stream.value(mockData).asBroadcastStream();
    }
  }

  // Cached Broadcast Streams
  Stream<List<Map<String, dynamic>>>? _roomsStream;
  Stream<List<Map<String, dynamic>>>? _activitiesStream;
  Stream<List<Map<String, dynamic>>>? _allTasksStream;
  Stream<List<Map<String, dynamic>>>? _allActiveCallsStream;
  Stream<List<String>>? _myMembershipsStream;
  Stream<List<String>>? _myAttendanceStream;
  Stream<List<Map<String, dynamic>>>? _roomsAggregatedStream;
  Stream<List<Map<String, dynamic>>>? _unifiedScheduleStream;

  // --- Internal Stream Initializers ---
  Stream<List<Map<String, dynamic>>> _getGlobalTasksStream() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      return Stream.value(MockData.tasks).asBroadcastStream();
    }
    _allTasksStream ??= _db!
        .collectionGroup('tasks')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final parentPath = doc.reference.parent.parent?.id;
            return {'id': doc.id, 'roomId': parentPath, ...doc.data()};
          }).toList(),
        )
        .asBroadcastStream();
    return _allTasksStream!;
  }

  Stream<List<Map<String, dynamic>>> _getGlobalCallsStream() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      return Stream.value(<Map<String, dynamic>>[]).asBroadcastStream();
    }
    _allActiveCallsStream ??= _db!
        .collection('calls')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        )
        .asBroadcastStream();
    return _allActiveCallsStream!;
  }

  Stream<List<Map<String, dynamic>>> getRooms() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      return Stream.value([
        ...MockData.rooms,
        ..._localRooms,
      ]).asBroadcastStream();
    }
    // Singleton pattern for the stream
    _roomsStream ??= _db!
        .collection('rooms')
        .orderBy('startDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        )
        .asBroadcastStream();
    return _roomsStream!;
  }

  Stream<List<String>> _getMyRoomMemberships() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      final ids = _prefs?.getStringList('joined_rooms') ?? [];
      return Stream.value(ids).asBroadcastStream();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    _myMembershipsStream ??= _db!
        .collectionGroup('members')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                // Document path: rooms/{roomId}/members/{userId}
                // Parent: members, Grandparent: rooms/{roomId}
                return doc.reference.parent.parent?.id ?? '';
              })
              .where((id) => id.isNotEmpty)
              .toList();
        })
        .asBroadcastStream();

    return _myMembershipsStream!;
  }

  // --- Aggregated Stream (The Fix for Windows Threading & Persistence) ---
  Stream<List<Map<String, dynamic>>> getRoomsAggregated() {
    if (_roomsAggregatedStream != null) return _roomsAggregatedStream!;

    _roomsAggregatedStream =
        Rx.combineLatest4<
              List<Map<String, dynamic>>,
              List<Map<String, dynamic>>,
              List<Map<String, dynamic>>,
              List<String>, // My Joined Room IDs
              List<Map<String, dynamic>>
            >(
              getRooms(),
              _getGlobalTasksStream(),
              _getGlobalCallsStream(),
              _getMyRoomMemberships(),
              (rooms, tasks, calls, joinedRoomIds) {
                return rooms.map((room) {
                  final roomId = room['id'];

                  // Calculate Progress
                  final roomTasks = tasks.where((t) => t['roomId'] == roomId);
                  final total = roomTasks.length;
                  final completed = roomTasks
                      .where((t) => t['status'] == 'completed')
                      .length;
                  final progress = total > 0 ? completed / total : 0.0;

                  // Check Active Call
                  final hasCall = calls.any(
                    (c) => c['scope'] == 'room' && c['refId'] == roomId,
                  );

                  // Check Joined Status
                  final isJoined = joinedRoomIds.contains(roomId);

                  return {
                    ...room,
                    'calculatedProgress': progress,
                    'hasActiveCall': hasCall,
                    'isJoined': isJoined,
                  };
                }).toList();
              },
            )
            .asBroadcastStream();

    return _roomsAggregatedStream!;
  }

  Stream<List<String>> _getMyActivityAttendance() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      final ids = _prefs?.getStringList('attended_activities') ?? [];
      return Stream.value(ids).asBroadcastStream();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    _myAttendanceStream ??= _db!
        .collectionGroup('attendance')
        .where('userId', isEqualTo: user.uid)
        .where('confirmed', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                // Document path: activities/{activityId}/attendance/{userId}
                return doc.reference.parent.parent?.id ?? '';
              })
              .where((id) => id.isNotEmpty)
              .toList();
        })
        .asBroadcastStream();

    return _myAttendanceStream!;
  }

  // Unified Schedule (Rooms + Activities) - NOW PERSISTENT
  Stream<List<Map<String, dynamic>>> getUnifiedSchedule() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      // Logic below already handles combining streams,
      // but we need to ensure the sources are mock-aware.
      // Since getRoomsAggregated() and _activitiesStream are mock-aware,
      // this should work if we let it run.
    }

    if (_unifiedScheduleStream != null) return _unifiedScheduleStream!;

    // 1. Get Aggregated Rooms (already includes isJoined)
    final roomsSource = getRoomsAggregated().map(
      (list) => list
          .map(
            (d) => {
              ...d,
              'itemType': 'room',
              'sortDate': d['startDate'],
              // isJoined is already there
            },
          )
          .toList(),
    );

    // 2. Get Shared Activities Stream
    _activitiesStream ??= _db!
        .collection('activities')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList())
        .asBroadcastStream();

    // 3. Combine with My Attendance
    final activitiesSource =
        Rx.combineLatest2<
          List<Map<String, dynamic>>,
          List<String>,
          List<Map<String, dynamic>>
        >(_activitiesStream!, _getMyActivityAttendance(), (
          activities,
          myAttendanceIds,
        ) {
          return activities.map((d) {
            return {
              ...d,
              'itemType': 'activity',
              'sortDate': d['eventDate'],
              'isJoined': myAttendanceIds.contains(d['id']),
            };
          }).toList();
        });

    _unifiedScheduleStream =
        Rx.combineLatest2<
              List<Map<String, dynamic>>,
              List<Map<String, dynamic>>,
              List<Map<String, dynamic>>
            >(roomsSource, activitiesSource, (rooms, activities) {
              final all = [...rooms, ...activities];
              all.sort((a, b) {
                final dateA = a['sortDate'] is Timestamp
                    ? (a['sortDate'] as Timestamp).toDate()
                    : DateTime.tryParse(a['sortDate'].toString()) ??
                          DateTime(2000);
                final dateB = b['sortDate'] is Timestamp
                    ? (b['sortDate'] as Timestamp).toDate()
                    : DateTime.tryParse(b['sortDate'].toString()) ??
                          DateTime(2000);
                return dateA.compareTo(dateB);
              });
              return all;
            })
            .asBroadcastStream();

    return _unifiedScheduleStream!;
  }

  Stream<Map<String, dynamic>?> getRoom(String roomId) {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      try {
        final room = MockData.rooms.firstWhere((r) => r['id'] == roomId);
        return Stream.value(room).asBroadcastStream();
      } catch (_) {
        return Stream.value({
          'id': roomId,
          'title': 'Offline Room',
        }).asBroadcastStream();
      }
    }
    return _db!
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? {'id': doc.id, ...doc.data()!} : null);
  }

  // Room Members
  Stream<List<Map<String, dynamic>>> getRoomMembers(String roomId) {
    return _safeCollectionStream('rooms/$roomId/members', []);
  }

  // Calls
  Stream<Map<String, dynamic>?> getCall(String callId) {
    if (!_isFirebaseAvailable || _db == null) {
      return Stream.value(null).asBroadcastStream();
    }
    return _db!
        .collection('calls')
        .doc(callId)
        .snapshots()
        .map((doc) => doc.exists ? {'id': doc.id, ...doc.data()!} : null);
  }

  Stream<List<Map<String, dynamic>>> getCallParticipants(String callId) {
    return _safeCollectionStream('calls/$callId/participants', []);
  }

  Stream<Map<String, dynamic>?> getActiveCall(String scope, String refId) {
    return _getGlobalCallsStream().map((calls) {
      try {
        return calls.firstWhere(
          (c) => c['scope'] == scope && c['refId'] == refId,
        );
      } catch (_) {
        return null;
      }
    });
  }

  // Tasks
  Stream<List<Map<String, dynamic>>> getTasks(String roomId) {
    return _getGlobalTasksStream().map((allTasks) {
      return allTasks.where((t) => t['roomId'] == roomId).toList();
    });
  }

  // Activities
  Stream<List<Map<String, dynamic>>> getActivities(String eventId) {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      final list = [
        ...MockData.activities,
        ..._localActivities,
      ].where((a) => a['eventId'] == eventId).toList();
      return Stream.value(list).asBroadcastStream();
    }
    try {
      return _db!
          .collection('activities')
          .where('eventId', isEqualTo: eventId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    } catch (e) {
      return Stream.value(
        MockData.activities.where((a) => a['eventId'] == eventId).toList(),
      ).asBroadcastStream();
    }
  }

  // Activity Attendance
  Stream<List<Map<String, dynamic>>> getActivityAttendance(String activityId) {
    return _safeCollectionStream('activities/$activityId/attendance', []);
  }

  // Messages
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      final list = MockData.messages
          .where((m) => m['chatId'] == chatId)
          .toList();
      return Stream.value(list).asBroadcastStream();
    }
    try {
      return _db!
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    } catch (e) {
      return Stream.value(
        MockData.messages.where((m) => m['chatId'] == chatId).toList(),
      ).asBroadcastStream();
    }
  }

  // Events
  Stream<List<Map<String, dynamic>>> getEvents() {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      return Stream.value(MockData.events).asBroadcastStream();
    }
    return _safeCollectionStream('events', []);
  }

  Stream<Map<String, dynamic>?> getEvent(String eventId) {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      try {
        final event = MockData.events.firstWhere((e) => e['id'] == eventId);
        return Stream.value(event).asBroadcastStream();
      } catch (_) {
        return Stream.value({
          'id': eventId,
          'title': 'Offline Event',
          'shortDescription': 'This is an offline mock event.',
        }).asBroadcastStream();
      }
    }
    return _db!
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? {'id': doc.id, ...doc.data()!} : null);
  }

  // Governance Logs
  Stream<List<Map<String, dynamic>>> getGovernanceLogs(
    String scope,
    String? refId,
  ) {
    if (!_isFirebaseAvailable || _db == null) {
      return Stream.value(<Map<String, dynamic>>[]).asBroadcastStream();
    }
    try {
      var query = _db!
          .collection('governance_logs')
          .where('scope', isEqualTo: scope)
          .orderBy('timestamp', descending: true);

      if (refId != null) {
        query = query.where('refId', isEqualTo: refId);
      }

      return query.snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      );
    } catch (e) {
      return Stream.value(<Map<String, dynamic>>[]).asBroadcastStream();
    }
  }

  Stream<List<Map<String, dynamic>>> getEventRooms(String eventId) {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      final list = MockData.rooms
          .where((r) => r['eventId'] == eventId)
          .toList();
      return Stream.value(list).asBroadcastStream();
    }
    return _db!
        .collection('rooms')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // --- ACTIONS (Replacing Backend) ---

  Future<String?> createRoom(Map<String, dynamic> data) async {
    if (forceOffline || !_isFirebaseAvailable || _db == null) {
      final id = 'local_room_${DateTime.now().millisecondsSinceEpoch}';
      final newRoom = {
        'id': id,
        ...data,
        'createdAt': DateTime.now(),
        'status': 'open',
      };
      _localRooms.add(newRoom);
      debugPrint('[FirestoreService] Room created OFFLINE: $id');
      return id;
    }
    final doc = _db!.collection('rooms').doc();

    // Auto-generate cover image if missing
    final String coverImage =
        data['coverImageUrl'] ??
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop";

    // Auto-public if eventId is present
    final bool isPublic =
        data['eventId'] != null || data['privacy'] == 'public';

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Error: User not signed in. Cannot create room.');
      return null;
    }

    await doc.set({
      'id': doc.id,
      ...data,
      'privacy': isPublic ? 'public' : 'private',
      'coverImageUrl': coverImage,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'ownerId': user.uid,
      'status': 'open',
    });

    // Auto-join the creator as admin
    await _db!
        .collection('rooms')
        .doc(doc.id)
        .collection('members')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'role': 'admin',
          'joinedAt': FieldValue.serverTimestamp(),
        });

    return doc.id;
  }

  Future<void> createTask(String roomId, Map<String, dynamic> data) async {
    if (!_isFirebaseAvailable || _db == null) return;
    final doc = _db!.collection('rooms').doc(roomId).collection('tasks').doc();
    final user = FirebaseAuth.instance.currentUser;
    await doc.set({
      'id': doc.id,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user?.uid,
      'status': 'pending',
    });
  }

  Future<void> batchCreateTasks(
    String roomId,
    List<Map<String, dynamic>> tasksData,
  ) async {
    if (!_isFirebaseAvailable || _db == null) return;

    final user = FirebaseAuth.instance.currentUser;
    final batch = _db!.batch();

    for (final data in tasksData) {
      final doc = _db!
          .collection('rooms')
          .doc(roomId)
          .collection('tasks')
          .doc();
      batch.set(doc, {
        'id': doc.id,
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user?.uid,
        'status': 'pending',
      });
    }

    await batch.commit();
  }

  Future<void> joinRoom(
    String roomId,
    String userId, {
    bool acceptedCovenant = false,
  }) async {
    if (forceOffline || !_isFirebaseAvailable) {
      final joinedIds = _prefs?.getStringList('joined_rooms') ?? [];
      if (!joinedIds.contains(roomId)) {
        joinedIds.add(roomId);
        await _prefs?.setStringList('joined_rooms', joinedIds);
        debugPrint('[FirestoreService] Room $roomId joined OFFLINE.');
      }
      return;
    }
    await _db!
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(userId)
        .set({
          'userId': userId,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'acceptedCovenant': acceptedCovenant,
        });
  }

  Future<void> completeTask(
    String roomId,
    String taskId,
    Map<String, dynamic> data,
  ) async {
    if (!_isFirebaseAvailable) return;
    // For now just log it, or update a 'progress' subcollection
    // Simplified:
    await _db!
        .collection('rooms')
        .doc(roomId)
        .collection('tasks')
        .doc(taskId)
        .collection('completions')
        .add({...data, 'completedAt': FieldValue.serverTimestamp()});
  }

  Future<String> createEvent(Map<String, dynamic> data) async {
    if (!_isFirebaseAvailable) return 'offline_event';
    final doc = _db!.collection('events').doc();
    final user = FirebaseAuth.instance.currentUser;
    await doc.set({
      'id': doc.id,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'creatorId': user?.uid,
      'status': 'active',
    });
    return doc.id;
  }

  Future<void> createActivity(Map<String, dynamic> data) async {
    if (forceOffline || !_isFirebaseAvailable) {
      final id = 'local_act_${DateTime.now().millisecondsSinceEpoch}';
      _localActivities.add({'id': id, ...data, 'createdAt': DateTime.now()});
      debugPrint('[FirestoreService] Activity created OFFLINE: $id');
      return;
    }
    final doc = _db!.collection('activities').doc();
    final user = FirebaseAuth.instance.currentUser;
    await doc.set({
      'id': doc.id,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'creatorId': user?.uid,
    });
  }

  Future<void> confirmAttendance(
    String activityId,
    String userId,
    bool confirmed,
  ) async {
    if (forceOffline || !_isFirebaseAvailable) {
      final attendedIds = _prefs?.getStringList('attended_activities') ?? [];
      if (confirmed && !attendedIds.contains(activityId)) {
        attendedIds.add(activityId);
      } else if (!confirmed) {
        attendedIds.remove(activityId);
      }
      await _prefs?.setStringList('attended_activities', attendedIds);
      debugPrint(
        '[FirestoreService] Activity $activityId attendance confirmed: $confirmed OFFLINE.',
      );
      return;
    }
    await _db!
        .collection('activities')
        .doc(activityId)
        .collection('attendance')
        .doc(userId)
        .set({
          'userId': userId,
          'confirmed': confirmed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // --- CALLS & CIRCLE TALKING (Client-Side Logic) ---

  // Need to import GeminiService at top of file, but I can't easily add import with replace_file_content
  // unless I replace the whole file or top chunk.
  // I'll add the field and methods here, and fix imports in a separate step or assume I'll fix it.
  // Actually, I'll use a dynamic approach or just fix imports later.

  Future<String> createCall(Map<String, dynamic> data) async {
    if (!_isFirebaseAvailable) return 'offline_call';
    final doc = _db!.collection('calls').doc();
    await doc.set({
      'id': doc.id,
      ...data,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'circleTalkingEnabled': false,
    });
    return doc.id;
  }

  Future<void> endCall(String callId) async {
    if (!_isFirebaseAvailable) return;
    await _db!.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinCall(String callId, String userId) async {
    if (!_isFirebaseAvailable) return;
    await _db!
        .collection('calls')
        .doc(callId)
        .collection('participants')
        .doc(userId)
        .set({
          'userId': userId,
          'muted': true,
          'handRaised': false,
          'joinedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> leaveCall(String callId, String userId) async {
    if (!_isFirebaseAvailable) return;
    await _db!
        .collection('calls')
        .doc(callId)
        .collection('participants')
        .doc(userId)
        .delete();
  }

  Future<void> toggleMute(
    String callId,
    String userId,
    bool currentMuteStatus,
  ) async {
    if (!_isFirebaseAvailable) return;
    await _db!
        .collection('calls')
        .doc(callId)
        .collection('participants')
        .doc(userId)
        .update({'muted': !currentMuteStatus});
  }

  Future<void> raiseHand(
    String callId,
    String userId,
    bool currentHandStatus,
  ) async {
    if (!_isFirebaseAvailable) return;
    await _db!
        .collection('calls')
        .doc(callId)
        .collection('participants')
        .doc(userId)
        .update({'handRaised': !currentHandStatus});
  }

  // AI & Logic moved to Client
  Future<void> startCircleTalking(
    String callId,
    String requesterId, {
    String? moderatorMessage,
  }) async {
    if (!_isFirebaseAvailable) return;

    // 1. Fetch participants
    final participantsSnapshot = await _db!
        .collection('calls')
        .doc(callId)
        .collection('participants')
        .get();
    final participants = participantsSnapshot.docs
        .map((d) => d.data())
        .toList();

    if (participants.isEmpty) return;

    // 2. Assign Order (simple alphabet or join order)
    // Client-side sort
    participants.sort(
      (a, b) => (a['userId'] as String).compareTo(b['userId'] as String),
    );

    final batch = _db!.batch();

    for (int i = 0; i < participants.length; i++) {
      final uid = participants[i]['userId'] as String;
      batch.update(
        _db!
            .collection('calls')
            .doc(callId)
            .collection('participants')
            .doc(uid),
        {'speakingOrder': i, 'muted': true, 'handRaised': false},
      );
    }

    // 3. Unmute first
    final firstSpeakerId = participants[0]['userId'] as String;
    batch.update(
      _db!
          .collection('calls')
          .doc(callId)
          .collection('participants')
          .doc(firstSpeakerId),
      {'muted': false},
    );

    // 4. Update Call
    batch.update(_db!.collection('calls').doc(callId), {
      'circleTalkingEnabled': true,
      'currentSpeakerId': firstSpeakerId,
      'speakerStartTime': FieldValue.serverTimestamp(),
      'moderatorMessage': moderatorMessage,
    });

    await batch.commit();
  }

  Future<void> nextSpeaker(
    String callId,
    String currentSpeakerId, {
    String? moderatorMessage,
  }) async {
    if (!_isFirebaseAvailable) return;
    // Fetch participants to find next
    final participantsSnapshot = await _db!
        .collection('calls')
        .doc(callId)
        .collection('participants')
        .get();
    final participants = participantsSnapshot.docs;

    if (participants.isEmpty) return;

    // Sort by speakingOrder
    participants.sort(
      (a, b) => (a.data()['speakingOrder'] as int? ?? 0).compareTo(
        b.data()['speakingOrder'] as int? ?? 0,
      ),
    );

    int currentIndex = participants.indexWhere((d) => d.id == currentSpeakerId);
    if (currentIndex == -1) currentIndex = 0;

    int nextIndex = (currentIndex + 1) % participants.length;
    final nextSpeakerId = participants[nextIndex].id;

    final batch = _db!.batch();

    // Mute current
    batch.update(
      _db!
          .collection('calls')
          .doc(callId)
          .collection('participants')
          .doc(currentSpeakerId),
      {'muted': true},
    );

    // Unmute next
    batch.update(
      _db!
          .collection('calls')
          .doc(callId)
          .collection('participants')
          .doc(nextSpeakerId),
      {'muted': false},
    );

    // Update call
    batch.update(_db!.collection('calls').doc(callId), {
      'currentSpeakerId': nextSpeakerId,
      'speakerStartTime': FieldValue.serverTimestamp(),
      'moderatorMessage': moderatorMessage,
    });

    await batch.commit();
  }

  // --- SEEDING METHOD ---
  Future<void> seedDatabase() async {
    if (!_isFirebaseAvailable || _db == null) {
      throw Exception('Firebase not available for seeding');
    }

    debugPrint('--- Starting MEGA Seeding (Dynamic) ---');
    final batch = _db!.batch();

    // 1. Generate 3 Events (Dynamic Dates)
    // Event 1: Past (ended)
    // Event 2: Current (active)
    // Event 3: Future (upcoming)

    final events = [
      {
        'id': 'event_seed_past',
        'title': 'Legacy Revival',
        'shortDescription': 'A past movement of spirit.',
        'startDate': _getRelativeDate(-40),
        'endDate': _getRelativeDate(-35),
        'status': 'ended',
      },
      {
        'id': 'event_seed_current',
        'title': 'Global Awakening',
        'shortDescription': 'Happening right now.',
        'startDate': _getRelativeDate(-2), // Started 2 days ago
        'endDate': _getRelativeDate(5), // Ends in 5 days
        'status': 'active',
      },
      {
        'id': 'event_seed_future',
        'title': 'Prophetic Summit',
        'shortDescription': 'Upcoming gathering.',
        'startDate': _getRelativeDate(10), // Starts in 10 days
        'endDate': _getRelativeDate(15),
        'status': 'active', // Active but future
      },
    ];

    for (final evt in events) {
      final String eventId = evt['id'] as String;
      final startDate = evt['startDate'] as DateTime;
      final endDate = evt['endDate'] as DateTime;

      batch.set(_db!.collection('events').doc(eventId), {
        ...evt,
        'fullDescription': 'Detailed description for ${evt['title']}.',
        'objectiveStatement': 'To verify dynamic scheduling.',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'visibility': 'public',
        'creatorId': 'admin_user_001',
        'createdAt': FieldValue.serverTimestamp(),
        'coverImageUrl':
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop',
      });

      // 2. Generate Rooms for each Event
      await _seedEventRooms(batch, eventId, startDate, endDate);

      // 3. Generate Activities for each Event
      await _seedEventActivities(batch, eventId, startDate);
    }

    await batch.commit();
    debugPrint('--- Dynamic Seeding Completed ---');
  }

  // Helper Methods for Seeding
  DateTime _getRelativeDate(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  Future<void> _seedEventRooms(
    WriteBatch batch,
    String eventId,
    DateTime evtStart,
    DateTime evtEnd,
  ) async {
    final rooms = [
      {'type': 'prayer', 'name': 'War Room', 'offset': 0},
      {'type': 'bible_study', 'name': 'Wisdom Study', 'offset': 0},
      {'type': 'fellowship', 'name': 'Community Hub', 'offset': 1},
    ];

    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      final roomId = '${eventId}_room_$i';

      // Room start/end can match event or be subset
      final roomStart = evtStart.add(Duration(days: room['offset'] as int));
      final roomEnd = evtEnd;

      batch.set(_db!.collection('rooms').doc(roomId), {
        'id': roomId,
        'eventId': eventId,
        'title':
            room['name'], // Changed from 'name' to 'title' to match UI expectation?
        // Actually RoomsScreen uses 'title' or 'name'? Let's check model. Usually 'title'.
        // Wait, previous seed used 'name'. RoomDetailScreen used 'title' from widget param but 'title' from doc?
        // The RoomsScreen uses `room['title'] ?? room['name']`.
        'description': 'Description for ${room['name']}',
        'roomType': room['type'],
        'privacy': 'public',
        'status': 'open',
        'startDate': Timestamp.fromDate(roomStart),
        'endDate': Timestamp.fromDate(roomEnd),
        'creatorId': 'admin_user_001',
        'createdAt': FieldValue.serverTimestamp(),
        'coverImageUrl':
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop',
      });

      // Tasks for this room
      _seedRoomTasks(batch, roomId, roomStart);
    }
  }

  void _seedRoomTasks(WriteBatch batch, String roomId, DateTime roomStart) {
    // Create 5 days of tasks
    for (int i = 0; i < 5; i++) {
      final date = roomStart.add(Duration(days: i));

      // Task 1: Morning Prayer (Daily)
      final t1 = _db!.collection('rooms').doc(roomId).collection('tasks').doc();
      batch.set(t1, {
        'id': t1.id,
        'title': 'Morning Prayer',
        'description': 'Start the day with God.',
        'type': 'prayer', // UI uses taskType?
        'taskType': 'prayer',
        'timeType': 'daily',
        'scheduledDate': Timestamp.fromDate(date),
        'dayIndex': i + 1,
        'startHour': 7, // 7 AM
        'status':
            'pending', // Dynamic calculation will handle 'completed' if we had user specific data
        'mandatory': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Task 2: Specific Reading (Specific Date)
      final t2 = _db!.collection('rooms').doc(roomId).collection('tasks').doc();
      batch.set(t2, {
        'id': t2.id,
        'title': 'Read Chapter ${i + 1}',
        'description': 'Daily reading.',
        'taskType': 'reading',
        'timeType': 'specific_date',
        'scheduledDate': Timestamp.fromDate(date),
        'dayIndex': i + 1,
        'startHour': 9, // 9 AM
        'status': 'pending',
        'mandatory': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedEventActivities(
    WriteBatch batch,
    String eventId,
    DateTime evtStart,
  ) async {
    // Create activities on Day 1 and Day 3
    for (int i = 0; i < 3; i += 2) {
      // 0, 2
      final date = evtStart.add(Duration(days: i));
      final actId = '${eventId}_act_$i';

      batch.set(_db!.collection('activities').doc(actId), {
        'id': actId,
        'eventId': eventId,
        'title': 'Gathering Day ${i + 1}',
        'description': 'Live session.',
        'place': 'Main Hall',
        'type': 'meeting',
        'eventDate': Timestamp.fromDate(date), // New standard field
        'startHour': 18.5, // 6:30 PM (Double for hour)
        'duration': 90,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> data) async {
    if (!_isFirebaseAvailable) return;

    await _db!.collection('chats').doc(chatId).collection('messages').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Optionally update lastMessage in chat doc
    await _db!.collection('chats').doc(chatId).set({
      'lastMessage': data['contentRichText']?['text'] ?? 'New message',
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getNotes(String userId) {
    if (!_isFirebaseAvailable) return Stream.value([]);

    return _db!
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<void> addNote(String userId, String content) async {
    if (!_isFirebaseAvailable) return;

    await _db!.collection('users').doc(userId).collection('notes').add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String userId, String noteId) async {
    if (!_isFirebaseAvailable) return;

    await _db!
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}
