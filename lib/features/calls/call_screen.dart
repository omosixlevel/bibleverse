import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/gemini_service.dart';
import '../../models/call_model.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String roomName;
  final bool isAdmin;
  final String userId;

  const CallScreen({
    super.key,
    required this.callId,
    required this.userId,
    this.roomName = 'Morning Prayer Room',
    this.isAdmin = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = true;
  bool _hasRaisedHand = false;
  Timer? _uiUpdateTimer;
  final _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _handleStartCircle(FirestoreService firestoreService) async {
    // Generate AI Message First
    final message = await _geminiService.generateModeratorMessage(
      action: 'start',
      nextSpeakerId: widget.userId, // Admin usually starts or first in list
      // Ideally we should know who is first, but keep it simple
    );

    await firestoreService.startCircleTalking(
      widget.callId,
      widget.userId,
      moderatorMessage: message,
    );
  }

  Future<void> _handleNextSpeaker(
    FirestoreService firestoreService,
    Call call,
  ) async {
    if (call.currentSpeakerId == null) return;

    final message = await _geminiService.generateModeratorMessage(
      action: 'next',
      currentSpeakerId: call.currentSpeakerId!,
      nextSpeakerId: "the next speaker", // Placeholder
    );

    await firestoreService.nextSpeaker(
      widget.callId,
      call.currentSpeakerId!,
      moderatorMessage: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<Map<String, dynamic>?>(
      stream: firestoreService.getCall(widget.callId),
      builder: (context, callSnapshot) {
        if (!callSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final callMap = callSnapshot.data!;
        final call = Call.fromMap({'id': widget.callId, ...callMap});

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestoreService.getCallParticipants(widget.callId),
          builder: (context, participantsSnapshot) {
            final participantsMaps = participantsSnapshot.data ?? [];
            final participants = participantsMaps
                .map((m) => CallParticipant.fromMap(m))
                .toList();

            // Automatic Mute Sync
            final me = participants
                .where((p) => p.userId == widget.userId)
                .firstOrNull;
            if (me != null && me.muted != _isMuted) {
              _isMuted = me.muted;
            }

            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: AppBar(
                title: Column(
                  children: [
                    Text(widget.roomName, style: theme.textTheme.titleMedium),
                    Text(
                      'ACTIVE CALL',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [if (widget.isAdmin) _buildAdminBadge(theme)],
              ),
              body: Column(
                children: [
                  if (call.moderatorMessage != null)
                    _buildGeminiBanner(theme, call.moderatorMessage!),

                  if (call.circleTalkingEnabled)
                    _buildCircleTalkingHeader(theme, call, participants),

                  Expanded(
                    child: _buildParticipantsList(theme, participants, call),
                  ),

                  if (widget.isAdmin && call.circleTalkingEnabled)
                    _buildAdminControls(theme, firestoreService, call),

                  _buildMainControls(context, theme, firestoreService, call),

                  _buildEndCallButton(context, theme, firestoreService),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminBadge(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Admin',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildGeminiBanner(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleTalkingHeader(
    ThemeData theme,
    Call call,
    List<CallParticipant> participants,
  ) {
    final currentSpeaker = participants
        .where((p) => p.userId == call.currentSpeakerId)
        .firstOrNull;

    int remainingSeconds = 0;
    if (call.speakerStartTime != null) {
      final elapsed = DateTime.now().difference(call.speakerStartTime!);
      remainingSeconds = 120 - elapsed.inSeconds;
      if (remainingSeconds < 0) remainingSeconds = 0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.record_voice_over,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Circle Talking Mode', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (currentSpeaker != null)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Text(currentSpeaker.userId[0].toUpperCase()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Speaking: ${currentSpeaker.userId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildTimerDisplay(theme, remainingSeconds),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(ThemeData theme, int seconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: seconds < 10
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: seconds < 10
              ? theme.colorScheme.error
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildParticipantsList(
    ThemeData theme,
    List<CallParticipant> participants,
    Call call,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final p = participants[index];
        final isSpeaking =
            call.circleTalkingEnabled && p.userId == call.currentSpeakerId;

        return Card(
          color: isSpeaking ? theme.colorScheme.primaryContainer : null,
          child: ListTile(
            leading: CircleAvatar(child: Text(p.userId[0].toUpperCase())),
            title: Text(p.userId == widget.userId ? 'You' : p.userId),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.muted)
                  Icon(
                    Icons.mic_off,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                if (p.handRaised)
                  Icon(
                    Icons.back_hand,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminControls(
    ThemeData theme,
    FirestoreService firestoreService,
    Call call,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _handleNextSpeaker(firestoreService, call),
            icon: const Icon(Icons.skip_next),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(
    BuildContext context,
    ThemeData theme,
    FirestoreService firestoreService,
    Call call,
  ) {
    final isMyTurn =
        call.circleTalkingEnabled && call.currentSpeakerId == widget.userId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            isActive: !_isMuted,
            onPressed: () async {
              await firestoreService.toggleMute(
                widget.callId,
                widget.userId,
                _isMuted,
              );
              // Optimistic UI update handled by stream
            },
          ),
          _buildControlButton(
            icon: Icons.back_hand,
            label: 'Raise Hand',
            isActive: _hasRaisedHand,
            onPressed: () async {
              setState(() => _hasRaisedHand = !_hasRaisedHand);
              await firestoreService.raiseHand(
                widget.callId,
                widget.userId,
                !_hasRaisedHand,
              );
            },
          ),
          if (widget.isAdmin && !call.circleTalkingEnabled)
            _buildControlButton(
              icon: Icons.record_voice_over,
              label: 'Start Circle',
              onPressed: () => _handleStartCircle(firestoreService),
            ),
          if (isMyTurn)
            _buildControlButton(
              icon: Icons.check_circle,
              label: 'Finish',
              isActive: true,
              onPressed: () => _handleNextSpeaker(firestoreService, call),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: isActive ? Colors.blue : Colors.grey[200],
            foregroundColor: isActive ? Colors.white : Colors.black,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildEndCallButton(
    BuildContext context,
    ThemeData theme,
    FirestoreService s,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            s.leaveCall(widget.callId, widget.userId);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.call_end),
          label: const Text('End Call'),
        ),
      ),
    );
  }
}
