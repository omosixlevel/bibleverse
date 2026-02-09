export interface DynamicText {
    ops: Array<{
        insert: string;
        attributes?: {
            bold?: boolean;
            italic?: boolean;
            link?: string;
            header?: number;
            [key: string]: any;
        };
    }>;
}

export type Visibility = 'public' | 'private';

export interface Timestamp {
    _seconds: number;
    _nanoseconds: number;
    toDate(): Date;
}
