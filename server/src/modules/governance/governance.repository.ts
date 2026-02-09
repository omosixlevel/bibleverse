import { firestore } from '../../config/firebase';
import { GovernanceLog, CreateGovernanceLogDto } from './governance.interface';

export class GovernanceRepository {
    private logsCollection = firestore.collection('governance_logs');

    private docToLog(doc: FirebaseFirestore.DocumentSnapshot): GovernanceLog | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            createdAt: data?.createdAt?.toDate(),
        } as GovernanceLog;
    }

    async create(data: CreateGovernanceLogDto): Promise<GovernanceLog> {
        const newLog: Partial<GovernanceLog> = {
            ...data,
            executedBy: 'gemini',
            createdAt: new Date(),
        };

        const docRef = await this.logsCollection.add(newLog);
        return { id: docRef.id, ...newLog } as GovernanceLog;
    }

    async findByRefId(scope: string, refId: string): Promise<GovernanceLog[]> {
        const snapshot = await this.logsCollection
            .where('scope', '==', scope)
            .where('refId', '==', refId)
            .orderBy('createdAt', 'desc')
            .get();

        return snapshot.docs.map(doc => this.docToLog(doc)!).filter(l => l !== null);
    }

    async findByTargetUser(userId: string): Promise<GovernanceLog[]> {
        const snapshot = await this.logsCollection
            .where('targetUserId', '==', userId)
            .orderBy('createdAt', 'desc')
            .get();

        return snapshot.docs.map(doc => this.docToLog(doc)!).filter(l => l !== null);
    }
}
