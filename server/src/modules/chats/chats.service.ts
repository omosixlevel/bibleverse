import { ChatsRepository } from './chats.repository';
import { CreateChatDto, CreateMessageDto, Chat, ChatMessage } from './chats.interface';

export class ChatsService {
    private chatsRepository = new ChatsRepository();

    async getOrCreateChat(data: CreateChatDto): Promise<Chat> {
        let chat = await this.chatsRepository.findByRefId(data.type, data.refId);
        if (!chat) {
            chat = await this.chatsRepository.create(data);
        }
        return chat;
    }

    async getChatById(id: string): Promise<Chat | null> {
        return this.chatsRepository.findById(id);
    }

    async sendMessage(chatId: string, data: CreateMessageDto): Promise<ChatMessage> {
        const chat = await this.chatsRepository.findById(chatId);
        if (!chat) {
            throw new Error('Chat not found');
        }
        return this.chatsRepository.addMessage(chatId, data);
    }

    async getMessages(chatId: string, limit?: number): Promise<ChatMessage[]> {
        const chat = await this.chatsRepository.findById(chatId);
        if (!chat) {
            throw new Error('Chat not found');
        }
        return this.chatsRepository.getMessages(chatId, limit);
    }
}
