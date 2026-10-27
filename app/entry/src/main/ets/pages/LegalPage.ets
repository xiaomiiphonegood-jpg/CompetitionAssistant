/**
 * 合规文档页：隐私政策 / 用户协议（上架必审）
 * 通过路由参数 type 区分：privacy / agreement
 */
import { AppColors } from '../common/Constants';
import router from '@ohos.router';

interface LegalParams {
  type: string;
}

const PRIVACY_TEXT: string = `隐私政策

更新日期：2026 年 9 月

欢迎使用「大学生竞赛助手」。我们深知个人信息对您的重要性，将严格依据《中华人民共和国个人信息保护法》等法律法规保护您的个人信息。

一、我们收集的信息
1. 账号信息：为提供跨设备数据同步，在您登录时收集华为账号标识（openid）。
2. 个人资料：您主动填写的学校、专业、年级、技能标签。
3. 使用数据：您收藏的竞赛、生成的学习规划、发布的帖子等，用于向您提供相应功能。

二、信息的使用
1. 用于提供竞赛信息展示、AI 学习规划、组队与经验分享等核心功能。
2. 用于改进产品体验，不用于其他无关用途。

三、信息的存储
1. 您的数据存储于华为云（AppGallery Connect）在中国境内的服务器。
2. 我们采取加密传输、访问控制等措施保护您的数据安全。

四、信息的共享
1. 我们不会向第三方出售您的个人信息。
2. 仅在法律法规要求、或为完成您主动发起的操作（如组队帖中的联系方式）时进行必要共享。

五、您的权利
您有权查询、更正、删除您的个人信息，有权撤回同意。可通过应用内"设置-关于"联系我们。

六、未成年人保护
本应用面向在校大学生，如您为未成年人，请在监护人指导下使用。

七、联系我们
如对本政策有任何疑问，请联系：competitionassistant@example.com`;

const AGREEMENT_TEXT: string = `用户协议

更新日期：2026 年 9 月

一、服务说明
「大学生竞赛助手」为用户提供竞赛信息展示、AI 学习规划、组队交流、经验分享等服务。AI 学习规划由大模型生成，仅供学习参考，不构成任何获奖承诺。

二、用户行为规范
1. 您应保证发布内容（组队帖、经验帖）真实、合法，不含有违法、侵权、诽谤、骚扰等内容。
2. 不得利用本应用从事代考、代写、作弊等违反学术诚信及法律法规的活动。
3. 不得发布广告、垃圾信息或恶意链接。

三、知识产权
1. 应用内竞赛信息的知识产权归相应主办方所有。
2. 用户发布的原创内容，其著作权归用户本人，用户授权本应用在服务范围内展示。

四、免责声明
1. 竞赛信息（时间、报名方式等）可能因主办方调整而变化，请以官方通知为准。
2. AI 生成的规划建议不构成专业指导，因参考本建议产生的后果由用户自行承担。

五、协议变更
我们可能适时修订本协议，修订后将通过应用内公告方式告知。

六、联系我们
competitionassistant@example.com`;

@Entry
@Component
struct LegalPage {
  @State title: string = '隐私政策';
  @State content: string = '';

  aboutToAppear(): void {
    this.load();
  }

  load(): void {
    try {
      const p = router.getParams() as LegalParams;
      if (p.type === 'agreement') {
        this.title = '用户协议';
        this.content = AGREEMENT_TEXT;
      } else {
        this.title = '隐私政策';
        this.content = PRIVACY_TEXT;
      }
    } catch (e) {
      this.title = '隐私政策';
      this.content = PRIVACY_TEXT;
    }
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Text(this.content)
          .fontSize(14)
          .fontColor(AppColors.TEXT_PRIMARY)
          .lineHeight(24)
          .width('100%')
      }
      .layoutWeight(1)
      .padding({ left: 20, right: 20, bottom: 24 })
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
