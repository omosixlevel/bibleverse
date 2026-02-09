import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

const app: Application = express();

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));

import routes from './routes';

// Routes
app.use('/api/v1', routes);

// Basic route
app.get('/', (req: Request, res: Response) => {
    res.send('Bibleverse API is running');
});

import { firestore } from './config/firebase';

app.get('/api/health', async (req: Request, res: Response) => {
    try {
        // Quick check to Firestore to ensure connectivity
        await firestore.listCollections();
        res.status(200).json({
            status: 'ok',
            firebase: 'connected',
            timestamp: new Date()
        });
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(503).json({
            status: 'error',
            firebase: 'disconnected',
            timestamp: new Date()
        });
    }
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: err.message || 'Internal Server Error',
    });
});

export default app;
