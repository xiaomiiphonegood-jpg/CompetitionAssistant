# 云函数部署指南（AGC Cloud Functions）

本目录是「大学生竞赛助手」的后端云函数，提供数据接口 + DeepSeek AI 代理。

## 目录结构

```
cloudfunctions/
├── index.js        # 统一入口（action 分发 + 数据接口 + AI 代理）
├── ai.js           # DeepSeek 调用封装 + 提示词
├── seed.js         # 竞赛种子数据生成脚本
├── package.json    # 依赖（@agconnect/cloud-server）
└── README.md
```

## 一、开通 AGC 云服务

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)，创建项目 + 应用
2. 开通 **Cloud Functions** 和 **Cloud DB**

## 二、创建云数据库集合

在 Cloud DB 控制台创建以下集合（字段见 `docs/02-数据库与云服务设计.md`）：

| 集合 | 说明 |
|---|---|
| competition | 竞赛主表 |
| competition_stage | 竞赛时间节点 |
| user_profile | 用户资料 |
| favorite | 收藏 |
| study_plan | 学习规划 |
| team_post | 组队帖 |
| share_post | 经验帖 |

## 三、导入种子数据

1. 本地运行 `node seed.js` 生成 `seed-data.json`
2. 在 Cloud DB 控制台将 `competition`、`competition_stage` 数据导入对应集合

## 四、部署云函数

1. 在 Cloud Functions 控制台创建函数，上传 `index.js` + `ai.js` + `package.json`
2. 配置环境变量：`DEEPSEEK_API_KEY = YOUR_DEEPSEEK_API_KEY`
3. 配置 HTTP 触发器，记下触发器地址

## 五、客户端接入

1. 客户端 `common/Constants.ets`：
   - `CloudConfig.USE_MOCK` 改为 `false`
   - `CloudConfig.CLOUD_FUNCTION_BASE` 填入云函数 HTTP 触发器地址
2. AI 调用改为走云函数 `plan-create`（`service/AiService.ets` 中 `USE_MOCK_AI=false` 时已指向云端）

> ⚠️ 安全要点：DeepSeek Key 只存在于云函数环境变量，客户端永不接触 Key。
