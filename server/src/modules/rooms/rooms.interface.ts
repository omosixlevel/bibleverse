export type RoomType = 'prayer' | 'reading' | 'retreat' | 'bible_study';
export type RoomStatus = 'open' | 'closed' | 'archived';

export interface Room {
    id: string;
    title: string;
    description: string;
    roomType: RoomType;
    visibility: 'public' | 'private';
    eventId?: string; // Optional link to parent Event
    startDate: Date;
    endDate: Date;
    status: RoomStatus;
    creatorId: string; // Admin User ID
    createdAt: Date;
}

export interface RoomCovenant {
    id: string;
    text: string;
    version: number;
    createdAt: Date;
}

export interface RoomParticipant {
    userId: string;
    role: 'admin' | 'member';
    joinedAt: Date;
    missedTasksCount: number;
    missedMeetingsCount: number;
    state: 'active' | 'warned' | 'removed';
}

export interface RoomSchedule {
    id: string;
    title: string;
    startDateTime: Date;
    durationMinutes: number;
    mandatory: boolean;
}

export interface CreateRoomDto {
    title: string;
    description: string;
    roomType: RoomType;
    visibility?: 'public' | 'private';
    eventId?: string;
    startDate: string; // ISO Date
    endDate: string; // ISO Date
    creatorId: string;
}

export interface UpdateRoomDto {
    title?: string;
    description?: string;
    // covenant updated via subcollection
    status?: RoomStatus;
}
