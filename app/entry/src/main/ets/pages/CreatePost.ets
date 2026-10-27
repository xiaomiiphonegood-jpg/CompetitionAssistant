/**
 * 发帖页：发布组队帖 / 经验帖（根据 type 参数区分）
 */
import { Competition } from '../model/Competition';
import { TeamPost, SharePost } from '../model/Social';
import { CloudService } from '../service/CloudService';
import { SocialService } from '../service/SocialService';
import { AppColors } from '../common/Constants';
import { ContentFilter } from '../common/ContentFilter';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

interface CreateParams {
  type: string;
}

function localGenId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

@Entry
@Component
struct CreatePost {
  @State type: string = 'team';
  @State competitions: Competition[] = [];
  @State selectedId: string = '';
  @State selectedName: string = '';
  @State needSkills: string = '';
  @State contact: string = '';
  @State title: string = '';
  @State content: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private readType(): string {
    try {
      const p = router.getParams() as CreateParams;
      if (p.type !== '') {
        return p.type;
      }
    } catch (e) {
      // 默认 team
    }
    return 'team';
  }

  async load(): Promise<void> {
    this.type = this.readType();
    this.competitions = await CloudService.getCompetitions();
    if (this.competitions.length > 0) {
      this.selectedId = this.competitions[0].id;
      this.selectedName = this.competitions[0].name;
    }
  }

  async submit(): Promise<void> {
    if (this.selectedId === '') {
      promptAction.showToast({ message: '请选择竞赛' });
      return;
    }
    if (this.type === 'team') {
      if (this.content.trim() === '') {
        promptAction.showToast({ message: '请填写招募描述' });
        return;
      }
      const hit = ContentFilter.checkAll([this.content, this.needSkills, this.contact]);
      if (hit !== '') {
        promptAction.showToast({ message: '内容包含违规信息，请修改后发布' });
        return;
      }
      const raw = this.needSkills.split(/[,，、\s]+/);
      const skills: string[] = raw.filter((s: string) => s !== '');
      const post: TeamPost = {
        id: localGenId('tp'),
        competitionId: this.selectedId,
        competitionName: this.selectedName,
        authorName: '我',
        needSkills: skills.length > 0 ? skills : ['未指定'],
        content: this.content.trim(),
        contact: this.contact.trim() === '' ? '未填写' : this.contact.trim(),
        createdAt: Date.now()
      };
      await SocialService.createTeamPost(post);
    } else {
      if (this.title.trim() === '' || this.content.trim() === '') {
        promptAction.showToast({ message: '请填写标题和内容' });
        return;
      }
      const hit = ContentFilter.checkAll([this.title, this.content]);
      if (hit !== '') {
        promptAction.showToast({ message: '内容包含违规信息，请修改后发布' });
        return;
      }
      const post: SharePost = {
        id: localGenId('sp'),
        competitionId: this.selectedId,
        competitionName: this.selectedName,
        authorName: '我',
        title: this.title.trim(),
        content: this.content.trim(),
        likes: 0,
        liked: false,
        createdAt: Date.now()
      };
      await SocialService.createSharePost(post);
    }
    const version = AppStorage.get<number>('socialVersion');
    AppStorage.setOrCreate('socialVersion', (version === undefined ? 0 : version) + 1);
    promptAction.showToast({ message: '发布成功' });
    router.back();
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text(this.type === 'team' ? '发布组队帖' : '发布经验帖')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column({ space: 16 }) {
          // 竞赛选择
          Column({ space: 8 }) {
            Text('选择竞赛')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            Scroll() {
              Row({ space: 8 }) {
                ForEach(this.competitions, (c: Competition) => {
                  Text(c.shortName)
                    .fontSize(13)
                    .fontColor(this.selectedId === c.id ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
                    .backgroundColor(this.selectedId === c.id ? AppColors.PRIMARY : AppColors.CARD)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .onClick(() => {
                      this.selectedId = c.id;
                      this.selectedName = c.name;
                    })
                }, (c: Competition) => c.id)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          if (this.type === 'team') {
            Column({ space: 8 }) {
              Text('招募技能（逗号分隔）')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              TextInput({ placeholder: '如：编程、Matlab、写作', text: $$this.needSkills })
                .height(44)
                .backgroundColor(AppColors.CARD)
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          if (this.type === 'team') {
            Column({ space: 8 }) {
              Text('联系方式')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              TextInput({ placeholder: '如：QQ/微信/邮箱', text: $$this.contact })
                .height(44)
                .backgroundColor(AppColors.CARD)
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          } else {
            Column({ space: 8 }) {
              Text('标题')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
              TextInput({ placeholder: '一句话概括你的经验', text: $$this.title })
                .height(44)
                .backgroundColor(AppColors.CARD)
                .borderRadius(12)
                .padding({ left: 12, right: 12 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          }

          // 内容
          Column({ space: 8 }) {
            Text(this.type === 'team' ? '招募描述' : '经验内容')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
            TextArea({ placeholder: this.type === 'team' ? '介绍一下你的队伍和需求…' : '分享你的备赛经验、踩坑和心得…', text: $$this.content })
              .height(160)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding(12)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Button('发布')
            .width('100%')
            .height(48)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(24)
            .fontSize(16)
            .onClick(() => this.submit())
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
