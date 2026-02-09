import { firestore } from '../../config/firebase';
import { Room, CreateRoomDto, UpdateRoomDto } from './rooms.interface';

export class RoomsRepository {
    private collection = firestore.collection('rooms');

    private docToRoom(doc: FirebaseFirestore.DocumentSnapshot): Room | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            startDate: data?.startDate?.toDate(),
            endDate: data?.endDate?.toDate(),
            createdAt: data?.createdAt?.toDate(),
            updatedAt: data?.updatedAt?.toDate()
        } as unknown as Room;
    }

    async findAll(): Promise<Room[]> {
        const snapshot = await this.collection.get();
        return snapshot.docs.map(doc => this.docToRoom(doc)!).filter(r => r !== null);
    }

    async findById(id: string): Promise<Room | null> {
        const doc = await this.collection.doc(id).get();
        return this.docToRoom(doc);
    }

    async create(data: CreateRoomDto): Promise<Room> {
        const now = new Date();
        const newRoom: Partial<Room> = {
            ...data,
            startDate: new Date(data.startDate),
            endDate: new Date(data.endDate),
            visibility: data.visibility || 'public',
            status: 'open',
            createdAt: now,
            // updatedAt removed from interface
        };

        // Validate undefined fields
        Object.keys(newRoom).forEach(key =>
            (newRoom as any)[key] === undefined && delete (newRoom as any)[key]
        );

        const docRef = await this.collection.add(newRoom);
        return { id: docRef.id, ...newRoom } as Room;
    }

    async update(id: string, data: UpdateRoomDto): Promise<Room | null> {
        const updates = { ...data, updatedAt: new Date() };
        await this.collection.doc(id).update(updates);
        return this.findById(id);
    }

    async addMember(roomId: string, userId: string): Promise<void> {
        await this.collection.doc(roomId).collection('members').doc(userId).set({
            joinedAt: new Date(),
            role: 'member'
        });
    }

    async removeMember(roomId: string, userId: string): Promise<void> {
        await this.collection.doc(roomId).collection('members').doc(userId).delete();
    }
}
