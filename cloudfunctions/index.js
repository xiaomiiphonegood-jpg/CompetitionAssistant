/**
 * 大学生竞赛助手 - AGC 云函数统一入口
 * 通过 event.action 分发；返回 { code, message, data }
 * 部署：上传到 AGC Cloud Functions，环境变量配置 DEEPSEEK_API_KEY
 *
 * 说明：数据库操作采用 AGC Cloud Functions 标准写法。
 * 若你使用的 AGC SDK 版本 API 有差异，只需调整 db.js 中的封装即可，业务逻辑不变。
 */
const ai = require('./ai');

// ============ 统一响应 ============
function ok(data) {
  return { code: 0, message: 'ok', data: data };
}
function fail(code, message) {
  return { code: code, message: message, data: null };
}

// ============ 数据库封装（AGC Cloud DB） ============
// 使用 @agconnect/cloud-server 提供的 database 能力
const cloud = require('@agconnect/cloud-server');
const db = cloud.database();

const COLLECTIONS = {
  COMPETITION: 'competition',
  STAGE: 'competition_stage',
  USER: 'user_profile',
  FAVORITE: 'favorite',
  PLAN: 'study_plan',
  TEAM: 'team_post',
  SHARE: 'share_post'
};

/** 获取当前登录用户标识（openid）：
 *  1. 优先取 AGC Auth / 云函数上下文注入的用户身份（不可由客户端伪造）；
 *  2. 未接入 AGC Auth 时，兼容开发环境由客户端注入的 event.openid。
 *  生产环境请启用 AGC Auth 并移除第 2 条回退逻辑。
 */
function currentUserId(context, event) {
  try {
    const verified = context.getUserId ? context.getUserId() : context.OPENID;
    if (typeof verified === 'string' && verified !== '') {
      return verified;
    }
  } catch (e) {
    // 未配置 AGC Auth 时忽略
  }
  if (event && typeof event.openid === 'string' && event.openid !== '') {
    return event.openid;
  }
  return null;
}

/** 查询集合（含条件、分页） */
async function queryCollection(name, where, orderBy, limit) {
  let q = db.collection(name);
  if (where && Object.keys(where).length > 0) {
    q = q.where(where);
  }
  if (orderBy) {
    q = q.orderBy(orderBy.field, orderBy.direction || 'desc');
  }
  if (limit) {
    q = q.limit(limit);
  }
  const res = await q.get();
  return res.data || [];
}

/** 字段规范化：把云数据库 _id 映射为客户端期望的 id，去除 _openid 内部字段 */
function toClient(doc) {
  if (!doc) {
    return doc;
  }
  const out = Object.assign({}, doc);
  if (!out.id) {
    out.id = out._id;
  }
  delete out._openid;
  return out;
}

function toClientList(list) {
  return (list || []).map(toClient);
}

// ============ 内容审核（服务端兜底） ============
const SENSITIVE_WORDS = [
  '代考', '代写', '代做', '枪手', '作弊', '替考', '泄题',
  '赌博', '博彩', '毒品', '大麻', '冰毒', '海洛因', '摇头丸',
  '枪支', '弹药', '诈骗', '洗钱', '传销', '非法集资',
  '裸聊', '援交', '卖淫', '嫖娼',
  '傻逼', '煞笔', '草泥马', '妈的', '去死', '废物',
  '加微信领', '刷单', '兼职日结', '日赚', '返利', '微商', '稳赚不赔'
];

/** 检测是否命中敏感词，命中返回该词，否则返回空串 */
function checkSensitive(text) {
  if (!text) {
    return '';
  }
  const normalized = String(text).toLowerCase().replace(/\s+/g, '');
  for (const w of SENSITIVE_WORDS) {
    if (normalized.indexOf(w) >= 0) {
      return w;
    }
  }
  return '';
}

// ============ 业务处理 ============

/** 竞赛列表 */
async function handleCompList(params) {
  const where = {};
  if (params.category && params.category !== 'all') {
    where.category = params.category;
  }
  if (params.level) {
    where.level = params.level;
  }
  const list = await queryCollection(COLLECTIONS.COMPETITION, where, { field: 'hot', direction: 'desc' }, 100);
  return toClientList(list);
}

