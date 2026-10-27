/**
 * 排行榜：竞赛积分榜
 */
import { RankItem } from '../model/Social';
import { SocialService } from '../service/SocialService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

function medalColor(rank: number): string {
  if (rank === 1) {
    return '#F5B800';
  }
  if (rank === 2) {
    return '#9BA5B0';
  }
  if (rank === 3) {
    return '#C8835A';
  }
  return AppColors.TEXT_SECONDARY;
}

@Entry
@Component
struct RankList {
  @State list: RankItem[] = [];

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.list = await SocialService.getRankList();
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('竞赛排行榜')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column({ space: 10 }) {
          ForEach(this.list, (item: RankItem) => {
            Row() {
              Text(`${item.rank}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(medalColor(item.rank))
                .width(40)
                .textAlign(TextAlign.Center)

              Column({ space: 2 }) {
                Text(item.name)
                  .fontSize(15)
                  .fontWeight(item.rank <= 3 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(AppColors.TEXT_PRIMARY)
                Text(item.school)
                  .fontSize(12)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Column({ space: 2 }) {
                Text(`${item.score}`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.PRIMARY)
                Text(`参赛 ${item.competitions} 场`)
                  .fontSize(11)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')
            .padding(14)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)
          }, (item: RankItem) => `${item.rank}_${item.name}`)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)

      Text('积分说明：参加竞赛、获奖、分享经验均可累计积分')
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
        .padding({ top: 4, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
