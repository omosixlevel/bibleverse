import { Router } from 'express';
import * as callsController from './calls.controller';

const router = Router();

router.post('/', callsController.createCall);
router.post('/:id/join', callsController.joinCall);
router.post('/:id/leave', callsController.leaveCall);
router.post('/:id/raise-hand', callsController.raiseHand);
router.post('/:id/circle-talking/start', callsController.startCircleTalking);
router.post('/:id/circle-talking/next', callsController.nextSpeaker);
router.post('/:id/end', callsController.endCall);

export default router;