/** 时间线节点 */
async function handleCompStages(params) {
  const { startTime, endTime, category } = params;
  const stages = await queryCollection(COLLECTIONS.STAGE, {}, { field: 'time', direction: 'asc' }, 500);
  const filtered = stages.filter((s) => {
    const inRange = s.time >= startTime && s.time <= endTime;
    const matchCat = !category || category === 'all' || s.category === category;
    return inRange && matchCat;
  });
  return toClientList(filtered);
}

/** 竞赛详情 */
async function handleCompDetail(params) {
  // 竞赛文档的业务主键是 id 字段（seed 数据里的 'mcm' 等），而非云 DB 自动生成的 _id
  const list = await queryCollection(COLLECTIONS.COMPETITION, { id: params.competitionId }, null, 1);
  if (list.length === 0) {
    throw new Error('竞赛不存在');
  }
  const stages = await queryCollection(COLLECTIONS.STAGE, { competitionId: params.competitionId }, { field: 'time', direction: 'asc' }, 100);
  return { competition: toClient(list[0]), stages: toClientList(stages) };
}

/** 收藏 / 取消收藏 */
async function handleFavToggle(params, userId) {
  const list = await queryCollection(COLLECTIONS.FAVORITE, { _openid: userId, competitionId: params.competitionId }, null, 1);
  if (list.length > 0) {
    await db.collection(COLLECTIONS.FAVORITE).doc(list[0]._id).remove();
    return { favorited: false };
  }
  await db.collection(COLLECTIONS.FAVORITE).add({
    _openid: userId,
    competitionId: params.competitionId,
    createdAt: Date.now()
  });
  return { favorited: true };
}

/** 我的收藏列表 */
async function handleFavList(userId) {
  const favs = await queryCollection(COLLECTIONS.FAVORITE, { _openid: userId }, { field: 'createdAt', direction: 'desc' }, 100);
  const ids = favs.map((f) => f.competitionId);
  const comps = await queryCollection(COLLECTIONS.COMPETITION, {}, null, 200);
  const matched = comps.filter((c) => ids.indexOf(c._id) >= 0 || ids.indexOf(c.id) >= 0);
  return toClientList(matched);
}

/** AI 生成学习规划（核心：Key 在服务端） */
async function handlePlanCreate(params, userId, context) {
  const apiKey = context.env && context.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    return fail(3001, '未配置 DEEPSEEK_API_KEY 环境变量');
  }
  const request = {
    competitionId: params.competitionId,
    competitionName: params.competitionName,
    level: params.level,
    weeklyHours: params.weeklyHours,
    target: params.target
  };
  const planJson = await ai.generatePlan(apiKey, request, params.feedback || '');
  const plan = Object.assign({
    _openid: userId,
    competitionId: params.competitionId,
    competitionName: params.competitionName,
    target: params.target,
    level: params.level,
    weeklyHours: params.weeklyHours,
    status: 'active',
    createdAt: Date.now(),
    doneTasks: []
  }, planJson);
  const addRes = await db.collection(COLLECTIONS.PLAN).add(plan);
  plan._id = addRes._id || addRes.id;
  return toClient(plan);
}

/** 我的规划列表 */
async function handlePlanList(userId) {
  const list = await queryCollection(COLLECTIONS.PLAN, { _openid: userId }, { field: 'createdAt', direction: 'desc' }, 100);
  return toClientList(list);
}

/** 保存规划（客户端已生成，直接落库，按 competitionId+用户去重） */
async function handlePlanSave(params, userId) {
  const existing = await queryCollection(COLLECTIONS.PLAN, { _openid: userId, id: params.id }, null, 1);
  if (existing.length > 0) {
    return toClient(existing[0]);
  }
  const plan = Object.assign({}, params, { _openid: userId, createdAt: Date.now() });
  const addRes = await db.collection(COLLECTIONS.PLAN).add(plan);
  plan._id = addRes._id || addRes.id;
  return toClient(plan);
}

/** 规划详情 */
async function handlePlanDetail(params, userId) {
  const list = await queryCollection(COLLECTIONS.PLAN, { _openid: userId, id: params.planId }, null, 1);
  if (list.length === 0) {
    return null;
  }
  return toClient(list[0]);
}

