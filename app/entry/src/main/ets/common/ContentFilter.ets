/**
 * 内容审核过滤：发帖 / AI 输入的基础敏感词拦截
 * 说明：此为「客户端基础过滤」，用于上架前的内容安全兜底；
 *      正式上线建议再接入 AGC 内容安全服务（云端更全面、支持图片/语义识别）。
 * 返回空串表示通过，否则返回命中的敏感词。
 */

/** 基础敏感词库（按类别，覆盖政治敏感/色情低俗/暴力/辱骂/广告等常见违规） */
const SENSITIVE_WORDS: string[] = [
  // 违法违规（政治敏感类）
  '代考', '代写', '代做', '枪手', '作弊', '替考', '泄题', '答案出售',
  '赌博', '博彩', '彩票代购', '赌球',
  '毒品', '大麻', '冰毒', '海洛因', '摇头丸',
  '枪支', '弹药', '管制刀具',
  '诈骗', '洗钱', '传销', '非法集资',
  '裸聊', '援交', '卖淫', '嫖娼', '色情服务',
  '办证', '假证', '学历造假',
  // 辱骂 / 人身攻击
  '傻逼', '煞笔', '草泥马', '妈的', '去死', '废物', '垃圾货',
  // 广告 / 垃圾信息
  '加微信领', '加群领', '刷单', '兼职日结', '日赚', '返利', '微商',
  '投资理财群', '稳赚不赔', '高收益', '无风险投资'
];

/** 半角/全角、大小写归一 */
function normalize(text: string): string {
  return text.toLowerCase().replace(/\s+/g, '');
}

/**
 * 检测文本是否包含敏感词
 * @returns 命中的敏感词（空串表示未命中）
 */
export class ContentFilter {
  static check(text: string): string {
    if (text === '') {
      return '';
    }
    const normalized = normalize(text);
    for (const word of SENSITIVE_WORDS) {
      if (normalized.indexOf(word) >= 0) {
        return word;
      }
    }
    return '';
  }

  /** 多字段联合检测（发帖含标题/内容/技能/联系方式时用） */
  static checkAll(fields: string[]): string {
    for (const f of fields) {
      const hit = ContentFilter.check(f);
      if (hit !== '') {
        return hit;
      }
    }
    return '';
  }
}
