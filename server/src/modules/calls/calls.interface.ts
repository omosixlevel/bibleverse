export type CallScope = 'room' | 'event';
export type CallMode = 'audio' | 'video';
export type CallStatus = 'active' | 'ended';

export interface Call {
    id: string;
    scope: CallScope;
    refId: string; // Target ID (room or event)
    mode: CallMode;
    status: CallStatus;
    circleTalkingEnabled: boolean; // If true, enforces speaking order
    currentSpeakerId?: string; // ID of user currently speaking
    speakerStartTime?: Date; // When the current speaker started
    startedBy: string; // User who started the call (admin)
    createdAt: Date;
    endedAt?: Date;
    moderatorMessage?: string;
}

export interface CallParticipant {
    userId: string;
    muted: boolean;
    handRaised: boolean;
    speakingOrder?: number; // For circle mode
    speakingTimeSeconds?: number; // Stats
}

export interface CreateCallDto {
    scope: CallScope;
    refId: string;
    mode: CallMode;
    startedBy: string; // Added startedBy
    circleTalkingEnabled: boolean;
}

export interface UpdateCallDto {
    status?: CallStatus;
    circleTalkingEnabled?: boolean;
}
