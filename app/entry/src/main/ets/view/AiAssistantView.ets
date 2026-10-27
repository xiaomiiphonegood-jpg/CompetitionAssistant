/**
 * AI 助手视图（Tab 2）：入口 + 我的规划列表
 */
import { StudyPlan } from '../model/StudyPlan';
import { AiSettings } from '../model/AiSettings';
import { CloudService } from '../service/CloudService';
import { AiSettingsService } from '../service/AiSettingsService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

@Component
export struct AiAssistantView {
  @State plans: StudyPlan[] = [];
  @State aiSettings: AiSettings | null = null;
  @StorageLink('plansVersion') @Watch('onPlanVersionChange') plansVersion: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  onPlanVersionChange(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.plans = await CloudService.getPlans();
    this.aiSettings = await AiSettingsService.getSettings();
  }

  private modelLabel(): string {
    if (this.aiSettings === null) {
      return '';
    }
    if (this.aiSettings.useMock) {
      return '当前：模拟模式';
    }
    if (this.aiSettings.provider === 'ollama') {
      return `当前：本地模型 ${this.aiSettings.model}`;
    }
    if (this.aiSettings.provider === 'deepseek') {
      return `当前：DeepSeek ${this.aiSettings.model}`;
    }
    return `当前：${this.aiSettings.model}`;
  }

  build() {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Text('🤖 AI 备赛规划')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('告诉 AI 你的基础、时间和目标，生成专属备赛计划')
          .fontSize(14)
          .fontColor(AppColors.TEXT_SECONDARY)
        Text(this.modelLabel())
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#EAF0FF')
          .borderRadius(10)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })

      Button('开始新的规划')
        .width('92%')
        .height(48)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .borderRadius(24)
        .onClick(() => {
          router.pushUrl({ url: 'pages/AiChat' });
        })

      Row() {
        Text('我的规划')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text(`${this.plans.length} 个`)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })

      if (this.plans.length === 0) {
        Column({ space: 8 }) {
          Text('📝').fontSize(40)
          Text('还没有规划，快去生成一个吧～').fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .margin({ top: 40 })
      } else {
        List({ space: 12 }) {
          ForEach(this.plans, (plan: StudyPlan) => {
            ListItem() {
              this.PlanCard(plan)
            }
          }, (plan: StudyPlan) => plan.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PlanCard(plan: StudyPlan) {
    Column({ space: 6 }) {
      Text(plan.competitionName)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text(`目标：${plan.target} · ${plan.totalWeeks}周 · 每周${plan.weeklyHours}h`)
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({ url: 'pages/PlanDetail', params: { planId: plan.id } });
    })
  }
}
