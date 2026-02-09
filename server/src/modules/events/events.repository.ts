import { firestore } from '../../config/firebase';
import { Event, CreateEventDto, UpdateEventDto } from './events.interface';

export class EventsRepository {
    private collection = firestore.collection('events');

    private docToEvent(doc: FirebaseFirestore.DocumentSnapshot): Event | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            startDate: data?.startDate?.toDate(),
            endDate: data?.endDate?.toDate(),
            createdAt: data?.createdAt?.toDate(),
            updatedAt: data?.updatedAt?.toDate()
        } as unknown as Event;
    }

    async findAll(filters: { creatorId?: string, visibility?: string }): Promise<Event[]> {
        let query: FirebaseFirestore.Query = this.collection;

        if (filters.creatorId) query = query.where('creatorId', '==', filters.creatorId);
        if (filters.visibility) query = query.where('visibility', '==', filters.visibility);

        const snapshot = await query.get();
        return snapshot.docs.map(doc => this.docToEvent(doc)!).filter(e => e !== null);
    }

    async findById(id: string): Promise<Event | null> {
        const doc = await this.collection.doc(id).get();
        return this.docToEvent(doc);
    }

    async create(data: CreateEventDto): Promise<Event> {
        const now = new Date();
        const newEvent: Partial<Event> = {
            ...data,
            startDate: new Date(data.startDate),
            endDate: new Date(data.endDate),
            visibility: data.visibility || 'public',
            status: 'draft', // Default to draft
            createdAt: now,
            // updatedAt removed from interface
        };

        const docRef = await this.collection.add(newEvent);
        return { id: docRef.id, ...newEvent } as Event;
    }

    async update(id: string, data: UpdateEventDto): Promise<Event | null> {
        const docRef = this.collection.doc(id);

        const updates: any = { ...data }; // updatedAt removed
        if (data.startDate) updates.startDate = new Date(data.startDate);
        if (data.endDate) updates.endDate = new Date(data.endDate);

        // Remove undefined
        Object.keys(updates).forEach(key =>
            updates[key] === undefined && delete updates[key]
        );

        await docRef.update(updates);
        return this.findById(id);
    }

    async delete(id: string): Promise<void> {
        await this.collection.doc(id).delete();
    }
}
