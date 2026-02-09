import { Request, Response, NextFunction } from 'express';
import { EventsService } from './events.service';

const eventsService = new EventsService();

export const getEvents = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const filters = {
            creatorId: req.query.creatorId as string,
            visibility: req.query.visibility as string
        };
        const events = await eventsService.getEvents(filters);
        res.json({ success: true, data: events });
    } catch (error) {
        next(error);
    }
};

export const getEvent = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const event = await eventsService.getEvent(req.params.id);
        if (!event) {
            res.status(404).json({ success: false, message: 'Event not found' });
            return;
        }
        res.json({ success: true, data: event });
    } catch (error) {
        next(error);
    }
};

export const createEvent = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await eventsService.createEvent(req.body);
        res.status(201).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

export const updateEvent = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.body.requesterId; // Temporary until Auth Middleware
        if (!userId) {
            res.status(400).json({ success: false, message: 'Requester ID required' });
            return;
        }
        const result = await eventsService.updateEvent(req.params.id, userId, req.body);
        if (!result) {
            res.status(404).json({ success: false, message: 'Event not found or unauthorized' });
            return;
        }
        res.json({ success: true, data: result });
    } catch (error) {
        if ((error as Error).message === 'Unauthorized') {
            res.status(403).json({ success: false, message: 'Unauthorized' });
            return;
        }
        next(error);
    }
};

export const deleteEvent = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = req.body.requesterId; // Temporary
        if (!userId) {
            res.status(400).json({ success: false, message: 'Requester ID required' });
            return;
        }
        await eventsService.deleteEvent(req.params.id, userId);
        res.json({ success: true, message: 'Event deleted' });
    } catch (error) {
        if ((error as Error).message === 'Unauthorized') {
            res.status(403).json({ success: false, message: 'Unauthorized' });
            return;
        }
        if ((error as Error).message.includes('Cannot delete')) {
            res.status(400).json({ success: false, message: (error as Error).message });
            return;
        }
        next(error);
    }
};
