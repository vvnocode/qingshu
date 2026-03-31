+++
date = '2026-03-15T10:20:00+08:00'
draft = false
title = 'OpenClaw 安装与部署'
tags = ['OpenClaw', 'AI', 'Agent', '部署']
+++

# OpenClaw 安装与部署

本篇覆盖安装、首次配置向导和国内模型快速接入。

---

## 1. 环境要求

### 平台支持

| 平台 | 支持情况 | 备注 |
|------|---------|------|
| macOS (Apple Silicon) | ✅ 完全支持 | 推荐平台 |
| macOS (Intel) | ✅ 完全支持 | |
| Linux (x86_64) | ✅ 完全支持 | Ubuntu 20.04+, CentOS 8+ |
| Linux (ARM64) | ✅ 完全支持 | 树莓派 4+ 等 |
| Windows (WSL2) | ✅ 支持 | 需先安装 WSL2 |
| Windows (原生) | ⚠️ 实验性 | 建议使用 WSL2 |

### 软件依赖

| 依赖项 | 最低版本 | 说明 |
|--------|---------|------|
| Node.js | Node 24（推荐）或 Node 22 LTS（22.16+） | **必须** |
| npm | >= 10 | 随 Node.js 一起安装 |
| Git | >= 2.0 | 源码编译时需要 |
| curl | 任意 | 一键脚本安装时需要 |

