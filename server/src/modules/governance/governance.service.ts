import { GovernanceRepository } from './governance.repository';
import { CreateGovernanceLogDto, GovernanceLog } from './governance.interface';

export class GovernanceService {
    private governanceRepository = new GovernanceRepository();

    async logAction(data: CreateGovernanceLogDto): Promise<GovernanceLog> {
        return this.governanceRepository.create(data);
    }

    async getLogsByRef(scope: string, refId: string): Promise<GovernanceLog[]> {
        return this.governanceRepository.findByRefId(scope, refId);
    }

    async getLogsByTargetUser(userId: string): Promise<GovernanceLog[]> {
        return this.governanceRepository.findByTargetUser(userId);
    }
}
