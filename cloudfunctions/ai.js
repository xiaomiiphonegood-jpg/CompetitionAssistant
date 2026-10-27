/**
 * DeepSeek 大模型调用封装（运行在 AGC 云函数服务端，Key 存环境变量，不下发客户端）
 */
const https = require('https');

/** 系统提示词（与客户端 docs/04 对齐） */
const SYSTEM_PROMPT = `你是「竞赛备赛规划师」，一位熟悉中国大学生各类学科竞赛的资深教练。
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

/**
 * 调用 DeepSeek chat/completions（OpenAI 兼容）
 * @param {string} apiKey DeepSeek API Key
 * @param {Array<{role:string,content:string}>} messages
 * @returns {Promise<string>} 模型回复内容
 */
function callDeepSeek(apiKey, messages) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      model: 'deepseek-chat',
      messages: messages,
      temperature: 0.7,
      max_tokens: 4096,
      stream: false
    });
    const options = {
      hostname: 'api.deepseek.com',
      path: '/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + apiKey,
        'Content-Length': Buffer.byteLength(data)
      }
    };
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          if (json.choices && json.choices.length > 0) {
            resolve(json.choices[0].message.content);
          } else {
            reject(new Error('DeepSeek 返回为空：' + body));
          }
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

/** 组装用户提示词 */
function buildUserPrompt(request, feedback) {
  let prompt = `请为以下情况制定备赛计划：

- 竞赛：${request.competitionName}
- 用户当前基础：${request.level}
- 每周可投入时间：${request.weeklyHours} 小时
- 目标：${request.target}

请直接输出 JSON 格式的备赛计划。`;
  if (feedback && feedback.trim() !== '') {
    prompt += `

用户对已生成计划的调整意见：${feedback.trim()}

请根据意见调整计划，重新输出完整 JSON。`;
  }
  return prompt;
}

/** 从模型输出提取 JSON 字符串 */
function extractJson(content) {
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

/**
 * 生成学习规划
 * @param {string} apiKey DeepSeek Key
 * @param {object} request { competitionId, competitionName, level, weeklyHours, target }
 * @param {string} feedback 调整意见（可选）
 * @returns {Promise<object>} 计划 JSON
 */
async function generatePlan(apiKey, request, feedback) {
  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: buildUserPrompt(request, feedback) }
  ];
  const content = await callDeepSeek(apiKey, messages);
  const jsonStr = extractJson(content);
  return JSON.parse(jsonStr);
}

module.exports = { generatePlan, SYSTEM_PROMPT };
