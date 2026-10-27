/**
 * 云服务封装：竞赛数据 + 收藏 + 学习规划
 * 说明：CloudConfig.USE_MOCK = true 时走本地 Mock 数据（可离线运行），
 *       接入 AppGallery Connect 后改为调用云函数。
 */
import { Competition, CompetitionDetail, CompetitionStage } from '../model/Competition';
import { StudyPlan } from '../model/StudyPlan';
import { CloudConfig } from '../common/Constants';
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import { LocalStore } from '../common/LocalStore';

/** 云函数统一响应结构 */
interface CloudResponse<T> {
  code: number;
  data: T;
}

/** 列表查询参数 */
interface ListQuery {
  page: number;
  size: number;
}

/** 时间线查询参数 */
interface StageQuery {
  startTime: number;
  endTime: number;
  category: string;
}

/** 按 ID 查询参数 */
interface IdQuery {
  competitionId: string;
}

/** 收藏切换结果 */
interface FavToggleResult {
  favorited: boolean;
}

/** 规划 ID 查询参数 */
interface PlanIdQuery {
  planId: string;
}

/** 打卡切换参数 */
interface TaskToggleQuery {
  planId: string;
  taskKey: string;
}

/** 打卡切换结果 */
interface TaskToggleResult {
  done: boolean;
}

/** 空查询参数（列表类 action 无过滤条件） */
interface EmptyQuery {}

/** 空查询参数实例（供无条件的列表 action 复用） */
const EMPTY_QUERY: EmptyQuery = {};

