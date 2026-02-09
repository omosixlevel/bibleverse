import { Request, Response, NextFunction } from 'express';
import { RoomsService } from './rooms.service';

const roomsService = new RoomsService();

export const getRooms = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const rooms = await roomsService.getRooms();
        res.json({ success: true, data: rooms });
    } catch (error) {
        next(error);
    }
};

export const getRoom = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const room = await roomsService.getRoom(req.params.id);
        if (!room) {
            res.status(404).json({ success: false, message: 'Room not found' });
            return;
        }
        res.json({ success: true, data: room });
    } catch (error) {
        next(error);
    }
};

export const createRoom = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const room = await roomsService.createRoom(req.body);
        res.status(201).json({ success: true, data: room });
    } catch (error) {
        next(error);
    }
};

export const updateRoom = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const room = await roomsService.updateRoom(req.params.id, req.body);
        if (!room) {
            res.status(404).json({ success: false, message: 'Room not found' });
            return;
        }
        res.json({ success: true, data: room });
    } catch (error) {
        next(error);
    }
};

export const joinRoom = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId, acceptedCovenant } = req.body;
        if (!userId) {
            res.status(400).json({ success: false, message: 'User ID required' });
            return;
        }
        await roomsService.joinRoom(req.params.id, userId, acceptedCovenant);
        res.json({ success: true, message: 'Joined room successfully' });
    } catch (error) {
        if ((error as Error).message === 'Must accept covenant') {
            res.status(400).json({ success: false, message: 'Must accept covenant' });
            return;
        }
        next(error);
    }
};

export const leaveRoom = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { userId } = req.body;
        if (!userId) {
            res.status(400).json({ success: false, message: 'User ID required' });
            return;
        }
        await roomsService.leaveRoom(req.params.id, userId);
        res.json({ success: true, message: 'Left room successfully' });
    } catch (error) {
        next(error);
    }
};
