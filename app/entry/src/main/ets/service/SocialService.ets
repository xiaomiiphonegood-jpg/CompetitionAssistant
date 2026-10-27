/**
 * 社交服务：组队广场、经验分享、排行榜、智能提醒
 * 数据本地持久化（Preferences）；排行榜为「演示数据 + 本人真实活跃度」动态统计。
 */
import { TeamPost, SharePost, RankItem, ReminderItem } from '../model/Social.ets';
import { CloudService } from './CloudService';
import { UserService } from './UserService';
import { LocalStore } from '../common/LocalStore';
import { CloudConfig } from '../common/Constants';

/** 点赞参数 */
interface LikeQuery {
  postId: string;
}

/** 空查询参数（列表类 action 无过滤条件） */
interface EmptyQuery {}

/** 空查询参数实例（供无条件的列表 action 复用） */
const EMPTY_QUERY: EmptyQuery = {};

function genId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

function daysAgo(days: number): number {
  return Date.now() - days * 86400000;
}

/** 初始组队帖（演示数据） */
function buildMockTeamPosts(): TeamPost[] {
  return [
    {
      id: 'tp_1',
      competitionId: 'mcm',
      competitionName: '全国大学生数学建模竞赛',
      authorName: '数学系小王',
      needSkills: ['编程', 'Matlab'],
      content: '三人队缺一名编程手，已有建模和写作，希望找一位熟悉 Matlab/Python 的同学，目标冲省一。',
      contact: 'QQ: 12345（示例）',
      createdAt: daysAgo(1)
    },
    {
      id: 'tp_2',
      competitionId: 'lanqiao',
      competitionName: '蓝桥杯',
      authorName: '计科小李',
      needSkills: ['算法', 'C++'],
      content: '备战蓝桥杯 C/C++ 组，求一起刷题互相监督的队友，每天线上打卡刷 5 题。',
      contact: '微信: example_01（示例）',
      createdAt: daysAgo(2)
    },
    {
      id: 'tp_3',
      competitionId: 'tiaozhan',
      competitionName: '挑战杯',
      authorName: '创新创业社',
      needSkills: ['文案', '美工', '路演'],
      content: '挑战杯项目已立项，缺会做 PPT 和答辩的同学，项目方向是智慧农业，欢迎加入。',
      contact: '邮箱: team@example.com',
      createdAt: daysAgo(4)
    }
  ];
}

/** 初始经验帖（演示数据） */
function buildMockSharePosts(): SharePost[] {
  return [
    {
      id: 'sp_1',
      competitionId: 'mcm',
      competitionName: '全国大学生数学建模竞赛',
      authorName: '国奖得主老张',
      title: '数学建模从入门到国奖：我的 90 天备赛路线',
      content: '重点不是刷题，是「建模+写作」配合。前 30 天吃透常微分方程、优化模型，中间 30 天精读 10 篇国奖论文，最后 30 天全真模拟。写作手一定要提前练，论文质量直接决定档次。',
      likes: 128,
      liked: false,
      createdAt: daysAgo(3)
    },
    {
      id: 'sp_2',
      competitionId: 'nepcs',
      competitionName: '全国大学生英语竞赛',
      authorName: '英语系阿敏',
      title: '大英赛拿奖其实不难，关键在听力',
      content: '大英赛初赛通过率比想象高，听力占大头。考前两周每天 30 分钟精听，把近三年真题刷两遍，词汇部分靠平时积累。别裸考，认真准备一个月就有机会。',
      likes: 86,
      liked: false,
      createdAt: daysAgo(6)
    },
    {
      id: 'sp_3',
      competitionId: 'lanqiao',
      competitionName: '蓝桥杯',
      authorName: 'ACMer 小林',
      title: '蓝桥杯省一经验：暴力也能拿高分',
      content: '蓝桥杯不是纯算法竞赛，暴力解+部分分策略很有效。先保证简单题全对，再啃中等题。数据结构必考：前缀和、并查集、树。刷题顺序：历年真题 > 模板题 > 难题。',
      likes: 95,
      liked: false,
      createdAt: daysAgo(9)
    }
  ];
}

