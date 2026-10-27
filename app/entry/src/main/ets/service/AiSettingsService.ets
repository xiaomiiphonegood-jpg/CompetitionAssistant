/**
 * AI 模型配置服务：读写运行时模型配置（本地持久化）。
 * 默认值来自 AiConfig，用户可在设置页覆盖。
 */
import { AiSettings } from '../model/AiSettings';
import { AiConfig } from '../common/Constants';
import { LocalStore } from '../common/LocalStore';

function defaultSettings(): AiSettings {
  return {
    provider: AiConfig.PROVIDER,
    baseUrl: AiConfig.BASE_URL,
    model: AiConfig.MODEL,
    apiKey: AiConfig.API_KEY,
    useMock: AiConfig.USE_MOCK_AI
  };
}

let cache: AiSettings | null = null;

export class AiSettingsService {
  /** 获取当前模型配置 */
  static async getSettings(): Promise<AiSettings> {
    if (cache !== null) {
      return cache;
    }
    try {
      const str = await LocalStore.load('ai_settings', '');
      if (str === '') {
        cache = defaultSettings();
      } else {
        const parsed = JSON.parse(str) as AiSettings;
        cache = {
          provider: parsed.provider !== '' ? parsed.provider : 'deepseek',
          baseUrl: parsed.baseUrl !== '' ? parsed.baseUrl : AiConfig.BASE_URL,
          model: parsed.model !== '' ? parsed.model : AiConfig.MODEL,
          apiKey: parsed.apiKey !== undefined ? parsed.apiKey : '',
          useMock: parsed.useMock === true
        };
      }
    } catch (e) {
      cache = defaultSettings();
    }
    return cache;
  }

  /** 保存模型配置 */
  static async saveSettings(settings: AiSettings): Promise<void> {
    cache = settings;
    await LocalStore.save('ai_settings', JSON.stringify(settings));
  }

  /** 恢复默认配置 */
  static async reset(): Promise<void> {
    cache = null;
    await LocalStore.save('ai_settings', '');
  }
}
