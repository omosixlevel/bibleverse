import { DynamicText } from '../shared/common.interface';

export const TASK_TYPES = ['tell_me', 'prayer', 'rhema', 'action', 'silence', 'worship'] as const;
export type TaskType = (typeof TASK_TYPES)[number];
export type TaskStatus = 'active' | 'archived';

export interface Task {
    id: string;
    // roomId is in the path: rooms/{roomId}/tasks/{taskId}
    // but might be useful to keep if querying broadly, though schema implies strict subcollection.
    // Keeping it optional or removing if strictly subcollection. Schema doesn't list it in fields table.
    // Field list: id, title, description, taskType, dayIndex, deadline, mandatory, createdBy, status, createdAt.
    title: string;
    description: string;
    taskType: TaskType;
    dayIndex: number;
    deadline?: Date;
    mandatory: boolean;
    createdBy: 'user' | 'gemini' | string; // 'string' allowing specific user IDs too? Schema says 'user | gemini'. But usually createdBy is a userId.
    // Schema says "createdBy: user | gemini". If it means ROLE, then it's different.
    // But usually this field is an ID. If "gemini" is a specific reserved ID, then string is fine.
    // Let's assume it's the ID string, or 'gemini' literal.
    status: TaskStatus;
    createdAt: Date;
}

export interface TaskProgress {
    // Composite ID: {userId}_{taskId}
    id: string;
    userId: string;
    taskId: string;
    completed: boolean;
    completedAt: Date;
    responseRichText?: DynamicText;
    proofUrl?: string;
    published: boolean;
}

export interface CreateTaskDto {
    title: string;
    description: string;
    taskType: TaskType;
    dayIndex: number;
    deadline?: string; // ISO
    mandatory: boolean;
    createdBy: string;
}

export interface UpdateTaskDto {
    title?: string;
    description?: string;
    taskType?: TaskType;
    dayIndex?: number;
    deadline?: string;
    mandatory?: boolean;
    status?: TaskStatus;
}
