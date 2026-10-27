/**
 * 全局常量：颜色、分类、云函数配置
 */

/** 设计规范颜色（与 docs/03 UI 设计对齐） */
export class AppColors {
  static readonly PRIMARY: string = '#4F7CFF';
  static readonly PRIMARY_DARK: string = '#2F5BE0';
  static readonly SUCCESS: string = '#00C853';
  static readonly WARNING: string = '#FF6B35';
  static readonly ERROR: string = '#F5222D';
  static readonly BACKGROUND: string = '#F5F6F8';
  static readonly CARD: string = '#FFFFFF';
  static readonly TEXT_PRIMARY: string = '#182431';
  static readonly TEXT_SECONDARY: string = '#6B7785';
  static readonly DIVIDER: string = '#E8EAEE';
  static readonly WHITE: string = '#FFFFFF';
}

/** 竞赛分类 */
export class Categories {
  static readonly ALL: string = 'all';
  static readonly LIST: string[] = ['all', 'subject', 'innovation', 'english', 'art', 'coding'];

  static text(code: string): string {
    switch (code) {
      case 'subject':
        return '学科竞赛';
      case 'innovation':
        return '创新创业';
      case 'english':
        return '英语';
      case 'art':
        return '艺术体育';
      case 'coding':
        return '编程';
      default:
        return '全部';
    }
  }
}

/** 竞赛级别 */
export class Levels {
  static text(code: string): string {
    switch (code) {
      case 'national':
        return '国家级';
      case 'international':
        return '国际级';
      case 'provincial':
        return '省级';
      case 'school':
        return '校级';
      default:
        return '其他';
    }
  }
}

/** 云服务配置 */
export class CloudConfig {
  /** 是否使用本地 Mock 数据（未接入 AGC 前为 true） */
  static readonly USE_MOCK: boolean = true;
  /** AGC 云函数 HTTP 触发器地址（接入后填写） */
  static readonly CLOUD_FUNCTION_BASE: string = 'https://your-func.agconnect.link';
  /** 大模型 API 端点（经云函数代理，不直接暴露） */
  static readonly AI_GATEWAY: string = '';
}

/** 大模型（AI 学习规划）配置 */
export class AiConfig {
  /** 服务商 */
  static readonly PROVIDER: string = 'deepseek';
  /** DeepSeek API 基础地址（OpenAI 兼容） */
  static readonly BASE_URL: string = 'https://api.deepseek.com';
  /** 模型名称 */
  static readonly MODEL: string = 'deepseek-chat';
  /**
   * DeepSeek API Key
   * TODO：在 https://platform.deepseek.com 注册后，把下面的 Key 替换为你的真实 Key，
   *       并把 USE_MOCK_AI 改为 false，即可调用真实大模型。
   */
  static readonly API_KEY: string = 'YOUR_DEEPSEEK_API_KEY';
  /** 是否使用本地模拟 AI（true=模拟，false=真实调用 DeepSeek） */
  static readonly USE_MOCK_AI: boolean = true;
}

/** 时间节点类型文案 */
export class StageTypeText {
  static text(type: string): string {
    switch (type) {
      case 'enroll_start':
        return '报名开始';
      case 'enroll_end':
        return '报名截止';
      case 'contest':
        return '正式比赛';
      case 'result':
        return '结果公布';
      default:
        return '节点';
    }
  }
}
