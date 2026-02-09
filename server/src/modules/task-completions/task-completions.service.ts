import { TaskCompletionsRepository } from './task-completions.repository';
// Use TaskProgress from tasks/tasks.interface
import { TaskProgress } from '../tasks/tasks.interface';
import { CreateTaskCompletionDto, DisciplineResult } from './task-completions.interface';
import { TasksRepository } from '../tasks/tasks.repository';

export class TaskCompletionsService {
    private repository: TaskCompletionsRepository;
    private tasksRepository: TasksRepository;

    constructor() {
        this.repository = new TaskCompletionsRepository();
        this.tasksRepository = new TasksRepository();
    }

    async completeTask(data: CreateTaskCompletionDto): Promise<TaskProgress> {
        // Check if already completed? Repo handles idempotent writes via composite ID now, 
        // but if we want to error on duplicate complete, we can check.
        const existing = await this.repository.findByTaskAndUser(data.roomId, data.taskId, data.userId);
        if (existing && existing.completed) {
            throw new Error('Task already completed');
        }

        // Map DTO
        return this.repository.createOrUpdate(data.roomId, {
            userId: data.userId,
            taskId: data.taskId,
            completed: true,
            responseRichText: data.content ? { ops: [{ insert: data.content }] } : undefined, // Simple text to RT conversion if needed
            published: data.isPublished
        });
    }

    async getCompletionsByUserInRoom(userId: string, roomId: string): Promise<TaskProgress[]> {
        return this.repository.findByUserAndRoom(userId, roomId);
    }

    async evaluateDiscipline(roomId: string, userId: string): Promise<DisciplineResult> {
        // Get all mandatory tasks in the room
        const allTasks = await this.tasksRepository.findAllByRoom(roomId);
        const mandatoryTasks = allTasks.filter(t => t.mandatory);

        // Get completions by user
        const completions = await this.repository.findByUserAndRoom(userId, roomId);
        const completedTaskIds = new Set(completions.filter(c => c.completed).map(c => c.taskId));

        // Count missed mandatory tasks
        let missedCount = 0;
        for (const task of mandatoryTasks) {
            if (!completedTaskIds.has(task.id)) {
                missedCount++;
            }
        }

        // TODO: Gemini governance could refine these thresholds
        if (missedCount >= 5) {
            return 'remove';
        } else if (missedCount >= 3) {
            return 'warning';
        }
        return 'ok';
    }
}
