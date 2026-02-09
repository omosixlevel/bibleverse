import { Router } from 'express';
import * as eventsController from './events.controller';

const router = Router();

router.post('/', eventsController.createEvent);
router.get('/', eventsController.getEvents);
router.get('/:id', eventsController.getEvent);
router.patch('/:id', eventsController.updateEvent);
router.delete('/:id', eventsController.deleteEvent);

export default router;
