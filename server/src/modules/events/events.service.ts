import { EventsRepository } from './events.repository';
import { CreateEventDto, UpdateEventDto, Event } from './events.interface';

export class EventsService {
    private repository: EventsRepository;

    constructor() {
        this.repository = new EventsRepository();
    }

    async getEvents(filters: any): Promise<Event[]> {
        const events = await this.repository.findAll(filters);
        // Dynamic status check could happen here update DB if changed
        return events.map(this.calculateDynamicStatus);
    }

    async getEvent(id: string): Promise<Event | null> {
        const event = await this.repository.findById(id);
        if (event) return this.calculateDynamicStatus(event);
        return null;
    }

    async createEvent(data: CreateEventDto): Promise<Event> {
        return this.repository.create(data);
    }

    async updateEvent(id: string, userId: string, data: UpdateEventDto): Promise<Event | null> {
        const event = await this.repository.findById(id);
        if (!event) return null;

        if (event.creatorId !== userId) {
            throw new Error('Unauthorized');
        }

        return this.repository.update(id, data);
    }

    async deleteEvent(id: string, userId: string): Promise<boolean> {
        const event = await this.repository.findById(id);
        if (!event) return false;

        if (event.creatorId !== userId) {
            throw new Error('Unauthorized');
        }

        if (new Date() > event.startDate) {
            throw new Error('Cannot delete event after start date');
        }

        await this.repository.delete(id);
        return true;
    }

    private calculateDynamicStatus(event: Event): Event {
        const now = new Date();
        // Just return the computed status for display, 
        // in a real job we might want to persist this if it changed.
        let status = event.status; // Keep original if manually set?
        // Or override based on dates if active/ended usage is preferred dynamically
        // but schema has explicit status. Let's respect DB status but maybe override for 'active' vs 'closed'?
        // For now, let's just default to what's in DB or simple date check if it was 'active'
        if (status === 'active') {
            if (now > event.endDate) status = 'closed';
        }

        return { ...event, status };
    }
}
