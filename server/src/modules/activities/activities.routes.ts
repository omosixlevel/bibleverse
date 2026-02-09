import { Router } from 'express';
import { ActivitiesController } from './activities.controller';

const router = Router();
const activitiesController = new ActivitiesController();

router.post('/', activitiesController.create);
router.get('/event/:eventId', activitiesController.getByEvent);
router.get('/:id', activitiesController.getById);
router.put('/:id', activitiesController.update);
router.delete('/:id', activitiesController.delete);
router.post('/:id/attendance', activitiesController.confirmAttendance);
router.get('/:id/attendance', activitiesController.getAttendance);

export default router;
