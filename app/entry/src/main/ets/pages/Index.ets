/**
 * 首页：底部 Tab 容器（竞赛日历 | 广场 | AI 助手 | 我的）+ 首次启动隐私弹窗
 */
import { TimelineView } from '../view/TimelineView';
import { SquareView } from '../view/SquareView';
import { AiAssistantView } from '../view/AiAssistantView';
import { ProfileView } from '../view/ProfileView';
import { AppColors } from '../common/Constants';
import { LocalStore } from '../common/LocalStore';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State showPrivacy: boolean = false;
  private tabTitles: string[] = ['首页', '广场', 'AI助手', '我的'];
  private tabIcons: string[] = ['🏠', '👥', '🤖', '👤'];

  aboutToAppear(): void {
    this.checkPrivacy();
  }

  async checkPrivacy(): Promise<void> {
    try {
      const agreed = await LocalStore.load('privacy_agreed', '');
      this.showPrivacy = agreed !== '1';
    } catch (e) {
      this.showPrivacy = true;
    }
  }

  private async agreePrivacy(): Promise<void> {
    await LocalStore.save('privacy_agreed', '1');
    this.showPrivacy = false;
  }

  @Builder
  TabItem(index: number) {
    Column({ space: 2 }) {
      Text(this.tabIcons[index]).fontSize(20)
      Text(this.tabTitles[index])
        .fontSize(11)
        .fontColor(this.currentTab === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }

  build() {
    Stack() {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          TimelineView()
        }
        .tabBar(this.TabItem(0))

        TabContent() {
          SquareView()
        }
        .tabBar(this.TabItem(1))

        TabContent() {
          AiAssistantView()
        }
        .tabBar(this.TabItem(2))

        TabContent() {
          ProfileView()
        }
        .tabBar(this.TabItem(3))
      }
      .onChange((index: number) => {
        this.currentTab = index;
      })
      .scrollable(false)
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BACKGROUND)

      // 首次启动隐私弹窗
      if (this.showPrivacy) {
        Column() {
          Column({ space: 14 }) {
            Text('欢迎使用大学生竞赛助手')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
            Text('我们重视您的隐私。使用前请阅读并同意《隐私政策》和《用户协议》，我们将依法保护您的个人信息。')
              .fontSize(14)
              .fontColor(AppColors.TEXT_PRIMARY)
              .lineHeight(22)
            Row({ space: 12 }) {
              Text('《隐私政策》')
                .fontSize(14)
                .fontColor(AppColors.PRIMARY)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/LegalPage', params: { type: 'privacy' } });
                })
              Text('《用户协议》')
                .fontSize(14)
                .fontColor(AppColors.PRIMARY)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/LegalPage', params: { type: 'agreement' } });
                })
            }
            Button('同意并继续')
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(AppColors.WHITE)
              .borderRadius(22)
              .onClick(() => this.agreePrivacy())
          }
          .width('100%')
          .padding(20)
          .backgroundColor(AppColors.WHITE)
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .padding(28)
      }
    }
    .width('100%')
    .height('100%')
  }
}
