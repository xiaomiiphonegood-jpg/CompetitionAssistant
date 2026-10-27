/**
 * 竞赛数据模型
 */

/** 竞赛主信息 */
export interface Competition {
  id: string;
  name: string;
  shortName: string;
  level: string;
  levelText: string;
  category: string;
  categoryText: string;
  organizer: string;
  description: string;
  officialUrl: string;
  logoUrl: string;
  suitable: string;
  tags: string[];
  reward: string;
  hot: number;
}

/** 竞赛时间节点（时间线单元） */
export interface CompetitionStage {
  id: string;
  competitionId: string;
  competitionName: string;
  level: string;
  category: string;
  type: string;
  typeText: string;
  title: string;
  time: number;
  note: string;
}

/** 竞赛详情（竞赛 + 节点） */
export interface CompetitionDetail {
  competition: Competition;
  stages: CompetitionStage[];
}

/** 时间线节点类型 */
export enum StageType {
  ENROLL_START = 'enroll_start',
  ENROLL_END = 'enroll_end',
  CONTEST = 'contest',
  RESULT = 'result'
}
