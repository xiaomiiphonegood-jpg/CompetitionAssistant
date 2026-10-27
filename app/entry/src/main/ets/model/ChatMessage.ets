/**
 * AI 对话消息模型
 */
import { StudyPlan } from './StudyPlan';

export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant'
}

/** 对话消息 */
export interface ChatMessage {
  id: string;
  role: MessageRole;
  content: string;
  /** 快捷选项按钮（assistant 消息可选） */
  options: string[];
  /** 生成的结构化计划（assistant 消息可选） */
  plan: StudyPlan | null;
}
