import { firestore } from '../config/firebase';
import * as admin from 'firebase-admin';

async function seed() {
    console.log('--- Starting Database Seeding ---');

    // 1. Create a Public Event
    const eventRef = firestore.collection('events').doc('event_demo_1');
    const eventData = {
        title: '7 Days of Spiritual Renewal',
        shortDescription: 'Deepen your walk with God in just one week.',
        fullDescription: 'Join thousands of believers across the globe as we dedicate 7 days to intense prayer, scripture meditation, and fellowship. This event is designed to reset your focus and renew your spirit through structured daily disciplines.',
        objectiveStatement: 'To foster a culture of daily spiritual discipline and communal growth.',
        thematicVerseSummary: 'Psalm 51:10 - Create in me a pure heart, O God, and renew a steadfast spirit within me.',
        startDate: admin.firestore.Timestamp.fromDate(new Date()),
        endDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
        visibility: 'public',
        status: 'active',
        creatorId: 'admin_user_001',
        createdAt: admin.firestore.Timestamp.fromDate(new Date()),
    };
    await eventRef.set(eventData);
    console.log('✅ Event "7 Days of Spiritual Renewal" created.');

    // 2. Create Rooms for the Event
    const rooms = [
        {
            id: 'room_prayer_warriors',
            title: 'Intercessory Prayer Room',
            description: 'A space for collective prayer and intercession.',
            roomType: 'prayer',
            visibility: 'public',
            eventId: 'event_demo_1',
            startDate: eventData.startDate,
            endDate: eventData.endDate,
            status: 'open',
            creatorId: 'admin_user_001',
            createdAt: admin.firestore.Timestamp.fromDate(new Date()),
        },
        {
            id: 'room_bible_study',
            title: 'KJV Deep Dive Study',
            description: 'Exploring the treasures of the King James Version.',
            roomType: 'bible',
            visibility: 'public',
            eventId: 'event_demo_1',
            startDate: eventData.startDate,
            endDate: eventData.endDate,
            status: 'open',
            creatorId: 'admin_user_001',
            createdAt: admin.firestore.Timestamp.fromDate(new Date()),
        }
    ];

    for (const room of rooms) {
        await firestore.collection('rooms').doc(room.id).set(room);
        console.log(`✅ Room "${room.title}" created.`);

        // 3. Add Tasks to each Room
        const tasks = [
            {
                title: 'Morning Silence',
                description: 'Spend 10 minutes in complete silence before God.',
                taskType: 'silence',
                dayIndex: 0,
                mandatory: true,
                createdBy: 'gemini',
                status: 'active',
                createdAt: admin.firestore.Timestamp.fromDate(new Date()),
            },
            {
                title: 'Rhema Meditation',
                description: 'Meditate on Psalm 23 and write down what God is saying to you personally.',
                taskType: 'rhema',
                dayIndex: 0,
                mandatory: true,
                createdBy: 'gemini',
                status: 'active',
                createdAt: admin.firestore.Timestamp.fromDate(new Date()),
            },
            {
                title: 'Acts of Love',
                description: 'Reach out to one person today and offer words of encouragement.',
                taskType: 'action',
                dayIndex: 1,
                mandatory: false,
                createdBy: 'gemini',
                status: 'active',
                createdAt: admin.firestore.Timestamp.fromDate(new Date()),
            },
            {
                title: 'Evening Worship',
                description: 'Worship with a heart of gratitude for at least 15 minutes.',
                taskType: 'worship',
                dayIndex: 1,
                mandatory: true,
                createdBy: 'gemini',
                status: 'active',
                createdAt: admin.firestore.Timestamp.fromDate(new Date()),
            }
        ];

        for (const task of tasks) {
            await firestore.collection('rooms').doc(room.id).collection('tasks').add(task);
        }
        console.log(`   - Added ${tasks.length} tasks to ${room.title}.`);
    }

    console.log('--- Seeding Completed Successfully ---');
    process.exit(0);
}

seed().catch(err => {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
});
