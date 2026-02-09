import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/event_model.dart';
import '../../models/room_model.dart';
import '../../models/task_model.dart';
import '../../models/activity_model.dart';
import 'mock_data.dart';

class MockStorageService {
  static final MockStorageService _instance = MockStorageService._internal();
  factory MockStorageService() => _instance;

  final _events = BehaviorSubject<List<Event>>.seeded([]);
  final _rooms = BehaviorSubject<List<Room>>.seeded([]);
  final _activities = BehaviorSubject<List<Activity>>.seeded([]);
  final _tasks = BehaviorSubject<List<Task>>.seeded([]);
  final _enrichedEvents = BehaviorSubject<List<Event>>.seeded([]);
  final _enrichedRooms = BehaviorSubject<List<Room>>.seeded([]);

  // Membership tracking
  final _joinedEventIds = BehaviorSubject<Set<String>>.seeded({});
  final _joinedRoomIds = BehaviorSubject<Set<String>>.seeded({});

  MockStorageService._internal() {
    _eventsEnrichmentStream().listen((data) {
      _enrichedEvents.add(data);
    });
    _roomsEnrichmentStream().listen((data) {
      _enrichedRooms.add(data);
    });
  }

  late final Stream<List<Event>> eventsStream = _enrichedEvents.stream;
  late final Stream<List<Room>> roomsStream = _enrichedRooms.stream;
  late final Stream<List<Activity>> activitiesStream = _activities.stream;
  late final Stream<List<Task>> tasksStream = _tasks.stream;

  // Filtered Streams
  late final Stream<List<Event>> myEventsStream = eventsStream
      .map((events) => events.where((e) => e.isJoined).toList())
      .asBroadcastStream();

  late final Stream<List<Event>> publicEventsDiscoveryStream = eventsStream
      .map(
        (events) => events
            .where((e) => !e.isJoined && e.creatorId != 'user_offline')
            .toList(),
      )
      .asBroadcastStream();

  late final Stream<List<Room>> myRoomsStream = roomsStream
      .map((rooms) => rooms.where((r) => r.isJoined).toList())
      .asBroadcastStream();

  late final Stream<List<Room>> publicRoomsDiscoveryStream = roomsStream
      .map(
        (rooms) => rooms
            .where((r) => !r.isJoined && r.creatorId != 'user_offline')
            .toList(),
      )
      .asBroadcastStream();

  late final Stream<Set<String>> joinedEventIdsStream = _joinedEventIds.stream;
  late final Stream<Set<String>> joinedRoomIdsStream = _joinedRoomIds.stream;

  Stream<List<Event>> _eventsEnrichmentStream() {
    return Rx.combineLatest5<
      List<Event>,
      List<Room>,
      List<Activity>,
      List<Task>,
      Set<String>,
      List<Event>
    >(
      _events.stream,
      _rooms.stream,
      _activities.stream,
      _tasks.stream,
      _joinedEventIds.stream,
      (events, rooms, activities, tasks, joinedIds) {
        return events.map((event) {
          final isJoined =
              joinedIds.contains(event.id) || event.creatorId == 'user_offline';

          final eventRooms = rooms.where((r) => r.eventId == event.id).toList();
          final eventActivities = activities
              .where((a) => a.eventId == event.id)
              .toList();

          final eventRoomIds = eventRooms.map((r) => r.id).toSet();
          final eventTasks = tasks
              .where((t) => eventRoomIds.contains(t.roomId))
              .toList();

          int completedItems = eventTasks
              .where((t) => t.status == TaskStatus.completed)
              .length;

          final now = DateTime.now();
          completedItems += eventActivities
              .where((a) => a.endDateTime.isBefore(now))
              .length;

          final totalItems = eventTasks.length + eventActivities.length;
          final progress = totalItems > 0 ? completedItems / totalItems : 0.0;

          return event.copyWith(
            numberOfRooms: eventRooms.length,
            numberOfActivities: eventActivities.length,
            aggregateProgress: progress,
            isJoined: isJoined,
          );
        }).toList();
      },
    );
  }

