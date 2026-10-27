/**
 * 登录页：华为账号一键登录
 * CloudConfig.USE_MOCK = true 时模拟登录；false 时经 Account Kit 真实华为账号登录。
 */
import { AppColors, CloudConfig } from '../common/Constants';
import { UserService } from '../service/UserService';
import { AuthService } from '../service/AuthService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Login {
  @State loggedIn: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const p = await UserService.getProfile();
    this.loggedIn = p.loggedIn;
  }

  private async doLogin(): Promise<void> {
    if (!CloudConfig.USE_MOCK) {
      // 真实登录：华为账号授权，拿到 openid 后落用户身份
      const ctx = this.getUIContext().getHostContext();
      const res = await AuthService.loginWithHuaweiId(ctx);
      if (!res.success) {
        promptAction.showToast({ message: res.message });
        return;
      }
      await UserService.login(res.openId);
    } else {
      // 模拟登录（本地体验）
      await UserService.login('');
    }
    this.loggedIn = true;
    const version = AppStorage.get<number>('profileVersion');
    AppStorage.setOrCreate('profileVersion', (version === undefined ? 0 : version) + 1);
    promptAction.showToast({ message: '登录成功' });
    setTimeout(() => {
      router.back();
    }, 500);
  }

  private openLegal(type: string): void {
    router.pushUrl({ url: 'pages/LegalPage', params: { type: type } });
  }

  build() {
    Column({ space: 16 }) {
      // Logo 区
      Column({ space: 10 }) {
        Text('🏆').fontSize(64)
        Text('大学生竞赛助手')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('竞赛日历 · AI 备赛 · 组队交流')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .margin({ top: 80 })

      Blank()

      // 登录按钮
      Button(this.loggedIn ? '已登录，返回' : '华为账号一键登录')
        .width('88%')
        .height(50)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .borderRadius(25)
        .fontSize(16)
        .onClick(() => this.doLogin())

      // 合规链接
      Row({ space: 12 }) {
        Text('《隐私政策》')
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => this.openLegal('privacy'))
        Text('《用户协议》')
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => this.openLegal('agreement'))
      }
      .margin({ top: 8 })

      Text('登录即代表同意《隐私政策》与《用户协议》')
        .fontSize(11)
        .fontColor(AppColors.TEXT_SECONDARY)
        .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
