/**
 * 用户服务：个人资料 + 登录状态
 * - CloudConfig.USE_MOCK = true 时本地持久化（离线可用）
 * - false 时走 AGC 云函数（资料云端存储、跨设备同步）
 */
import { UserProfile } from '../model/User';
import { LocalStore } from '../common/LocalStore';
import { CloudConfig } from '../common/Constants';
import { CloudService } from './CloudService';

/** 云端资料结构（不含 loggedIn，登录态为客户端概念） */
interface CloudProfile {
  nickname: string;
  school: string;
  major: string;
  grade: string;
}

/** 资料查询/更新参数 */
interface ProfileQuery {
  action: string;
  nickname: string;
  school: string;
  major: string;
  grade: string;
}

/** 资料读取参数（仅查询动作） */
interface ProfileGetQuery {
  action: string;
}

const DEFAULT_PROFILE: UserProfile = {
  nickname: '竞赛小助手用户',
  school: '未设置学校',
  major: '未设置专业',
  grade: '未设置年级',
  loggedIn: false
};

let cache: UserProfile | null = null;

/** 当前登录用户 openid 缓存（本地持久化 key = user_openid） */
let cachedOpenId: string | null = null;

export class UserService {
  /** 记录当前用户 openid（华为账号登录成功后调用） */
  static async setCurrentUserId(openId: string): Promise<void> {
    cachedOpenId = openId;
    await LocalStore.save('user_openid', openId);
  }

  /** 获取当前用户 openid（未登录返回空串） */
  static async getCurrentUserId(): Promise<string> {
    if (cachedOpenId !== null) {
      return cachedOpenId;
    }
    try {
      cachedOpenId = await LocalStore.load('user_openid', '');
    } catch (e) {
      cachedOpenId = '';
    }
    return cachedOpenId;
  }

  /** 获取用户资料 */
  static async getProfile(): Promise<UserProfile> {
    if (cache !== null) {
      return cache;
    }
    if (!CloudConfig.USE_MOCK) {
      try {
        const params: ProfileGetQuery = { action: 'get' };
        const p = await CloudService.callCloudFunction<CloudProfile>('profile', params);
        cache = {
          nickname: p.nickname !== '' ? p.nickname : DEFAULT_PROFILE.nickname,
          school: p.school !== '' ? p.school : DEFAULT_PROFILE.school,
          major: p.major !== '' ? p.major : DEFAULT_PROFILE.major,
          grade: p.grade !== '' ? p.grade : DEFAULT_PROFILE.grade,
          loggedIn: true
        };
      } catch (e) {
        cache = DEFAULT_PROFILE;
      }
      return cache;
    }
    try {
      const str = await LocalStore.load('user_profile', '');
      if (str === '') {
        cache = DEFAULT_PROFILE;
      } else {
        const parsed = JSON.parse(str) as UserProfile;
        cache = {
          nickname: parsed.nickname || DEFAULT_PROFILE.nickname,
          school: parsed.school || DEFAULT_PROFILE.school,
          major: parsed.major || DEFAULT_PROFILE.major,
          grade: parsed.grade || DEFAULT_PROFILE.grade,
          loggedIn: parsed.loggedIn === true
        };
      }
    } catch (e) {
      cache = DEFAULT_PROFILE;
    }
    return cache;
  }

  /** 保存用户资料 */
  static async saveProfile(profile: UserProfile): Promise<void> {
    cache = profile;
    if (!CloudConfig.USE_MOCK) {
      const params: ProfileQuery = {
        action: 'update',
        nickname: profile.nickname,
        school: profile.school,
        major: profile.major,
        grade: profile.grade
      };
      await CloudService.callCloudFunction<object>('profile', params);
      return;
    }
    await LocalStore.save('user_profile', JSON.stringify(profile));
  }

  /**
   * 登录（已获得 openid 后调用）
   * @param openId 华为账号 openid；mock 模式下传空串即可（仅置登录态）
   */
  static async login(openId: string): Promise<void> {
    if (openId !== '') {
      await UserService.setCurrentUserId(openId);
    }
    const p = await UserService.getProfile();
    p.loggedIn = true;
    await UserService.saveProfile(p);
  }

  /** 退出登录 */
  static async logout(): Promise<void> {
    const p = await UserService.getProfile();
    p.loggedIn = false;
    await UserService.saveProfile(p);
    cachedOpenId = '';
    await LocalStore.save('user_openid', '');
  }

  /** 重置为默认资料 */
  static async reset(): Promise<void> {
    cache = DEFAULT_PROFILE;
    cachedOpenId = '';
    await LocalStore.save('user_profile', JSON.stringify(DEFAULT_PROFILE));
    await LocalStore.save('user_openid', '');
  }
}
