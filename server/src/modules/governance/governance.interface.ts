export type GovernanceScope = 'room' | 'task' | 'call';
export type GovernanceAction = 'warn_user' | 'remove_user' | 'suggest_task' | 'summarize_call';

export interface GovernanceLog {
    id: string;
    scope: GovernanceScope;
    refId: string; // Target ID
    action: GovernanceAction;
    executedBy: 'gemini'; // Constant
    targetUserId?: string; // If action targets a specific user
    createdAt: Date; // Log time
}

export interface CreateGovernanceLogDto {
    scope: GovernanceScope;
    refId: string;
    action: GovernanceAction;
    targetUserId?: string;
}
