/**
 * 规划详情页：展示 AI 生成的学习规划 + 任务打卡 + 进度
 */
import { StudyPlan, PlanPhase } from '../model/StudyPlan';
import { CloudService } from '../service/CloudService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

interface PlanDetailParams {
  planId: string;
}

@Entry
@Component
struct PlanDetail {
  @State plan: StudyPlan | null = null;
  @State doneTasks: string[] = [];

  aboutToAppear(): void {
    let planId = '';
    try {
      const params = router.getParams() as PlanDetailParams;
      planId = params.planId;
    } catch (e) {
      planId = '';
    }
    if (planId === '') {
      this.plan = null;
      return;
    }
    this.load(planId);
  }

  async load(planId: string): Promise<void> {
    const found = await CloudService.getPlanById(planId);
    if (found === undefined || found === null) {
      this.plan = null;
      return;
    }
    this.plan = found;
    this.doneTasks = found.doneTasks.slice();
  }

  private totalTasks(): number {
    if (this.plan === null) {
      return 0;
    }
    let n = 0;
    for (const p of this.plan.phases) {
      n += p.tasks.length;
    }
    return n;
  }

  private donePercent(): number {
    const total = this.totalTasks();
    if (total === 0) {
      return 0;
    }
    return Math.round(this.doneTasks.length * 100 / total);
  }

  private isDone(pi: number, ti: number): boolean {
    return this.doneTasks.indexOf(`${pi}_${ti}`) >= 0;
  }

  async toggleTask(pi: number, ti: number): Promise<void> {
    if (this.plan === null) {
      return;
    }
    const key = `${pi}_${ti}`;
    const idx = this.doneTasks.indexOf(key);
    if (idx >= 0) {
      this.doneTasks.splice(idx, 1);
    } else {
      this.doneTasks.push(key);
    }
    this.doneTasks = this.doneTasks.slice();
    await CloudService.toggleTask(this.plan.id, key);
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('规划详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)

      if (this.plan === null) {
        Text('未找到该规划').fontSize(14).fontColor(AppColors.TEXT_SECONDARY).margin({ top: 80 })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 概览卡
            Column({ space: 8 }) {
              Text(this.plan.competitionName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(`目标 ${this.plan.target} · 共 ${this.plan.totalWeeks} 周 · 每周 ${this.plan.weeklyHours}h`)
                .fontSize(13)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(this.plan.summary)
                .fontSize(14)
                .fontColor(AppColors.TEXT_PRIMARY)
                .margin({ top: 6 })
                .lineHeight(21)

              Row({ space: 10 }) {
                Progress({ value: this.donePercent(), total: 100, type: ProgressType.Linear })
                  .layoutWeight(1)
                  .height(8)
                  .color(AppColors.PRIMARY)
                  .backgroundColor(AppColors.DIVIDER)
                Text(`${this.donePercent()}%`)
                  .fontSize(13)
                  .fontColor(AppColors.PRIMARY)
              }
              .width('100%')
              .margin({ top: 6 })
              Text(`已完成 ${this.doneTasks.length} / ${this.totalTasks()} 个任务`)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)

            // 阶段列表（含打卡）
            ForEach(this.plan.phases, (phase: PlanPhase, pi: number) => {
              Column({ space: 8 }) {
                Row() {
                  Text(phase.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.PRIMARY)
                  Blank()
                  Text(phase.weeks)
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_SECONDARY)
                }
                .width('100%')
                Text(phase.goal)
                  .fontSize(13)
                  .fontColor(AppColors.TEXT_PRIMARY)
                ForEach(phase.tasks, (task: string, ti: number) => {
                  Row() {
                    Text(this.isDone(pi, ti) ? '✅' : '⬜')
                      .fontSize(18)
                      .margin({ right: 8 })
                      .onClick(() => this.toggleTask(pi, ti))
                    Text(task)
                      .fontSize(13)
                      .fontColor(this.isDone(pi, ti) ? AppColors.TEXT_SECONDARY : AppColors.TEXT_PRIMARY)
                      .layoutWeight(1)
                      .decoration({ type: this.isDone(pi, ti) ? TextDecorationType.LineThrough : TextDecorationType.None })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                  .padding({ top: 2, bottom: 2 })
                }, (task: string, ti: number) => `${phase.name}_${ti}`)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(16)
              .backgroundColor(AppColors.CARD)
              .borderRadius(16)
            }, (phase: PlanPhase, pi: number) => `${phase.name}_${pi}`)

            // 风险提示
            Column({ space: 6 }) {
              Text('⚠️ 注意事项')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              ForEach(this.plan.risks, (risk: string, idx: number) => {
                Text(`• ${risk}`)
                  .fontSize(13)
                  .fontColor(AppColors.TEXT_SECONDARY)
                  .width('100%')
                  .lineHeight(20)
              }, (risk: string, idx: number) => `risk_${idx}`)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor('#FFF7E6')
            .borderRadius(16)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