/** 排行榜演示数据 */
function buildMockRank(): RankItem[] {
  return [
    { rank: 1, name: '张三', school: '清华大学', score: 1280, competitions: 6 },
    { rank: 2, name: '李四', school: '北京大学', score: 1150, competitions: 5 },
    { rank: 3, name: '王五', school: '浙江大学', score: 990, competitions: 5 },
    { rank: 4, name: '赵六', school: '上海交通大学', score: 880, competitions: 4 },
    { rank: 5, name: '孙七', school: '华中科技大学', score: 760, competitions: 4 },
    { rank: 6, name: '周八', school: '武汉大学', score: 690, competitions: 3 },
    { rank: 7, name: '吴九', school: '西安交通大学', score: 620, competitions: 3 },
    { rank: 8, name: '郑十', school: '电子科技大学', score: 550, competitions: 3 },
    { rank: 9, name: '本人', school: '某某大学', score: 320, competitions: 2 },
    { rank: 10, name: '陈同学', school: '东南大学', score: 280, competitions: 2 }
  ];
}

let teamPosts: TeamPost[] = [];
let sharePosts: SharePost[] = [];
let socialInitPromise: Promise<void> | null = null;

async function doSocialInit(): Promise<void> {
  try {
    const tpStr = await LocalStore.load('team_posts', '');
    if (tpStr === '') {
      teamPosts = buildMockTeamPosts();
    } else {
      teamPosts = JSON.parse(tpStr) as TeamPost[];
    }
  } catch (e) {
    teamPosts = buildMockTeamPosts();
  }
  try {
    const spStr = await LocalStore.load('share_posts', '');
    if (spStr === '') {
      sharePosts = buildMockSharePosts();
    } else {
      sharePosts = JSON.parse(spStr) as SharePost[];
    }
  } catch (e) {
    sharePosts = buildMockSharePosts();
  }
}

export class SocialService {
  static init(): Promise<void> {
    if (socialInitPromise === null) {
      socialInitPromise = doSocialInit();
    }
    return socialInitPromise;
  }

  /** 组队帖列表（返回新数组引用，确保 @State 触发刷新） */
  static async getTeamPosts(): Promise<TeamPost[]> {
    if (!CloudConfig.USE_MOCK) {
      return CloudService.callCloudFunction<TeamPost[]>('team-list', EMPTY_QUERY);
    }
    await SocialService.init();
    return teamPosts.slice();
  }

  /** 按 ID 查询组队帖详情 */
  static async getTeamPostById(id: string): Promise<TeamPost | undefined> {
    if (!CloudConfig.USE_MOCK) {
      const list = await CloudService.callCloudFunction<TeamPost[]>('team-list', EMPTY_QUERY);
      return list.find((p: TeamPost) => p.id === id);
    }
    await SocialService.init();
    return teamPosts.find((p: TeamPost) => p.id === id);
  }

  /** 发布组队帖 */
  static async createTeamPost(post: TeamPost): Promise<void> {
    if (!CloudConfig.USE_MOCK) {
      await CloudService.callCloudFunction<object>('team-create', post);
      return;
    }
    await SocialService.init();
    teamPosts.unshift(post);
    teamPosts = teamPosts.slice();
    await LocalStore.save('team_posts', JSON.stringify(teamPosts));
  }

  /** 经验帖列表（返回新数组引用） */
  static async getSharePosts(): Promise<SharePost[]> {
    if (!CloudConfig.USE_MOCK) {
      return CloudService.callCloudFunction<SharePost[]>('share-list', EMPTY_QUERY);
    }
    await SocialService.init();
    return sharePosts.slice();
  }

  /** 按 ID 查询经验帖详情 */
  static async getSharePostById(id: string): Promise<SharePost | undefined> {
    if (!CloudConfig.USE_MOCK) {
      const list = await CloudService.callCloudFunction<SharePost[]>('share-list', EMPTY_QUERY);
      return list.find((p: SharePost) => p.id === id);
    }
    await SocialService.init();
    return sharePosts.find((p: SharePost) => p.id === id);
  }

  /** 发布经验帖 */
  static async createSharePost(post: SharePost): Promise<void> {
    if (!CloudConfig.USE_MOCK) {
      await CloudService.callCloudFunction<object>('share-create', post);
      return;
    }
    await SocialService.init();
    sharePosts.unshift(post);
    sharePosts = sharePosts.slice();
    await LocalStore.save('share_posts', JSON.stringify(sharePosts));
  }

