/**
 * AI 对话页：对话式学习规划（信息收集 → 生成计划 → 保存）
 */
import { ChatMessage, MessageRole } from '../model/ChatMessage';
import { StudyPlan, PlanPhase } from '../model/StudyPlan';
import { Competition } from '../model/Competition';
import { CloudService } from '../service/CloudService';
import { AiService } from '../service/AiService';
import { AppColors } from '../common/Constants';
import { ContentFilter } from '../common/ContentFilter';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

interface ChatParams {
  competitionId: string;
  competitionName: string;
}

enum Step {
  CHOOSE_COMPETITION = 0,
  ASK_LEVEL = 1,
  ASK_HOURS = 2,
  ASK_TARGET = 3,
  GENERATING = 4,
  DONE = 5
}

const LEVEL_OPTIONS: string[] = ['完全小白', '有一些基础', '基础扎实'];
const HOURS_OPTIONS: string[] = ['每周<5小时', '每周5-10小时', '每周10-20小时', '每周>20小时'];
const TARGET_OPTIONS: string[] = ['保底参与', '省级奖项', '国家级奖项'];

function parseHours(option: string): number {
  if (option.indexOf('<5') >= 0) {
    return 4;
  }
  if (option.indexOf('5-10') >= 0) {
    return 8;
  }
  if (option.indexOf('10-20') >= 0) {
    return 15;
  }
  return 24;
}

@Entry
@Component
struct AiChat {
  @State messages: ChatMessage[] = [];
  @State input: string = '';
  @State step: Step = Step.CHOOSE_COMPETITION;
  @State competitionId: string = '';
  @State competitionName: string = '';
  @State level: string = '';
  @State weeklyHours: number = 0;
  @State target: string = '';
  @State currentPlan: StudyPlan | null = null;
  @State allCompetitions: Competition[] = [];

  private scroller: Scroller = new Scroller();
  private msgSeq: number = 0;

  aboutToAppear(): void {
    this.bootstrap();
  }

  private readParams(): ChatParams {
    const result: ChatParams = { competitionId: '', competitionName: '' };
    try {
      const p = router.getParams() as ChatParams;
      if (p.competitionId !== '' && p.competitionName !== '') {
        result.competitionId = p.competitionId;
        result.competitionName = p.competitionName;
      }
    } catch (e) {
      // 无参数（从 AI 助手入口进入），保持空
    }
    return result;
  }

  async bootstrap(): Promise<void> {
    this.allCompetitions = await CloudService.getCompetitions();
    const params = this.readParams();
    if (params.competitionId !== '') {
      this.competitionId = params.competitionId;
      this.competitionName = params.competitionName;
      this.pushAssistant(`好的，为「${params.competitionName}」做备赛规划！首先，你目前的基础怎么样？`, LEVEL_OPTIONS);
      this.step = Step.ASK_LEVEL;
    } else {
      const names: string[] = this.competitionOptions();
      this.pushAssistant('你好！我是你的 AI 备赛规划师 👋 想为哪场比赛做规划？可以先选一个：', names);
      this.step = Step.CHOOSE_COMPETITION;
    }
  }

  private pushAssistant(content: string, options: string[] = [], plan: StudyPlan | null = null): void {
    this.messages.push({ id: `a_${this.msgSeq++}`, role: MessageRole.ASSISTANT, content: content, options: options, plan: plan });
    this.scrollToBottom();
  }

  private pushUser(content: string): void {
    this.messages.push({ id: `u_${this.msgSeq++}`, role: MessageRole.USER, content: content, options: [], plan: null });
    this.scrollToBottom();
  }

