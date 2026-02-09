import { Request, Response } from 'express';
import { ActivitiesService } from './activities.service';
import { CreateActivityDto, UpdateActivityDto } from './activities.interface';

export class ActivitiesController {
    private activitiesService = new ActivitiesService();

    create = async (req: Request, res: Response) => {
        try {
            const data: CreateActivityDto = req.body;
            const activity = await this.activitiesService.createActivity(data);
            res.status(201).json(activity);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getByEvent = async (req: Request, res: Response) => {
        try {
            const activities = await this.activitiesService.getActivitiesByEvent(req.params.eventId);
            res.status(200).json(activities);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getById = async (req: Request, res: Response) => {
        try {
            const activity = await this.activitiesService.getActivityById(req.params.id);
            if (!activity) return res.status(404).json({ error: 'Activity not found' });
            res.status(200).json(activity);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    update = async (req: Request, res: Response) => {
        try {
            const activity = await this.activitiesService.updateActivity(req.params.id, req.body);
            if (!activity) return res.status(404).json({ error: 'Activity not found' });
            res.status(200).json(activity);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    delete = async (req: Request, res: Response) => {
        try {
            await this.activitiesService.deleteActivity(req.params.id);
            res.status(204).send();
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    confirmAttendance = async (req: Request, res: Response) => {
        try {
            const { userId, confirmed } = req.body;
            await this.activitiesService.confirmAttendance(req.params.id, userId, confirmed);
            res.status(200).send();
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getAttendance = async (req: Request, res: Response) => {
        try {
            const attendance = await this.activitiesService.getActivityAttendance(req.params.id);
            res.status(200).json(attendance);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };
}
