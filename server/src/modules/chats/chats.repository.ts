import { firestore } from '../../config/firebase';
import { Chat, ChatMessage, CreateChatDto, CreateMessageDto } from './chats.interface';

export class ChatsRepository {
    private chatsCollection = firestore.collection('chats');

    private docToChat(doc: FirebaseFirestore.DocumentSnapshot): Chat | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            createdAt: data?.createdAt?.toDate(),
        } as Chat;
    }

    private docToMessage(doc: FirebaseFirestore.DocumentSnapshot): ChatMessage | null {
        if (!doc.exists) return null;
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            createdAt: data?.createdAt?.toDate(),
        } as ChatMessage;
    }

    async findById(id: string): Promise<Chat | null> {
        const doc = await this.chatsCollection.doc(id).get();
        return this.docToChat(doc);
    }

    async findByRefId(type: string, refId: string): Promise<Chat | null> {
        const snapshot = await this.chatsCollection
            .where('type', '==', type)
            .where('refId', '==', refId)
            .limit(1)
            .get();

        if (snapshot.empty) return null;
        return this.docToChat(snapshot.docs[0]);
    }

    async create(data: CreateChatDto): Promise<Chat> {
        const newChat: Partial<Chat> = {
            ...data,
            createdAt: new Date(),
        };

        const docRef = await this.chatsCollection.add(newChat);
        return { id: docRef.id, ...newChat } as Chat;
    }

    async addMessage(chatId: string, data: CreateMessageDto): Promise<ChatMessage> {
        const newMessage: Partial<ChatMessage> = {
            ...data,
            chatId,
            createdAt: new Date(),
        };

        const docRef = await this.chatsCollection.doc(chatId).collection('messages').add(newMessage);
        return { id: docRef.id, ...newMessage } as ChatMessage;
    }

    async getMessages(chatId: string, limit: number = 50): Promise<ChatMessage[]> {
        const snapshot = await this.chatsCollection
            .doc(chatId)
            .collection('messages')
            .orderBy('createdAt', 'desc')
            .limit(limit)
            .get();

        return snapshot.docs.map(doc => this.docToMessage(doc)!).filter(m => m !== null);
    }
}
