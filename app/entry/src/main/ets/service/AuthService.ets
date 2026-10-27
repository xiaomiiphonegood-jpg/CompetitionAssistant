/**
 * 认证服务：华为账号一键登录（Account Kit）
 *
 * 通过 @kit.AccountKit 的 authentication 模块拉起华为账号授权，
 * 获取 openID（应用维度用户唯一标识）与 unionID（开发者维度用户标识）。
 *
 * 接入前置（见 docs/06 §3.1）：
 *   1. module.json5 配置 client_id 元数据（来自 AGC 项目设置）；
 *   2. AGC 控制台登记应用签名 SHA256 指纹；
 *   3. 真机 + 已登录华为账号运行。
 * CloudConfig.USE_MOCK = true 时不走本服务，Login/Settings 直接模拟登录。
 */
import { authentication } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

/** 登录结果 */
export interface AuthResult {
  success: boolean;
  openId: string;
  unionId: string;
  message: string;
}

export class AuthService {
  /**
   * 拉起华为账号授权登录，成功后返回 openID / unionID。
   * @param context 页面上下文（需在 ArkUI 页面生命周期内传入，否则拉不起授权页）
   */
  static loginWithHuaweiId(context: common.Context | undefined): Promise<AuthResult> {
    return new Promise<AuthResult>((resolve) => {
      if (context === undefined) {
        resolve(AuthService.fail('无法获取页面上下文，请重试'));
        return;
      }
      let request: authentication.LoginWithHuaweiIDRequest;
      try {
        request = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
        request.forceLogin = true;
        request.state = util.generateRandomUUID();
      } catch (e) {
        resolve(AuthService.fail('初始化登录请求失败'));
        return;
      }
      const controller = new authentication.AuthenticationController(context);
      controller.executeRequest(request).then((response: authentication.AuthenticationResponse) => {
        // executeRequest 返回 AuthenticationResponse，实际为 LoginWithHuaweiIDResponse
        const loginResp = response as authentication.LoginWithHuaweiIDResponse;
        const credential = loginResp.data;
        if (credential === undefined) {
          resolve(AuthService.fail('未获取到登录凭据，请重试'));
          return;
        }
        resolve({
          success: true,
          openId: credential.openID,
          unionId: credential.unionID,
          message: '登录成功'
        });
      }).catch((err: BusinessError) => {
        resolve(AuthService.fail(AuthService.errorText(err.code)));
      });
    });
  }

  /** 构造失败结果 */
  private static fail(message: string): AuthResult {
    const r: AuthResult = { success: false, openId: '', unionId: '', message: message };
    return r;
  }

  /** 错误码 → 用户可读文案 */
  private static errorText(code: number): string {
    switch (code) {
      case 1001502001:
        return '华为账号未登录，请先登录华为账号';
      case 1001502002:
        return '应用未授权，请检查 AGC 配置';
      case 1001500001:
        return '应用签名指纹未登记，请在 AGC 配置 SHA256 指纹';
      case 1001502005:
        return '网络异常，请检查网络后重试';
      case 1001502012:
        return '已取消授权';
      case 1001500002:
        return '请求重复，请稍后重试';
      case 1001502009:
        return '服务异常，请稍后重试';
      default:
        return `登录失败（错误码 ${code}）`;
    }
  }
}
