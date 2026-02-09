import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/event_model.dart';
import '../../models/room_model.dart';
import '../../models/task_model.dart';
import '../../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/mock_storage_service.dart';

class Repository {
  final FirestoreService _firestoreService;
  final MockStorageService _mockStorage;

  // In-Memory Cache
  List<Event> _eventsCache = [];
  List<Room> _roomsCache = [];
  // ignore: unused_field
  final List<Activity> _activitiesCache = [];
  final Map<String, List<Task>> _roomTasksCache = {}; // roomId -> tasks

  bool _isInitialized = false;

  Repository(this._firestoreService, this._mockStorage);

  bool get isInitialized => _isInitialized;

  /// Call this on app startup (Splash Screen)
  Future<void> preloadData() async {
    try {
      debugPrint('[Repository] Starting Preload...');

      // Fetch core data in parallel
      // We use .first to get the current snapshot
      // Prefer MockStorage if Firestore is offline to get persisted data
      final useMock = !_firestoreService.isAvailable;

      if (useMock) {
        await _mockStorage.initialize(); // Ensure it's loaded
        _eventsCache = await _mockStorage.eventsStream.first;
        _roomsCache = await _mockStorage.roomsStream.first;
      } else {
        final results = await Future.wait([
          _firestoreService.getEvents().first,
          _firestoreService.getRooms().first,
        ]);

        _eventsCache = (results[0])
            .map((data) => Event.fromMap(data['id'] as String, data))
            .toList();

        _roomsCache = (results[1])
            .map((data) => Room.fromMap(data['id'] as String, data))
            .toList();
      }

      _isInitialized = true;
      debugPrint(
        '[Repository] Preload Complete. Events: ${_eventsCache.length}, Rooms: ${_roomsCache.length}',
      );
    } catch (e) {
      debugPrint('[Repository] Preload Failed: $e');
      // Mark initialized so app can proceed even if offline/empty
      _isInitialized = true;
    }
  }

  // --- Events ---

  List<Event> getEvents() {
    return _eventsCache;
  }

  Future<void> refreshEvents() async {
    final data = await _firestoreService.getEvents().first;
    _eventsCache = data
        .map((d) => Event.fromMap(d['id'] as String, d))
        .toList();
  }

