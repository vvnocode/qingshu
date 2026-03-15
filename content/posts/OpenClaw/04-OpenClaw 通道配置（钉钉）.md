+++
date = '2026-03-15T00:04:00+08:00'
draft = false
title = 'OpenClaw 通道配置（钉钉）'
tags = ['OpenClaw', '钉钉', 'IM']
+++

## 本章导读

> **这篇文档回答以下问题：**
>
> 1. 怎么让 OpenClaw 接入钉钉（@ 机器人或私聊即可对话）？
> 2. Markdown 和 AI 卡片两种消息模式如何选择和配置？
> 3. 私聊/群聊的安全策略怎么设？
>
> 本章假设你已完成 [02-安装与部署](./02-OpenClaw%20安装与部署.md) 和 [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) 的学习。

---

## 1. 钉钉插件安装

### 1.1 安装插件

```bash
openclaw plugins install @soimy/dingtalk
```

### 1.2 国内网络环境解决方案

如果安装过程中遇到网络问题（下载超时、连接失败），可以设置国内 NPM 镜像源：

```bash
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com openclaw plugins install @soimy/dingtalk
```

或者永久设置：

```bash
npm config set registry https://registry.npmmirror.com
openclaw plugins install @soimy/dingtalk
```

### 1.3 更新插件

```bash
openclaw plugins install @soimy/dingtalk@latest
```

更新后需重启 Gateway 使新版本生效：

```bash
openclaw gateway restart
```

