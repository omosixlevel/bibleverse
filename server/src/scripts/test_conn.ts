import { firestore } from '../config/firebase';

async function test() {
    console.log('Testing Firestore connection...');
    try {
        const collections = await firestore.listCollections();
        console.log('Collections count:', collections.length);
        console.log('Collections names:', collections.map(c => c.id));
    } catch (error) {
        console.error('Firestore connection test failed:', error);
    }
    process.exit(0);
}

test();
