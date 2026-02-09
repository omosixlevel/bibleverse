import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';

// Create a safe initialization function
const initializeFirebase = () => {
    dotenv.config();

    try {
        // specific check for FIREBASE_SERVICE_ACCOUNT which might contain the raw JSON
        const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT;

        let credential;

        if (serviceAccountRaw) {
            try {
                const serviceAccount = JSON.parse(serviceAccountRaw);
                credential = admin.credential.cert(serviceAccount);
            } catch (parseError) {
                console.error('Error parsing FIREBASE_SERVICE_ACCOUNT JSON:', parseError);
                throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT environment variable');
            }
        } else {
            // Fallback to Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS)
            // This is standard for Cloud Run, App Engine, etc.
            credential = admin.credential.applicationDefault();
        }

        const app = admin.initializeApp({
            credential,
            // If using Realtime Database, you'd add databaseURL here
        });

        console.log('Firebase Admin initialized successfully');
        return app;
    } catch (error) {
        console.error('Fatal Error: Firebase Admin initialization failed');
        console.error(error);
        // In a critical backend service, if DB logic is essential, we might want to exit.
        // However, we'll let the main process decide whether to crash, 
        // but throwing here ensures imports fail if this is top-level.
        process.exit(1);
    }
};

const app = initializeFirebase();

export const firestore = app.firestore();
export const auth = app.auth();

// Ensure firestore settings are optimized for server usage if needed
firestore.settings({
    ignoreUndefinedProperties: true,
});
