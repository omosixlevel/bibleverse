import { RoomsRepository } from './rooms.repository';
import { CreateRoomDto, UpdateRoomDto, Room } from './rooms.interface';

export class RoomsService {
    private repository: RoomsRepository;

    constructor() {
        this.repository = new RoomsRepository();
    }

    async getRooms(): Promise<Room[]> {
        return this.repository.findAll();
    }

    async getRoom(id: string): Promise<Room | null> {
        return this.repository.findById(id);
    }

    async createRoom(data: CreateRoomDto): Promise<Room> {
        return this.repository.create(data);
    }

    async updateRoom(id: string, data: UpdateRoomDto): Promise<Room | null> {
        // Auth check logic should be here (e.g., check if requester is creator)
        return this.repository.update(id, data);
    }

    async joinRoom(roomId: string, userId: string, acceptedCovenant: boolean): Promise<void> {
        if (!acceptedCovenant) {
            throw new Error('Must accept covenant');
        }
        const room = await this.repository.findById(roomId);
        if (!room) throw new Error('Room not found');

        await this.repository.addMember(roomId, userId);
    }

    async leaveRoom(roomId: string, userId: string): Promise<void> {
        await this.repository.removeMember(roomId, userId);
    }
}
