/**
 * 首页「竞赛日历」视图：问候语 + 热门竞赛 + 搜索筛选 + 月份时间线
 */
import { Competition, CompetitionStage } from '../model/Competition';
import { CloudService } from '../service/CloudService';
import { AppColors, Categories, StageTypeText, Levels } from '../common/Constants';
import router from '@ohos.router';

function formatMonthLabel(year: number, month: number): string {
  return `${year}年${month + 1}月`;
}

function formatDay(ts: number): string {
  const d = new Date(ts);
  return `${d.getMonth() + 1}/${d.getDate()}`;
}

function daysLeft(ts: number): number {
  return Math.ceil((ts - Date.now()) / 86400000);
}

function greeting(): string {
  const h = new Date().getHours();
  if (h < 6) {
    return '夜深了';
  }
  if (h < 12) {
    return '早上好';
  }
  if (h < 14) {
    return '中午好';
  }
  if (h < 18) {
    return '下午好';
  }
  return '晚上好';
}

@Component
export struct TimelineView {
  @State stages: CompetitionStage[] = [];
  @State hotCompetitions: Competition[] = [];
  @State selectedCategory: string = 'all';
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth();
  @State loading: boolean = true;
  @State searchKeyword: string = '';

  aboutToAppear(): void {
    this.load();
    this.loadHot();
  }

  private isCurrentMonth(): boolean {
    const now = new Date();
    return now.getFullYear() === this.currentYear && now.getMonth() === this.currentMonth;
  }

  async load(): Promise<void> {
    this.loading = true;
    const monthStart = new Date(this.currentYear, this.currentMonth, 1).getTime();
    const monthEnd = new Date(this.currentYear, this.currentMonth + 1, 1).getTime();
    const start = this.isCurrentMonth() ? Math.max(Date.now(), monthStart) : monthStart;
    this.stages = await CloudService.getStages(start, monthEnd, this.selectedCategory);
    this.loading = false;
  }

  async loadHot(): Promise<void> {
    const all = await CloudService.getCompetitions();
    const sorted = all.slice().sort((a: Competition, b: Competition) => b.hot - a.hot);
    this.hotCompetitions = sorted.slice(0, 5);
  }

  private prevMonth(): void {
    if (this.currentMonth === 0) {
      this.currentYear -= 1;
      this.currentMonth = 11;
    } else {
      this.currentMonth -= 1;
    }
    this.load();
  }

  private nextMonth(): void {
    if (this.currentMonth === 11) {
      this.currentYear += 1;
      this.currentMonth = 0;
    } else {
      this.currentMonth += 1;
    }
    this.load();
  }

  private filteredStages(): CompetitionStage[] {
    const kw = this.searchKeyword.trim();
    if (kw === '') {
      return this.stages;
    }
    return this.stages.filter((s: CompetitionStage) => s.competitionName.indexOf(kw) >= 0);
  }

  private nodeColor(type: string): string {
    if (type === 'enroll_end') {
      return AppColors.WARNING;
    }
    if (type === 'result') {
      return AppColors.SUCCESS;
    }
    return AppColors.PRIMARY;
  }

  build() {
    Column() {
      List({ space: 0 }) {
        // 顶部标题
        ListItem() {
          Column({ space: 4 }) {
            Text(`${greeting()}，同学`)
              .fontSize(14)
              .fontColor(AppColors.TEXT_SECONDARY)
            Text('竞赛日历')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 4 })
        }

        // 搜索框
        ListItem() {
          Row() {
            Search({ value: this.searchKeyword, placeholder: '搜索竞赛名称' })
              .layoutWeight(1)
              .height(40)
              .onChange((value: string) => {
                this.searchKeyword = value;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })
        }

        // 热门竞赛
        ListItem() {
          Column({ space: 8 }) {
            Text('🔥 热门竞赛')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')
            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.hotCompetitions, (c: Competition) => {
                  this.HotCard(c)
                }, (c: Competition) => c.id)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })
        }

        // 分类筛选
        ListItem() {
          Scroll() {
            Row({ space: 8 }) {
              ForEach(Categories.LIST, (cat: string) => {
                Text(Categories.text(cat))
                  .fontSize(13)
                  .fontColor(this.selectedCategory === cat ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
                  .backgroundColor(this.selectedCategory === cat ? AppColors.PRIMARY : AppColors.CARD)
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .onClick(() => {
                    this.selectedCategory = cat;
                    this.load();
                  })
              }, (cat: string) => cat)
            }
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }

        // 月份切换
        ListItem() {
          Row() {
            Text('◀')
              .fontSize(18)
              .fontColor(AppColors.TEXT_SECONDARY)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => this.prevMonth())
            Text(formatMonthLabel(this.currentYear, this.currentMonth))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .margin({ left: 24, right: 24 })
            Text('▶')
              .fontSize(18)
              .fontColor(AppColors.TEXT_SECONDARY)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => this.nextMonth())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 10, bottom: 6 })
        }

        // 时间线内容
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width(40)
              .height(40)
              .margin({ top: 60 })
          }
        } else if (this.filteredStages().length === 0) {
          ListItem() {
            Column({ space: 8 }) {
              Text('📭').fontSize(40)
              Text(this.searchKeyword.trim() === '' ? '本月暂无竞赛节点' : '没有匹配的竞赛')
                .fontSize(14)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .width('100%')
            .margin({ top: 60 })
          }
        } else {
          ForEach(this.filteredStages(), (stage: CompetitionStage) => {
            ListItem() {
              this.StageItem(stage)
            }
          }, (stage: CompetitionStage) => stage.id)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HotCard(c: Competition) {
    Column({ space: 6 }) {
      Text(c.shortName)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .maxLines(1)
      Text(Levels.text(c.level))
        .fontSize(11)
        .fontColor(AppColors.PRIMARY)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor('#EAF0FF')
        .borderRadius(8)
    }
    .alignItems(HorizontalAlign.Start)
    .width(132)
    .padding(12)
    .backgroundColor(AppColors.CARD)
    .borderRadius(14)
    .onClick(() => {
      router.pushUrl({ url: 'pages/CompetitionDetail', params: { competitionId: c.id } });
    })
  }

  @Builder
  StageItem(stage: CompetitionStage) {
    Row() {
      Column() {
        Circle()
          .width(10)
          .height(10)
          .fill(this.nodeColor(stage.type))
        Divider()
          .vertical(true)
          .width(2)
          .height(44)
          .color(AppColors.DIVIDER)
      }
      .alignItems(HorizontalAlign.Center)
      .width(24)

      Column({ space: 4 }) {
        Row() {
          Text(stage.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
          Blank()
          if (stage.type === 'enroll_end' || stage.type === 'contest') {
            Text(daysLeft(stage.time) >= 0 ? `剩余${daysLeft(stage.time)}天` : '已结束')
              .fontSize(11)
              .fontColor(daysLeft(stage.time) >= 0 ? AppColors.WARNING : AppColors.TEXT_SECONDARY)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(daysLeft(stage.time) >= 0 ? '#FFE9DD' : AppColors.DIVIDER)
              .borderRadius(10)
          }
        }
        .width('100%')

        Text(stage.competitionName)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
        Text(`${formatDay(stage.time)} · ${StageTypeText.text(stage.type)}`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding(14)
      .backgroundColor(AppColors.CARD)
      .borderRadius(16)
    }
    .width('100%')
    .margin({ left: 16, right: 16, top: 6 })
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      router.pushUrl({ url: 'pages/CompetitionDetail', params: { competitionId: stage.competitionId } });
    })
  }
}
