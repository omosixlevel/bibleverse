import { firestore } from '../../config/firebase';
import { User, CreateUserDto, UpdateUserDto } from './users.interface';

export class UsersRepository {
    private collection = firestore.collection('users');

    async findById(id: string): Promise<User | null> {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;

        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            createdAt: data?.createdAt?.toDate(),
            lastActiveAt: data?.lastActiveAt?.toDate()
        } as User;
    }

    async create(id: string, userDto: CreateUserDto): Promise<User> {
        const now = new Date();
        const newUser: User = {
            ...userDto,
            id,
            disciplineScore: 0,
            streakDays: 0,
            spiritualInterests: userDto.spiritualInterests || [],
            createdAt: now,
            lastActiveAt: now,
        };

        await this.collection.doc(id).set(newUser);
        return newUser;
    }

    async update(id: string, userDto: UpdateUserDto): Promise<User | null> {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;

        const updates = {
            ...userDto,
            updatedAt: new Date(),
        };

        // Remove undefined fields
        Object.keys(updates).forEach(key =>
            (updates as any)[key] === undefined && delete (updates as any)[key]
        );

        await docRef.update(updates);
        return this.findById(id);
    }
}
