# 大学生竞赛助手（Competition Assistant）

> 项目总览（解决什么问题、主要功能、安装与使用方法、输入输出示例）见仓库根目录 [README.md](../README.md)。本文档聚焦客户端工程目录与构建细节。

一款面向大学生的 **HarmonyOS 竞赛助手应用**：竞赛日历时间线 + AI 备赛规划。

- 技术栈：ArkTS + ArkUI（Stage 模型，API 12 / HarmonyOS 5.0）
- 云服务：AppGallery Connect（云数据库 + 云函数 + 认证 + 推送）
- AI：可插拔大模型 API（DeepSeek / Ollama；客户端可直连调试，生产建议经云函数代理，Key 不下发客户端）

## 快速开始

> ✅ 已用本机 DevEco Studio 6.0.2 命令行**真实构建通过**（BUILD SUCCESSFUL，零编译错误）。

**方式一：DevEco Studio 一键运行（推荐）**
1. 用 DevEco Studio 打开本目录（`app/`）
2. 首次需配置签名：`File > Project Structure > Signing Configs` 勾选 "Automatically generate signature"（登录华为账号自动生成 debug 证书）
3. 连接模拟器或真机，点击 **Run** 即可安装运行

**方式二：命令行构建（已验证）**

在 `app/` 目录下执行（Windows PowerShell），先把 `<DevEco Studio 安装目录>` 替换为本机实际路径：

```powershell
$DEVECO = "<DevEco Studio 安装目录>"
$env:NODE_HOME = "$DEVECO/tools/node"
$env:DEVECO_SDK_HOME = "$DEVECO/sdk"
& "$DEVECO/tools/hvigor/bin/hvigorw.bat" assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`（未签名，签名后即可安装）

> 当前默认以 **本地 Mock 数据** 运行（无需后端即可完整体验闭环），接入 AGC 见下文「接入云端」。

## 目录结构

```
app/
├── AppScope/
│   ├── app.json5                  # 应用级配置（包名/版本/图标）
│   └── resources/
├── build-profile.json5            # 工程构建配置
├── hvigorfile.ts
├── oh-package.json5
└── entry/
    ├── build-profile.json5
    ├── hvigorfile.ts
    ├── oh-package.json5
    └── src/main/
        ├── module.json5           # 模块配置（能力/权限）
        ├── ets/
        │   ├── entryability/EntryAbility.ets   # 应用入口
        │   ├── pages/             # 页面（@Entry）
        │   │   ├── Index.ets              # 首页 Tab 容器
        │   │   ├── CompetitionDetail.ets   # 竞赛详情
        │   │   ├── AiChat.ets             # AI 对话（学习规划）
        │   │   └── PlanDetail.ets         # 规划详情
        │   ├── view/              # 视图组件（@Component）
        │   │   ├── TimelineView.ets       # 竞赛日历时间线
        │   │   ├── AiAssistantView.ets    # AI 助手入口+规划列表
        │   │   └── ProfileView.ets        # 我的
        │   ├── model/             # 数据模型
        │   │   ├── Competition.ets
        │   │   ├── StudyPlan.ets
        │   │   └── ChatMessage.ets
        │   ├── common/Constants.ets       # 常量（颜色/分类/云配置）
        │   └── service/           # 服务层
        │       ├── CloudService.ets       # 竞赛/收藏/规划（Mock + 云函数）
        │       ├── SocialService.ets      # 组队/经验/排行榜/提醒
        │       ├── UserService.ets        # 个人资料 + 登录态
        │       ├── AiService.ets          # AI 规划生成（DeepSeek/Ollama/模拟）
        │       └── AiSettingsService.ets  # 模型运行时配置
        └── resources/             # 资源（字符串/颜色/图标/路由表）
```

## 功能清单（MVP）

| 模块 | 说明 | 状态 |
|---|---|---|
| 竞赛日历时间线 | 按月分组、分类筛选、搜索、剩余天数角标 | ✅ |
| 竞赛详情 | 简介/主办方/时间节点/收藏 | ✅ |
| AI 备赛规划 | 对话式收集基础/时间/目标，生成周计划（支持 DeepSeek 大模型） | ✅ |
| 学习打卡 | 规划任务勾选完成 + 进度条 | ✅ |
| 组队广场 | 发布组队帖、浏览招募、技能标签 | ✅ |
| 经验分享 | 发帖、点赞、竞赛标签 | ✅ |
| 排行榜 | 竞赛积分榜 | ✅ |
| 智能提醒 | 临近节点倒计时提醒 | ✅ |
| 我的收藏 / 我的规划 | 本地持久化，接入 AGC 后云端同步 | ✅ |
| 个人资料编辑 | 昵称/学校/专业/年级可改，登录/退出 | ✅ |
| 设置中心 | 模型配置 / 清除数据 / 隐私协议 / 关于 | ✅ |
| 模型配置 | 运行时切换 DeepSeek / Ollama / 模拟模式 | ✅ |

> 收藏、规划、打卡默认走 Preferences 本地持久化（重启不丢）；
> 将 `CloudConfig.USE_MOCK` 置 `false` 后，个人资料、发帖、收藏、规划、打卡、点赞全部经 AGC 云函数写入 Cloud DB，**全员可访问**（见 `docs/06` 第三节「数据上云共享」）。

## 接入 AI 大模型（DeepSeek / Ollama 本地模型）

AI 备赛规划默认走本地模拟。接入真实大模型**无需改代码**，在 APP 内即可配置：

1. 打开 APP → `我的` → `设置` → `模型配置`
2. 选服务商：
   - **DeepSeek**：填 `https://api.deepseek.com` + 模型 `deepseek-chat` + 你的 API Key
   - **Ollama（本地）**：填 `http://服务器IP:11434` + 模型 `qwen2.5:7b`，Key 留空
3. 关闭「模拟模式」开关 → 保存

之后 AI 助手即真实调用大模型生成计划。自建本地大模型详见 `docs/07-Ollama本地大模型部署指南.md`。

> 配置保存在本地 Preferences，重启不丢；`设置 → 模型配置 → 恢复默认` 可还原。

## 接入云端（AppGallery Connect）

1. 在 AGC 控制台创建项目，开通 **Cloud DB / Cloud Functions / Auth Service / Push Kit**
2. 按 `docs/02-数据库与云服务设计.md` 创建数据集合（competition、competition_stage、user_profile、favorite、study_plan、team_post、share_post）
3. 部署云函数（上传 `cloudfunctions/` 下 `index.js` + `ai.js` + `package.json`），在环境变量配置大模型 API Key，并配置 HTTP 触发器
4. 在 `entry/src/main/ets/common/Constants.ets` 中：
   - `CloudConfig.USE_MOCK` 改为 `false`
   - `CloudConfig.CLOUD_FUNCTION_BASE` 填入云函数 HTTP 触发器地址
5. 配置签名证书后重新构建

## 设计文档

见项目根目录 `docs/`：
1. `01-需求分析与功能清单.md`
2. `02-数据库与云服务设计.md`
3. `03-UI设计与交互规范.md`
4. `04-AI学习规划Prompt设计.md`
5. `05-项目目录结构与开发建议.md`
6. `06-上架与后端部署指南.md`
7. `07-Ollama本地大模型部署指南.md`
8. `08-上架文案与合规文本.md`
