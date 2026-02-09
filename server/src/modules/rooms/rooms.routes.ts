import { Router } from 'express';
import * as roomsController from './rooms.controller';

const router = Router();

router.get('/', roomsController.getRooms);
router.post('/', roomsController.createRoom);
router.get('/:id', roomsController.getRoom);
router.patch('/:id', roomsController.updateRoom);
router.post('/:id/join', roomsController.joinRoom);
router.post('/:id/leave', roomsController.leaveRoom);

export default router;
