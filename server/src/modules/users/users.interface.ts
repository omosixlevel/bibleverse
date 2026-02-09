import { DynamicText, Timestamp } from '../shared/common.interface';

export interface User {
    id: string; // Auth UID
    name: string;
    email: string;
    avatarUrl?: string;
    spiritualInterests: string[];

    // PRIVATE fields (should be guarded in repository/controller)
    disciplineScore: number;
    streakDays: number;

    createdAt: Date; // or Timestamp if raw from Firestore
    lastActiveAt: Date;
}

export interface UserNotebook {
    id: string;
    contentRichText: DynamicText;
    linkedVerses: string[];
    createdAt: Date;
    updatedAt: Date;
    synced: boolean;
}

export interface UserActivityLog {
    id: string;
    type: 'task_completed' | 'joined_room' | 'warned' | 'removed';
    refId: string;
    createdAt: Date;
}

export interface CreateUserDto {
    name: string;
    email: string;
    avatarUrl?: string;
    spiritualInterests?: string[];
}

export interface UpdateUserDto {
    name?: string;
    avatarUrl?: string;
    spiritualInterests?: string[];
    lastActiveAt?: Date;
    // Private fields updated via specific methods usually
    disciplineScore?: number;
    streakDays?: number;
}
