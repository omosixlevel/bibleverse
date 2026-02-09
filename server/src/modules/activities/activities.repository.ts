import { firestore } from '../../config/firebase';
import { Activity, CreateActivityDto, UpdateActivityDto, ActivityAttendance } from './activities.interface';

export class ActivitiesRepository {
    private activitiesCollection = firestore.collection('activities');

    private docToActivity(doc: FirebaseFirestore.DocumentSnapshot): Activity | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            startDateTime: data?.startDateTime?.toDate(),
            endDateTime: data?.endDateTime?.toDate(),
            createdAt: data?.createdAt?.toDate(),
        } as Activity;
    }

    async findAllByEventId(eventId: string): Promise<Activity[]> {
        const snapshot = await this.activitiesCollection.where('eventId', '==', eventId).get();
        return snapshot.docs.map(doc => this.docToActivity(doc)!).filter(a => a !== null);
    }

    async findById(id: string): Promise<Activity | null> {
        const doc = await this.activitiesCollection.doc(id).get();
        return this.docToActivity(doc);
    }

    async create(data: CreateActivityDto): Promise<Activity> {
        const newActivity: Partial<Activity> = {
            ...data,
            startDateTime: new Date(data.startDateTime),
            endDateTime: new Date(data.endDateTime),
            createdAt: new Date(),
        };

        const docRef = await this.activitiesCollection.add(newActivity);
        return { id: docRef.id, ...newActivity } as Activity;
    }

    async update(id: string, data: UpdateActivityDto): Promise<Activity | null> {
        const updates: any = { ...data };
        if (data.startDateTime) updates.startDateTime = new Date(data.startDateTime);
        if (data.endDateTime) updates.endDateTime = new Date(data.endDateTime);

        await this.activitiesCollection.doc(id).update(updates);
        return this.findById(id);
    }

    async delete(id: string): Promise<void> {
        await this.activitiesCollection.doc(id).delete();
    }

    async confirmAttendance(activityId: string, userId: string, confirmed: boolean): Promise<void> {
        await this.activitiesCollection.doc(activityId).collection('attendance').doc(userId).set({
            userId,
            confirmed,
            updatedAt: new Date()
        }, { merge: true });
    }

    async markAttendance(activityId: string, userId: string, attended: boolean): Promise<void> {
        await this.activitiesCollection.doc(activityId).collection('attendance').doc(userId).update({
            attended,
            updatedAt: new Date()
        });
    }

    async getAttendance(activityId: string): Promise<ActivityAttendance[]> {
        const snapshot = await this.activitiesCollection.doc(activityId).collection('attendance').get();
        return snapshot.docs.map(doc => doc.data() as ActivityAttendance);
    }
}
