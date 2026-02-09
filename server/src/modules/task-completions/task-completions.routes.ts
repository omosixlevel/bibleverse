import { Router } from 'express';
import * as controller from './task-completions.controller';

const router = Router();

// POST /tasks/:taskId/complete
router.post('/tasks/:taskId/complete', controller.completeTask);

// GET /rooms/:roomId/completions/:userId
router.get('/rooms/:roomId/completions/:userId', controller.getCompletions);

// GET /rooms/:roomId/discipline/:userId (optional helper)
router.get('/rooms/:roomId/discipline/:userId', controller.checkDiscipline);

export default router;