  Stream<List<Room>> _roomsEnrichmentStream() {
    return Rx.combineLatest2<List<Room>, Set<String>, List<Room>>(
      _rooms.stream,
      _joinedRoomIds.stream,
      (rooms, joinedIds) {
        return rooms.map((room) {
          final isJoined =
              joinedIds.contains(room.id) || room.creatorId == 'user_offline';
          return room.copyWith(isJoined: isJoined);
        }).toList();
      },
    );
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Events
    final eventsJson = prefs.getString('mock_events');
    if (eventsJson != null && eventsJson != '[]') {
      final List decoded = json.decode(eventsJson);
      _events.add(decoded.map((e) => Event.fromMap(e['id'], e)).toList());
    } else {
      _events.add(MockData.events.map((e) => _mapToEvent(e)).toList());
    }

    // Load Rooms
    final roomsJson = prefs.getString('mock_rooms');
    if (roomsJson != null && roomsJson != '[]') {
      final List decoded = json.decode(roomsJson);
      _rooms.add(decoded.map((r) => Room.fromMap(r['id'], r)).toList());
    } else {
      _rooms.add(MockData.rooms.map((r) => _mapToRoom(r)).toList());
    }

    // Load Activities
    final actsJson = prefs.getString('mock_activities');
    if (actsJson != null) {
      final List decoded = json.decode(actsJson);
      _activities.add(decoded.map((a) => Activity.fromMap(a)).toList());
    } else {
      _activities.add(
        MockData.activities.map((a) => Activity.fromMap(a)).toList(),
      );
    }

    // Load Tasks
    final tasksJson = prefs.getString('mock_tasks');
    if (tasksJson != null) {
      final List decoded = json.decode(tasksJson);
      _tasks.add(decoded.map((t) => Task.fromMap(t['id'], t)).toList());
    } else {
      _tasks.add(MockData.tasks.map((t) => Task.fromMap(t['id'], t)).toList());
    }

    // Load Memberships
    final joinedEvents = prefs.getStringList('mock_joined_events') ?? [];
    _joinedEventIds.add(joinedEvents.toSet());

    final joinedRooms = prefs.getStringList('mock_joined_rooms') ?? [];
    _joinedRoomIds.add(joinedRooms.toSet());

    // Initial persistence if first run
    if (eventsJson == null) _persistState();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mock_events',
      json.encode(_events.value.map((e) => e.toMap()).toList()),
    );
    await prefs.setString(
      'mock_rooms',
      json.encode(_rooms.value.map((r) => r.toMap()).toList()),
    );
    await prefs.setString(
      'mock_activities',
      json.encode(_activities.value.map((a) => a.toMap()).toList()),
    );
    await prefs.setString(
      'mock_tasks',
      json.encode(_tasks.value.map((t) => t.toMap()).toList()),
    );
    await prefs.setStringList(
      'mock_joined_events',
      _joinedEventIds.value.toList(),
    );
    await prefs.setStringList(
      'mock_joined_rooms',
      _joinedRoomIds.value.toList(),
    );
  }

  // --- EVENTS ---
  Future<String> createEvent(Map<String, dynamic> data) async {
    final id = 'evt_${DateTime.now().millisecondsSinceEpoch}';
    final newEvent = Event(
      id: id,
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      fullDescription: data['fullDescription'] ?? '',
      objectiveStatement: data['objectiveStatement'] ?? '',
      coverImageUrl:
          data['coverImageUrl'] ??
          'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4',
      thematicVerseSummary: data['thematicVerseSummary'] ?? '',
      startDate: DateTime.tryParse(data['startDate'] ?? '') ?? DateTime.now(),
      endDate:
          DateTime.tryParse(data['endDate'] ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      visibility: EventVisibility.public,
      status: EventStatus.active,
      creatorId: data['creatorId'] ?? 'user_offline',
      createdAt: DateTime.now(),
    );

    final current = _events.value;
    _events.add([...current, newEvent]);

    // Auto-join created events
    joinEvent(id);

    await _persistState();
    return id;
  }

  void joinEvent(String id) {
    final current = _joinedEventIds.value;
    if (!current.contains(id)) {
      _joinedEventIds.add({...current, id});
      _persistState();
    }
  }

  void leaveEvent(String id) {
    final current = _joinedEventIds.value;
    if (current.contains(id)) {
      _joinedEventIds.add(current.where((itemId) => itemId != id).toSet());
      _persistState();
    }
  }

  Stream<Event?> getEvent(String id) {
    return eventsStream.map((list) {
      try {
        return list.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }).asBroadcastStream();
  }

  // --- ROOMS ---
  Future<String> createRoom(Map<String, dynamic> data) async {
    final id = 'room_${DateTime.now().millisecondsSinceEpoch}';
    final newRoom = Room(
      id: id,
      eventId: data['eventId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      objective: data['objective'] ?? '',
      roomType: _parseRoomType(data['roomType']),
      visibility: RoomVisibility.public,
      startDate:
          DateTime.tryParse(data['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(data['endDate']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 4)),
      status: RoomStatus.open,
      creatorId: 'user_offline',
      createdAt: DateTime.now(),
    );

    final current = _rooms.value;
    _rooms.add([...current, newRoom]);

    // Auto-join created rooms
    joinRoom(id);

    // Handle initial tasks generation if present
    if (data['initialTasks'] != null) {
      await generateTasksForRoom(
        id,
        List<Map<String, dynamic>>.from(data['initialTasks']),
        newRoom.startDate,
        newRoom.endDate,
      );
    }

    await _persistState();
    return id;
  }

  void joinRoom(String id) {
    final current = _joinedRoomIds.value;
    if (!current.contains(id)) {
      _joinedRoomIds.add({...current, id});
      _persistState();
    }
  }

  void leaveRoom(String id) {
    final current = _joinedRoomIds.value;
    if (current.contains(id)) {
      _joinedRoomIds.add(current.where((itemId) => itemId != id).toSet());
      _persistState();
    }
  }

  Stream<List<Room>> getEventRooms(String eventId) {
    return _rooms.stream
        .map((list) => list.where((r) => r.eventId == eventId).toList())
        .asBroadcastStream();
  }

  Stream<Room?> getRoom(String id) {
    return _rooms.stream.map((list) {
      try {
        return list.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }).asBroadcastStream();
  }

  // --- ACTIVITIES ---
  Future<String> createActivity(Map<String, dynamic> data) async {
    final id = 'act_${DateTime.now().millisecondsSinceEpoch}';
    final newActivity = Activity(
      id: id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      activityType: data['activityType'] is ActivityType
          ? data['activityType']
          : ActivityType.meeting,
      locationName: data['locationName'] ?? 'Online',
      mapLink: data['mapLink'] ?? '',
      startDateTime:
          DateTime.tryParse(data['startDateTime']?.toString() ?? '') ??
          DateTime.now(),
      endDateTime:
          DateTime.tryParse(data['endDateTime']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      costType: CostType.free,
      organizerContact: 'offline@bibleverse.com',
      createdAt: DateTime.now(),
    );

    final current = _activities.value;
    _activities.add([...current, newActivity]);
    await _persistState();
    return id;
  }

  Stream<List<Activity>> getEventActivities(String eventId) {
    return _activities.stream
        .map((list) => list.where((a) => a.eventId == eventId).toList())
        .asBroadcastStream();
  }

  // --- TASKS ---
  Future<void> generateTasksForRoom(
    String roomId,
    List<Map<String, dynamic>> templates,
    DateTime start,
    DateTime end,
  ) async {
    final List<Task> generated = [];
    final duration = end.difference(start).inDays + 1;

    for (var i = 0; i < templates.length; i++) {
      final data = templates[i];

      if (data.containsKey('scheduledDate')) {
        // Pre-instantiated task from the config sheet
        final scheduledTime =
            DateTime.tryParse(data['scheduledDate'].toString()) ?? start;
        final dayIndex = scheduledTime.difference(start).inDays + 1;

        generated.add(
          Task(
            id: 'task_${DateTime.now().microsecondsSinceEpoch}_${roomId}_$i',
            roomId: roomId,
            title: data['title'] ?? 'Sacred Task',
            description: data['description'] ?? '',
            taskType: _parseTaskType(data['taskType']),
            dayIndex: dayIndex,
            deadline: scheduledTime.add(
              Duration(hours: data['durationHours']?.toInt() ?? 4),
            ),
            createdBy: 'user',
            createdAt: DateTime.now(),
            status: TaskStatus.pending,
            scheduledStartTime: scheduledTime,
            questions: data['questions'] != null
                ? List<String>.from(data['questions'])
                : null,
            prayerPoints: data['prayerPoints'] != null
                ? List<String>.from(data['prayerPoints'])
                : null,
            startHour: data['startHour'],
            durationHours: data['durationHours']?.toDouble(),
            meetingName: data['meetingName'],
          ),
        );
        continue;
      }

      // Legacy frequency-based template generation
      final frequency = data['frequency'];
      if (frequency == 'once') {
        generated.add(_createTask(roomId, data, start, 1));
      } else if (frequency == 'daily') {
        for (int d = 1; d <= duration; d++) {
          generated.add(
            _createTask(roomId, data, start.add(Duration(days: d - 1)), d),
          );
        }
      } else if (frequency == 'hours_4') {
        for (int d = 1; d <= duration; d++) {
          for (int h = 0; h < 24; h += 4) {
            final taskTime = start.add(Duration(days: d - 1, hours: h));
            if (taskTime.isBefore(end)) {
              generated.add(
                _createTask(roomId, data, taskTime, d, suffix: ' - ${h}h'),
              );
            }
          }
        }
      }
    }

    final current = _tasks.value;
    _tasks.add([...current, ...generated]);
    await _persistState();
  }

  Task _createTask(
    String roomId,
    Map<String, dynamic> template,
    DateTime time,
    int dayIndex, {
    String suffix = '',
  }) {
    return Task(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}_${roomId}_$dayIndex',
      roomId: roomId,
      title: (template['title'] ?? 'Task') + suffix,
      description: template['description'] ?? '',
      taskType: _parseTaskType(template['type'] ?? template['taskType']),
      dayIndex: dayIndex,
      deadline: time.add(const Duration(hours: 4)),
      createdBy: 'user',
      createdAt: DateTime.now(),
      status: TaskStatus.pending,
      scheduledStartTime: time,
      questions: template['questions'] != null
          ? List<String>.from(template['questions'])
          : null,
      prayerPoints: template['prayerPoints'] != null
          ? List<String>.from(template['prayerPoints'])
          : null,
      startHour: template['startHour'],
      durationHours: template['durationHours']?.toDouble(),
      meetingName: template['meetingName'],
    );
  }

  Future<void> completeTask(String taskId, Map<String, dynamic> data) async {
    final current = _tasks.value;
    final index = current.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = current[index];
      current[index] = Task.fromMap(task.id, {
        ...task.toMap(),
        'status': TaskStatus.completed.name,
        'progressData': data,
      });
      _tasks.add([...current]);
      _persistState();
    }
  }

  void toggleTaskCompletion(String taskId) {
    completeTask(taskId, {});
  }

  Stream<List<Task>> getRoomTasks(String roomId) {
    return _tasks.stream
        .map((list) => list.where((t) => t.roomId == roomId).toList())
        .asBroadcastStream();
  }

  // --- CHAT ---
  final _messages = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _messages.stream.map((msgs) {
      final chatMsgs = msgs.where((m) => m['chatId'] == chatId).toList();
      chatMsgs.sort(
        (a, b) => b['createdAt'].compareTo(a['createdAt']),
      ); // Newest first
      return chatMsgs;
    }).asBroadcastStream();
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> data) async {
    final current = _messages.value;
    final newMessage = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'chatId': chatId,
      'senderId': data['senderId'],
      'content': data['content'], // Plain text fallback
      'contentRichText': data['contentRichText'],
      'createdAt': DateTime.now(),
      'type': 'text',
    };
    _messages.add([...current, newMessage]);
    // TODO: Persist messages if needed, but ephemeral is fine for demo
  }

  // --- GOVERNANCE ---
  final _governanceLogs = BehaviorSubject<List<Map<String, dynamic>>>.seeded(
    [],
  );

  Stream<List<Map<String, dynamic>>> getGovernanceLogs(
    String scope,
    String refId,
  ) {
    if (_governanceLogs.value.isEmpty) {
      // Seed if empty
      _governanceLogs.add(MockData.governanceLogs);
    }
    return _governanceLogs.stream.map((logs) {
      return logs
          .where((l) => l['scope'] == scope && l['refId'] == refId)
          .toList();
    }).asBroadcastStream();
  }

  // Helpers
  Event _mapToEvent(Map<String, dynamic> data) {
    return Event(
      id: data['id'],
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      fullDescription: data['fullDescription'] ?? '',
      objectiveStatement: data['objectiveStatement'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      thematicVerseSummary: data['thematicVerseSummary'] ?? '',
      startDate: data['startDate'] is DateTime
          ? data['startDate']
          : DateTime.now(),
      endDate: data['endDate'] is DateTime ? data['endDate'] : DateTime.now(),
      visibility: EventVisibility.public,
      status: EventStatus.active,
      creatorId: data['creatorId'] ?? '',
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.now(),
    );
  }

  Room _mapToRoom(Map<String, dynamic> data) {
    return Room(
      id: data['id'],
      eventId: data['eventId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      roomType: _parseRoomType(data['roomType']),
      visibility: RoomVisibility.public,
      startDate: data['startDate'] is DateTime
          ? data['startDate']
          : DateTime.now(),
      endDate: data['endDate'] is DateTime ? data['endDate'] : DateTime.now(),
      status: RoomStatus.open,
      creatorId: data['creatorId'] ?? '',
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.now(),
    );
  }

  TaskType _parseTaskType(String? val) {
    switch (val) {
      case 'prayer':
        return TaskType.prayer;
      case 'silence':
        return TaskType.silence;
      case 'worship':
        return TaskType.worship;
      case 'rhema':
        return TaskType.rhema;
      case 'tell_me':
        return TaskType.tell_me;
      default:
        return TaskType.action;
    }
  }

  RoomType _parseRoomType(dynamic val) {
    if (val is RoomType) return val;
    final str = val?.toString().toLowerCase();
    switch (str) {
      case 'prayer_fasting':
      case 'prayer & fasting':
        return RoomType.prayer_fasting;
      case 'bible_study':
      case 'bible study':
        return RoomType.bible_study;
      case 'book_study':
      case 'book_reading':
      case 'book study':
        return RoomType.book_reading;
      case 'retreat':
      case 'spiritual retreat':
        return RoomType.retreat;
      default:
        return RoomType.prayer_fasting;
    }
  }
}
