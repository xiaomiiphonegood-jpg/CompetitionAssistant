/**
 * 竞赛详情页：基本信息 + 时间节点 + 收藏 + AI 规划入口
 */
import { Competition, CompetitionStage } from '../model/Competition';
import { CloudService } from '../service/CloudService';
import { AppColors, Levels, Categories } from '../common/Constants';
import { getAppContext } from '../common/AppContext';
import { common, Want } from '@kit.AbilityKit';
import router from '@ohos.router';

interface DetailParams {
  competitionId: string;
}

function formatDay(ts: number): string {
  const d = new Date(ts);
  return `${d.getMonth() + 1}/${d.getDate()}`;
}

@Entry
@Component
struct CompetitionDetail {
  @State competition: Competition | null = null;
  @State stages: CompetitionStage[] = [];
  @State favorited: boolean = false;
  @State loading: boolean = true;

  aboutToAppear(): void {
    let competitionId = '';
    try {
      const params = router.getParams() as DetailParams;
      competitionId = params.competitionId;
    } catch (e) {
      competitionId = '';
    }
    if (competitionId === '') {
      this.loading = false;
      this.competition = null;
      return;
    }
    this.load(competitionId);
  }

  async load(competitionId: string): Promise<void> {
    this.loading = true;
    try {
      const detail = await CloudService.getCompetitionDetail(competitionId);
      this.competition = detail.competition;
      this.stages = detail.stages;
      this.favorited = await CloudService.isFavorite(competitionId);
    } catch (e) {
      this.competition = null;
    }
    this.loading = false;
  }

  async toggleFav(): Promise<void> {
    if (this.competition === null) {
      return;
    }
    this.favorited = await CloudService.toggleFavorite(this.competition.id);
    const version = AppStorage.get<number>('favoritesVersion');
    AppStorage.setOrCreate('favoritesVersion', (version === undefined ? 0 : version) + 1);
  }

  private goAiPlan(): void {
    if (this.competition === null) {
      return;
    }
    router.pushUrl({
      url: 'pages/AiChat',
      params: {
        competitionId: this.competition.id,
        competitionName: this.competition.name
      }
    });
  }

  private openOfficial(): void {
    if (this.competition === null || this.competition.officialUrl === '') {
      return;
    }
    try {
      const ctx: common.UIAbilityContext | null = getAppContext();
      if (ctx === null) {
        return;
      }
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: this.competition.officialUrl
      };
      ctx.startAbility(want);
    } catch (e) {
      // 无浏览器或打开失败时静默忽略，URL 已展示可手动复制
    }
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Blank()
        Text('竞赛详情')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Text('  ').fontSize(26)
      }
      .width('100%')
      .padding(14)

      // 内容区
      if (this.loading) {
        LoadingProgress().width(40).height(40).margin({ top: 80 })
      } else if (this.competition === null) {
        Text('竞赛信息加载失败').fontSize(14).fontColor(AppColors.TEXT_SECONDARY).margin({ top: 80 })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            // 标题区
            Column({ space: 8 }) {
              Text(this.competition.name)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT_PRIMARY)
              Row({ space: 8 }) {
                Text(Levels.text(this.competition.level))
                  .fontSize(12)
                  .fontColor(AppColors.PRIMARY)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#EAF0FF')
                  .borderRadius(10)
                Text(Categories.text(this.competition.category))
                  .fontSize(12)
                  .fontColor('#00A882')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#E5F7F0')
                  .borderRadius(10)
                Blank()
              }
              .width('100%')
              Text(`主办方：${this.competition.organizer}`)
                .fontSize(13)
                .fontColor(AppColors.TEXT_SECONDARY)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)

            // 简介
            Column({ space: 6 }) {
              Text('竞赛简介')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              Text(this.competition.description)
                .fontSize(14)
                .fontColor(AppColors.TEXT_PRIMARY)
                .lineHeight(22)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)

            // 赛事信息（标签 / 适合人群 / 奖项）
            Column({ space: 10 }) {
              Text('赛事信息')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)

              if (this.competition.tags.length > 0) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.competition.tags, (tag: string) => {
                    Text(tag)
                      .fontSize(12)
                      .fontColor(AppColors.PRIMARY)
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .backgroundColor('#EAF0FF')
                      .borderRadius(10)
                      .margin({ right: 8, bottom: 6 })
                  }, (tag: string) => tag)
                }
                .width('100%')
              }

              if (this.competition.suitable !== '') {
                Row() {
                  Text('适合人群')
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .width(72)
                  Text(this.competition.suitable)
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }

              if (this.competition.reward !== '') {
                Row() {
                  Text('奖项设置')
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .width(72)
                  Text(this.competition.reward)
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }

              if (this.competition.officialUrl !== '') {
                Row() {
                  Text('官方网站')
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .width(72)
                  Text(this.competition.officialUrl)
                    .fontSize(13)
                    .fontColor(AppColors.PRIMARY)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Button('前往官网报名')
                  .width('100%')
                  .height(42)
                  .fontSize(14)
                  .backgroundColor(AppColors.PRIMARY)
                  .fontColor(AppColors.WHITE)
                  .borderRadius(21)
                  .margin({ top: 2 })
                  .onClick(() => this.openOfficial())
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)

            // 时间节点
            Column({ space: 10 }) {
              Text('关键时间节点')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              ForEach(this.stages, (stage: CompetitionStage) => {
                Row() {
                  Circle()
                    .width(8)
                    .height(8)
                    .fill(stage.type === 'enroll_end' ? AppColors.WARNING : AppColors.PRIMARY)
                    .margin({ right: 10 })
                  Text(stage.title)
                    .fontSize(14)
                    .fontColor(AppColors.TEXT_PRIMARY)
                  Blank()
                  Text(formatDay(stage.time))
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_SECONDARY)
                }
                .width('100%')
              }, (stage: CompetitionStage) => stage.id)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .layoutWeight(1)
      }

      // 底部操作栏
      if (!this.loading && this.competition !== null) {
        Row({ space: 12 }) {
          Button(this.favorited ? '★ 已收藏' : '☆ 收藏')
            .width(120)
            .height(48)
            .fontColor(this.favorited ? AppColors.SUCCESS : AppColors.PRIMARY)
            .backgroundColor(AppColors.WHITE)
            .border({ width: 1, color: this.favorited ? AppColors.SUCCESS : AppColors.PRIMARY })
            .borderRadius(24)
            .onClick(() => this.toggleFav())

          Button('🤖 AI 备赛规划')
            .layoutWeight(1)
            .height(48)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(24)
            .onClick(() => this.goAiPlan())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(AppColors.WHITE)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