/** 本地 Mock：竞赛数据（当前日期约 2026-09） */
const MOCK_COMPETITIONS: Competition[] = [
  {
    id: 'mcm',
    name: '全国大学生数学建模竞赛',
    shortName: '数学建模国赛',
    level: 'national',
    levelText: '国家级',
    category: 'subject',
    categoryText: '学科竞赛',
    organizer: '中国工业与应用数学学会',
    description: '全国高校规模最大的基础性学科竞赛，三人一队，在三天内完成一道实际问题的数学建模求解并撰写论文。含金量高，是保研加分的重要依据。',
    officialUrl: 'http://www.mcm.edu.cn',
    logoUrl: '',
    suitable: '数学、计算机、工程等专业，具备一定建模与编程能力',
    tags: ['数学建模', '论文写作', '保研加分'],
    reward: '国奖（一、二等奖）约占参赛队伍 8%',
    hot: 98
  },
  {
    id: 'lanqiao',
    name: '蓝桥杯全国软件和信息技术专业人才大赛',
    shortName: '蓝桥杯',
    level: 'national',
    levelText: '国家级',
    category: 'coding',
    categoryText: '编程',
    organizer: '工业和信息化部人才交流中心',
    description: '面向高校的程序设计竞赛，覆盖 C/C++、Java、Python 等多个组别，个人赛为主，适合练手与证明编程能力。',
    officialUrl: 'https://dasai.lanqiao.cn',
    logoUrl: '',
    suitable: '计算机相关专业，有编程基础',
    tags: ['算法', '编程', '个人赛'],
    reward: '省赛一、二、三等奖；国赛一、二、三等奖',
    hot: 92
  },
  {
    id: 'tiaozhan',
    name: '挑战杯全国大学生课外学术科技作品竞赛',
    shortName: '挑战杯',
    level: 'national',
    levelText: '国家级',
    category: 'innovation',
    categoryText: '创新创业',
    organizer: '共青团中央、中国科协',
    description: '被誉为大学生科技创新的"奥林匹克"，需提交课外学术科技作品，两年一届，含金量极高。',
    officialUrl: 'http://www.tiaozhanbei.net',
    logoUrl: '',
    suitable: '各专业，有科研或创新项目基础',
    tags: ['创新创业', '科研', '团队赛'],
    reward: '国赛特等、一、二、三等奖',
    hot: 95
  },
  {
    id: 'nepcs',
    name: '全国大学生英语竞赛（NECCS）',
    shortName: '大英赛',
    level: 'national',
    levelText: '国家级',
    category: 'english',
    categoryText: '英语',
    organizer: '高等学校大学外语教学研究会',
    description: '全国性大学英语学科竞赛，分 A/B/C/D 类，初赛在校内进行，获奖相对容易，是英语能力与综测加分的热门赛事。',
    officialUrl: 'http://www.chinaneccs.cn',
    logoUrl: '',
    suitable: '全体大学生，英语基础即可',
    tags: ['英语', '综测加分'],
    reward: '初赛全国一、二、三等奖',
    hot: 88
  },
  {
    id: 'acm',
    name: 'ACM-ICPC 国际大学生程序设计竞赛',
    shortName: 'ACM-ICPC',
    level: 'international',
    levelText: '国际级',
    category: 'coding',
    categoryText: '编程',
    organizer: 'ACM 国际计算机协会',
    description: '全球最具影响力的大学生编程竞赛，三人一队共用一台电脑解算法题，亚洲区域赛选拔进入世界总决赛。',
    officialUrl: 'https://icpc.global',
    logoUrl: '',
    suitable: '算法竞赛爱好者，编程基础扎实',
    tags: ['算法', '团队赛', '国际赛'],
    reward: '区域赛金银铜牌',
    hot: 90
  },
  {
    id: 'jsjds',
    name: '中国大学生计算机设计大赛',
    shortName: '计算机设计大赛',
    level: 'national',
    levelText: '国家级',
    category: 'coding',
    categoryText: '编程',
    organizer: '教育部高等学校计算机类专业教学指导委员会',
    description: '涵盖软件应用开发、人工智能、物联网、数字媒体等多个赛道，作品形式参赛，适合发挥创意。',
    officialUrl: 'https://jsjds.blcu.edu.cn',
    logoUrl: '',
    suitable: '计算机相关专业，有项目或作品想法',
    tags: ['软件开发', '作品赛', '创意'],
    reward: '国赛一、二、三等奖',
    hot: 82
  },
  {
    id: 'waiyanshe',
    name: '外研社·国才杯英语演讲大赛',
    shortName: '外研社英语演讲',
    level: 'national',
    levelText: '国家级',
    category: 'english',
    categoryText: '英语',
    organizer: '外语教学与研究出版社',
    description: '全国英语演讲、写作、阅读系列赛事，锻炼英语表达与思辨能力，是英语类高含金量赛事之一。',
    officialUrl: 'https://uchallenge.unipus.cn',
    logoUrl: '',
    suitable: '英语口语或写作突出',
    tags: ['英语', '演讲', '写作'],
    reward: '全国金、银、铜奖',
    hot: 78
  },
  {
    id: 'internetplus',
    name: '中国国际大学生创新大赛',
    shortName: '中国国际创新大赛',
    level: 'national',
    levelText: '国家级',
    category: 'innovation',
    categoryText: '创新创业',
    organizer: '教育部等十二部委联合主办',
    description: '全国规格最高、覆盖面最广的大学生创新创业赛事（原"互联网+"大赛）。以"我敢闯、我会创"为主题，分高教主赛道、红旅赛道、职教赛道、产业赛道、萌芽赛道，经校赛、省赛、全国总决赛三级选拔创业项目。',
    officialUrl: 'https://cy.ncss.cn',
    logoUrl: '',
    suitable: '各专业，有创业项目或创新想法',
    tags: ['创新创业', '创业计划', '团队赛', '保研加分'],
    reward: '国赛金、银、铜奖',
    hot: 99
  },
  {
    id: 'nuedc',
    name: '全国大学生电子设计竞赛',
    shortName: '电赛',
    level: 'national',
    levelText: '国家级',
    category: 'coding',
    categoryText: '编程',
    organizer: '教育部高等教育司、工业和信息化部人事教育司',
    description: '电子信息类顶级赛事，三人一队在四天三夜内完成一道电子系统设计与制作题目，覆盖模拟/数字电路、嵌入式、通信等领域，需现场演示与答辩，最高奖为 TI 杯。',
    officialUrl: 'http://nuedc.xjtu.edu.cn',
    logoUrl: '',
    suitable: '电子信息、自动化、通信、计算机等专业',
    tags: ['电子设计', '硬件', '团队赛', '工程实践'],
    reward: '全国一、二等奖（TI杯为最高奖）',
    hot: 91
  },
  {
    id: 'cmc',
    name: '全国大学生数学竞赛（CMC）',
    shortName: '数学竞赛',
    level: 'national',
    levelText: '国家级',
    category: 'subject',
    categoryText: '学科竞赛',
    organizer: '中国数学会',
    description: '国内规模最大、级别最高的基础数学学科竞赛，分数学专业类与非数学专业类，先分区初赛再全国决赛，覆盖微积分、线性代数、数学分析等内容，是保研与奖学金的重要加分项。',
    officialUrl: 'https://www.cmathc.org.cn',
    logoUrl: '',
    suitable: '全体本科生，数学基础扎实',
    tags: ['数学', '个人赛', '保研加分'],
    reward: '初赛一/二/三等奖，决赛一/二/三等奖',
    hot: 89
  },
  {
    id: 'sanchuang',
    name: '全国大学生电子商务创新创意及创业挑战赛',
    shortName: '三创赛',
    level: 'national',
    levelText: '国家级',
    category: 'innovation',
    categoryText: '创新创业',
    organizer: '全国电子商务产教融合创新联盟、西安交通大学',
    description: '以"创新、创意及创业"为主题，围绕电子商务开展创业项目策划与路演，设常规赛与实战、跨境、乡村振兴等方向，提交商业计划书并现场答辩。',
    officialUrl: 'http://www.3chuang.net',
    logoUrl: '',
    suitable: '经管、电商、计算机等专业',
    tags: ['电子商务', '创业', '路演'],
    reward: '国赛特、一、二、三等奖',
    hot: 80
  },
  {
    id: 'dagguang',
    name: '全国大学生广告艺术大赛',
    shortName: '大广赛',
    level: 'national',
    levelText: '国家级',
    category: 'art',
    categoryText: '艺术体育',
    organizer: '中国高等教育学会、教育部新闻传播学类专业教学指导委员会',
    description: '面向全国大学生的广告创意设计赛事，围绕企业真实命题创作平面、视频、动画、文案、策划案等作品，是设计类、传媒类学生的热门赛事。',
    officialUrl: 'http://www.sun-ada.net',
    logoUrl: '',
    suitable: '设计、传媒、广告、营销等专业',
    tags: ['广告设计', '创意', '作品赛'],
    reward: '全国一、二、三等奖',
    hot: 76
  },
  {
    id: 'fuwubao',
    name: '中国大学生服务外包创新创业大赛',
    shortName: '服务外包大赛',
    level: 'national',
    levelText: '国家级',
    category: 'innovation',
    categoryText: '创新创业',
    organizer: '教育部、商务部、无锡市人民政府',
    description: '以服务外包产业为背景，企业发布真实命题，学生团队进行解决方案设计与开发，注重产教融合与实际落地，是 IT 与商科交叉的高含金量赛事。',
    officialUrl: 'http://www.fwwb.org.cn',
    logoUrl: '',
    suitable: '计算机、软件、商科等专业',
    tags: ['服务外包', '产教融合', '团队赛'],
    reward: '国赛一、二、三等奖',
    hot: 74
  },
  {
    id: 'jieneng',
    name: '全国大学生节能减排社会实践与科技竞赛',
    shortName: '节能减排大赛',
    level: 'national',
    levelText: '国家级',
    category: 'innovation',
    categoryText: '创新创业',
    organizer: '教育部高等教育司',
    description: '围绕"节能减排、绿色能源"主题的全国性科技竞赛，提交科技作品或社会实践调查报告，分科技制作类与调研报告类，倡导绿色低碳创新。',
    officialUrl: 'http://www.jienengjianpai.org',
    logoUrl: '',
    suitable: '能源、环境、机械、化工等专业',
    tags: ['节能减排', '绿色能源', '作品赛'],
    reward: '全国特、一、二、三等奖',
    hot: 72
  }
];

