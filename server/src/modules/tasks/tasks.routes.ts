import { Router } from 'express';
import * as tasksController from './tasks.controller';

const router = Router({ mergeParams: true });

router.get('/', tasksController.getTasks);
router.post('/', tasksController.createTask);
router.get('/:taskId', tasksController.getTask);
router.patch('/:taskId', tasksController.updateTask);
router.delete('/:taskId', tasksController.deleteTask);

export default router;
