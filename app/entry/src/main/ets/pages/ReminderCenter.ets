/**
 * 提醒中心：未来关键时间节点的倒计时提醒
 */
import { ReminderItem } from '../model/Social';
import { SocialService } from '../service/SocialService';
import { ReminderService } from '../service/ReminderService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

function formatDay(ts: number): string {
  const d = new Date(ts);
  return `${d.getMonth() + 1}月${d.getDate()}日`;
}

@Entry
@Component
struct ReminderCenter {
  @State list: ReminderItem[] = [];

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.list = await SocialService.getReminders();
  }

  async enableReminders(): Promise<void> {
    if (this.list.length === 0) {
      promptAction.showToast({ message: '暂无临近的竞赛节点' });
      return;
    }
    try {
      const count = await ReminderService.publishAll(this.list);
      if (count > 0) {
        promptAction.showToast({ message: `已开启 ${count} 条提醒，届时系统将通知你` });
      } else {
        promptAction.showToast({ message: '开启失败，请确认已授予提醒权限' });
      }
    } catch (e) {
      promptAction.showToast({ message: '开启失败，请检查系统设置中的提醒权限' });
    }
  }

  private urgencyText(days: number): string {
    if (days <= 7) {
      return '紧急';
    }
    if (days <= 30) {
      return '临近';
    }
    return '关注';
  }

  private urgencyColor(days: number): string {
    if (days <= 7) {
      return AppColors.ERROR;
    }
    if (days <= 30) {
      return AppColors.WARNING;
    }
    return AppColors.PRIMARY;
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('智能提醒')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Button('🔔 开启系统提醒')
        .width('92%')
        .height(44)
        .fontSize(15)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(AppColors.WHITE)
        .borderRadius(22)
        .margin({ top: 4, bottom: 8 })
        .onClick(() => this.enableReminders())

      Text('开启后将在节点到来前由系统推送通知（应用退出后仍有效）')
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('92%')
        .margin({ bottom: 8 })

      if (this.list.length === 0) {
        Text('暂无临近的竞赛节点').fontSize(14).fontColor(AppColors.TEXT_SECONDARY).margin({ top: 80 })
      } else {
        List({ space: 12 }) {
          ForEach(this.list, (item: ReminderItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(`${item.daysLeft}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.urgencyColor(item.daysLeft))
                  Text('天后')
                    .fontSize(11)
                    .fontColor(AppColors.TEXT_SECONDARY)
                }
                .width(56)
                .alignItems(HorizontalAlign.Center)

                Column({ space: 3 }) {
                  Text(item.competitionName)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${formatDay(item.time)} · ${item.title}`)
                    .fontSize(12)
                    .fontColor(AppColors.TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(this.urgencyText(item.daysLeft))
                  .fontSize(12)
                  .fontColor(this.urgencyColor(item.daysLeft))
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.urgencyColor(item.daysLeft) + '1A')
                  .borderRadius(10)
              }
              .width('100%')
              .padding(14)
              .backgroundColor(AppColors.CARD)
              .borderRadius(16)
              .onClick(() => {
                router.pushUrl({ url: 'pages/CompetitionDetail', params: { competitionId: item.competitionId } });
              })
            }
          }, (item: ReminderItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