/** 本地 Mock：时间节点（围绕 2026 年 9-12 月） */
function buildMockStages(): CompetitionStage[] {
  const d = (m: number, day: number): number => new Date(2026, m, day).getTime();
  return [
    { id: 'mcm-s1', competitionId: 'mcm', competitionName: '全国大学生数学建模竞赛', level: 'national', category: 'subject', type: 'enroll_start', typeText: '报名开始', title: '报名开始', time: d(8, 1), note: '通过官网组队报名' },
    { id: 'mcm-s2', competitionId: 'mcm', competitionName: '全国大学生数学建模竞赛', level: 'national', category: 'subject', type: 'enroll_end', typeText: '报名截止', title: '报名截止', time: d(8, 25), note: '逾期不再受理报名' },
    { id: 'mcm-s3', competitionId: 'mcm', competitionName: '全国大学生数学建模竞赛', level: 'national', category: 'subject', type: 'contest', typeText: '正式比赛', title: '正式比赛', time: d(8, 26), note: '连续 72 小时赛题求解' },
    { id: 'mcm-s4', competitionId: 'mcm', competitionName: '全国大学生数学建模竞赛', level: 'national', category: 'subject', type: 'result', typeText: '结果公布', title: '结果公布', time: d(9, 15), note: '官网公示获奖名单' },
    { id: 'lanqiao-s1', competitionId: 'lanqiao', competitionName: '蓝桥杯', level: 'national', category: 'coding', type: 'enroll_start', typeText: '报名开始', title: '报名开始', time: d(9, 8), note: '学校统一报名' },
    { id: 'tiaozhan-s1', competitionId: 'tiaozhan', competitionName: '挑战杯', level: 'national', category: 'innovation', type: 'enroll_end', typeText: '报名截止', title: '校赛报名截止', time: d(9, 30), note: '提交作品申报书' },
    { id: 'jsjds-s1', competitionId: 'jsjds', competitionName: '中国大学生计算机设计大赛', level: 'national', category: 'coding', type: 'enroll_start', typeText: '报名开始', title: '报名开始', time: d(10, 5), note: '提交作品简介' },
    { id: 'acm-s1', competitionId: 'acm', competitionName: 'ACM-ICPC', level: 'international', category: 'coding', type: 'contest', typeText: '正式比赛', title: '亚洲区域赛', time: d(9, 24), note: '区域赛站点赛' },
    { id: 'nepcs-s1', competitionId: 'nepcs', competitionName: '全国大学生英语竞赛', level: 'national', category: 'english', type: 'enroll_start', typeText: '报名开始', title: '报名开始', time: d(11, 1), note: '校内统一组织报名' },
    { id: 'tiaozhan-s2', competitionId: 'tiaozhan', competitionName: '挑战杯', level: 'national', category: 'innovation', type: 'contest', typeText: '正式比赛', title: '校级选拔赛', time: d(10, 20), note: '校内答辩评审' },
    { id: 'waiyanshe-s1', competitionId: 'waiyanshe', competitionName: '外研社英语演讲大赛', level: 'national', category: 'english', type: 'contest', typeText: '正式比赛', title: '初赛', time: d(10, 5), note: '线上提交演讲视频' },
    { id: 'jsjds-s2', competitionId: 'jsjds', competitionName: '中国大学生计算机设计大赛', level: 'national', category: 'coding', type: 'enroll_end', typeText: '报名截止', title: '报名截止', time: d(10, 31), note: '提交完整作品' },
    { id: 'internetplus-s1', competitionId: 'internetplus', competitionName: '中国国际大学生创新大赛', level: 'national', category: 'innovation', type: 'enroll_end', typeText: '报名截止', title: '报名截止', time: d(8, 25), note: '登录全国大学生创业服务网报名' },
    { id: 'internetplus-s2', competitionId: 'internetplus', competitionName: '中国国际大学生创新大赛', level: 'national', category: 'innovation', type: 'contest', typeText: '正式比赛', title: '全国总决赛', time: d(9, 15), note: '国赛项目路演答辩' },
    { id: 'cmc-s1', competitionId: 'cmc', competitionName: '全国大学生数学竞赛', level: 'national', category: 'subject', type: 'contest', typeText: '正式比赛', title: '分区初赛', time: d(9, 28), note: '各省统一组织考试' },
    { id: 'nuedc-s1', competitionId: 'nuedc', competitionName: '全国大学生电子设计竞赛', level: 'national', category: 'coding', type: 'contest', typeText: '正式比赛', title: '专题赛/省赛', time: d(10, 5), note: '电赛两年一届，间隔年设专题赛' },
    { id: 'sanchuang-s1', competitionId: 'sanchuang', competitionName: '三创赛', level: 'national', category: 'innovation', type: 'enroll_end', typeText: '报名截止', title: '校赛报名截止', time: d(10, 15), note: '提交商业计划书' },
    { id: 'dagguang-s1', competitionId: 'dagguang', competitionName: '大广赛', level: 'national', category: 'art', type: 'enroll_end', typeText: '报名截止', title: '作品提交截止', time: d(10, 30), note: '提交广告创意作品' },
    { id: 'fuwubao-s1', competitionId: 'fuwubao', competitionName: '服务外包大赛', level: 'national', category: 'innovation', type: 'enroll_start', typeText: '报名开始', title: '报名开始', time: d(11, 1), note: '企业命题发布' }
  ];
}

