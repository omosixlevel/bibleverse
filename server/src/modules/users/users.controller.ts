import { Request, Response, NextFunction } from 'express';
import { UsersService } from './users.service';

const userService = new UsersService();

export const getUser = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const user = await userService.getUser(id);

        if (!user) {
            res.status(404).json({
                success: false,
                message: 'User not found'
            });
            return;
        }

        res.json({ success: true, data: user });
    } catch (error) {
        next(error);
    }
};

export const createUser = async (req: Request, res: Response, next: NextFunction) => {
    try {
        // In a real scenario, ID would come from Auth token middleware usually
        // For now, we expect it in body or query, but typically:
        // const id = req.user.uid;
        // However, requirements say POST /users (create user profile after auth)
        // Let's assume the client sends the ID or we extract it. 
        // Typically extracting from token is best, but "No authentication middleware yet" means 
        // we might pass it in body for now? Or assume the param is available?
        // Standard practice for "create profile" is often POST /users with body { ...profile } using Auth token UID.
        // But without auth middleware, I'll require `id` in the body for testing purposes.

        const { id, email, name, avatarUrl, spiritualInterests } = req.body;

        if (!id || !email || !name) {
            res.status(400).json({
                success: false,
                message: 'Missing required fields: id, email, name'
            });
            return;
        }

        const user = await userService.createUser(id, {
            email,
            name,
            avatarUrl,
            spiritualInterests
        });

        res.status(201).json({ success: true, data: user });
    } catch (error) {
        next(error);
    }
};

export const updateUser = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { name, avatarUrl, spiritualInterests } = req.body;

        const updatedUser = await userService.updateUser(id, {
            name,
            avatarUrl,
            spiritualInterests
        });

        if (!updatedUser) {
            res.status(404).json({
                success: false,
                message: 'User not found'
            });
            return;
        }

        res.json({ success: true, data: updatedUser });
    } catch (error) {
        next(error);
    }
};
