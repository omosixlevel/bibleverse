import { TasksRepository } from './tasks.repository';
import { CreateTaskDto, UpdateTaskDto, Task, TASK_TYPES } from './tasks.interface';

const VALID_TASK_TYPES: readonly string[] = TASK_TYPES;

export class TasksService {
    private repository: TasksRepository;

    constructor() {
        this.repository = new TasksRepository();
    }

    async getTasks(roomId: string): Promise<Task[]> {
        return this.repository.findAllByRoom(roomId);
    }

    async getTask(roomId: string, taskId: string): Promise<Task | null> {
        return this.repository.findById(roomId, taskId);
    }

    async createTask(roomId: string, data: CreateTaskDto): Promise<Task> {
        if (!VALID_TASK_TYPES.includes(data.taskType)) {
            throw new Error(`Invalid task type: ${data.taskType}`);
        }
        // TODO: Gemini could generate tasks here
        return this.repository.create(roomId, data);
    }

    async updateTask(roomId: string, taskId: string, data: UpdateTaskDto): Promise<Task | null> {
        if (data.taskType && !VALID_TASK_TYPES.includes(data.taskType)) {
            throw new Error(`Invalid task type: ${data.taskType}`);
        }
        return this.repository.update(roomId, taskId, data);
    }

    async deleteTask(roomId: string, taskId: string): Promise<void> {
        await this.repository.delete(roomId, taskId);
    }
}
