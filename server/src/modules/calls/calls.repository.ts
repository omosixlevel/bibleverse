import { firestore } from '../../config/firebase';
import { Call, CallParticipant, CreateCallDto } from './calls.interface';

export class CallsRepository {
    private collection = firestore.collection('calls');

    private getParticipantsCollection(callId: string) {
        return this.collection.doc(callId).collection('participants');
    }

    private docToCall(doc: FirebaseFirestore.DocumentSnapshot): Call | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            speakerStartTime: data?.speakerStartTime?.toDate(),
            createdAt: data?.createdAt?.toDate(),
            endedAt: data?.endedAt?.toDate()
        } as unknown as Call;
    }

    async findById(id: string): Promise<Call | null> {
        const doc = await this.collection.doc(id).get();
        return this.docToCall(doc);
    }

    async create(data: CreateCallDto): Promise<Call> {
        const newCall = {
            ...data,
            status: 'active',
            circleTalkingEnabled: data.circleTalkingEnabled || false,
            createdAt: new Date(),
        };
        const docRef = await this.collection.add(newCall);
        return { id: docRef.id, ...newCall } as unknown as Call;
    }

    async update(id: string, data: Partial<Call>): Promise<Call | null> {
        await this.collection.doc(id).update(data);
        return this.findById(id);
    }

    async addParticipant(callId: string, userId: string): Promise<void> {
        await this.getParticipantsCollection(callId).doc(userId).set({
            userId,
            muted: true,
            handRaised: false,
            // speakingOrder & speakingTimeSeconds optional
        });
    }

    async removeParticipant(callId: string, userId: string): Promise<void> {
        await this.getParticipantsCollection(callId).doc(userId).delete();
    }

    async updateParticipant(callId: string, userId: string, data: Partial<CallParticipant>): Promise<void> {
        await this.getParticipantsCollection(callId).doc(userId).update(data);
    }

    async getParticipants(callId: string): Promise<CallParticipant[]> {
        const snapshot = await this.getParticipantsCollection(callId).get();
        return snapshot.docs.map(doc => {
            const data = doc.data();
            return {
                userId: doc.id,
                ...data,
            } as unknown as CallParticipant;
        });
    }

    async getParticipant(callId: string, userId: string): Promise<CallParticipant | null> {
        const doc = await this.getParticipantsCollection(callId).doc(userId).get();
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            userId: doc.id,
            ...data,
        } as unknown as CallParticipant;
    }
}
