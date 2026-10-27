/**
 * 设置页：个人资料、模型配置、账号、清除数据、关于
 */
import { UserProfile } from '../model/User';
import { UserService } from '../service/UserService';
import { AuthService } from '../service/AuthService';
import { AiSettings } from '../model/AiSettings';
import { AiSettingsService } from '../service/AiSettingsService';
import { CloudService } from '../service/CloudService';
import { SocialService } from '../service/SocialService';
import { AppColors, CloudConfig } from '../common/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SettingsPage {
  @State profile: UserProfile | null = null;
  @State aiSettings: AiSettings | null = null;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.profile = await UserService.getProfile();
    this.aiSettings = await AiSettingsService.getSettings();
  }

  private providerLabel(): string {
    if (this.aiSettings === null) {
      return '';
    }
    if (this.aiSettings.useMock) {
      return '模拟模式（离线）';
    }
    if (this.aiSettings.provider === 'ollama') {
      return `Ollama · ${this.aiSettings.model}`;
    }
    if (this.aiSettings.provider === 'deepseek') {
      return `DeepSeek · ${this.aiSettings.model}`;
    }
    return `自定义 · ${this.aiSettings.model}`;
  }

  async doLoginOrLogout(): Promise<void> {
    if (this.profile === null) {
      return;
    }
    if (this.profile.loggedIn) {
      await UserService.logout();
      promptAction.showToast({ message: '已退出登录' });
    } else {
      if (!CloudConfig.USE_MOCK) {
        // 真实登录：华为账号授权
        const ctx = this.getUIContext().getHostContext();
        const res = await AuthService.loginWithHuaweiId(ctx);
        if (!res.success) {
          promptAction.showToast({ message: res.message });
          return;
        }
        await UserService.login(res.openId);
      } else {
        await UserService.login('');
      }
      promptAction.showToast({ message: '登录成功' });
    }
    const version = AppStorage.get<number>('profileVersion');
    AppStorage.setOrCreate('profileVersion', (version === undefined ? 0 : version) + 1);
    this.profile = await UserService.getProfile();
  }

  async clearData(): Promise<void> {
    await CloudService.clearAll();
    await SocialService.clearAll();
    await UserService.reset();
    const version = AppStorage.get<number>('profileVersion');
    AppStorage.setOrCreate('profileVersion', (version === undefined ? 0 : version) + 1);
    this.profile = await UserService.getProfile();
    promptAction.showToast({ message: '本地数据已清除' });
  }

  private openLegal(type: string): void {
    router.pushUrl({ url: 'pages/LegalPage', params: { type: type } });
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column({ space: 12 }) {
          // 个人资料
          Row() {
            Text('👤').fontSize(22)
            Column({ space: 2 }) {
              Text('个人资料')
                .fontSize(15)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(this.profile === null ? '' : `${this.profile.nickname} · ${this.profile.school}`)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 12 })
            Text('›')
              .fontSize(16)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ProfileEdit' });
          })

          // 账号
          Row() {
            Text('🔐').fontSize(22)
            Column({ space: 2 }) {
              Text('账号登录')
                .fontSize(15)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(this.profile !== null && this.profile.loggedIn ? '已登录' : '未登录')
                .fontSize(12)
                .fontColor(this.profile !== null && this.profile.loggedIn ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 12 })
            Button(this.profile !== null && this.profile.loggedIn ? '退出登录' : '去登录')
              .height(34)
              .fontSize(13)
              .backgroundColor(AppColors.WHITE)
              .fontColor(AppColors.PRIMARY)
              .border({ width: 1, color: AppColors.PRIMARY })
              .borderRadius(17)
              .onClick(() => this.doLoginOrLogout())
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)

          // 模型配置
          Row() {
            Text('🤖').fontSize(22)
            Column({ space: 2 }) {
              Text('模型配置')
                .fontSize(15)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(this.providerLabel())
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 12 })
            Text('›')
              .fontSize(16)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ModelConfig' });
          })

          // 隐私与协议
          Row() {
            Text('📄').fontSize(22)
            Text('隐私政策')
              .fontSize(15)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)
              .margin({ left: 12 })
            Text('›')
              .fontSize(16)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)
          .onClick(() => this.openLegal('privacy'))

          Row() {
            Text('📋').fontSize(22)
            Text('用户协议')
              .fontSize(15)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)
              .margin({ left: 12 })
            Text('›')
              .fontSize(16)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)
          .onClick(() => this.openLegal('agreement'))

          // 清除数据
          Row() {
            Text('🗑').fontSize(22)
            Text('清除本地数据')
              .fontSize(15)
              .fontColor(AppColors.ERROR)
              .layoutWeight(1)
              .margin({ left: 12 })
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)
          .onClick(() => this.clearData())

          Text('v1.1.0 · 大学生竞赛助手')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
