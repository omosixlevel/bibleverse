import { GoogleGenerativeAI } from '@google/generative-ai';
import { Call } from '../calls/calls.interface';

export class GeminiService {
    private genAI: GoogleGenerativeAI;
    private model: any;

    constructor() {
        const apiKey = process.env.GEMINI_API_KEY || '';
        if (!apiKey) {
            console.warn('GEMINI_API_KEY is not set. AI features will be disabled.');
        }
        this.genAI = new GoogleGenerativeAI(apiKey);
        this.model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });
    }

    async generateModeratorMessage(
        action: 'start' | 'next',
        currentSpeakerId: string | null,
        nextSpeakerId: string,
        context?: string
    ): Promise<string> {
        if (!process.env.GEMINI_API_KEY) {
            return action === 'start'
                ? `Welcome to the circle. ${nextSpeakerId} will start us off.`
                : `Thank you. Next up is ${nextSpeakerId}.`;
        }

        try {
            let prompt = '';
            if (action === 'start') {
                prompt = `You are a spiritual moderator for a Christian prayer circle. 
                The circle is just starting. 
                The first speaker is ${nextSpeakerId}.
                Generate a brief, welcoming, one-sentence announcement introducing the first speaker and setting a reverent tone.`;
            } else {
                prompt = `You are a spiritual moderator for a Christian prayer circle.
                The previous speaker was ${currentSpeakerId}.
                The next speaker is ${nextSpeakerId}.
                Generate a brief, encouraging one-sentence transition. Acknowledge the previous speaker simply and invite the next one.`;
            }

            const result = await this.model.generateContent(prompt);
            const response = await result.response;
            return response.text().trim();
        } catch (error) {
            console.error('Gemini generation error:', error);
            // Fallback messages
            return action === 'start'
                ? `Let us begin. ${nextSpeakerId}, you have the floor.`
                : `Amen. ${nextSpeakerId}, please proceed.`;
        }
    }
}
