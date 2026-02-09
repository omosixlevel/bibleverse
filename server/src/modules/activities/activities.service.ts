import { ActivitiesRepository } from './activities.repository';
import { CreateActivityDto, UpdateActivityDto, Activity, ActivityAttendance } from './activities.interface';

export class ActivitiesService {
    private activitiesRepository = new ActivitiesRepository();

    async createActivity(data: CreateActivityDto): Promise<Activity> {
        return this.activitiesRepository.create(data);
    }

    async getActivitiesByEvent(eventId: string): Promise<Activity[]> {
        return this.activitiesRepository.findAllByEventId(eventId);
    }

    async getActivityById(id: string): Promise<Activity | null> {
        return this.activitiesRepository.findById(id);
    }

    async updateActivity(id: string, data: UpdateActivityDto): Promise<Activity | null> {
        return this.activitiesRepository.update(id, data);
    }

    async deleteActivity(id: string): Promise<void> {
        return this.activitiesRepository.delete(id);
    }

    async confirmAttendance(activityId: string, userId: string, confirmed: boolean): Promise<void> {
        return this.activitiesRepository.confirmAttendance(activityId, userId, confirmed);
    }

    async markAttendance(activityId: string, userId: string, attended: boolean): Promise<void> {
        return this.activitiesRepository.markAttendance(activityId, userId, attended);
    }

    async getActivityAttendance(activityId: string): Promise<ActivityAttendance[]> {
        return this.activitiesRepository.getAttendance(activityId);
    }
}