/** 打卡切换 */
async function handlePlanTaskToggle(params, userId) {
  const list = await queryCollection(COLLECTIONS.PLAN, { _openid: userId, id: params.planId }, null, 1);
  if (list.length === 0) {
    throw new Error('规划不存在');
  }
  const plan = list[0];
  const done = Array.isArray(plan.doneTasks) ? plan.doneTasks : [];
  const idx = done.indexOf(params.taskKey);
  let nowDone = false;
  if (idx >= 0) {
    done.splice(idx, 1);
  } else {
    done.push(params.taskKey);
    nowDone = true;
  }
  await db.collection(COLLECTIONS.PLAN).doc(plan._id).update({ doneTasks: done });
  return { done: nowDone };
}

/** 组队帖列表 */
async function handleTeamList(params) {
  const where = {};
  if (params.competitionId) {
    where.competitionId = params.competitionId;
  }
  const list = await queryCollection(COLLECTIONS.TEAM, where, { field: 'createdAt', direction: 'desc' }, 100);
  return toClientList(list);
}

/** 发布组队帖 */
async function handleTeamCreate(params, userId) {
  const hit = checkSensitive(`${params.content || ''} ${(params.needSkills || []).join(' ')} ${params.contact || ''}`);
  if (hit) {
    return fail(4001, '内容包含违规信息，请修改后发布');
  }
  const res = await db.collection(COLLECTIONS.TEAM).add({
    _openid: userId,
    competitionId: params.competitionId,
    competitionName: params.competitionName,
    authorName: params.authorName || '同学',
    needSkills: params.needSkills || [],
    content: params.content,
    contact: params.contact || '',
    createdAt: Date.now()
  });
  return { id: res._id || res.id };
}

/** 经验帖列表 */
async function handleShareList(userId) {
  const list = await queryCollection(COLLECTIONS.SHARE, {}, { field: 'createdAt', direction: 'desc' }, 100);
  // 按当前用户标记 liked，并剥离 likedBy（避免泄露其他用户 openid）
  return list.map((p) => {
    const likedBy = Array.isArray(p.likedBy) ? p.likedBy : [];
    const out = toClient(p);
    delete out.likedBy;
    out.liked = likedBy.indexOf(userId) >= 0;
    out.likes = p.likes || 0;
    return out;
  });
}

/** 发布经验帖 */
async function handleShareCreate(params, userId) {
  const hit = checkSensitive(`${params.title || ''} ${params.content || ''}`);
  if (hit) {
    return fail(4001, '内容包含违规信息，请修改后发布');
  }
  const res = await db.collection(COLLECTIONS.SHARE).add({
    _openid: userId,
    competitionId: params.competitionId,
    competitionName: params.competitionName,
    authorName: params.authorName || '同学',
    title: params.title,
    content: params.content,
    likes: 0,
    liked: false,
    likedBy: [],
    createdAt: Date.now()
  });
  return { id: res._id || res.id };
}

/** 点赞 / 取消点赞（按用户 toggle，记录 likedBy） */
async function handleShareLike(params, userId) {
  const list = await queryCollection(COLLECTIONS.SHARE, { _id: params.postId }, null, 1);
  if (list.length === 0) {
    throw new Error('帖子不存在');
  }
  const post = list[0];
  const likedBy = Array.isArray(post.likedBy) ? post.likedBy.slice() : [];
  const idx = likedBy.indexOf(userId);
  let liked = false;
  if (idx >= 0) {
    likedBy.splice(idx, 1);
    liked = false;
  } else {
    likedBy.push(userId);
    liked = true;
  }
  const newLikes = liked ? (post.likes || 0) + 1 : Math.max(0, (post.likes || 0) - 1);
  await db.collection(COLLECTIONS.SHARE).doc(post._id).update({ likedBy: likedBy, likes: newLikes });
  return { liked: liked };
}