/** 收藏的竞赛 ID（本地持久化） */
let favoritedIds: string[] = [];

/** 已保存的规划（本地持久化） */
let savedPlans: StudyPlan[] = [];

let initPromise: Promise<void> | null = null;

/** 从本地存储加载收藏与规划 */
async function doInit(): Promise<void> {
  try {
    const favStr = await LocalStore.load('favorites', '[]');
    favoritedIds = JSON.parse(favStr) as string[];
  } catch (e) {
    favoritedIds = [];
  }
  try {
    const planStr = await LocalStore.load('plans', '[]');
    savedPlans = JSON.parse(planStr) as StudyPlan[];
    // 兼容旧数据：确保 doneTasks 字段存在
    for (const p of savedPlans) {
      if (!Array.isArray(p.doneTasks)) {
        p.doneTasks = [];
      }
    }
  } catch (e) {
    savedPlans = [];
  }
}

export class CloudService {
  /** 初始化本地存储（应用启动时调用，幂等） */
  static init(): Promise<void> {
    if (initPromise === null) {
      initPromise = doInit();
    }
    return initPromise;
  }

  /** 获取全部竞赛 */
  static async getCompetitions(): Promise<Competition[]> {
    if (CloudConfig.USE_MOCK) {
      return MOCK_COMPETITIONS;
    }
    const params: ListQuery = { page: 1, size: 100 };
    return CloudService.callCloudFunction<Competition[]>('comp-list', params);
  }

