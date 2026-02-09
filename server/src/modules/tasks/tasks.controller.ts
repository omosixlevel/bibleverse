import { Request, Response, NextFunction } from 'express';
import { TasksService } from './tasks.service';

const tasksService = new TasksService();

export const getTasks = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId } = req.params;
        const tasks = await tasksService.getTasks(roomId);
        res.json({ success: true, data: tasks });
    } catch (error) {
        next(error);
    }
};

export const getTask = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId, taskId } = req.params;
        const task = await tasksService.getTask(roomId, taskId);
        if (!task) {
            res.status(404).json({ success: false, message: 'Task not found' });
            return;
        }
        res.json({ success: true, data: task });
    } catch (error) {
        next(error);
    }
};

export const createTask = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId } = req.params;
        const task = await tasksService.createTask(roomId, req.body);
        res.status(201).json({ success: true, data: task });
    } catch (error) {
        if ((error as Error).message.includes('Invalid task type')) {
            res.status(400).json({ success: false, message: (error as Error).message });
            return;
        }
        next(error);
    }
};

export const updateTask = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId, taskId } = req.params;
        const task = await tasksService.updateTask(roomId, taskId, req.body);
        if (!task) {
            res.status(404).json({ success: false, message: 'Task not found' });
            return;
        }
        res.json({ success: true, data: task });
    } catch (error) {
        if ((error as Error).message.includes('Invalid task type')) {
            res.status(400).json({ success: false, message: (error as Error).message });
            return;
        }
        next(error);
    }
};

export const deleteTask = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId, taskId } = req.params;
        await tasksService.deleteTask(roomId, taskId);
        res.json({ success: true, message: 'Task deleted' });
    } catch (error) {
        next(error);
    }
};
