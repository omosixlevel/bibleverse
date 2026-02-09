import 'package:flutter/material.dart';
import 'dart:async';

/// Participant info for call
class CallParticipant {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isMuted;
  final bool isSpeaking;
  final bool hasRaisedHand;
  final bool isAdmin;

  const CallParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isMuted = false,
    this.isSpeaking = false,
    this.hasRaisedHand = false,
    this.isAdmin = false,
  });

  CallParticipant copyWith({
    bool? isMuted,
    bool? isSpeaking,
    bool? hasRaisedHand,
  }) {
    return CallParticipant(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      hasRaisedHand: hasRaisedHand ?? this.hasRaisedHand,
      isAdmin: isAdmin,
    );
  }
}

/// Full-screen Call Overlay
class CallOverlay extends StatefulWidget {
  final String roomName;
  final List<CallParticipant> participants;
  final bool isCurrentUserMuted;
  final bool isCurrentUserAdmin;
  final int? speakingTimeLimit; // seconds
  final VoidCallback? onLeave;
  final VoidCallback? onToggleMute;
  final VoidCallback? onRaiseHand;
  final ValueChanged<String>? onMuteParticipant;
  final ValueChanged<String>? onRemoveParticipant;

  const CallOverlay({
    super.key,
    required this.roomName,
    required this.participants,
    this.isCurrentUserMuted = true,
    this.isCurrentUserAdmin = false,
    this.speakingTimeLimit,
    this.onLeave,
    this.onToggleMute,
    this.onRaiseHand,
    this.onMuteParticipant,
    this.onRemoveParticipant,
  });

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _speakingTimer;
  int _speakingSeconds = 0;
  bool _hasRaisedHand = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.speakingTimeLimit != null) {
      _startSpeakingTimer();
    }
  }

  void _startSpeakingTimer() {
    _speakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isCurrentUserMuted) {
        setState(() => _speakingSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speakingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speaker = widget.participants.where((p) => p.isSpeaking).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roomName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.participants.length} participants',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => _showLeaveConfirmation(context),
                  ),
                ],
              ),
            ),

            // Speaking Timer (if applicable)
            if (widget.speakingTimeLimit != null && !widget.isCurrentUserMuted)
              _buildSpeakingTimer(theme),

            // Circle Talking Indicator
            Expanded(
              flex: 2,
              child: Center(
                child: _buildCircleTalkingIndicator(theme, speaker),
              ),
            ),

            // Participant List
            Expanded(flex: 2, child: _buildParticipantList(theme)),

            // Control Bar
            _buildControlBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingTimer(ThemeData theme) {
    final remaining = (widget.speakingTimeLimit ?? 0) - _speakingSeconds;
    final isWarning = remaining <= 10;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isWarning ? Colors.red : Colors.white60,
          ),
          const SizedBox(width: 8),
          Text(
            '${remaining}s remaining',
            style: TextStyle(
              color: isWarning ? Colors.red : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleTalkingIndicator(
    ThemeData theme,
    CallParticipant? speaker,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: speaker != null
              ? _pulseAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: speaker != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    )
                  : null,
              color: speaker == null ? Colors.white.withOpacity(0.1) : null,
              boxShadow: speaker != null
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: speaker != null
                  ? Text(
                      speaker.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.mic_off, size: 48, color: Colors.white38),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          speaker?.name ?? 'No one speaking',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (speaker != null)
          Text(
            'Speaking...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants',
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: widget.participants.length,
              itemBuilder: (context, index) {
                final participant = widget.participants[index];
                return _buildParticipantTile(theme, participant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(ThemeData theme, CallParticipant participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: participant.isSpeaking
                    ? theme.colorScheme.primary
                    : Colors.white.withOpacity(0.1),
                child: Text(
                  participant.name[0].toUpperCase(),
                  style: TextStyle(
                    color: participant.isSpeaking
                        ? Colors.white
                        : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (participant.hasRaisedHand)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pan_tool,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      participant.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: participant.isSpeaking
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                    if (participant.isAdmin)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (participant.isSpeaking)
                  Text(
                    'Speaking',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            participant.isMuted ? Icons.mic_off : Icons.mic,
            size: 18,
            color: participant.isMuted ? Colors.red : Colors.green,
          ),
          if (widget.isCurrentUserAdmin && !participant.isAdmin) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white54,
                size: 18,
              ),
              onSelected: (value) {
                if (value == 'mute') {
                  widget.onMuteParticipant?.call(participant.id);
                }
                if (value == 'remove') {
                  widget.onRemoveParticipant?.call(participant.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'mute', child: Text('Toggle Mute')),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: widget.isCurrentUserMuted ? Icons.mic_off : Icons.mic,
            label: widget.isCurrentUserMuted ? 'Unmute' : 'Mute',
            isActive: !widget.isCurrentUserMuted,
            onTap: widget.onToggleMute,
          ),
          _buildControlButton(
            icon: Icons.pan_tool,
            label: 'Raise Hand',
            isActive: _hasRaisedHand,
            onTap: () {
              setState(() => _hasRaisedHand = !_hasRaisedHand);
              widget.onRaiseHand?.call();
            },
          ),
          _buildControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            isDestructive: true,
            onTap: () => _showLeaveConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red
                  : isActive
                  ? Colors.green
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Call?'),
        content: const Text('Are you sure you want to leave this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLeave?.call();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