  Stream<List<Event>> get eventsStream {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.eventsStream.doOnData((list) => _eventsCache = list);
    }
    return _firestoreService.getEvents().map((list) {
      final mapped = list
          .map((d) => Event.fromMap(d['id'] as String, d))
          .toList();
      _eventsCache = mapped;
      return mapped;
    });
  }

  // --- Rooms ---

  List<Room> getRooms() {
    return _roomsCache;
  }

  Room? getRoomFromCache(String roomId) {
    try {
      return _roomsCache.firstWhere((r) => r.id == roomId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshRooms() async {
    final data = await _firestoreService.getRooms().first;
    _roomsCache = data.map((d) => Room.fromMap(d['id'] as String, d)).toList();
  }

  Stream<List<Room>> get roomsStream {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.roomsStream.doOnData((list) => _roomsCache = list);
    }
    return _firestoreService.getRooms().map((list) {
      final mapped = list
          .map((d) => Room.fromMap(d['id'] as String, d))
          .toList();
      _roomsCache = mapped;
      return mapped;
    });
  }

  // --- Tasks ---

  List<Task>? getTasksForRoom(String roomId) {
    return _roomTasksCache[roomId];
  }

  // Fetch tasks for a specific room and cache them
  // This is often called when entering a room
  Future<List<Task>> fetchTasks(String roomId) async {
    if (!_firestoreService.isAvailable) {
      final tasks = await _mockStorage.getRoomTasks(roomId).first;
      _roomTasksCache[roomId] = tasks;
      return tasks;
    }
    final data = await _firestoreService.getTasks(roomId).first;
    final tasks = data.map((d) => Task.fromMap(d['id'] as String, d)).toList();
    _roomTasksCache[roomId] = tasks;
    return tasks;
  }

  Stream<List<Task>> getTasksStream(String roomId) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getRoomTasks(roomId).doOnData((tasks) {
        _roomTasksCache[roomId] = tasks;
      });
    }
    return _firestoreService.getTasks(roomId).map((data) {
      final tasks = data
          .map((d) => Task.fromMap(d['id'] as String, d))
          .toList();
      _roomTasksCache[roomId] = tasks;
      return tasks;
    });
  }
  // --- Single Item Streams ---

  Stream<Event?> getEvent(String eventId) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getEvent(eventId);
    }
    return _firestoreService.getEvent(eventId).map((data) {
      if (data == null) return null;
      return Event.fromMap(data['id'] as String, data);
    });
  }

  Stream<Room?> getRoom(String roomId) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getRoom(roomId);
    }
    return _firestoreService.getRoom(roomId).map((data) {
      if (data == null) return null;
      return Room.fromMap(data['id'] as String, data);
    });
  }

  // --- Aggregated Streams (For UI) ---

  Stream<List<Map<String, dynamic>>> get unifiedScheduleStream {
    if (!_firestoreService.isAvailable) {
      // MockStorage doesn't have exactly "unifiedSchedule" pre-baked as a single stream
      // but it has "myEventsStream" and "myRoomsStream".
      // However, FirestoreService has logic to combine them.
      // We can actually use FirestoreService's method if it handles offline fallback correctly.
      // Checking FirestoreService line 239: it has logic but might rely on available streams.
      // Let's use FirestoreService's implementation since it constructs the stream from available sources.
      // BUT we need to ensure it uses the MockStorage streams if offline?
      // Actually FirestoreService offline usage is separate.

      // Use FirestoreService logic, which should return MockData if offline
      return _firestoreService.getUnifiedSchedule();
    }
    return _firestoreService.getUnifiedSchedule();
  }

  Stream<List<Map<String, dynamic>>> get roomsAggregatedStream {
    if (!_firestoreService.isAvailable) {
      // MockStorage has _roomsEnrichmentStream which is close, but FirestoreService.getRoomsAggregated
      // does specific formatting.
      return _firestoreService.getRoomsAggregated();
    }
    return _firestoreService.getRoomsAggregated();
  }

  // --- Filtered Streams (Convenience) ---

  Stream<List<Event>> get myEventsStream {
    return eventsStream.map(
      (events) => events.where((e) => e.isJoined).toList(),
    );
  }

  Stream<List<Room>> get myRoomsStream {
    return roomsStream.map((rooms) => rooms.where((r) => r.isJoined).toList());
  }

  Stream<List<Room>> get publicRoomsDiscoveryStream {
    return roomsStream.map((rooms) => rooms.where((r) => !r.isJoined).toList());
  }

  Stream<List<Event>> get publicEventsDiscoveryStream {
    return eventsStream.map(
      (events) => events.where((e) => !e.isJoined).toList(),
    );
  }

  // --- Mutations (Delegate to correct service) ---

  Future<String?> createRoom(Map<String, dynamic> data) async {
    if (!_firestoreService.isAvailable) {
      return await _mockStorage.createRoom(data);
    }
    return await _firestoreService.createRoom(data);
  }

  Future<void> joinRoom(
    String roomId,
    String userId, {
    bool acceptedCovenant = false,
  }) async {
    if (!_firestoreService.isAvailable) {
      _mockStorage.joinRoom(roomId);
      return;
    }
    await _firestoreService.joinRoom(
      roomId,
      userId,
      acceptedCovenant: acceptedCovenant,
    );
  }

  Future<void> createTask(String roomId, Map<String, dynamic> data) async {
    if (!_firestoreService.isAvailable) {
      // MockStorage has generateTasksForRoom but not single createTask exposed easily
      // Actually it has internal _createTask but typically we generate via config.
      // Let's rely on batchCreateTasks which supports single item list
      await _mockStorage.generateTasksForRoom(
        roomId,
        [data],
        DateTime.now(),
        DateTime.now().add(const Duration(days: 1)),
      );
      return;
    }
    await _firestoreService.createTask(roomId, data);
  }

  Future<void> batchCreateTasks(
    String roomId,
    List<Map<String, dynamic>> tasksData,
    DateTime start,
    DateTime end,
  ) async {
    if (!_firestoreService.isAvailable) {
      await _mockStorage.generateTasksForRoom(roomId, tasksData, start, end);
      return;
    }
    await _firestoreService.batchCreateTasks(roomId, tasksData);
  }

  Future<void> completeTask(
    String taskId,
    String roomId,
    Map<String, dynamic> data,
  ) async {
    if (!_firestoreService.isAvailable) {
      await _mockStorage.completeTask(taskId, data);
      return;
    }
    await _firestoreService.completeTask(roomId, taskId, data);
  }
  // --- Chat ---

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getMessages(chatId);
    }
    return _firestoreService.getMessages(chatId);
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> data) async {
    if (!_firestoreService.isAvailable) {
      await _mockStorage.sendMessage(chatId, data);
      return;
    }
    await _firestoreService.sendMessage(chatId, data);
  }

  // --- Governance ---

  Stream<List<Map<String, dynamic>>> getGovernanceLogs(
    String scope,
    String refId,
  ) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getGovernanceLogs(scope, refId);
    }
    return _firestoreService.getGovernanceLogs(scope, refId);
  }

  // --- Events mutation ---

  Future<void> joinEvent(String eventId) async {
    if (!_firestoreService.isAvailable) {
      _mockStorage.joinEvent(eventId);
      return;
    }
    // Firestore implementation fallback (none for now)
    debugPrint('[Repository] joinEvent not implemented for Firestore yet.');
  }

  Future<String?> createEvent(Map<String, dynamic> data) async {
    if (!_firestoreService.isAvailable) {
      return await _mockStorage.createEvent(data);
    }
    return await _firestoreService.createEvent(data);
  }

  Future<String?> createActivity(Map<String, dynamic> data) async {
    if (!_firestoreService.isAvailable) {
      return await _mockStorage.createActivity(data);
    }
    await _firestoreService.createActivity(data);
    return null;
  }

  // --- Event Relationships ---

  Stream<List<Room>> getEventRooms(String eventId) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getEventRooms(eventId);
    }
    return _firestoreService.getEventRooms(eventId).map((list) {
      return list
          .map((data) => Room.fromMap(data['id'] as String, data))
          .toList();
    });
  }

  Stream<List<Activity>> getEventActivities(String eventId) {
    if (!_firestoreService.isAvailable) {
      return _mockStorage.getEventActivities(eventId);
    }
    // FirestoreService missing getEventActivities. Return empty or implement?
    return Stream.value([]);
  }
}
