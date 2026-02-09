export type ActivityType = 'donation' | 'evangelism' | 'meeting' | 'service';
export type CostType = 'free' | 'paid';

export interface Activity {
    id: string;
    eventId: string; // Link to Event
    title: string;
    description: string;
    activityType: ActivityType;
    locationName: string;
    mapLink: string;
    startDateTime: Date;
    endDateTime: Date;
    costType: CostType;
    price?: number;
    flyerUrl?: string; // Image URL
    organizerContact: string; // Phone/Email
    createdAt: Date;
}

export interface ActivityAttendance {
    userId: string;
    confirmed: boolean; // RSVP
    attended?: boolean; // Marked after event
}

export interface CreateActivityDto {
    eventId: string;
    title: string;
    description: string;
    activityType: ActivityType;
    locationName: string;
    mapLink: string;
    startDateTime: string; // ISO
    endDateTime: string; // ISO
    costType: CostType;
    price?: number;
    flyerUrl?: string;
    organizerContact: string;
}

export interface UpdateActivityDto {
    title?: string;
    description?: string;
    activityType?: ActivityType;
    locationName?: string;
    mapLink?: string;
    startDateTime?: string;
    endDateTime?: string;
    costType?: CostType;
    price?: number;
    flyerUrl?: string;
    organizerContact?: string;
}
