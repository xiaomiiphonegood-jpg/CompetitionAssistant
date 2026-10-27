/**
 * 个人资料编辑页：修改昵称、学校、专业、年级
 */
import { UserProfile } from '../model/User';
import { UserService } from '../service/UserService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct ProfileEdit {
  @State nickname: string = '';
  @State school: string = '';
  @State major: string = '';
  @State grade: string = '';
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const p = await UserService.getProfile();
    this.nickname = p.nickname;
    this.school = p.school;
    this.major = p.major;
    this.grade = p.grade;
    this.loading = false;
  }

  async save(): Promise<void> {
    const name = this.nickname.trim();
    if (name === '') {
      promptAction.showToast({ message: '昵称不能为空' });
      return;
    }
    const cur = await UserService.getProfile();
    const profile: UserProfile = {
      nickname: name,
      school: this.school.trim(),
      major: this.major.trim(),
      grade: this.grade.trim(),
      loggedIn: cur.loggedIn
    };
    await UserService.saveProfile(profile);
    const version = AppStorage.get<number>('profileVersion');
    AppStorage.setOrCreate('profileVersion', (version === undefined ? 0 : version) + 1);
    promptAction.showToast({ message: '已保存' });
    router.back();
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('编辑资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
        Text('保存')
          .fontSize(16)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => this.save())
      }
      .width('100%')
      .padding(16)

      if (this.loading) {
        LoadingProgress().width(40).height(40).margin({ top: 80 })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            this.FieldLabel('昵称')
            TextInput({ text: $$this.nickname, placeholder: '请输入昵称' })
              .height(48)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            this.FieldLabel('学校')
            TextInput({ text: $$this.school, placeholder: '如：清华大学' })
              .height(48)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            this.FieldLabel('专业')
            TextInput({ text: $$this.major, placeholder: '如：计算机科学与技术' })
              .height(48)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            this.FieldLabel('年级')
            TextInput({ text: $$this.grade, placeholder: '如：大三' })
              .height(48)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            Button('保存')
              .width('100%')
              .height(48)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(AppColors.WHITE)
              .borderRadius(24)
              .fontSize(16)
              .margin({ top: 12 })
              .onClick(() => this.save())
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_PRIMARY)
      .width('100%')
  }
}
