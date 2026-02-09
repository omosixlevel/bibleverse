import { Router } from 'express';
import { ChatsController } from './chats.controller';

const router = Router();
const chatsController = new ChatsController();

router.post('/', chatsController.getOrCreateChat);
router.get('/:id', chatsController.getChatById);
router.post('/:id/messages', chatsController.sendMessage);
router.get('/:id/messages', chatsController.getMessages);

export default router;