  /** 获取时间线节点（按时间区间） */
  static async getStages(startTime: number, endTime: number, category: string): Promise<CompetitionStage[]> {
    if (!CloudConfig.USE_MOCK) {
      const params: StageQuery = { startTime: startTime, endTime: endTime, category: category };
      return CloudService.callCloudFunction<CompetitionStage[]>('comp-stages', params);
    }
    let stages = buildMockStages().filter((s: CompetitionStage) => {
      return s.time >= startTime && s.time <= endTime;
    });
    if (category !== 'all') {
      stages = stages.filter((s: CompetitionStage) => s.category === category);
    }
    stages.sort((a: CompetitionStage, b: CompetitionStage) => a.time - b.time);
    return stages;
  }

  /** 获取竞赛详情（含节点） */
  static async getCompetitionDetail(competitionId: string): Promise<CompetitionDetail> {
    if (!CloudConfig.USE_MOCK) {
      const params: IdQuery = { competitionId: competitionId };
      return CloudService.callCloudFunction<CompetitionDetail>('comp-detail', params);
    }
    const competition = MOCK_COMPETITIONS.find((c: Competition) => c.id === competitionId);
    if (competition === undefined) {
      throw new Error('竞赛不存在');
    }
    const stages = buildMockStages()
      .filter((s: CompetitionStage) => s.competitionId === competitionId)
      .sort((a: CompetitionStage, b: CompetitionStage) => a.time - b.time);
    return { competition: competition, stages: stages };
  }

  /** 收藏 / 取消收藏 */
  static async toggleFavorite(competitionId: string): Promise<boolean> {
    if (!CloudConfig.USE_MOCK) {
      const params: IdQuery = { competitionId: competitionId };
      const r = await CloudService.callCloudFunction<FavToggleResult>('fav-toggle', params);
      return r.favorited;
    }
    await CloudService.init();
    const index = favoritedIds.indexOf(competitionId);
    let result = false;
    if (index >= 0) {
      favoritedIds.splice(index, 1);
      result = false;
    } else {
      favoritedIds.push(competitionId);
      result = true;
    }
    await LocalStore.save('favorites', JSON.stringify(favoritedIds));
    return result;
  }

  /** 是否已收藏 */
  static async isFavorite(competitionId: string): Promise<boolean> {
    if (!CloudConfig.USE_MOCK) {
      const favs = await CloudService.getFavorites();
      return favs.findIndex((c: Competition) => c.id === competitionId) >= 0;
    }
    await CloudService.init();
    return favoritedIds.indexOf(competitionId) >= 0;
  }

