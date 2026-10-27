/**
 * 本地持久化封装（基于 Preferences）
 * 用于收藏、学习规划、打卡状态的本地存储（接入 AGC 后可平滑切换为云同步）
 */
import preferences from '@ohos.data.preferences';
import { getAppContext } from './AppContext';

const STORE_NAME = 'competition_assistant';

async function getPref(): Promise<preferences.Preferences> {
  const ctx = getAppContext();
  if (ctx === null) {
    throw new Error('AppContext 未初始化');
  }
  return preferences.getPreferences(ctx, STORE_NAME);
}

export class LocalStore {
  /** 保存字符串（复杂对象请 JSON.stringify 后传入） */
  static async save(key: string, value: string): Promise<void> {
    const pref = await getPref();
    await pref.put(key, value);
    await pref.flush();
  }

  /** 读取字符串，无则返回默认值 */
  static async load(key: string, defaultValue: string): Promise<string> {
    const pref = await getPref();
    const v = await pref.get(key, defaultValue);
    return v as string;
  }
}
