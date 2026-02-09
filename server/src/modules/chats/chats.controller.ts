import { Request, Response } from 'express';
import { ChatsService } from './chats.service';
import { CreateChatDto, CreateMessageDto } from './chats.interface';

export class ChatsController {
    private chatsService = new ChatsService();

    getOrCreateChat = async (req: Request, res: Response) => {
        try {
            const data: CreateChatDto = req.body;
            const chat = await this.chatsService.getOrCreateChat(data);
            res.status(200).json(chat);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getChatById = async (req: Request, res: Response) => {
        try {
            const chat = await this.chatsService.getChatById(req.params.id);
            if (!chat) {
                return res.status(404).json({ error: 'Chat not found' });
            }
            res.status(200).json(chat);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    sendMessage = async (req: Request, res: Response) => {
        try {
            const data: CreateMessageDto = req.body;
            const message = await this.chatsService.sendMessage(req.params.id, data);
            res.status(201).json(message);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };

    getMessages = async (req: Request, res: Response) => {
        try {
            const limit = req.query.limit ? parseInt(req.query.limit as string) : undefined;
            const messages = await this.chatsService.getMessages(req.params.id, limit);
            res.status(200).json(messages);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    };
}