> 💡 更新前建议查看 [插件 Changelog](https://github.com/soimy/openclaw-channel-dingtalk/releases) 确认是否有破坏性变更。

### 1.4 插件信任白名单

OpenClaw 出于安全考虑，默认不允许运行未经信任的插件。安装后需要将插件加入白名单：

在 `~/.openclaw/openclaw.json` 中添加：

```json
{
  "plugins": {
    "allow": ["dingtalk"]
  }
}
```

---

## 2. 钉钉开发者后台配置

### 2.1 创建企业内部应用

1. 打开 [钉钉开放平台](https://open-dev.dingtalk.com/)
2. 登录企业管理员账号
3. 进入 **应用开发 → 企业内部开发 → 创建应用**
4. 填写应用名称（如 "OpenClaw AI 助手"）和描述
5. 点击 **创建**

### 2.2 添加机器人能力

1. 在应用详情页，找到 **应用能力 → 机器人**
2. 点击 **添加机器人能力**
3. 填写机器人名称和头像

### 2.3 选择 Stream 模式

1. 在机器人配置页面，**消息接收模式** 选择 **Stream 模式**
2. Stream 模式不需要公网回调地址，适合内网部署

> 💡 **为什么选 Stream？** 传统 HTTP 回调模式需要公网可访问的 URL，而 Stream 模式由客户端主动连接钉钉服务器，无需暴露端口，更安全也更简单。

### 2.4 发布应用

1. 配置完成后，进入 **版本管理与发布**
2. 点击 **发布**
3. 等待企业管理员审批通过（如果你就是管理员，可以自行审批）

### 2.5 开通权限

在应用详情页的 **权限管理** 中，开通以下权限：

**必须权限：**

| 权限名称 | 权限码 | 说明 |
|---------|--------|------|
| 企业内机器人发送消息 | `qyapi_robot_sendmsg` | 机器人回复消息 |
| 创建和投放卡片实例 | `Card.Instance.Write` | Card 模式必须 |
| 对卡片进行流式更新 | `Card.Streaming.Write` | Card 模式流式输出 |
| 通讯录个人信息读权限 | `Contact.User.Read` | 读取用户基本信息 |
| 媒体文件上传相关权限 | — | 允许调用媒体上传接口 |

**可选权限（推荐开通）：**

| 权限名称 | 权限码 | 说明 |
|---------|--------|------|
| 个人手机号信息 | `Contact.User.mobile` | 识别用户身份 |
| 群会话管理 | `Chat.Manage` | 管理群聊信息 |
| 消息通知服务 | `Notify.Message` | 主动推送消息 |
| 文件上传 | `Storage.Write` | Agent 上传文件到钉钉 |
| 文件下载 | `Storage.Read` | Agent 下载钉钉文件 |

**群聊文件引用场景额外开通（可选）：**

| 权限名称 | 权限码 | 说明 |
|---------|--------|------|
| 群文件空间读权限 | `ConvFile.Space.Read` | 读取群文件 |
| 企业存储文件读权限 | `Storage.File.Read` | 读取企业存储文件 |
| 文件下载信息读权限 | `Storage.DownloadInfo.Read` | 获取文件下载链接 |

> 群文件 API 链路可能要求企业具备**企业认证**，未认证企业会返回 `orgAuthLevelNotEnough`。此限制不影响单聊文件和图片引用。

### 2.6 获取凭证

在应用详情页获取以下信息（后续配置需要用到）：

| 凭证 | 获取位置 | 说明 |
|------|---------|------|
| **Client ID** (AppKey) | 应用信息 → 凭证与基础信息 | 应用的唯一标识 |
| **Client Secret** (AppSecret) | 同上 | 应用密钥，**请妥善保管** |
| **Robot Code** | 机器人配置页 | 机器人的唯一编码 |
| **Corp ID** | 企业信息页 | 企业的唯一标识 |
| **Agent ID** | 应用信息页 | 钉钉内的 Agent ID（非 OpenClaw Agent ID） |

---

## 3. OpenClaw 侧配置

### 3.1 交互式配置（推荐）

运行以下命令，按提示输入钉钉凭证：

```bash
openclaw configure --section channels
```

系统会依次提示你输入 Channel 类型、Client ID、Client Secret 等信息。

### 3.2 手动配置

也可以直接编辑 `~/.openclaw/openclaw.json`，在 `channels` 对象中添加钉钉配置：

```json5
{
  "channels": {
    "dingtalk": {
      "enabled": true,
      "clientId": "dingxxxxxx",
      "clientSecret": "your-app-secret",
      "robotCode": "dingxxxxxx",
      "corpId": "dingxxxxxx",
      "agentId": "123456789",
      "messageType": "markdown",
      "dmPolicy": "open",
      "groupPolicy": "open",
      "allowFrom": []
    }
  }
}
```

各字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `enabled` | boolean | 是否启用该通道 |
| `clientId` | string | 钉钉应用的 Client ID (AppKey) |
| `clientSecret` | string | 钉钉应用的 Client Secret (AppSecret) |
| `robotCode` | string | 机器人编码（与 clientId 相同） |
| `corpId` | string | 企业 ID |
| `agentId` | string | 钉钉应用的 Agent ID（非 OpenClaw Agent ID） |
| `messageType` | string | 消息展示模式：`markdown` 或 `card` |
| `dmPolicy` | string | 私聊策略：`open` / `pairing` / `allowlist` |
| `groupPolicy` | string | 群聊策略：`open` / `allowlist` |
| `allowFrom` | string[] | 允许的发送者 ID 列表 |

---

## 4. Agent 绑定

在 `bindings` 中将钉钉渠道绑定到指定 Agent：

```json5
{
  "bindings": [
    {
      "agentId": "dingtalk-agent",
      "match": { "channel": "dingtalk" }
    },
    {
      "agentId": "denied",
      "match": { "channel": "*" }
    }
  ]
}
```

- 群聊中的 @ 机制通过 `channels.dingtalk.groups` 或 agent 级别的 `groupChat.mentionPatterns` 配置
- 私聊消息始终会响应

---

## 5. 消息类型选择

钉钉插件支持两种消息展示模式。

### 5.1 Markdown 模式（默认）

Agent 的回复以 Markdown 格式渲染，适合大多数场景。

### 5.2 Card 模式（AI 互动卡片）

Agent 的回复以钉钉 AI 互动卡片形式展示，支持**流式更新**——用户可以实时看到 Agent 的回复逐步生成，还可显示 AI 思考过程和工具执行结果。

**Card 模式额外配置：**

```json5
{
  "channels": {
    "dingtalk": {
      "messageType": "card",
      "cardTemplateId": "你的模板ID.schema",  // 在钉钉卡片平台创建
      "cardTemplateKey": "content"              // 模板内容字段名
    }
  }
}
```

**创建 AI 卡片模板：**

1. 访问 [钉钉卡片平台](https://card.dingtalk.com)
2. 进入「我的模板」→「创建模板」
3. 场景选择「AI 卡片」
4. 设计排版并保存发布
5. 复制模板 ID，填入 `cardTemplateId`

### 5.3 模式对比

| 维度 | Markdown 模式 | Card 模式 |
|------|-------------|-----------|
| 流式输出 | 不支持（一次性完整输出） | 支持（实时更新） |
| 视觉效果 | 标准 Markdown | 卡片式，更美观 |
| 图文混排 | 不支持 | 不支持（均需单独发送图片） |
| API 消耗 | 每条回复 2 次 | 1 + M 次（M=回复块数） |
| 配置复杂度 | 无额外配置 | 需创建卡片模板 |
| 适用场景 | 短回复、简单对话 | 长回复、复杂分析 |

### 5.4 Card 模式下的对话命令

Card 模式支持以下特殊命令：

| 命令 | 说明 |
|------|------|
| `/stop` | 停止当前流式输出 |
| `/retry` | 重新生成上一条回复 |
| `/clear` | 清除当前对话上下文 |
| `/reasoning stream` | 开启 AI 推理流显示 |
| `/reasoning off` | 关闭推理流 |
| `/verbose on` | 开启工具执行结果显示 |
| `/verbose off` | 关闭工具执行显示 |

> 推理流和工具执行显示会产生额外 API 调用，按需开启。

---

## 6. 安全策略

### 6.1 私聊策略 dmPolicy

| 策略 | 说明 |
|------|------|
| `open` | 任何企业成员都可以私聊机器人 |
| `pairing` | 用户需要先完成配对验证 |
| `allowlist` | 只有白名单内的用户可以私聊 |

### 6.2 群聊策略 groupPolicy

| 策略 | 说明 |
|------|------|
| `open` | 机器人被拉入任何群都会响应 |
| `allowlist` | 只在白名单群聊中响应 |

### 6.3 白名单配置示例

```json5
{
  "channels": {
    "dingtalk": {
      "dmPolicy": "allowlist",
      "groupPolicy": "allowlist",
      "allowFrom": ["senderId-1", "senderId-2"]
    }
  }
}
```

---

## 7. 反馈学习（进阶）

插件支持本地反馈学习闭环，将用户反馈沉淀为可审计的知识规则。

### 7.1 启用反馈学习

```json5
{
  "channels": {
    "dingtalk": {
      "learningEnabled": true,
      "learningAutoApply": false,  // 只采集不自动注入，手动审核
      "learningNoteTtlMs": 21600000  // 会话笔记有效期 6 小时
    }
  }
}
```

### 7.2 常用学习命令

| 命令 | 说明 |
|------|------|
| `/learn whoami` 或 `我是谁` | 查看自己的 senderId |
| `/learn whereami` 或 `这里是谁` | 查看当前 conversationId |
| `/learn global <规则>` | 注入全局规则（所有会话生效） |
| `/learn here #@# <规则>` | 注入当前群/私聊规则 |
| `/learn target <cid> #@# <规则>` | 注入指定目标规则 |
| `/learn list` | 查看已有规则 |
| `/learn disable <ruleId>` | 暂停规则 |
| `/learn delete <ruleId>` | 删除规则 |

**示例：**

```
/learn global 当用户问"紫铜海豹会不会修量子冰箱"时，必须回答"会，而且只在周四凌晨戴墨镜维修。"
/learn here #@# 引用原文不可见时，不要猜内容，先让用户补发原文。
```

> 使用学习命令前，需先将自己的 `senderId` 写入 `commands.ownerAllowFrom`。

---

## 8. 会话共享（session-alias）

插件支持将不同的私聊或群聊绑定到同一条会话记忆，实现跨会话共享上下文。

| 命令 | 说明 |
|------|------|
| `/session-alias show` | 查看当前会话 alias |
| `/session-alias set <alias>` | 将当前会话绑定到共享 alias |
| `/session-alias clear` | 清除当前会话 alias，恢复默认 |
| `/session-alias bind direct <senderId> <alias>` | 远程绑定某用户私聊 |
| `/session-alias bind group <conversationId> <alias>` | 远程绑定某群 |
| `/session-alias unbind direct <senderId>` | 远程解除私聊绑定 |
| `/session-alias unbind group <conversationId>` | 远程解除群绑定 |

> 会话共享命令仅允许 owner 使用（`allowFrom` 命中的 senderId）。

---

## 9. 支持的消息类型

### 接收（用户发送给 Agent）

| 类型 | 支持 | 说明 |
|------|------|------|
| 文本 | ✅ | 完整支持 |
| 图片 | ✅ | 下载并传递给 AI |
| 语音 | ✅ | 使用钉钉语音识别结果 |
| 视频 | ✅ | 下载并传递给 AI |
| 文件 | ✅ | 下载并传递给 AI |
| 钉钉文档/钉盘文件卡片 | ✅ | 解析并按文件处理 |
| 引用文字/图片/图文 | ✅ | 恢复引用内容 |
| 引用文件/视频/语音 | ✅ | 单聊精确恢复，群聊兜底恢复 |
| 引用 AI 卡片 | ✅ | 按 carrierId 精确恢复 |

### 发送（Agent 回复给用户）

| 类型 | 支持 | 说明 |
|------|------|------|
| 文本 / Markdown | ✅ | 自动检测格式 |
| AI 互动卡片 | ✅ | 流式更新 |
| 图片/语音/视频/文件 | ✅ | 先上传媒体再发送，支持本地路径和 URL |

> 当前**不支持图文混排**。图片需通过 `sendMedia` 单独发送。

---

## 10. 其他通道简要说明

除了钉钉，OpenClaw 还支持以下通道：

### 飞书

- 可通过 **KimiClaw**、**飞书妙搭** 一键部署，也可自建飞书机器人
- 自建方式类似钉钉：创建飞书应用 → 开通机器人能力 → 获取凭证 → 配置 Channel
- 飞书集成详细指南待后续补充

### QQ

- 通过 **QQ 开放平台** 创建机器人
- 获取 Bot AppID 和 Token
- 配置 Channel 类型为 `qq`

### Telegram

Telegram 是海外用户最常用的通道之一，以下是完整配置流程。

**第 1 步：创建 Bot**

1. 在 Telegram 中搜索 **@BotFather**
2. 发送 `/newbot`
3. 按提示设置 Bot 名称和用户名
4. 获取 **Bot Token**（格式如 `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`）

**第 2 步：配置 OpenClaw**

在 `~/.openclaw/openclaw.json` 中添加：

```json
{
  "env": {
    "TELEGRAM_BOT_TOKEN": "your-bot-token-here"
  },
  "channels": {
    "telegram": {}
  },
  "plugins": {
    "entries": {
      "telegram": { "enabled": true }
    }
  }
}
```

**第 3 步：启动服务**

```bash
openclaw doctor --fix && openclaw gateway restart
```

**第 4 步：配对流程**

Telegram 通道默认需要配对验证：

1. 用户在 Telegram 向 Bot 发送任意消息
2. Bot 返回配对码
3. 管理员执行配对审批：

```bash
# 查看待配对列表
openclaw pairing list --channel telegram
# 批准配对（--notify 会通知用户）
openclaw pairing approve --channel telegram <配对码> --notify
```

**第 5 步：验证**

```bash
openclaw channels status
```

**第 6 步：查看已配对设备**

```bash
openclaw devices list
```

**配对策略说明**

| 策略 | 说明 |
|------|------|
| 默认（需配对） | 用户发消息后需管理员审批配对码 |
| 白名单 `allowFrom` | 预设允许的 Telegram 用户 ID，无需配对 |
| 开放模式 | 任何用户均可直接对话，无需配对（仅建议测试环境使用） |

### Discord

- 在 [Discord Developer Portal](https://discord.com/developers/applications) 创建 Bot
- 获取 Bot Token
- 通过 Bot Token 配置 Channel

### 企业微信

- 可通过 **WorkBuddy** 等方案接入
- 或使用企业微信开放 API 自建集成

### Mobile Nodes（移动端节点）

> ⚠️没有上架 APP Store，需要自己打包

- [安卓](https://docs.openclaw.ai/platforms/android)
- [iOS](https://docs.openclaw.ai/platforms/ios)

---

## 11. 连接鲁棒性配置

当网络不稳定时，可以调整重连参数以提高连接可靠性：

```json5
{
  "channels": {
    "dingtalk": {
      "maxConnectionAttempts": 10,       // 最大重连次数
      "initialReconnectDelay": 1000,     // 初始重连延迟（ms）
      "maxReconnectDelay": 60000,        // 最大重连延迟（ms）
      "reconnectJitter": 0.3            // 延迟抖动因子
    }
  }
}
```

重连延迟公式：`delay = min(initialDelay × 2^attempt, maxDelay) × (1 ± jitter)`

---

## 12. 多 Agent 多机器人绑定（进阶）

当需要将一个 OpenClaw 实例接入多个钉钉机器人、并把不同机器人的消息分别交给不同 Agent 处理时，使用 `channels.dingtalk.accounts` 多账户配置 + `bindings` 路由规则。

核心思路：在 `channels.dingtalk.accounts` 中为每个机器人定义独立的 `accountId`，然后在 `bindings` 中通过 `match.accountId` 将不同机器人的消息路由到对应的 Agent。

**accounts 配置示例**：

```json5
{
  "channels": {
    "dingtalk": {
      "accounts": {
        "bot_1": {
          "clientId": "dingxxxxxx_bot1",
          "clientSecret": "your-bot1-app-secret",
          "robotCode": "dingxxxxxx_bot1",
          "corpId": "dingxxxxxx",
          "agentId": "111111111"
        },
        "bot_2": {
          "clientId": "dingxxxxxx_bot2",
          "clientSecret": "your-bot2-app-secret",
          "robotCode": "dingxxxxxx_bot2",
          "corpId": "dingxxxxxx",
          "agentId": "222222222"
        }
      }
    }
  }
}
```

**bindings 路由配置**：

```json5
{
  "bindings": [
    { "agentId": "main", "match": { "channel": "dingtalk", "accountId": "bot_1" } },
    { "agentId": "growth-agent", "match": { "channel": "dingtalk", "accountId": "bot_2" } }
  ]
}
```

> **注意**：`bindings[].match.accountId` 必须与 `channels.dingtalk.accounts` 下的 key 完全一致。每个 Agent 建议使用独立的 `workspace`。
>
> 完整的多 Agent 架构设计（包括 `agents.list` 定义、Workspace 隔离、权限配置等）请参见 [11-Multi-Agent：多智能体协作](./11-OpenClaw%20Multi-Agent：多智能体协作.md)。

---

## 13. 故障排查

| 问题 | 可能原因 | 解决方法 |
|------|---------|---------|
| 插件安装失败 | 网络问题 | 设置 NPM 镜像源后重试 |
| 机器人无响应 | Gateway 未启动 | 运行 `openclaw gateway start` |
| 机器人无响应 | 插件未加入白名单 | 检查 `plugins.allow` 配置 |
| 机器人无响应 | Bindings 未配置 | 检查 bindings 中是否有匹配的路由规则 |
| 群聊不响应 | `requireMention` 为 true | 在群聊中 @ 机器人后发送消息 |
| 提示权限不足 | 钉钉权限未开通 | 在钉钉开放平台补充开通权限 |
| 消息发送失败 | Client Secret 错误 | 重新获取并更新凭证 |
| Stream 连接断开 | 网络不稳定 | 检查网络连接，OpenClaw 会自动重连 |

---

## 14. 配置选项速查

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| enabled | boolean | true | 是否启用 |
| clientId | string | 必填 | AppKey |
| clientSecret | string | 必填 | AppSecret |
| robotCode | string | - | 机器人代码 |
| corpId | string | - | 企业 ID |
| agentId | string | - | 应用 ID |
| dmPolicy | string | "open" | 私聊策略 |
| groupPolicy | string | "open" | 群聊策略 |
| allowFrom | string[] | [] | 允许的发送者 ID |
| messageType | string | "markdown" | markdown / card |
| showThinking | boolean | true | 显示"思考中" |
| cardTemplateId | string | - | AI 卡片模板 ID |
| cardTemplateKey | string | "content" | 卡片内容字段键 |
| debug | boolean | false | 调试日志 |
| mediaMaxMb | number | 5 | 接收文件大小上限（MB） |
| learningEnabled | boolean | false | 启用反馈学习 |
| bypassProxyForSend | boolean | false | 仅对发送链路绕过 HTTP(S) 代理 |
| aicardDegradeMs | number | 1800000 | AI 卡片连续失败后降级持续时间（毫秒） |
| thinkingMessage | string | "🤔 思考中..." | 自定义"思考中"提示文案（设为 `"emoji"` 启用随机颜文字） |
| maxConnectionAttempts | number | 10 | 最大连接尝试次数 |
| journalTTLDays | number | 7 | 引用回溯日志保留天数 |
| mediaUrlAllowlist | string[] | [] | 允许通过 mediaUrl 下载的主机白名单 |

---

## 15. 延伸阅读

- [03-OpenClaw 核心概念与配置](./03-OpenClaw%20核心概念与配置.md) —— 回顾核心概念
- [05-OpenClaw Memory：让 AI 越用越聪明](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) —— 让 Agent 记住对话上下文
- [钉钉开放平台文档](https://open.dingtalk.com/document/)
- [OpenClaw 官方文档](https://docs.openclaw.ai)
- 有问题？联系内部 AI 基础设施团队或在钉钉群内提问

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [05-Memory：让 AI 越用越聪明](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) |
