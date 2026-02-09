export interface TaskCompletion {
    id: string;
    taskId: string;
    roomId: string;
    userId: string;
    completedAt: Date;
    content?: string;
    isPublished: boolean;
}

export interface CreateTaskCompletionDto {
    taskId: string;
    roomId: string;
    userId: string;
    content?: string;
    isPublished?: boolean;
}

export type DisciplineResult = 'ok' | 'warning' | 'remove';
