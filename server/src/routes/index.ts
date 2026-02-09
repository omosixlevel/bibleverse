import { Router } from 'express';

import usersRoutes from '../modules/users/users.routes';
import eventsRoutes from '../modules/events/events.routes';
import roomsRoutes from '../modules/rooms/rooms.routes';
import tasksRoutes from '../modules/tasks/tasks.routes';
import taskCompletionsRoutes from '../modules/task-completions/task-completions.routes';
import callsRoutes from '../modules/calls/calls.routes';
import chatsRoutes from '../modules/chats/chats.routes';
import activitiesRoutes from '../modules/activities/activities.routes';
import governanceRoutes from '../modules/governance/governance.routes';

const router = Router();

// User routes
router.use('/users', usersRoutes);

// Events routes
router.use('/events', eventsRoutes);

// Rooms routes
router.use('/rooms', roomsRoutes);

// Tasks routes (nested under rooms)
router.use('/rooms/:roomId/tasks', tasksRoutes);

// Task Completions routes
router.use('/', taskCompletionsRoutes);

// Calls routes
router.use('/calls', callsRoutes);

// Chats routes
router.use('/chats', chatsRoutes);

// Activities routes
router.use('/activities', activitiesRoutes);

// Governance routes
router.use('/governance', governanceRoutes);

export default router;
