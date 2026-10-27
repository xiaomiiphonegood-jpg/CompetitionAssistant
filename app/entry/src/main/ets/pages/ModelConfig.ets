/**
 * 模型配置页：配置 AI 大模型（DeepSeek / Ollama 本地模型等）
 * 修改后立即生效，无需重新编译。
 */
import { AiSettings } from '../model/AiSettings';
import { AiSettingsService } from '../service/AiSettingsService';
import { AppColors } from '../common/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

const PROVIDERS: string[] = ['deepseek', 'ollama', 'custom'];
const PROVIDER_NAMES: string[] = ['DeepSeek', 'Ollama(本地)', '自定义'];

@Entry
@Component
struct ModelConfig {
  @State provider: string = 'deepseek';
  @State baseUrl: string = '';
  @State model: string = '';
  @State apiKey: string = '';
  @State useMock: boolean = true;
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const s = await AiSettingsService.getSettings();
    this.provider = s.provider;
    this.baseUrl = s.baseUrl;
    this.model = s.model;
    this.apiKey = s.apiKey;
    this.useMock = s.useMock;
    this.loading = false;
  }

  private pickProvider(p: string): void {
    this.provider = p;
    if (p === 'ollama') {
      if (this.baseUrl === '' || this.baseUrl.indexOf('api.deepseek') >= 0) {
        this.baseUrl = 'http://127.0.0.1:11434';
      }
      if (this.model === '' || this.model === 'deepseek-chat') {
        this.model = 'qwen2.5:7b';
      }
    } else if (p === 'deepseek') {
      if (this.baseUrl === '' || this.baseUrl.indexOf('127.0.0.1') >= 0 || this.baseUrl.indexOf('11434') >= 0) {
        this.baseUrl = 'https://api.deepseek.com';
      }
      if (this.model === '' || this.model.indexOf(':') >= 0) {
        this.model = 'deepseek-chat';
      }
    }
  }

  private providerName(): string {
    const idx = PROVIDERS.indexOf(this.provider);
    return idx >= 0 ? PROVIDER_NAMES[idx] : this.provider;
  }

  async save(): Promise<void> {
    let base = this.baseUrl.trim();
    if (!this.useMock && base === '') {
      promptAction.showToast({ message: '请填写接口地址' });
      return;
    }
    if (!this.useMock && this.model.trim() === '') {
      promptAction.showToast({ message: '请填写模型名称' });
      return;
    }
    while (base.length > 0 && base.charAt(base.length - 1) === '/') {
      base = base.substring(0, base.length - 1);
    }
    const settings: AiSettings = {
      provider: this.provider,
      baseUrl: base,
      model: this.model.trim(),
      apiKey: this.apiKey.trim(),
      useMock: this.useMock
    };
    await AiSettingsService.saveSettings(settings);
    promptAction.showToast({ message: this.useMock ? '已保存（当前为模拟模式）' : '已保存（真实调用大模型）' });
    router.back();
  }

  async reset(): Promise<void> {
    await AiSettingsService.reset();
    const s = await AiSettingsService.getSettings();
    this.provider = s.provider;
    this.baseUrl = s.baseUrl;
    this.model = s.model;
    this.apiKey = s.apiKey;
    this.useMock = s.useMock;
    promptAction.showToast({ message: '已恢复默认配置' });
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Text('模型配置')
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
            // 模式开关
            Column({ space: 10 }) {
              Row() {
                Text('模拟模式')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.useMock })
                  .selectedColor(AppColors.PRIMARY)
                  .onChange((isOn: boolean) => {
                    this.useMock = isOn;
                  })
              }
              .width('100%')
              Text(this.useMock ? '开启后离线使用内置模拟规划，不联网' : '关闭后真实调用下方配置的大模型')
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)

            // 服务商
            Column({ space: 10 }) {
              Text('服务商')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TEXT_PRIMARY)
                .width('100%')
              Row({ space: 8 }) {
                ForEach(PROVIDERS, (p: string, index: number) => {
                  Text(PROVIDER_NAMES[index])
                    .fontSize(13)
                    .fontColor(this.provider === p ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
                    .backgroundColor(this.provider === p ? AppColors.PRIMARY : AppColors.CARD)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .borderRadius(18)
                    .border({ width: 1, color: this.provider === p ? AppColors.PRIMARY : AppColors.DIVIDER })
                    .onClick(() => this.pickProvider(p))
                }, (p: string) => p)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.CARD)
            .borderRadius(16)

            // 接口地址
            this.FieldLabel('接口地址 Base URL')
            TextInput({ text: $$this.baseUrl, placeholder: 'https://api.deepseek.com 或 http://IP:11434' })
              .height(48)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            // 模型名称
            this.FieldLabel('模型名称 Model')
            TextInput({ text: $$this.model, placeholder: 'deepseek-chat / qwen2.5:7b / llama3' })
              .height(48)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            // API Key
            this.FieldLabel('API Key（Ollama 可留空）')
            TextInput({ text: $$this.apiKey, placeholder: '请输入 API Key' })
              .height(48)
              .type(InputType.Password)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .padding({ left: 12, right: 12 })

            Text('💡 本地大模型：在云服务器安装 Ollama 后，将地址填为 http://服务器IP:11434，模型填如 qwen2.5:7b，关闭模拟模式即可。详见 docs/07-Ollama本地大模型部署指南.md')
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
              .lineHeight(18)
              .width('100%')

            Button('保存配置')
              .width('100%')
              .height(48)
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(AppColors.WHITE)
              .borderRadius(24)
              .fontSize(16)
              .onClick(() => this.save())

            Button('恢复默认')
              .width('100%')
              .height(44)
              .backgroundColor(AppColors.WHITE)
              .fontColor(AppColors.TEXT_SECONDARY)
              .borderRadius(22)
              .fontSize(15)
              .border({ width: 1, color: AppColors.DIVIDER })
              .onClick(() => this.reset())
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
