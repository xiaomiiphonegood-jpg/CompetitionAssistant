/**
 * AI 学习规划数据模型
 */

/** 规划中的单个阶段 */
export interface PlanPhase {
  name: string;
  weeks: string;
  goal: string;
  tasks: string[];
}

/** 学习规划 */
export interface StudyPlan {
  id: string;
  competitionId: string;
  competitionName: string;
  target: string;
  level: string;
  weeklyHours: number;
  totalWeeks: number;
  summary: string;
  phases: PlanPhase[];
  risks: string[];
  status: string;
  createdAt: number;
  /** 已完成任务的 key（格式 "阶段下标_任务下标"），用于打卡 */
  doneTasks: string[];
}

/** 生成规划所需的用户输入三要素 */
export interface PlanRequest {
  competitionId: string;
  competitionName: string;
  level: string;
  weeklyHours: number;
  target: string;
}
