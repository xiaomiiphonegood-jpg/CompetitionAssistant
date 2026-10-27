/**
 * AI 服务：学习规划生成
 * - AiConfig.USE_MOCK_AI = true 时走本地模拟（离线可用）
 * - false 时真实调用 DeepSeek 大模型（OpenAI 兼容接口）
 * 提示词体系见 docs/04-AI学习规划Prompt设计.md
 */
import { StudyPlan, PlanPhase, PlanRequest } from '../model/StudyPlan';
import { AiSettings } from '../model/AiSettings';
import { AiSettingsService } from './AiSettingsService';
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve();
    }, ms);
  });
}

/** 生成唯一 ID */
function genId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

/** DeepSeek 对话消息 */
interface ChatMsg {
  role: string;
  content: string;
}

/** DeepSeek 请求体 */
interface DeepSeekRequest {
  model: string;
  messages: ChatMsg[];
  temperature: number;
  max_tokens: number;
  stream: boolean;
}

/** DeepSeek 响应结构 */
interface DeepSeekMessage {
  role: string;
  content: string;
}

interface DeepSeekChoice {
  message: DeepSeekMessage;
}

interface DeepSeekResponse {
  choices: DeepSeekChoice[];
}

/** 大模型返回的计划 JSON 结构 */
interface AiPlanJson {
  summary: string;
  totalWeeks: number;
  phases: PlanPhase[];
  risks: string[];
}

/** 系统提示词（与 docs/04 对齐） */
const SYSTEM_PROMPT: string = `你是「竞赛备赛规划师」，一位熟悉中国大学生各类学科竞赛的资深教练。
你了解：数学建模、挑战杯、互联网+、蓝桥杯、ACM/ICPC、大创、英语竞赛、中国大学生计算机设计大赛等赛事的考核内容、备赛方法与时间节奏。

【职责】帮助大学生针对某场比赛制定分阶段、周粒度的备赛计划。

【必须遵守】
1. 根据用户提供的基础、每周时间、目标，制定可执行的计划。
2. 计划分 2-4 个阶段，阶段内拆周任务；周任务要具体、可执行。
3. 任务量必须匹配用户每周可投入时间，循序渐进，不要贪多。
4. 只输出 JSON，不要输出任何其他文字或解释。

【JSON 输出结构】（严格输出，字段名不可改）
{
  "summary": "一句话概括整体策略",
  "totalWeeks": 12,
  "phases": [
    {
      "name": "阶段名",
      "weeks": "第1-3周",
      "goal": "阶段目标",
      "tasks": ["第1周：...", "第2周：..."]
    }
  ],
  "risks": ["注意事项1", "注意事项2"]
}`;

/** 组装用户提示词 */
function buildUserPrompt(request: PlanRequest, feedback: string): string {
  let prompt = `请为以下情况制定备赛计划：

- 竞赛：${request.competitionName}
- 用户当前基础：${request.level}
- 每周可投入时间：${request.weeklyHours} 小时
- 目标：${request.target}

请直接输出 JSON 格式的备赛计划。`;
  if (feedback.trim() !== '') {
    prompt += `

用户对已生成计划的调整意见：${feedback.trim()}

请根据意见调整计划，重新输出完整 JSON。`;
  }
  return prompt;
}

/** 从模型输出中提取 JSON 字符串 */
function extractJson(content: string): string {
  const s = content.trim();
  const jsonMark = s.indexOf('```json');
  if (jsonMark >= 0) {
    const start = s.indexOf('\n', jsonMark);
    const end = s.indexOf('```', start >= 0 ? start + 1 : jsonMark + 7);
    if (start >= 0 && end > start) {
      return s.substring(start + 1, end).trim();
    }
  }
  const firstBrace = s.indexOf('{');
  const lastBrace = s.lastIndexOf('}');
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    return s.substring(firstBrace, lastBrace + 1);
  }
  return s;
}

/** 解析模型 JSON 为 StudyPlan */
function parsePlanJson(jsonStr: string, request: PlanRequest): StudyPlan {
  const data = JSON.parse(jsonStr) as AiPlanJson;
  const phases: PlanPhase[] = Array.isArray(data.phases) ? data.phases : [];
  const risks: string[] = Array.isArray(data.risks) ? data.risks : [];
  const totalWeeks: number = typeof data.totalWeeks === 'number' ? data.totalWeeks : 12;
  const summary: string = typeof data.summary === 'string' ? data.summary : '';
  return {
    id: genId('plan'),
    competitionId: request.competitionId,
    competitionName: request.competitionName,
    target: request.target,
    level: request.level,
    weeklyHours: request.weeklyHours,
    totalWeeks: totalWeeks,
    summary: summary,
    phases: phases,
    risks: risks,
    status: 'active',
    createdAt: Date.now(),
    doneTasks: []
  };
}

export class AiService {
  /** 生成学习规划（自动分流 mock / 真实大模型） */
  static async generatePlan(request: PlanRequest, feedback: string = ''): Promise<StudyPlan> {
    const settings = await AiSettingsService.getSettings();
    if (settings.useMock) {
      return AiService.generateMockPlan(request, feedback);
    }
    return AiService.generateRealPlan(request, feedback, settings);
  }

