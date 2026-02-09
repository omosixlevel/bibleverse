import { DynamicText } from '../shared/common.interface';

export type ChatType = 'direct' | 'room' | 'event';

export interface Chat {
    id: string;
    type: ChatType;
    refId: string; // ID of the Room/Event (if applicable)
    createdAt: Date;
}

export interface ChatMessage {
    id: string;
    chatId: string; // Optional if only subcollection
    senderId: string;
    contentRichText: DynamicText;
    attachedVerse?: {
        book: string;
        chapter: number;
        verse: number;
        text?: string;
    };
    attachedRoomId?: string;
    attachedEventId?: string;
    createdAt: Date;
}

export interface CreateChatDto {
    type: ChatType;
    refId: string;
}

export interface CreateMessageDto {
    senderId: string;
    contentRichText: DynamicText;
    attachedVerse?: {
        book: string;
        chapter: number;
        verse: number;
        text?: string;
    };
    attachedRoomId?: string;
    attachedEventId?: string;
}
