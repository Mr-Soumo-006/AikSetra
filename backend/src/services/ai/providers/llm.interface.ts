import { AIMessageInput, AIChatOptions, AIChatResponse } from '../ai.types.js';

export interface ILLMProvider {
  readonly name: string;
  isAvailable(): Promise<boolean>;
  chat(messages: AIMessageInput[], options?: AIChatOptions): Promise<AIChatResponse>;
  embed(text: string): Promise<number[]>;
}