> 💡 **不确定有没有装 Node.js？** 终端输入 `node --version` 看看。如果提示"command not found"，先去 [nodejs.org](https://nodejs.org) 下载安装。

---

## 2. 安装方式

### 方式一：一键脚本安装（推荐新手）

最简单的方式，一行命令搞定：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**Windows (PowerShell)：**

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

脚本会自动完成：
- 检测系统环境
- 安装必要依赖
- 下载并安装 OpenClaw 最新版本
- 配置环境变量

安装完成后，终端会提示你运行 `openclaw onboard` 进入配置向导。

### 方式二：npm 全局安装（推荐）

如果你已经有 Node.js 环境，这种方式最直接：

```bash
npm install -g openclaw@latest
```

更新版本：

```bash
npm update -g openclaw
```

### 方式三：源码编译（开发者）

适合需要定制或参与开发的同事：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install
npm run build
npm link
```

### 方式四：Docker 部署

适合服务器长期运行或容器化环境：

```bash
# clone项目后执行
./docker-setup.sh
```

> Docker 部署适合生产环境，支持自动重启和持久化存储。详见 [OpenClaw 官方文档](https://docs.openclaw.ai/install/docker)。

---

## 3. 验证安装

安装完成后，运行以下命令确认一切正常：

```bash
openclaw --version
```

应输出类似 `OpenClaw 2026.3.13 (61d171a)` 的版本号。

运行完整的环境检测：

```bash
openclaw doctor
```

`openclaw doctor` 会检查：
- Node.js 版本是否满足要求
- 网络连通性
- 配置文件是否完整
- 已配置的模型是否可用

如果有问题，它会给出具体的修复建议。

---

## 4. 首次配置向导

运行配置向导：

```bash
openclaw onboard --install-daemon
```

> `--install-daemon` 参数会同时安装守护进程，让 OpenClaw 在后台持续运行（定时任务需要）。

向导会引导你完成以下步骤：

### 步骤 1：选择 Provider（模型提供商）

```
? 请选择 AI 模型提供商:
  ❯ 阿里云百炼（推荐国内用户）
    硅基流动（SiliconFlow）
    火山方舟（字节跳动）
    OpenAI
    Anthropic
    自定义 Provider
```

### 步骤 2：填写认证信息

根据所选 Provider 填入 API Key：

```
? 请输入 API Key: sk-xxxxxxxxxxxxxxxxxxxx
✓ API Key 验证通过！
```

### 步骤 3：选择 Gateway 模式

```
? 请选择 Gateway 模式:
  ❯ 本地模式（推荐，数据不出境）
    代理模式（通过公司统一代理）
    直连模式（直接连接 Provider API）
```

### 步骤 4：配置 IM 通道

```
? 请选择要接入的 IM 通道（可多选）:
  ❯ ◉ 终端 CLI（默认）
    ◯ 钉钉
    ◯ 飞书
    ◯ 微信
    ◯ Slack
    ◯ 暂不配置，稍后再说
```

完成后，向导会输出一份配置摘要，确认无误后自动生效。

---

## 5. 配置文件位置说明

OpenClaw 的所有配置文件都在 `~/.openclaw/` 目录下：

```
~/.openclaw/
├── openclaw.json           # 主配置文件（JSON5 格式）
├── agents/                 # 各 Agent 的状态目录
│   └── main/               # 默认 Agent
│       ├── agent/          # Agent 配置（auth-profiles.json、models.json 等）
│       └── sessions/       # 会话记录存储
├── workspace/              # 默认 Agent 的工作目录
│   ├── AGENTS.md           # Agent 行为指令
│   ├── MEMORY.md           # 长期记忆
│   ├── xxxxx.md            # 其他md文件
│   └── memory/             # 每日记忆
│   └── skills/             # 已安装的 Skill 包（当前agent生效）
├── skills/                 # 已安装的 Skill 包（全局共享）
├── extensions/             # 已安装的插件
├── logs/                   # 运行日志
├── cron/                   # 定时任务配置
└── .env                    # 环境变量（可选）
```

> 💡 **注意**：`memory/` 目录位于 `~/.openclaw/各Agent的**Workspace**/memory/` 下，用于存储每日记忆。详见 [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) 中的 Workspace 目录结构。

主配置文件 `openclaw.json` 可以手动编辑，也可以通过命令修改：

```bash
openclaw config set agents.defaults.model.primary "bailian/kimi-k2.5"
```

---

## 6. 国内模型快速配置

> 完整的模型配置说明、平台对比、费用优化策略请参见 [06-大模型配置与费用优化](./06-OpenClaw%20大模型配置与费用优化.md)。以下仅展示快速上手配置。

### 阿里云百炼（快速开始）

**获取 API Key**：登录 [百炼控制台](https://bailian.console.aliyun.com/) → API-KEY 管理 → 创建 Key

百炼作为统一网关，聚合了 Qwen 系列及第三方模型（kimi-k2.5、MiniMax-M2.5、glm 系列等）。官方模型配置文档：[百炼模型配置](https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023085)

在 `~/.openclaw/openclaw.json` 中添加：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "YOUR_API_KEY",
        "api": "openai-completions",
        "models": [
          {
            "id": "MiniMax-M2.5",
            "name": "MiniMax-M2.5",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 196608,
            "maxTokens": 32768
          },
          {
            "id": "glm-5",
            "name": "glm-5",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 202752,
            "maxTokens": 16384,
            "compat": {
              "thinkingFormat": "qwen"
            }
          },
          {
            "id": "kimi-k2.5",
            "name": "kimi-k2.5",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 262144,
            "maxTokens": 32768,
            "compat": {
              "thinkingFormat": "qwen"
            }
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "bailian/kimi-k2.5"
      },
      "models": {
        "bailian/MiniMax-M2.5": {},
        "bailian/glm-5": {},
        "bailian/kimi-k2.5": {}
      }
    }
  },
  "gateway": {
    "mode": "local"
  }
}
```

> 以上列出推荐的 3 个模型。百炼还支持 qwen3.5-plus、qwen3-coder-next、qwen3-coder-plus、glm-4.7 等，完整列表见[官方文档](https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023085)。百炼 Coding Plan 包月模式下 `cost` 均为 0。更多模型配置和费用优化策略请参见 [06-大模型配置与费用优化](./06-OpenClaw%20大模型配置与费用优化.md)。

---

## 7. 更新与维护

### 更新到最新版本

```bash
npm update -g openclaw
# 或者
openclaw update
```

### 重启守护进程

更新后建议重启守护进程以应用新版本：

```bash
openclaw gateway restart
```

---

## 8. 远程访问

如果 OpenClaw 部署在远程服务器上，需要配置安全的远程访问方式。

### 方式一：SSH 端口转发（推荐）

最简单安全的方式，无需暴露公网端口：

```bash
ssh -L 18789:127.0.0.1:18789 user@your-server
```

然后在本地浏览器访问 `http://127.0.0.1:18789/` 即可打开 Dashboard。

### 方式二：Tailscale（推荐团队使用）

[Tailscale](https://tailscale.com/) 提供零配置的 VPN 方案，适合团队多人访问：

1. 在服务器和本地机器上都安装 Tailscale
2. 两端都登录同一个 Tailscale 网络
3. 通过 Tailscale 分配的内网 IP 访问：`http://<tailscale-ip>:18789/`

### 方式三：反向代理 + HTTPS

适合正式生产环境部署：

```nginx
server {
    listen 443 ssl;
    server_name openclaw.your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

> ⚠️ **安全警告**：无论使用哪种方式，**绝不要直接将 Gateway 端口暴露在公网上**。务必启用 `gateway.auth.token` 认证。

---

## 9. 常见安装问题排查

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| `command not found: openclaw` | 环境变量未生效 | 重启终端，或运行 `source ~/.bashrc`（Linux）/ `source ~/.zshrc`（Mac） |
| `Error: Node.js version too old` | Node.js 版本不满足要求 | 升级 Node.js：`nvm install 24 && nvm use 24`（或 `nvm install 22 && nvm use 22`） |
| `EACCES: permission denied` | npm 全局安装权限不足 | 使用 `sudo npm install -g openclaw` 或配置 npm prefix |
| `connect ETIMEDOUT` | 网络连接超时 | 检查网络代理设置，或使用国内镜像源 |
| `API Key invalid` | API Key 填写错误或已过期 | 重新获取 API Key，运行 `openclaw config set provider.apiKey "新Key"` |
| `openclaw doctor` 报红 | 环境依赖不满足 | 按 `doctor` 输出的提示逐条修复 |
| 守护进程启动失败 | 端口被占用或权限不足 | 检查 `~/.openclaw/logs/error.log`，释放端口或调整权限 |
| npm 安装速度很慢 | 默认 npm registry 在国外 | 使用国内镜像：`npm config set registry https://registry.npmmirror.com` |

---

## 10. 运维注意事项

### 磁盘空间管理

OpenClaw 长期运行会积累大量 Session 日志（`.jsonl` 文件）和 Memory 文件。建议定期清理：

```bash
# 查看 sessions 目录占用
du -sh ~/.openclaw/agents/*/sessions/

# 清理超过 30 天的 session 文件
find ~/.openclaw/agents/*/sessions/ -name "*.jsonl" -mtime +30 -delete
```

Memory 文件（`memory/*.md`）通常体积较小，但建议每季度归档一次过旧的记录。

### 配置备份与恢复

`openclaw.json` 是系统核心配置。虽然 AGENTS.md 模板中的 Configuration Change Rules 规定了自动备份（保留最新 50 次到 `~/.openclaw/backups/`），仍建议额外做定期备份：

```bash
# 手动备份
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y%m%d)

# 恢复
cp ~/.openclaw/backups/openclaw.json.back.<timestamp> ~/.openclaw/openclaw.json
openclaw gateway restart
```

### Gateway 进程恢复

如果 Gateway 进程崩溃或被意外终止：

```bash
# 检查进程状态
openclaw gateway status

# 重启
openclaw gateway restart

# 查看错误日志定位原因
tail -100 ~/.openclaw/logs/error.log
```

生产环境建议使用 systemd 或 Docker 的 `restart: always` 策略确保进程自动恢复。

### 外部链接说明

本系列文档中引用的部分外部链接可能尚在建设中：

| 链接 | 状态 |
|------|------|
| `https://docs.openclaw.ai` | 官方文档（建设中） |
| `https://github.com/openclaw/openclaw` | GitHub 仓库（建设中） |
| `https://clawhub.ai` | Skill 仓库（建设中） |

如遇链接不可访问，请联系内部 AI 基础设施团队获取最新地址。

---

## 11. 延伸阅读

- [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) — 深入理解 Agent、Skill、Memory 的工作原理
- [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) — 把 OpenClaw 变成钉钉群里的 AI 助手
- [05-Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) — Memory 记忆系统详解
- [06-大模型配置与费用优化](./06-OpenClaw%20大模型配置与费用优化.md) — 各模型对比和费用估算
- [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) — 生产环境安全加固

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [01-入门指南：从零开始](./01-OpenClaw%20入门指南：从零开始.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) |
