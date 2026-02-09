import { UsersRepository } from './users.repository';
import { CreateUserDto, UpdateUserDto, User } from './users.interface';

export class UsersService {
    private repository: UsersRepository;

    constructor() {
        this.repository = new UsersRepository();
    }

    async getUser(id: string): Promise<User | null> {
        return this.repository.findById(id);
    }

    async createUser(id: string, data: CreateUserDto): Promise<User> {
        // Here we could add business validation (e.g. check email uniqueness if not handled by Auth)
        return this.repository.create(id, data);
    }

    async updateUser(id: string, data: UpdateUserDto): Promise<User | null> {
        return this.repository.update(id, data);
    }
}