  /** 真实调用大模型生成计划 */
  static async generateRealPlan(request: PlanRequest, feedback: string, settings: AiSettings): Promise<StudyPlan> {
    const userPrompt = buildUserPrompt(request, feedback);
    const content = await AiService.chat(SYSTEM_PROMPT, userPrompt, settings);
    const jsonStr = extractJson(content);
    return parsePlanJson(jsonStr, request);
  }

  /** 调用大模型 chat/completions 接口（兼容 DeepSeek 与 Ollama OpenAI 兼容端点） */
  static async chat(systemPrompt: string, userPrompt: string, settings: AiSettings): Promise<string> {
    let base = settings.baseUrl;
    while (base.length > 0 && base.charAt(base.length - 1) === '/') {
      base = base.substring(0, base.length - 1);
    }
    // Ollama 走 OpenAI 兼容端点 /v1/chat/completions，DeepSeek 走 /chat/completions
    const url = settings.provider === 'ollama'
      ? `${base}/v1/chat/completions`
      : `${base}/chat/completions`;

    const messages: ChatMsg[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
    const body: DeepSeekRequest = {
      model: settings.model,
      messages: messages,
      temperature: 0.7,
      max_tokens: 4096,
      stream: false
    };
    const bodyStr = JSON.stringify(body);

    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (settings.apiKey !== '') {
      headers['Authorization'] = `Bearer ${settings.apiKey}`;
    }

    return new Promise<string>((resolve, reject) => {
      const httpRequest = http.createHttp();
      httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: bodyStr,
        connectTimeout: 15000,
        readTimeout: 60000
      }).then((response) => {
        const result = response.result as string;
        httpRequest.destroy();
        const json = JSON.parse(result) as DeepSeekResponse;
        if (json.choices !== undefined && json.choices.length > 0) {
          resolve(json.choices[0].message.content);
        } else {
          reject(new Error('大模型返回为空'));
        }
      }).catch((err: BusinessError) => {
        httpRequest.destroy();
        reject(new Error(`大模型调用失败: ${err.message}`));
      });
    });
  }

  /** 本地模拟生成（离线兜底） */
  static async generateMockPlan(request: PlanRequest, feedback: string): Promise<StudyPlan> {
    await sleep(900);

    let totalWeeks = 12;
    let intensity = '循序渐进，稳步推进';
    if (request.weeklyHours < 5) {
      totalWeeks = 16;
      intensity = '时间有限，拉长周期、降低单周强度';
    } else if (request.weeklyHours <= 10) {
      totalWeeks = 12;
      intensity = '节奏均衡，按部就班';
    } else {
      totalWeeks = 8;
      intensity = '时间充裕，集中高强度冲刺';
    }

    const p1 = Math.floor(totalWeeks / 3);
    const p2 = Math.floor(totalWeeks / 3);
    const p3 = totalWeeks - p1 - p2;

    const phases: PlanPhase[] = [
      {
        name: '基础夯实',
        weeks: `第1-${p1}周`,
        goal: `补齐「${request.competitionName}」所需的基础知识与必备技能`,
        tasks: [
          `第1周：通读官方往届赛题与评分标准，明确考察方向`,
          `第2周：系统学习核心知识点，整理笔记与知识框架`,
          `第${Math.max(3, Math.floor(p1 / 2))}周：完成 1-2 套基础练习，定位薄弱环节`,
          `第${p1}周：复盘基础阶段，输出阶段性小结`
        ]
      },
      {
        name: '专题突破',
        weeks: `第${p1 + 1}-${p1 + p2}周`,
        goal: '针对薄弱点与高频考点做专题强化',
        tasks: [
          `第${p1 + 1}周：逐个击破薄弱专题，配合针对性练习`,
          `第${p1 + Math.ceil(p2 / 2)}周：开始做完整往届真题，严格计时`,
          `第${p1 + p2}周：总结高频题型与解题套路，形成自己的方法论`
        ]
      },
      {
        name: '实战冲刺',
        weeks: `第${p1 + p2 + 1}-${totalWeeks}周`,
        goal: '全真模拟 + 查漏补缺，调整到最佳状态',
        tasks: [
          `第${p1 + p2 + 1}周：全真模拟 2 次，完全按正式流程`,
          `第${totalWeeks - 1}周：复盘模拟问题，针对性补漏`,
          `第${totalWeeks}周：调整心态、整理物资清单，轻松上阵`
        ]
      }
    ];

    const risks: string[] = [
      '临近截止节点前易焦虑，建议用倒计时提醒自我监督',
      '避免只学不练，每周至少安排一次实践/真题输出',
      '组队项目需尽早固定队友，避免临时换人'
    ];

    return {
      id: genId('plan'),
      competitionId: request.competitionId,
      competitionName: request.competitionName,
      target: request.target,
      level: request.level,
      weeklyHours: request.weeklyHours,
      totalWeeks: totalWeeks,
      summary: `针对「${request.competitionName}」，以「${request.target}」为目标，每周投入约 ${request.weeklyHours} 小时，规划 ${totalWeeks} 周，${intensity}。`,
      phases: phases,
      risks: risks,
      status: 'active',
      createdAt: Date.now(),
      doneTasks: []
    };
  }
}
