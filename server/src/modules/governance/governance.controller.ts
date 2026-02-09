import { Request, Response } from 'express';
import { GovernanceService } from './governance.service';
import { CreateGovernanceLogDto } from './governance.interface';

export class GovernanceController {
    private governanceService = new GovernanceService();

    logAction = async (req: Request, res: Response) => {
        try {
            const data: CreateGovernanceLogDto = req.body;
            const log = await this.governanceService.logAction(data);
            res.status(201).json(log);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getLogsByRef = async (req: Request, res: Response) => {
        try {
            const { scope, refId } = req.params;
            const logs = await this.governanceService.getLogsByRef(scope, refId);
            res.status(200).json(logs);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getLogsByUser = async (req: Request, res: Response) => {
        try {
            const logs = await this.governanceService.getLogsByTargetUser(req.params.userId);
            res.status(200).json(logs);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };
}
