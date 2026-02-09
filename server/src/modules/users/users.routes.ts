import { Router } from 'express';
import * as userController from './users.controller';

const router = Router();

// POST /users - Create new user
router.post('/', userController.createUser);

// GET /users/:id - Get user by ID
router.get('/:id', userController.getUser);

// PATCH /users/:id - Update user
router.patch('/:id', userController.updateUser);

export default router;