  private scrollToBottom(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 60);
  }

  private competitionOptions(): string[] {
    return this.allCompetitions.slice()
      .sort((a: Competition, b: Competition) => b.hot - a.hot)
      .slice(0, 5)
      .map((c: Competition) => c.shortName);
  }

  private onPickOption(option: string): void {
    if (this.step === Step.GENERATING) {
      return;
    }
    this.pushUser(option);
    switch (this.step) {
      case Step.CHOOSE_COMPETITION: {
        const comp = this.allCompetitions.find((c: Competition) => c.shortName === option);
        if (comp !== undefined) {
          this.competitionId = comp.id;
          this.competitionName = comp.name;
          this.pushAssistant(`好的，为「${comp.name}」做规划！你目前的基础怎么样？`, LEVEL_OPTIONS);
          this.step = Step.ASK_LEVEL;
        } else {
          this.pushAssistant('没找到这场比赛，请从下方选择或直接输入竞赛全名～', this.competitionOptions());
        }
        break;
      }
      case Step.ASK_LEVEL: {
        this.level = option;
        this.pushAssistant('收到～每周大概能投入多少小时备赛？', HOURS_OPTIONS);
        this.step = Step.ASK_HOURS;
        break;
      }
      case Step.ASK_HOURS: {
        this.weeklyHours = parseHours(option);
        this.pushAssistant('明白～这次的目标是？', TARGET_OPTIONS);
        this.step = Step.ASK_TARGET;
        break;
      }
      case Step.ASK_TARGET: {
        this.target = option;
        this.step = Step.GENERATING;
        this.generatePlan();
        break;
      }
      default:
        break;
    }
  }

  async generatePlan(feedback: string = ''): Promise<void> {
    this.pushAssistant('正在为你生成专属备赛计划…⏳', []);
    try {
      const plan = await AiService.generatePlan({
        competitionId: this.competitionId,
        competitionName: this.competitionName,
        level: this.level,
        weeklyHours: this.weeklyHours,
        target: this.target
      }, feedback);
      this.currentPlan = plan;
      this.pushAssistant('计划已生成！你可以直接保存，或输入意见让我调整。', [], plan);
      this.step = Step.DONE;
    } catch (e) {
      this.pushAssistant('抱歉，AI 生成计划失败了。请到「我的 → 设置 → 模型配置」检查接口地址、模型名称或 API Key 是否正确（或切回模拟模式）。重新选择目标再试一次：', TARGET_OPTIONS);
      this.step = Step.ASK_TARGET;
    }
  }

  async savePlan(plan: StudyPlan): Promise<void> {
    if (plan === null) {
      return;
    }
    await CloudService.savePlan(plan);
    const version = AppStorage.get<number>('plansVersion');
    AppStorage.setOrCreate('plansVersion', (version === undefined ? 0 : version) + 1);
    promptAction.showToast({ message: '已保存到我的规划' });
  }

  private sendText(): void {
    const text = this.input.trim();
    if (text === '') {
      return;
    }
    if (ContentFilter.check(text) !== '') {
      promptAction.showToast({ message: '输入包含违规信息，请修改' });
      this.input = '';
      return;
    }
    this.input = '';
    this.pushUser(text);

    if (this.step === Step.DONE && this.currentPlan !== null) {
      this.pushAssistant('好的，我根据你的意见重新调整计划…⏳', []);
      this.step = Step.GENERATING;
      this.generatePlan(text);
    } else if (this.step === Step.CHOOSE_COMPETITION) {
      const comp = this.allCompetitions.find((c: Competition) => c.name.indexOf(text) >= 0 || c.shortName.indexOf(text) >= 0);
      if (comp !== undefined) {
        this.competitionId = comp.id;
        this.competitionName = comp.name;
        this.pushAssistant(`好的，为「${comp.name}」做规划！你目前的基础怎么样？`, LEVEL_OPTIONS);
        this.step = Step.ASK_LEVEL;
      } else {
        this.pushAssistant('暂未收录这场比赛，可以先从下方热门赛事选一个～', this.competitionOptions());
      }
    } else {
      this.pushAssistant('请点击下方选项，或按提示继续告诉我～', this.currentOptions());
    }
  }

  private currentOptions(): string[] {
    switch (this.step) {
      case Step.CHOOSE_COMPETITION:
        return this.competitionOptions();
      case Step.ASK_LEVEL:
        return LEVEL_OPTIONS;
      case Step.ASK_HOURS:
        return HOURS_OPTIONS;
      case Step.ASK_TARGET:
        return TARGET_OPTIONS;
      default:
        return [];
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
        Text('AI 备赛规划')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(14)

      // 消息列表
      List({ scroller: this.scroller, space: 12 }) {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            this.MessageBubble(msg)
          }
        }, (msg: ChatMessage) => msg.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 输入框
      Row({ space: 10 }) {
        TextInput({ placeholder: '输入你想问的…', text: $$this.input })
          .layoutWeight(1)
          .height(44)
          .backgroundColor(AppColors.CARD)
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
        Button('发送')
          .height(44)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(22)
          .padding({ left: 20, right: 20 })
          .onClick(() => this.sendText())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(AppColors.WHITE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  MessageBubble(msg: ChatMessage) {
    if (msg.role === MessageRole.USER) {
      Row() {
        Blank()
        Text(msg.content)
          .fontSize(15)
          .fontColor(AppColors.WHITE)
          .padding(12)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(16)
          .constraintSize({ maxWidth: '75%' })
      }
      .width('100%')
    } else {
      Column({ space: 10 }) {
        Text(msg.content)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .lineHeight(22)
          .padding(12)
          .backgroundColor(AppColors.CARD)
          .borderRadius(16)
          .constraintSize({ maxWidth: '88%' })

        if (msg.options.length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(msg.options, (opt: string) => {
              Text(opt)
                .fontSize(13)
                .fontColor(AppColors.PRIMARY)
                .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                .backgroundColor('#EAF0FF')
                .borderRadius(16)
                .margin({ right: 8, bottom: 8 })
                .onClick(() => this.onPickOption(opt))
            }, (opt: string) => opt)
          }
          .width('100%')
        }

        if (msg.plan !== null) {
          this.PlanCard(msg.plan)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
  }

  @Builder
  PlanCard(plan: StudyPlan) {
    Column({ space: 8 }) {
      Text(plan.summary)
        .fontSize(13)
        .fontColor(AppColors.TEXT_PRIMARY)
        .lineHeight(20)
      ForEach(plan.phases, (phase: PlanPhase) => {
        Row() {
          Text(phase.name)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.PRIMARY)
            .width(64)
          Text(phase.weeks)
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width(52)
          Text(phase.goal)
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(2)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }, (phase: PlanPhase) => phase.name)

      Row({ space: 10 }) {
        Button('保存为我的规划')
          .height(40)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(20)
          .fontSize(14)
          .onClick(() => this.savePlan(plan))
        Button('调整计划')
          .height(40)
          .backgroundColor(AppColors.WHITE)
          .fontColor(AppColors.PRIMARY)
          .border({ width: 1, color: AppColors.PRIMARY })
          .borderRadius(20)
          .fontSize(14)
          .onClick(() => {
            this.pushAssistant('请告诉我你想调整的地方，比如"第2阶段任务太多"～', []);
          })
      }
      .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.CARD)
    .borderRadius(16)
  }
}
