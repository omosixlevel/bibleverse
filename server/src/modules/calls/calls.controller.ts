import { Request, Response, NextFunction } from 'express';
import { CallsService } from './calls.service';

const callsService = new CallsService();

export const createCall = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const call = await callsService.createCall(req.body);
        res.status(201).json({ success: true, data: call });
    } catch (error) {
        next(error);
    }
};

export const joinCall = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;
        if (!userId) {
            res.status(400).json({ success: false, message: 'userId required' });
            return;
        }
        await callsService.joinCall(id, userId);
        res.json({ success: true, message: 'Joined call' });
    } catch (error) {
        next(error);
    }
};

export const leaveCall = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;
        await callsService.leaveCall(id, userId);
        res.json({ success: true, message: 'Left call' });
    } catch (error) {
        next(error);
    }
};

export const raiseHand = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;
        await callsService.raiseHand(id, userId);
        res.json({ success: true, message: 'Hand raised' });
    } catch (error) {
        next(error);
    }
};

export const startCircleTalking = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { requesterId } = req.body;
        const call = await callsService.startCircleTalking(id, requesterId);
        res.json({ success: true, data: call });
    } catch (error) {
        if ((error as Error).message.includes('Only admin')) {
            res.status(403).json({ success: false, message: (error as Error).message });
            return;
        }
        next(error);
    }
};

export const nextSpeaker = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { requesterId } = req.body;
        const call = await callsService.nextSpeaker(id, requesterId);
        res.json({ success: true, data: call });
    } catch (error) {
        if ((error as Error).message.includes('Only admin')) {
            res.status(403).json({ success: false, message: (error as Error).message });
            return;
        }
        next(error);
    }
};
export const endCall = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { requesterId } = req.body;
        const call = await callsService.endCall(id, requesterId);
        res.json({ success: true, data: call });
    } catch (error) {
        if ((error as Error).message.includes('Only admin')) {
            res.status(403).json({ success: false, message: (error as Error).message });
            return;
        }
        next(error);
    }
};