  /** 点赞 / 取消点赞 */
  static async toggleLike(postId: string): Promise<void> {
    if (!CloudConfig.USE_MOCK) {
      const params: LikeQuery = { postId: postId };
      await CloudService.callCloudFunction<object>('share-like', params);
      return;
    }
    await SocialService.init();
    const idx = sharePosts.findIndex((p: SharePost) => p.id === postId);
    if (idx < 0) {
      return;
    }
    const old = sharePosts[idx];
    const updated: SharePost = {
      id: old.id,
      competitionId: old.competitionId,
      competitionName: old.competitionName,
      authorName: old.authorName,
      title: old.title,
      content: old.content,
      likes: old.liked ? old.likes - 1 : old.likes + 1,
      liked: !old.liked,
      createdAt: old.createdAt
    };
    sharePosts[idx] = updated;
    sharePosts = sharePosts.slice();
    await LocalStore.save('share_posts', JSON.stringify(sharePosts));
  }

  /** 排行榜 */
  static async getRankList(): Promise<RankItem[]> {
    if (!CloudConfig.USE_MOCK) {
      return CloudService.callCloudFunction<RankItem[]>('rank-list', EMPTY_QUERY);
    }
    // mock：演示数据 + 本人真实活跃度，按积分重新排序
    const base = buildMockRank().filter((r: RankItem) => r.name !== '本人');
    const mine = await SocialService.buildMyRankItem();
    const list: RankItem[] = base.concat([mine]);
    list.sort((a: RankItem, b: RankItem) => b.score - a.score);
    const result: RankItem[] = [];
    for (let i = 0; i < list.length; i++) {
      const item: RankItem = {
        rank: i + 1,
        name: list[i].name,
        school: list[i].school,
        score: list[i].score,
        competitions: list[i].competitions
      };
      result.push(item);
    }
    return result;
  }

  /** 统计"本人"真实活跃度（发帖数/获赞数/收藏数/参与竞赛数） */
  static async buildMyRankItem(): Promise<RankItem> {
    await SocialService.init();
    const myTeamCount = teamPosts.filter((p: TeamPost) => p.authorName === '我').length;
    const myShares = sharePosts.filter((p: SharePost) => p.authorName === '我');
    let myLikes = 0;
    for (const p of myShares) {
      myLikes += p.likes;
    }
    const favCount = (await CloudService.getFavorites()).length;
    const compIds: string[] = [];
    for (const p of teamPosts) {
      if (p.authorName === '我' && compIds.indexOf(p.competitionId) < 0) {
        compIds.push(p.competitionId);
      }
    }
    for (const p of myShares) {
      if (compIds.indexOf(p.competitionId) < 0) {
        compIds.push(p.competitionId);
      }
    }
    const profile = await UserService.getProfile();
    const school = profile.school !== '' && profile.school !== '未设置学校' ? profile.school : '我的大学';
    const name = profile.nickname !== '' && profile.nickname !== '竞赛小助手用户' ? profile.nickname : '我';
    const mine: RankItem = {
      rank: 0,
      name: name,
      school: school,
      score: myTeamCount * 20 + myShares.length * 20 + myLikes + favCount * 10,
      competitions: compIds.length
    };
    return mine;
  }

  /** 智能提醒：未来 90 天内即将到来的关键节点（报名截止/比赛） */
  static async getReminders(): Promise<ReminderItem[]> {
    const now = Date.now();
    const future = now + 90 * 86400000;
    const stages = await CloudService.getStages(now, future, 'all');
    const reminders: ReminderItem[] = [];
    for (const s of stages) {
      if (s.type === 'enroll_end' || s.type === 'contest') {
        const daysLeft = Math.ceil((s.time - now) / 86400000);
        reminders.push({
          id: s.id,
          competitionId: s.competitionId,
          competitionName: s.competitionName,
          type: s.type,
          typeText: s.typeText,
          title: s.title,
          time: s.time,
          daysLeft: daysLeft
        });
      }
    }
    reminders.sort((a: ReminderItem, b: ReminderItem) => a.time - b.time);
    return reminders;
  }

  /** 清除本地社交数据（重置为初始演示数据） */
  static async clearAll(): Promise<void> {
    await SocialService.init();
    teamPosts = buildMockTeamPosts();
    sharePosts = buildMockSharePosts();
    await LocalStore.save('team_posts', '');
    await LocalStore.save('share_posts', '');
  }
}

export { genId };
