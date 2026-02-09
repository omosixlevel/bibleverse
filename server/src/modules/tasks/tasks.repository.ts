import { firestore } from '../../config/firebase';
import { Task, CreateTaskDto, UpdateTaskDto } from './tasks.interface';

export class TasksRepository {
    private getRoomTasksCollection(roomId: string) {
        return firestore.collection('rooms').doc(roomId).collection('tasks');
    }

    private docToTask(doc: FirebaseFirestore.DocumentSnapshot): Task | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            // roomId not in interface anymore
            ...data,
            createdAt: data?.createdAt?.toDate(),
            // updatedAt removed from interface
        } as unknown as Task;
    }

    async findAllByRoom(roomId: string): Promise<Task[]> {
        const snapshot = await this.getRoomTasksCollection(roomId).orderBy('dayIndex').get();
        return snapshot.docs.map(doc => this.docToTask(doc)!).filter(t => t !== null);
    }

    async findById(roomId: string, taskId: string): Promise<Task | null> {
        const doc = await this.getRoomTasksCollection(roomId).doc(taskId).get();
        return this.docToTask(doc);
    }

    async create(roomId: string, data: CreateTaskDto): Promise<Task> {
        const now = new Date();
        const newTask = {
            ...data,
            mandatory: data.mandatory ?? false,
            status: 'active',
            createdAt: now,
        };

        const docRef = await this.getRoomTasksCollection(roomId).add(newTask);
        return { id: docRef.id, ...newTask } as unknown as Task;
    }

    async update(roomId: string, taskId: string, data: UpdateTaskDto): Promise<Task | null> {
        const updates: any = { ...data, updatedAt: new Date() };

        Object.keys(updates).forEach(key =>
            updates[key] === undefined && delete updates[key]
        );

        await this.getRoomTasksCollection(roomId).doc(taskId).update(updates);
        return this.findById(roomId, taskId);
    }

    async delete(roomId: string, taskId: string): Promise<void> {
        await this.getRoomTasksCollection(roomId).doc(taskId).delete();
    }
}
