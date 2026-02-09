import { CallsRepository } from './calls.repository';
import { CreateCallDto, Call, CallParticipant } from './calls.interface';

import { GeminiService } from '../shared/gemini.service';

export class CallsService {
    private repository: CallsRepository;
    private geminiService: GeminiService;

    constructor() {
        this.repository = new CallsRepository();
        this.geminiService = new GeminiService();
    }

    async createCall(data: CreateCallDto): Promise<Call> {
        return this.repository.create(data);
    }

    async getCall(id: string): Promise<Call | null> {
        return this.repository.findById(id);
    }

    async joinCall(callId: string, userId: string): Promise<void> {
        const call = await this.repository.findById(callId);
        if (!call || call.status !== 'active') {
            throw new Error('Call not found or ended');
        }
        await this.repository.addParticipant(callId, userId);
    }

    async leaveCall(callId: string, userId: string): Promise<void> {
        await this.repository.removeParticipant(callId, userId);
    }

    async raiseHand(callId: string, userId: string): Promise<void> {
        await this.repository.updateParticipant(callId, userId, { handRaised: true });
    }

    async startCircleTalking(callId: string, requesterId: string): Promise<Call> {
        const call = await this.repository.findById(callId);
        if (!call) throw new Error('Call not found');

        const participants = await this.repository.getParticipants(callId);
        if (participants.length === 0) throw new Error('No participants to start circle');

        // Assign speaking order
        for (let i = 0; i < participants.length; i++) {
            await this.repository.updateParticipant(callId, participants[i].userId, {
                speakingOrder: i,
                muted: true,
                handRaised: false
            });
        }

        // Set first speaker
        const firstSpeakerId = participants[0].userId;
        await this.repository.updateParticipant(callId, firstSpeakerId, { muted: false });

        // Generate AI Message
        const message = await this.geminiService.generateModeratorMessage(
            'start',
            null,
            firstSpeakerId
        );

        return (await this.repository.update(callId, {
            circleTalkingEnabled: true,
            currentSpeakerId: firstSpeakerId,
            speakerStartTime: new Date(),
            moderatorMessage: message,
        }))!;
    }

    async nextSpeaker(callId: string, requesterId: string): Promise<Call> {
        const call = await this.repository.findById(callId);
        if (!call) throw new Error('Call not found');
        if (!call.circleTalkingEnabled || !call.currentSpeakerId) {
            throw new Error('Circle talking not active');
        }

        const participants = await this.repository.getParticipants(callId);
        const sorted = [...participants].sort((a, b) =>
            (a.speakingOrder ?? 0) - (b.speakingOrder ?? 0) || a.userId.localeCompare(b.userId)
        );

        const currentIndex = sorted.findIndex(p => p.userId === call.currentSpeakerId);
        const nextIndex = (currentIndex + 1) % sorted.length;
        const nextSpeakerId = sorted[nextIndex].userId;

        // Mute current
        await this.repository.updateParticipant(callId, call.currentSpeakerId, { muted: true });

        // Unmute next
        await this.repository.updateParticipant(callId, nextSpeakerId, {
            muted: false,
            handRaised: false
        });

        // Generate AI Message
        const message = await this.geminiService.generateModeratorMessage(
            'next',
            call.currentSpeakerId,
            nextSpeakerId
        );

        return (await this.repository.update(callId, {
            currentSpeakerId: nextSpeakerId,
            speakerStartTime: new Date(),
            moderatorMessage: message,
        }))!;
    }

    async endCall(callId: string, requesterId: string): Promise<Call> {
        const call = await this.repository.findById(callId);
        if (!call) throw new Error('Call not found');

        return (await this.repository.update(callId, {
            status: 'ended',
            circleTalkingEnabled: false,
            endedAt: new Date()
        }))!;
    }
}
