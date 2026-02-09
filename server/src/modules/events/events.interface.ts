import { DynamicText } from '../shared/common.interface';

export type EventStatus = 'draft' | 'active' | 'closed' | 'archived';

export interface Event {
    id: string;
    title: string;
    shortDescription: string;
    fullDescription: string;
    objectiveStatement: string; // MANDATORY
    coverImageUrl?: string;
    thematicVerseSummary: string;
    startDate: Date;
    endDate: Date;
    visibility: 'public' | 'private';
    status: EventStatus;
    creatorId: string;
    createdAt: Date;
}

export interface EventParticipant {
    userId: string;
    role: 'admin' | 'participant';
    joinedAt: Date;
}

export interface EventAnnouncement {
    id: string;
    title: string;
    contentRichText: DynamicText;
    createdAt: Date;
}

export interface CreateEventDto {
    title: string;
    shortDescription: string;
    fullDescription: string;
    objectiveStatement: string;
    coverImageUrl?: string;
    thematicVerseSummary: string;
    startDate: string; // ISO Date
    endDate: string; // ISO Date
    visibility?: 'public' | 'private';
    status?: EventStatus;
    creatorId: string;
}

export interface UpdateEventDto {
    title?: string;
    shortDescription?: string;
    fullDescription?: string;
    objectiveStatement?: string;
    coverImageUrl?: string;
    thematicVerseSummary?: string;
    startDate?: string;
    endDate?: string;
    visibility?: 'public' | 'private';
    status?: EventStatus;
}
