/**
 * 帖子详情页：展示组队帖 / 经验帖完整内容
 * 通过路由参数 type（team/share）+ postId 加载对应帖子。
 */
import { TeamPost, SharePost } from '../model/Social';
import { SocialService } from '../service/SocialService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

interface PostDetailParams {
  type: string;
  postId: string;
}

function two(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

function formatTime(ts: number): string {
  const d = new Date(ts);
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())} ${two(d.getHours())}:${two(d.getMinutes())}`;
}

@Entry
@Component
struct PostDetail {
  @State type: string = 'team';
  @State teamPost: TeamPost | null = null;
  @State sharePost: SharePost | null = null;
  @State loading: boolean = true;
  @State notFound: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private readParams(): PostDetailParams {
    const result: PostDetailParams = { type: 'team', postId: '' };
    try {
      const p = router.getParams() as PostDetailParams;
      result.type = p.type === 'share' ? 'share' : 'team';
      result.postId = p.postId;
    } catch (e) {
      result.type = 'team';
      result.postId = '';
    }
    return result;
  }

  async load(): Promise<void> {
    const params = this.readParams();
    this.type = params.type;
    this.loading = true;
    this.notFound = false;
    this.teamPost = null;
    this.sharePost = null;
    if (params.postId === '') {
      this.loading = false;
      this.notFound = true;
      return;
    }
    if (params.type === 'team') {
      const p = await SocialService.getTeamPostById(params.postId);
      if (p === undefined) {
        this.notFound = true;
      } else {
        this.teamPost = p;
      }
    } else {
      const p = await SocialService.getSharePostById(params.postId);
      if (p === undefined) {
        this.notFound = true;
      } else {
        this.sharePost = p;
      }
    }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .padding({ right: 12 })
          .onClick(() => router.back())
        Text(this.type === 'team' ? '组队详情' : '经验分享')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .padding(16)

      if (this.loading) {
        LoadingProgress().width(40).height(40).margin({ top: 80 })
      } else if (this.notFound) {
        Text('帖子不存在或已删除').fontSize(14).fontColor(AppColors.TEXT_SECONDARY).margin({ top: 80 })
      } else if (this.type === 'team') {
        this.TeamDetail(this.teamPost)
      } else {
        this.ShareDetail(this.sharePost)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  TeamDetail(post: TeamPost | null) {
    if (post !== null) {
      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 8 }) {
            Text(post.competitionName)
              .fontSize(13)
              .fontColor(AppColors.PRIMARY)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#EAF0FF')
              .borderRadius(10)
            Text(post.content)
              .fontSize(16)
              .fontColor(AppColors.TEXT_PRIMARY)
              .lineHeight(24)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)

          Column({ space: 8 }) {
            Text('所需技能')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(post.needSkills, (skill: string) => {
                Text(skill)
                  .fontSize(13)
                  .fontColor(AppColors.PRIMARY)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#EAF0FF')
                  .borderRadius(10)
                  .margin({ right: 8, bottom: 6 })
              }, (skill: string) => skill)
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)

          Column({ space: 8 }) {
            Text('联系方式')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            Text(post.contact)
              .fontSize(15)
              .fontColor(AppColors.PRIMARY)
              .width('100%')
            Text(`发布人：${post.authorName} · ${formatTime(post.createdAt)}`)
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
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
  }

  @Builder
  ShareDetail(post: SharePost | null) {
    if (post !== null) {
      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 10 }) {
            Text(post.title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')
            Text(post.competitionName)
              .fontSize(13)
              .fontColor(AppColors.PRIMARY)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#EAF0FF')
              .borderRadius(10)
            Text(post.content)
              .fontSize(16)
              .fontColor(AppColors.TEXT_PRIMARY)
              .lineHeight(26)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)

          Column({ space: 6 }) {
            Row() {
              Text(post.authorName)
                .fontSize(14)
                .fontColor(AppColors.TEXT_PRIMARY)
              Blank()
              Text(`❤️ ${post.likes}`)
                .fontSize(14)
                .fontColor(AppColors.PRIMARY)
            }
            .width('100%')
            Text(formatTime(post.createdAt))
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
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
  }
}
