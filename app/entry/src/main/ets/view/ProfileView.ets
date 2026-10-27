/**
 * 我的视图（Tab 3）：个人资料 + 我的竞赛 + 快捷入口 + 设置
 */
import { Competition } from '../model/Competition';
import { UserProfile } from '../model/User';
import { CloudService } from '../service/CloudService';
import { UserService } from '../service/UserService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

function firstChar(name: string): string {
  if (name === '' || name === '未设置学校') {
    return '👤';
  }
  return name.substring(0, 1);
}

function subLine(p: UserProfile): string {
  const school = p.school !== '' && p.school !== '未设置学校' ? p.school : '未填写学校';
  const major = p.major !== '' && p.major !== '未设置专业' ? p.major : '未填写专业';
  const grade = p.grade !== '' && p.grade !== '未设置年级' ? p.grade : '未填写年级';
  return `${school} · ${major} · ${grade}`;
}

@Component
export struct ProfileView {
  @State favorites: Competition[] = [];
  @State profile: UserProfile | null = null;
  @StorageLink('profileVersion') @Watch('onProfileChange') profileVersion: number = 0;
  @StorageLink('favoritesVersion') @Watch('onFavoritesChange') favoritesVersion: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  onProfileChange(): void {
    this.load();
  }

  onFavoritesChange(): void {
    this.loadFavorites();
  }

  async load(): Promise<void> {
    this.favorites = await CloudService.getFavorites();
    this.profile = await UserService.getProfile();
  }

  async loadFavorites(): Promise<void> {
    this.favorites = await CloudService.getFavorites();
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        // 用户资料卡
        Row() {
          Column() {
            Text(this.profile === null ? '👤' : firstChar(this.profile.nickname))
              .fontSize(26)
              .fontColor(AppColors.WHITE)
          }
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor(AppColors.PRIMARY)
          .justifyContent(FlexAlign.Center)

          Column({ space: 4 }) {
            Text(this.profile === null ? '竞赛小助手用户' : this.profile.nickname)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
            Text(this.profile === null ? '' : subLine(this.profile))
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          .layoutWeight(1)

          Text(this.profile !== null && this.profile.loggedIn ? '已登录' : '登录 ›')
            .fontSize(13)
            .fontColor(this.profile !== null && this.profile.loggedIn ? AppColors.SUCCESS : AppColors.PRIMARY)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColors.CARD)
        .borderRadius(16)
        .onClick(() => {
          if (this.profile !== null && this.profile.loggedIn) {
            router.pushUrl({ url: 'pages/ProfileEdit' });
          } else {
            router.pushUrl({ url: 'pages/Login' });
          }
        })

        // 我的竞赛（收藏）
        Column({ space: 8 }) {
          Row() {
            Text('📋 我的竞赛')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            Blank()
            Text(`${this.favorites.length} 个收藏`)
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')

          if (this.favorites.length === 0) {
            Text('还没有收藏的竞赛，去首页看看吧～')
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: 4 })
          } else {
            ForEach(this.favorites, (c: Competition) => {
              Row() {
                Text(c.name)
                  .fontSize(14)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('›')
                  .fontSize(16)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/CompetitionDetail', params: { competitionId: c.id } });
              })
            }, (c: Competition) => c.id)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor(AppColors.CARD)
        .borderRadius(16)

        // AI 备赛规划入口
        this.MenuRow('🗓', 'AI 备赛规划', 'pages/AiChat')

        // 排行榜
        this.MenuRow('🏆', '排行榜', 'pages/RankList')

        // 智能提醒
        this.MenuRow('⏰', '智能提醒', 'pages/ReminderCenter')

        // 设置
        this.MenuRow('⚙️', '设置', 'pages/SettingsPage')

        Text('v1.1.0 · 大学生竞赛助手')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: 24 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MenuRow(icon: string, label: string, targetUrl: string) {
    Row() {
      Text(icon).fontSize(22)
      Text(label)
        .fontSize(16)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ left: 12 })
        .layoutWeight(1)
      Text('›')
        .fontSize(16)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({ url: targetUrl });
    })
  }
}
