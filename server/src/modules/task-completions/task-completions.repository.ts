import { firestore } from '../../config/firebase';
import { TaskProgress } from '../tasks/tasks.interface';

// Interface for create DTO matching TaskProgress but optional fields
interface CreateTaskProgressDto {
    userId: string;
    taskId: string;
    completed: boolean;
    responseRichText?: any;
    proofUrl?: string;
    published?: boolean;
}

export class TaskCompletionsRepository {
    // Collection access requires roomId, so methods need roomId

    // Helper to get collection ref
    private getCollection(roomId: string) {
        return firestore.collection('rooms').doc(roomId).collection('taskProgress');
    }

    private docToProgress(doc: FirebaseFirestore.DocumentSnapshot): TaskProgress | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            completedAt: data?.completedAt?.toDate()
        } as unknown as TaskProgress;
    }

    async findByUserAndRoom(userId: string, roomId: string): Promise<TaskProgress[]> {
        // Query pattern: complex if subcollection is per room.
        // We need to query this specific room's subcollection
        const snapshot = await this.getCollection(roomId)
            .where('userId', '==', userId)
            .get();
        return snapshot.docs.map(doc => this.docToProgress(doc)!).filter(c => c !== null);
    }

    async findByTaskAndUser(roomId: string, taskId: string, userId: string): Promise<TaskProgress | null> {
        // Composite ID: {userId}_{taskId}
        const id = `${userId}_${taskId}`;
        const doc = await this.getCollection(roomId).doc(id).get();
        return this.docToProgress(doc);
    }

    async createOrUpdate(roomId: string, data: CreateTaskProgressDto): Promise<TaskProgress> {
        // Composite ID: {userId}_{taskId}
        const id = `${data.userId}_${data.taskId}`;
        const collection = this.getCollection(roomId);

        const progressData = {
            ...data,
            completedAt: new Date(),
            published: data.published ?? false
        };

        await collection.doc(id).set(progressData, { merge: true });

        return { id, ...progressData } as unknown as TaskProgress;
    }

    async countCompletionsByUserInRoom(userId: string, roomId: string): Promise<number> {
        const snapshot = await this.getCollection(roomId)
            .where('userId', '==', userId)
            .where('completed', '==', true)
            .get();
        return snapshot.size;
    }
}
