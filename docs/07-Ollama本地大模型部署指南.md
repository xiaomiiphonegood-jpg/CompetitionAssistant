# Ollama 本地大模型部署指南（云服务器版）

> 目标：在你自己购买的云服务器上跑一个本地大模型，让「大学生竞赛助手」APP 直接调用它，不再依赖第三方 API、不再「自说自话」。

---

## 一、为什么要自建本地大模型

| 对比项 | 第三方 API（DeepSeek 等） | 自建本地大模型（Ollama） |
|---|---|---|
| 费用 | 按 token 计费 | 只付服务器月租，调用无限次 |
| 隐私 | 数据出域 | 数据不出你自己的服务器 |
| 稳定性 | 依赖对方服务 | 完全自主可控 |
| 门槛 | 低（填 Key 即可） | 中（需配一台服务器） |

APP 已同时支持两者：`设置 → 模型配置` 里可随时切换 DeepSeek / Ollama / 自定义。

---

## 二、服务器选购建议（够用即可）

跑 7B 量化模型（约 4~5GB 显存/内存）推荐：

| 配置 | 说明 | 约价格 |
|---|---|---|
| 2 核 4G | 能跑 7B 量化，速度一般 | ~60~100 元/月 |
| 4 核 8G | 7B 流畅，推荐 | ~120~200 元/月 |
| 8 核 16G | 可跑 14B 量化，效果更好 | ~250+ 元/月 |

> 系统选 **Ubuntu 22.04 / 24.04 LTS**，地区选国内（延迟低）。
> 可选：阿里云 / 腾讯云 / 华为云 / 雨云等均可，只要有公网 IP。

---

## 三、安装 Ollama（Linux 一行命令）

SSH 登录服务器后执行：

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

安装完成后验证：

```bash
ollama --version
```

---

## 四、拉取模型（推荐中文模型）

```bash
# 推荐：通义千问 7B，中文能力强、体积小
ollama pull qwen2.5:7b

# 备选：更大的 qwen2.5:14b（效果更好，需 8G+ 内存）
ollama pull qwen2.5:14b
```

查看已安装模型：

```bash
ollama list
```

---

## 五、让 Ollama 监听公网 + 开机自启

默认 Ollama 只监听 `127.0.0.1`，需要改成 `0.0.0.0` 才能让 APP 连上。

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama
```

---

## 六、开放防火墙 / 安全组端口

在云厂商控制台的**安全组**里，放行 TCP `11434` 端口（若仅自己用，建议限制为「仅你的 IP」白名单）。

若服务器自带 ufw 防火墙：

```bash
sudo ufw allow 11434/tcp
```

---

## 七、测试接口是否可用

在你本地电脑（或服务器上）执行：

```bash
curl http://服务器公网IP:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "你好"}],
    "stream": false
  }'
```

返回一段 JSON 且包含 `choices[0].message.content` 即成功。

---

## 八、在 APP 中接入

1. 打开 APP → `我的` → `设置` → `模型配置`
2. 服务商选 **Ollama(本地)**
3. 接口地址填：`http://服务器公网IP:11434`
4. 模型名称填：`qwen2.5:7b`
5. API Key 留空
6. **关闭「模拟模式」开关**
7. 点「保存配置」

回到「AI 助手」即可真实调用你自己的大模型生成备赛计划。

---

## 九、安全注意事项（重要）

1. **不要长期裸奔公网**：`11434` 端口无鉴权，任何人都能白嫖你的算力。建议：
   - 安全组只放行你自己的 IP；
   - 或用 Nginx 反向代理 + Basic Auth / API Key 做鉴权；
   - 或 APP 与服务器走内网/VPN。
2. **Key 安全**：APP 里的 DeepSeek Key 仅用于个人快速验证；正式上架请迁移到 AGC 云函数（Key 放云函数环境变量），见 `docs/06-上架与后端部署指南.md`。
3. 若服务器内存不足，模型加载慢或报 OOM，换更小模型（如 `qwen2.5:3b`）。

---

## 十、常见问题

| 现象 | 原因 | 解决 |
|---|---|---|
| APP 提示「大模型调用失败」 | 地址/端口/防火墙不通 | 用第七步 curl 自测 |
| 返回空 | 模型名写错 | `ollama list` 核对，填完整名如 `qwen2.5:7b` |
| 很慢 | 服务器配置低 | 换 3b 模型或升级内存 |
| 服务器连接被拒 | OLLAMA_HOST 没改 | 重做第五步并 restart |

---

## 附录：可选——用 Nginx 加一层鉴权（进阶）

```nginx
server {
    listen 11435;
    location / {
        auth_basic "restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:11434;
        proxy_read_timeout 300s;
    }
}
```

这样对外只开 `11435`（带账号密码），`11434` 只对本机开放，更安全。