  /** 我的收藏列表 */
  static async getFavorites(): Promise<Competition[]> {
    if (!CloudConfig.USE_MOCK) {
      return CloudService.callCloudFunction<Competition[]>('fav-list', EMPTY_QUERY);
    }
    await CloudService.init();
    return MOCK_COMPETITIONS.filter((c: Competition) => favoritedIds.indexOf(c.id) >= 0);
  }

  /** 保存学习规划（按 id 去重） */
  static async savePlan(plan: StudyPlan): Promise<boolean> {
    if (!CloudConfig.USE_MOCK) {
      const r = await CloudService.callCloudFunction<StudyPlan>('plan-save', plan);
      return r.id !== '';
    }
    await CloudService.init();
    const exists = savedPlans.find((p: StudyPlan) => p.id === plan.id);
    if (exists === undefined) {
      savedPlans.push(plan);
      await LocalStore.save('plans', JSON.stringify(savedPlans));
    }
    return true;
  }

  /** 我的规划列表 */
  static async getPlans(): Promise<StudyPlan[]> {
    if (!CloudConfig.USE_MOCK) {
      return CloudService.callCloudFunction<StudyPlan[]>('plan-list', EMPTY_QUERY);
    }
    await CloudService.init();
    return savedPlans;
  }

  /** 按 ID 获取规划详情 */
  static async getPlanById(planId: string): Promise<StudyPlan | undefined> {
    if (!CloudConfig.USE_MOCK) {
      const params: PlanIdQuery = { planId: planId };
      return CloudService.callCloudFunction<StudyPlan | undefined>('plan-detail', params);
    }
    await CloudService.init();
    return savedPlans.find((p: StudyPlan) => p.id === planId);
  }

  /** 打卡：切换某任务的完成状态，返回是否已完成 */
  static async toggleTask(planId: string, taskKey: string): Promise<boolean> {
    if (!CloudConfig.USE_MOCK) {
      const params: TaskToggleQuery = { planId: planId, taskKey: taskKey };
      const r = await CloudService.callCloudFunction<TaskToggleResult>('plan-task-toggle', params);
      return r.done;
    }
    await CloudService.init();
    const plan = savedPlans.find((p: StudyPlan) => p.id === planId);
    if (plan === undefined) {
      return false;
    }
    const idx = plan.doneTasks.indexOf(taskKey);
    if (idx >= 0) {
      plan.doneTasks.splice(idx, 1);
    } else {
      plan.doneTasks.push(taskKey);
    }
    await LocalStore.save('plans', JSON.stringify(savedPlans));
    return idx < 0;
  }

  /** 清除本地收藏与规划数据 */
  static async clearAll(): Promise<void> {
    await CloudService.init();
    favoritedIds = [];
    savedPlans = [];
    await LocalStore.save('favorites', '[]');
    await LocalStore.save('plans', '[]');
  }

  /**
   * 调用 AGC 云函数（HTTP 触发器，泛型返回）
   * 接入后：将 CloudConfig.USE_MOCK 置 false，并配置 CLOUD_FUNCTION_BASE
   * 注：自动在请求体注入 openid（华为账号登录后的用户标识），云函数据此识别数据归属。
   */
  static async callCloudFunction<T>(action: string, params: object): Promise<T> {
    const url = `${CloudConfig.CLOUD_FUNCTION_BASE}/${action}`;
    // 注入用户标识（直接读 LocalStore，避免与 UserService 形成循环依赖）
    let openId = '';
    try {
      openId = await LocalStore.load('user_openid', '');
    } catch (e) {
      openId = '';
    }
    const payload: Record<string, Object> = params as Record<string, Object>;
    const merged: Record<string, Object> = {};
    const keys = Object.keys(payload);
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      merged[k] = payload[k];
    }
    merged['openid'] = openId;
    // 同时把 action 放入请求体，云函数据此分发（与 URL 路径互为冗余，兼容不同 HTTP 触发器配置）
    merged['action'] = action;
    const body = JSON.stringify(merged);
    return new Promise<T>((resolve, reject) => {
      const httpRequest = http.createHttp();
      httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 30000
      }).then((response) => {
        const result = response.result as string;
        httpRequest.destroy();
        const json = JSON.parse(result) as CloudResponse<T>;
        if (json.code === 0) {
          resolve(json.data);
        } else {
          reject(new Error(`云函数错误 code=${json.code}`));
        }
      }).catch((err: BusinessError) => {
        httpRequest.destroy();
        reject(err);
      });
    });
  }
}
