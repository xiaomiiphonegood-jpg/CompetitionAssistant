/**
 * 广场视图（Tab）：组队广场 + 经验分享
 */
import { TeamPost, SharePost } from '../model/Social';
import { SocialService } from '../service/SocialService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

function formatTime(ts: number): string {
  const diff = Date.now() - ts;
  if (diff < 3600000) {
    return `${Math.floor(diff / 60000)}分钟前`;
  }
  if (diff < 86400000) {
    return `${Math.floor(diff / 3600000)}小时前`;
  }
  if (diff < 7 * 86400000) {
    return `${Math.floor(diff / 86400000)}天前`;
  }
  const d = new Date(ts);
  return `${d.getMonth() + 1}月${d.getDate()}日`;
}

@Component
export struct SquareView {
  @State tab: number = 0;
  @State teamPosts: TeamPost[] = [];
  @State sharePosts: SharePost[] = [];
  @StorageLink('socialVersion') @Watch('onSocialChange') socialVersion: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  onSocialChange(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.teamPosts = await SocialService.getTeamPosts();
    this.sharePosts = await SocialService.getSharePosts();
  }

  async toggleLike(postId: string): Promise<void> {
    await SocialService.toggleLike(postId);
    this.sharePosts = await SocialService.getSharePosts();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('广场')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
        Button('＋ 发布')
          .height(36)
          .fontSize(14)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(18)
          .onClick(() => {
            router.pushUrl({ url: 'pages/CreatePost', params: { type: this.tab === 0 ? 'team' : 'share' } });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 子 Tab
      Row() {
        Text('组队广场')
          .fontSize(15)
          .fontWeight(this.tab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.tab === 0 ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.tab = 0;
          })
        Text('经验分享')
          .fontSize(15)
          .fontWeight(this.tab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.tab === 1 ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.tab = 1;
          })
      }
      .width('100%')
      .height(44)
      .padding({ top: 4, bottom: 4 })

      // 列表
      if (this.tab === 0) {
        List({ space: 12 }) {
          ForEach(this.teamPosts, (post: TeamPost) => {
            ListItem() {
              this.TeamCard(post)
            }
          }, (post: TeamPost) => post.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      } else {
        List({ space: 12 }) {
          ForEach(this.sharePosts, (post: SharePost) => {
            ListItem() {
              this.ShareCard(post)
            }
          }, (post: SharePost) => `${post.id}_${post.likes}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TeamCard(post: TeamPost) {
    Column({ space: 8 }) {
      Row() {
        Text(post.authorName)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
        Blank()
        Text(formatTime(post.createdAt))
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')

      Text(post.competitionName)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Row({ space: 6 }) {
        ForEach(post.needSkills, (skill: string) => {
          Text(skill)
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#EAF0FF')
            .borderRadius(10)
        }, (skill: string) => skill)
      }
      .width('100%')

      Text(post.content)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(20)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`联系方式：${post.contact}`)
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
      Row() {
        Blank()
        Text('查看详情 ›')
          .fontSize(12)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({ url: 'pages/PostDetail', params: { type: 'team', postId: post.id } });
    })
  }

  @Builder
  ShareCard(post: SharePost) {
    Column({ space: 8 }) {
      Row() {
        Text(post.authorName)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
        Blank()
        Text(formatTime(post.createdAt))
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')

      Text(post.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)

      Text(post.competitionName)
        .fontSize(12)
        .fontColor(AppColors.PRIMARY)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .backgroundColor('#EAF0FF')
        .borderRadius(10)

      Text(post.content)
        .fontSize(14)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(20)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Blank()
        Row({ space: 4 }) {
          Text(post.liked ? '❤️' : '🤍')
            .fontSize(18)
          Text(`${post.likes}`)
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onClick(() => this.toggleLike(post.id))
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({ url: 'pages/PostDetail', params: { type: 'share', postId: post.id } });
    })
  }
}
