/**
 * 社交与社区数据模型：组队帖、经验帖、排行榜
 */

/** 组队帖 */
export interface TeamPost {
  id: string;
  competitionId: string;
  competitionName: string;
  authorName: string;
  needSkills: string[];
  content: string;
  contact: string;
  createdAt: number;
}

/** 经验分享帖 */
export interface SharePost {
  id: string;
  competitionId: string;
  competitionName: string;
  authorName: string;
  title: string;
  content: string;
  likes: number;
  liked: boolean;
  createdAt: number;
}

/** 排行榜条目 */
export interface RankItem {
  rank: number;
  name: string;
  school: string;
  score: number;
  competitions: number;
}

/** 提醒条目 */
export interface ReminderItem {
  id: string;
  competitionId: string;
  competitionName: string;
  type: string;
  typeText: string;
  title: string;
  time: number;
  daysLeft: number;
}