/** 排行榜：按发帖数 + 获赞数实时统计，真实数据不足时以演示数据兜底 */
async function handleRankList() {
  const shares = await queryCollection(COLLECTIONS.SHARE, {}, null, 500);
  const teams = await queryCollection(COLLECTIONS.TEAM, {}, null, 500);

  const stat = {};
  for (const s of shares) {
    const name = s.authorName || '同学';
    if (!stat[name]) {
      stat[name] = { posts: 0, likes: 0, comps: {} };
    }
    stat[name].posts += 1;
    stat[name].likes += (s.likes || 0);
    if (s.competitionId) {
      stat[name].comps[s.competitionId] = true;
    }
  }
  for (const t of teams) {
    const name = t.authorName || '同学';
    if (!stat[name]) {
      stat[name] = { posts: 0, likes: 0, comps: {} };
    }
    stat[name].posts += 1;
    if (t.competitionId) {
      stat[name].comps[t.competitionId] = true;
    }
  }

  const list = Object.keys(stat).map((name) => {
    const u = stat[name];
    return {
      name: name,
      school: '—',
      score: u.posts * 20 + u.likes,
      competitions: Object.keys(u.comps).length
    };
  });

  // 真实数据不足 5 人时，用演示数据补齐，保证排行榜可看
  if (list.length < 5) {
    const demo = [
      { name: '张三', school: '清华大学', score: 1280, competitions: 6 },
      { name: '李四', school: '北京大学', score: 1150, competitions: 5 },
      { name: '王五', school: '浙江大学', score: 990, competitions: 5 },
      { name: '赵六', school: '上海交通大学', score: 880, competitions: 4 },
      { name: '孙七', school: '华中科技大学', score: 760, competitions: 4 }
    ];
    const names = list.map((x) => x.name);
    for (const d of demo) {
      if (names.indexOf(d.name) < 0) {
        list.push(d);
      }
    }
  }

  list.sort((a, b) => b.score - a.score);
  return list.slice(0, 10).map((u, i) => ({
    rank: i + 1,
    name: u.name,
    school: u.school,
    score: u.score,
    competitions: u.competitions
  }));
}

/** 用户资料（获取/更新） */
async function handleProfile(params, userId) {
  if (params.action === 'update') {
    const existing = await queryCollection(COLLECTIONS.USER, { _openid: userId }, null, 1);
    const payload = {
      nickname: params.nickname,
      school: params.school,
      major: params.major,
      grade: params.grade,
      updatedAt: Date.now()
    };
    if (existing.length > 0) {
      await db.collection(COLLECTIONS.USER).doc(existing[0]._id).update(payload);
    } else {
      await db.collection(COLLECTIONS.USER).add(Object.assign({ _openid: userId, createdAt: Date.now() }, payload));
    }
  }
  const list = await queryCollection(COLLECTIONS.USER, { _openid: userId }, null, 1);
  if (list.length === 0) {
    return {};
  }
  const u = list[0];
  return { nickname: u.nickname || '', school: u.school || '', major: u.major || '', grade: u.grade || '' };
}

// ============ 云函数入口 ============
module.exports = async function (event, context) {
  const action = event.action;
  const userId = currentUserId(context, event);
  try {
    switch (action) {
      case 'comp-list':
        return ok(await handleCompList(event));
      case 'comp-stages':
        return ok(await handleCompStages(event));
      case 'comp-detail':
        return ok(await handleCompDetail(event));
      case 'fav-toggle':
        return ok(await handleFavToggle(event, userId));
      case 'fav-list':
        return ok(await handleFavList(userId));
      case 'plan-create': {
        const r = await handlePlanCreate(event, userId, context);
        return r.code ? r : ok(r);
      }
      case 'plan-save':
        return ok(await handlePlanSave(event, userId));
      case 'plan-list':
        return ok(await handlePlanList(userId));
      case 'plan-detail':
        return ok(await handlePlanDetail(event, userId));
      case 'plan-task-toggle':
        return ok(await handlePlanTaskToggle(event, userId));
      case 'team-list':
        return ok(await handleTeamList(event));
      case 'team-create': {
        const r = await handleTeamCreate(event, userId);
        return r && r.code ? r : ok(r);
      }
      case 'share-list':
        return ok(await handleShareList(userId));
      case 'share-create': {
        const r = await handleShareCreate(event, userId);
        return r && r.code ? r : ok(r);
      }
      case 'share-like':
        return ok(await handleShareLike(event, userId));
      case 'rank-list':
        return ok(await handleRankList());
      case 'profile':
        return ok(await handleProfile(event, userId));
      default:
        return fail(1002, '未知 action: ' + action);
    }
  } catch (e) {
    return fail(5000, e.message || '服务器内部错误');
  }
};
