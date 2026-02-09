import { Request, Response, NextFunction } from 'express';
import { TaskCompletionsService } from './task-completions.service';

const service = new TaskCompletionsService();

export const completeTask = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { taskId } = req.params;
        const { userId, roomId, content, isPublished } = req.body;

        if (!userId || !roomId) {
            res.status(400).json({ success: false, message: 'userId and roomId are required' });
            return;
        }

        const completion = await service.completeTask({
            taskId,
            roomId,
            userId,
            content,
            isPublished
        });

        res.status(201).json({ success: true, data: completion });
    } catch (error) {
        if ((error as Error).message === 'Task already completed') {
            res.status(400).json({ success: false, message: 'Task already completed' });
            return;
        }
        next(error);
    }
};

export const getCompletions = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId, userId } = req.params;
        const completions = await service.getCompletionsByUserInRoom(userId, roomId);
        res.json({ success: true, data: completions });
    } catch (error) {
        next(error);
    }
};

export const checkDiscipline = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { roomId, userId } = req.params;
        const result = await service.evaluateDiscipline(roomId, userId);
        res.json({ success: true, data: { status: result } });
    } catch (error) {
        next(error);
    }
};
