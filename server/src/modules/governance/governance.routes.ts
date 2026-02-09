import { Router } from 'express';
import { GovernanceController } from './governance.controller';

const router = Router();
const governanceController = new GovernanceController();

router.post('/logs', governanceController.logAction);
router.get('/logs/:scope/:refId', governanceController.getLogsByRef);
router.get('/logs/user/:userId', governanceController.getLogsByUser);

export default router;
