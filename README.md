# 大学生竞赛助手（Competition Assistant）

> 一款面向大学生的 HarmonyOS **竞赛全周期助手**：把散落的竞赛信息收进日历，用 AI 把备赛拆成可执行的周计划，再用组队、经验与排行榜把「人和经验」沉淀下来。

[快速开始](#三安装方法) · [主要功能](#二主要功能) · [使用方法](#四使用方法) · [输入输出示例](#五输入--输出示例) · [设计文档](#八设计文档) · [许可证](#十一许可证)

| 项目 | 说明 |
|---|---|
| 应用包名 | `com.campus.competitionassistant` |
| 当前版本 | v1.1.0 |
| 运行平台 | HarmonyOS 5.0（API 12），手机 / 平板 |
| 客户端 | ArkTS + ArkUI（Stage 模型） |
| 云服务 | AppGallery Connect：Cloud DB / Cloud Functions / Auth / Push（可选） |
| AI 能力 | DeepSeek / Ollama（OpenAI 兼容接口）/ 本地模拟，运行时可切换 |
| 默认模式 | 本地 Mock 数据 + Preferences 持久化，**不接后端也能完整体验** |
| 许可证 | [MIT](LICENSE) |

---

## 一、这个项目解决什么问题

### 1.1 真实痛点

大学生参加学科竞赛（数学建模、挑战杯、互联网+、ACM、蓝桥杯、大创等）时，普遍卡在四个地方：

| 痛点 | 具体表现 |
|---|---|
| **信息分散，容易错过** | 竞赛通知散落在教务处网站、公众号、QQ 群，报名截止时间经常一不留神就过了 |
| **知道要比赛，但不知道怎么准备** | 没有阶段性的学习路径，容易临时抱佛脚，也不知道每周该做什么 |
| **找不到靠谱队友** | 想组队却没有匹配渠道，能力互补的队友可遇不可求 |
| **经验无法沉淀** | 往届获奖经验靠口口相传，换一届学生就从零开始 |

### 1.2 解决思路

用一条「**发现 → 收藏 → 规划 → 执行 → 交流**」的主线，把备赛这件事变得有条理：

- **竞赛日历**：把报名开始、报名截止、正式比赛、结果公布统一到一条时间线，按月分组，支持分类筛选、关键词搜索、剩余天数角标与节点类型标识，重要节点不再错过。
- **AI 备赛规划**：对话式收集「当前基础 / 每周可投入时间 / 目标」，生成 2–4 个阶段、周粒度的计划；任务具体到"学什么、练什么、产出什么"，还可以继续对话调整。
- **学习打卡**：计划任务逐项勾选完成，进度条实时反馈，解决"计划做完就吃灰"。
- **组队与经验**：组队广场发布/浏览招募帖，经验分享支持发帖、点赞、按竞赛聚合，排行榜提供正向激励。
- **开箱即用**：默认 Mock 数据 + 本地持久化，不配置任何云服务也能跑通完整闭环；需要多人共享时再切到 AGC。

### 1.3 目标用户

| 角色 | 特征 | 核心诉求 |
|---|---|---|
| 小白型（约 50%） | 大一/大二，没参加过竞赛，想尝试 | 有什么适合我的竞赛？怎么入门？ |
| 进阶型（约 35%） | 参加过 1–2 次，想冲奖 | 时间怎么安排？重点学什么？ |
| 大佬型（约 15%） | 多次获奖，带团队 | 组队招人、分享经验、获得认可 |

### 1.4 产品定位

> 不做「报名工具」，做「备赛教练」——差异化在于 **AI 个性化备赛规划 + 竞赛全周期管理**。

---

## 二、主要功能

| 模块 | 能力 | 状态 |
|---|---|---|
| 竞赛日历时间线 | 按月分组、分类筛选、关键词搜索、剩余天数角标、节点类型标识 | ✅ |
| 竞赛详情 | 简介、主办方、级别、官网、完整时间节点、收藏 | ✅ |
| 我的收藏 | 本地持久化，按紧急度展示，详情页与「我的」状态同步 | ✅ |
| AI 备赛规划 | 对话式收集基础/时间/目标，生成周粒度分阶段计划，支持追问调整 | ✅ |
| 学习打卡 | 计划任务逐项勾选，完成进度可视化 | ✅ |
| 我的规划 | 规划列表、阶段与周任务详情、打卡状态持久化 | ✅ |
| 组队广场 | 发布组队帖（所需技能、联系方式）、浏览招募、竞赛标签 | ✅ |
| 经验分享 | 发帖、点赞、按竞赛标签聚合、详情页 | ✅ |
| 排行榜 | 竞赛积分榜（演示数据 + 本人真实活跃度动态统计） | ✅ |
| 智能提醒 | 基于系统 `reminderAgentManager` 的日历提醒，应用退出后仍可触发 | ✅ |
| 个人资料与登录 | 模拟登录 / 华为账号一键登录（需 AGC Auth），昵称/学校/专业/年级可编辑 | ✅ |
| 设置中心 | 模型配置、清除本地数据、隐私政策、用户协议、关于 | ✅ |
| 数据上云（可选） | `USE_MOCK = false` 后，资料、收藏、规划、打卡、发帖、点赞经云函数写入 Cloud DB | ✅ |

> 默认运行在 **Mock 模式**：无需服务器、无需 API Key，即可体验「看日历 → 收藏 → AI 规划 → 打卡」的完整闭环。
> 需要多人共享数据或真实华为账号登录时，按 [3.4 接入 AGC](#34-可选接入-agc-云服务多人共享--真实登录) 切换。

---

## 三、安装方法

### 3.1 环境要求

| 依赖 | 要求 |
|---|---|
| 操作系统 | Windows 10/11 或 macOS |
| DevEco Studio | 6.0.2 及以上（内置 hvigor、Node.js） |
| HarmonyOS SDK | API 12（HarmonyOS 5.0），`compatibleSdkVersion` / `targetSdkVersion` 均为 `5.0.0(12)` |
| 运行设备 | HarmonyOS 模拟器，或开启开发者模式的真机 |
| 可选 | 华为开发者账号（签名、AGC、真实登录） |
| 可选 | DeepSeek API Key，或本机 Ollama 服务 |

### 3.2 方式一：DevEco Studio 运行（推荐）

1. **打开工程**：用 DevEco Studio 打开 `app/` 目录（注意是 `app/`，不是仓库根目录）。
2. **配置签名**：`File > Project Structure > Signing Configs`，勾选 **Automatically generate signature**，登录华为账号自动生成 debug 证书。未签名的 HAP 无法安装。
3. **选择设备**：启动 HarmonyOS 模拟器，或连接已开启开发者模式的真机。
4. **运行**：点击 **Run**，构建成功后应用会自动安装并启动。
5. **首次启动**：阅读并同意《隐私政策》《用户协议》后进入首页。

> 已在 DevEco Studio 6.0.2 下实测通过命令行构建（`BUILD SUCCESSFUL`，零编译错误）。

### 3.3 方式二：命令行构建

在 `app/` 目录下执行（Windows PowerShell）。先把 `<DevEco Studio 安装目录>` 替换为本机实际路径：

```powershell
$DEVECO = "<DevEco Studio 安装目录>"
$env:NODE_HOME = "$DEVECO/tools/node"
$env:DEVECO_SDK_HOME = "$DEVECO/sdk"
& "$DEVECO/tools/hvigor/bin/hvigorw.bat" assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

macOS / Linux：

```bash
export DEVECO_HOME="<DevEco Studio 安装目录>"
export NODE_HOME="$DEVECO_HOME/Contents/tools/node"
export DEVECO_SDK_HOME="$DEVECO_HOME/Contents/sdk"
"$DEVECO_HOME/Contents/tools/hvigor/bin/hvigorw" assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

构建成功后输出 `BUILD SUCCESSFUL`，产物位于：

```
app/entry/build/default/outputs/default/entry-default-unsigned.hap
```

> 该产物为**未签名** HAP，不能直接安装。请用 DevEco Studio 的 **Run** 安装，或先配置签名再通过 `hdc install` 安装。

### 3.4 可选：接入 AGC 云服务（多人共享 / 真实登录）

1. 在 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html) 创建项目，开通 **Cloud DB、Cloud Functions、Auth Service、Push Kit**。
2. 按 [docs/02-数据库与云服务设计.md](docs/02-数据库与云服务设计.md) 创建集合（`competition`、`competition_stage`、`user_profile`、`favorite`、`study_plan`、`team_post`、`share_post`）。
3. 部署云函数：上传 `cloudfunctions/` 下的 `index.js`、`ai.js`、`package.json`，在环境变量中配置 `DEEPSEEK_API_KEY`，并配置 HTTP 触发器。
4. 修改 `app/entry/src/main/ets/common/Constants.ets`：
   - `CloudConfig.USE_MOCK` 改为 `false`
   - `CloudConfig.CLOUD_FUNCTION_BASE` 填入云函数 HTTP 触发器地址
5. 重新构建并安装。

详细步骤见 [cloudfunctions/README.md](cloudfunctions/README.md) 与 [docs/06-上架与后端部署指南.md](docs/06-上架与后端部署指南.md)。

### 3.5 可选：接入本地大模型（Ollama）

```bash
ollama pull qwen2.5:7b

# Linux / macOS / 云服务器
OLLAMA_HOST=0.0.0.0 ollama serve

# Windows PowerShell
$env:OLLAMA_HOST="0.0.0.0"; ollama serve
```

然后在 APP 内按 [4.4 配置 AI 模型](#44-配置-ai-模型) 填写 Base URL 为 `http://Ollama所在机器IP:11434`、模型为 `qwen2.5:7b`，Key 留空（本机/局域网填电脑 IP，云服务器填公网 IP）。

完整部署与排错见 [docs/07-Ollama本地大模型部署指南.md](docs/07-Ollama本地大模型部署指南.md)。

---

## 四、使用方法

### 4.1 首次启动

1. 首次打开应用会弹出隐私政策与用户协议，点击「同意并继续」。
2. 进入首页（竞赛日历）。
3. 需要登录时：`我的` → 点头像/「登录」→ 华为账号一键登录（Mock 模式下为本地模拟登录）。

### 4.2 界面导航

| Tab | 主要入口 | 能做什么 |
|---|---|---|
| **首页** | 竞赛时间线、搜索框、分类筛选 | 按月浏览竞赛节点，搜索竞赛，点卡片进入详情 |
| **广场** | 组队广场 / 经验分享 | 浏览/发布组队帖，浏览/发布经验帖并点赞 |
| **AI 助手** | AI 备赛规划、我的规划 | 新建规划、查看已保存规划 |
| **我的** | 个人资料、我的竞赛、排行榜、智能提醒、设置 | 编辑资料、管理收藏、看排行榜、配置提醒与模型 |

### 4.3 核心闭环（推荐体验路径）

1. **发现竞赛**：首页按月份浏览，或用分类（学科 / 创新创业 / 英语 / 艺术体育 / 编程）和关键词筛选。
2. **查看详情**：点竞赛卡片进入详情页，查看主办方、级别、官网与完整时间节点，点击「收藏」。
3. **发起 AI 规划**：在详情页点「AI 备赛规划」（或从 AI 助手 Tab 直接进入）。
4. **回答三个问题**：当前基础（完全小白 / 有一些基础 / 基础扎实）、每周可投入时间（<5 / 5–10 / 10–20 / >20 小时）、目标（保底参与 / 省级奖项 / 国家级奖项）。
5. **生成并保存**：AI 生成分阶段计划后，可直接「保存到我的规划」，也可以继续输入意见（如「第 5 周任务太重了，帮我减轻一点」）重新生成。
6. **执行打卡**：`AI 助手` 或 `我的规划` → 打开计划 → 逐项勾选周任务，进度条自动更新。
7. **交流沉淀**：到广场发布组队帖或经验帖，点赞感兴趣的内容；在 `我的 → 排行榜` 查看积分。

### 4.4 配置 AI 模型

默认使用**本地模拟**，无需配置即可体验。接入真实大模型：

1. 打开 `我的` → `设置` → `模型配置`。
2. 选择服务商并填写参数：

| 服务商 | Base URL | 模型 | API Key |
|---|---|---|---|
| DeepSeek | `https://api.deepseek.com` | `deepseek-chat` | 必填（[platform.deepseek.com](https://platform.deepseek.com) 申请） |
| Ollama（本地） | `http://服务器IP:11434` | `qwen2.5:7b` | 留空 |
| 自定义 | 任意 OpenAI 兼容地址 | 对应模型名 | 按服务商要求 |

3. 关闭「模拟模式」开关，点击右上角「保存」。
4. 回到 AI 助手重新生成计划即可真实调用大模型。

> 当前实现由客户端直连模型（Base URL 可直接填 DeepSeek 或 Ollama），便于本地调试；正式上架建议改用云函数 `plan-create` 代理，Key 只放服务端环境变量。

> **注意**：`127.0.0.1` 指向设备自身。模拟器/真机要访问 Ollama，必须填 **Ollama 所在机器的 IP**（本机/局域网如 `http://192.168.1.20:11434`，云服务器填公网 IP）；本机/局域网需与手机同一网络，云服务器需放行 11434 端口，且 Ollama 已监听 `0.0.0.0`。
> 配置保存在本地 Preferences，重启不丢；`设置 → 模型配置 → 恢复默认` 可还原。

### 4.5 数据存储与云端切换

- **Mock 模式（默认）**：竞赛数据内置，收藏 / 规划 / 打卡 / 发帖 / 资料保存在本机 Preferences，重启不丢，但仅本机可见。
- **云端模式**：`CloudConfig.USE_MOCK = false` 并部署 AGC 后，个人资料、收藏、规划、打卡、组队帖、经验帖、点赞均经云函数写入 Cloud DB，**所有用户可见**。
- 清除数据：`我的 → 设置 → 清除本地数据`（会重置本地登录态与缓存，操作前请确认）。

### 4.6 提醒与打卡

- 提醒：`我的 → 智能提醒`，可为临近的竞赛节点批量发布系统日历提醒；应用退出后仍由系统按时触发。
- 打卡：进入任意规划详情，点击任务前的复选框即可切换完成状态，进度条与完成率实时更新。

---

## 五、输入 / 输出示例

### 5.1 示例一：AI 生成备赛规划（核心链路）

**输入**（对话中的选择，等价于 `PlanRequest`）：

| 字段 | 示例值 |
|---|---|
| `competitionId` | `mcm` |
| `competitionName` | 全国大学生数学建模竞赛 |
| `level` | 有一些基础 |
| `weeklyHours` | 8（即「每周 5–10 小时」） |
| `target` | 省级奖项 |

**输出**（保存后的计划对象，字段与真实返回一致；此处由本地模拟生成，真实大模型返回同结构）：

```json
{
  "id": "plan_1793059200000_4821",
  "competitionId": "mcm",
  "competitionName": "全国大学生数学建模竞赛",
  "target": "省级奖项",
  "level": "有一些基础",
  "weeklyHours": 8,
  "totalWeeks": 12,
  "summary": "针对「全国大学生数学建模竞赛」，以「省级奖项」为目标，每周投入约 8 小时，规划 12 周，节奏均衡，按部就班。",
  "phases": [
    {
      "name": "基础夯实",
      "weeks": "第1-4周",
      "goal": "补齐「全国大学生数学建模竞赛」所需的基础知识与必备技能",
      "tasks": [
        "第1周：通读官方往届赛题与评分标准，明确考察方向",
        "第2周：系统学习核心知识点，整理笔记与知识框架",
        "第3周：完成 1-2 套基础练习，定位薄弱环节",
        "第4周：复盘基础阶段，输出阶段性小结"
      ]
    },
    {
      "name": "专题突破",
      "weeks": "第5-8周",
      "goal": "针对薄弱点与高频考点做专题强化",
      "tasks": [
        "第5周：逐个击破薄弱专题，配合针对性练习",
        "第6周：开始做完整往届真题，严格计时",
        "第8周：总结高频题型与解题套路，形成自己的方法论"
      ]
    },
    {
      "name": "实战冲刺",
      "weeks": "第9-12周",
      "goal": "全真模拟 + 查漏补缺，调整到最佳状态",
      "tasks": [
        "第9周：全真模拟 2 次，完全按正式流程",
        "第11周：复盘模拟问题，针对性补漏",
        "第12周：调整心态、整理物资清单，轻松上阵"
      ]
    }
  ],
  "risks": [
    "临近截止节点前易焦虑，建议用倒计时提醒自我监督",
    "避免只学不练，每周至少安排一次实践/真题输出",
    "组队项目需尽早固定队友，避免临时换人"
  ],
  "status": "active",
  "createdAt": 1793059200000,
  "doneTasks": []
}
```

> 调整计划时，用户在对话里输入意见（如「第 5 周任务太重」），客户端会把意见作为 `feedback` 一并发给模型，重新返回完整 JSON 覆盖展示。

### 5.2 示例二：云函数 `plan-create`

客户端/云函数统一使用 `action` 分发。请求：

```json
{
  "action": "plan-create",
  "competitionId": "mcm",
  "competitionName": "全国大学生数学建模竞赛",
  "level": "有一些基础",
  "weeklyHours": 8,
  "target": "省级奖项"
}
```

成功响应（为便于阅读，`phases` 与 `risks` 仅保留部分）：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "6a1f2c3d4e5f60718293a4b5",
    "competitionId": "mcm",
    "competitionName": "全国大学生数学建模竞赛",
    "target": "省级奖项",
    "level": "有一些基础",
    "weeklyHours": 8,
    "totalWeeks": 12,
    "summary": "针对「全国大学生数学建模竞赛」，以「省级奖项」为目标，每周投入约 8 小时，规划 12 周。",
    "phases": [
      {
        "name": "基础夯实",
        "weeks": "第1-4周",
        "goal": "补齐基础知识与必备技能",
        "tasks": [
          "第1周：通读官方往届赛题与评分标准",
          "第2周：系统学习核心知识点"
        ]
      }
    ],
    "risks": ["临近截止前易焦虑，建议用倒计时提醒自我监督"],
    "status": "active",
    "createdAt": 1793059200000,
    "doneTasks": []
  }
}
```

失败响应示例（未配置模型 Key）：

```json
{
  "code": 3001,
  "message": "未配置 DEEPSEEK_API_KEY 环境变量",
  "data": null
}
```

### 5.3 示例三：收藏切换 `fav-toggle`

请求：

```json
{
  "action": "fav-toggle",
  "competitionId": "mcm"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "favorited": true
  }
}
```

> 所有云函数返回统一结构 `{ code, message, data }`，`code = 0` 表示成功；错误码见 [docs/02 第四节](docs/02-数据库与云服务设计.md)。

---

## 六、项目结构

```text
CompetitionAssistant/
├── app/                          # HarmonyOS 客户端工程（用 DevEco Studio 打开这里）
│   ├── AppScope/                 # 应用级配置（包名 / 版本 / 图标）
│   ├── entry/src/main/
│   │   ├── module.json5          # 模块配置、权限（网络、代理提醒）
│   │   ├── ets/
│   │   │   ├── pages/            # 页面：首页、详情、AI 对话、规划详情、广场、设置等
│   │   │   ├── view/             # Tab 视图：时间线、广场、AI 助手、我的
│   │   │   ├── service/          # CloudService / AiService / SocialService / UserService 等
│   │   │   ├── model/            # Competition / StudyPlan / ChatMessage / User 等数据模型
│   │   │   └── common/           # 常量、本地存储、内容过滤
│   │   └── resources/            # 字符串、颜色、图标、路由表
│   ├── build-profile.json5       # 构建配置（API 12 / HarmonyOS 5.0）
│   └── README.md                 # 客户端工程细节（目录、构建、接入说明）
├── cloudfunctions/               # AGC 云函数（Node.js）
│   ├── index.js                  # 统一入口：action 分发 + 数据接口
│   ├── ai.js                     # DeepSeek 调用封装 + 提示词
│   ├── seed.js                   # 竞赛种子数据生成脚本
│   └── README.md                 # 云函数部署指南
├── docs/                         # 需求、设计、AI Prompt、部署、合规文档
├── .gitignore                    # Git 忽略规则（构建产物 / IDE 状态）
├── LICENSE                       # MIT 开源许可证
└── README.md                     # 项目总览（本文档）
```

更细的工程目录与源码说明见 [app/README.md](app/README.md)。

---

## 七、技术栈

| 层 | 选型 |
|---|---|
| 客户端框架 | ArkTS + ArkUI，Stage 模型 |
| 状态与存储 | `@State` / `@StorageLink`，Preferences（`LocalStore`） |
| 网络 | `@ohos.net.http`，OpenAI 兼容的 `chat/completions` 接口 |
| 云服务 | AppGallery Connect：Cloud DB、Cloud Functions、Auth Service、Push Kit（可选） |
| AI | DeepSeek（`deepseek-chat`）/ Ollama（OpenAI 兼容端点）/ 本地模拟 |
| 构建 | DevEco Studio 6.0.2 + hvigor |
| 后端运行时 | Node.js（AGC 云函数） |

---

## 八、设计文档

| 文档 | 内容 |
|---|---|
| [docs/01-需求分析与功能清单.md](docs/01-需求分析与功能清单.md) | 背景痛点、用户画像、功能优先级（P0/P1/P2）、信息架构 |
| [docs/02-数据库与云服务设计.md](docs/02-数据库与云服务设计.md) | 集合表结构、云函数清单、API 约定、权限策略 |
| [docs/03-UI设计与交互规范.md](docs/03-UI设计与交互规范.md) | 视觉规范、页面布局、交互细节 |
| [docs/04-AI学习规划Prompt设计.md](docs/04-AI学习规划Prompt设计.md) | 规划状态机、系统提示词、JSON 契约、评测记录 |
| [docs/05-项目目录结构与开发建议.md](docs/05-项目目录结构与开发建议.md) | 交付清单、测试审查、路线图与技术债 |
| [docs/06-上架与后端部署指南.md](docs/06-上架与后端部署指南.md) | 上架流程、云函数与云数据库部署 |
| [docs/07-Ollama本地大模型部署指南.md](docs/07-Ollama本地大模型部署指南.md) | 本地大模型安装、配置与排错 |
| [docs/08-上架文案与合规文本.md](docs/08-上架文案与合规文本.md) | 应用市场文案、隐私政策、用户协议 |

---

## 九、常见问题（FAQ）

**Q1：用 DevEco Studio 打开仓库根目录报错？**
工程在 `app/` 子目录，请直接打开 `app/`。

**Q2：构建提示找不到 SDK / 版本不匹配？**
安装 HarmonyOS SDK API 12（5.0.0），并确认 `app/build-profile.json5` 中的 `compatibleSdkVersion` 为 `5.0.0(12)`；命令行构建时正确设置 `NODE_HOME` 与 `DEVECO_SDK_HOME`。

**Q3：HAP 构建成功但安装失败？**
`entry-default-unsigned.hap` 未签名，不能直接安装。请在 DevEco Studio 中配置自动签名后通过 Run 安装，或先签名再 `hdc install`。

**Q4：AI 一直返回模拟计划？**
`我的 → 设置 → 模型配置` 中「模拟模式」仍处于开启状态。关闭后填写正确的 Base URL、模型名与 API Key 并保存。

**Q5：Ollama 连接失败？**
模拟器/真机里的 `127.0.0.1` 是设备自身，需改成 Ollama 所在机器的 IP（本机/局域网填电脑 IP，云服务器填公网 IP）；同时确认 `OLLAMA_HOST=0.0.0.0`、11434 端口可访问、网络互通。

**Q6：收藏/规划重启后丢失？**
数据默认存于本机 Preferences，清除应用数据或「设置 → 清除本地数据」会重置；如需跨设备同步，请接入 AGC 云端模式。

**Q7：多人看不到彼此的数据？**
当前仍是 Mock 模式（`CloudConfig.USE_MOCK = true`），数据仅本机可见；按 3.4 部署云函数并切换为 `false` 后才会写入 Cloud DB。

**Q8：生产环境如何保护大模型 Key？**
当前客户端直连模型便于本地调试；正式上架建议迁移到云函数 `plan-create`，Key 只存放在云函数环境变量，客户端永不接触（云函数代码已提供）。

---

## 十、后续规划

- **V1.x**：真实华为账号登录、AGC 数据全量上云、推送提醒、组队申请与消息通知。
- **V2.0**：竞赛数据自动采集、获奖作品库、AI 模拟答辩/评审、院校定制与排行榜徽章体系。

详见 [docs/05-项目目录结构与开发建议.md](docs/05-项目目录结构与开发建议.md)。

---

## 十一、许可证

本项目采用 [MIT License](LICENSE) 开源，可自由使用、修改、分发与商用，只需保留版权声明与许可声明。

```
Copyright (c) 2026 CompetitionAssistant contributors
```
