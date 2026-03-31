+++
date = '2026-03-15T10:40:00+08:00'
draft = false
title = 'OpenClaw 通道配置（钉钉）'
tags = ['OpenClaw', 'AI', 'Agent', '钉钉']
+++

# OpenClaw 通道配置（钉钉）

本篇介绍如何将 OpenClaw 接入钉钉，包括插件安装、消息模式选择、安全策略配置。阅读前建议先完成 [02-安装与部署](./02-OpenClaw%20安装与部署.md) 和 [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md)。

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

如果插件已处于半安装状态（扩展目录存在但依赖未装全），可进入插件目录手动补装：

```bash
cd ~/.openclaw/extensions/dingtalk
rm -rf node_modules package-lock.json
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com npm install
```

或者永久设置镜像源：

```bash
npm config set registry https://registry.npmmirror.com
```

### 1.3 更新插件

```bash
openclaw plugins update dingtalk
```

国内网络环境可临时指定镜像源后再更新：

```bash
NPM_CONFIG_REGISTRY=https://registry.npmmirror.com openclaw plugins update dingtalk
```

更新后需重启 Gateway 使新版本生效：

```bash
openclaw gateway restart
```

> 💡 更新前建议查看 [插件 Changelog](https://github.com/soimy/openclaw-channel-dingtalk/releases) 确认是否有破坏性变更。

### 1.4 插件信任白名单

OpenClaw 出于安全考虑，默认不允许运行未经信任的插件。安装后需要将插件加入白名单：

在 `~/.openclaw/openclaw.json` 中添加：

```json5
{
  "plugins": {
    "enabled": true,
    "allow": ["dingtalk"]
  }
}
```

如果还有其他已安装且需启用的插件，请一并加入：

```json5
{
  "plugins": {
    "allow": ["dingtalk", "telegram", "voice-call"]
  }
}
```

添加后重启 Gateway：

```bash
openclaw gateway restart
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
4. 版本详情中确认可见范围为"全员员工"

### 2.5 开通权限

在应用详情页的 **权限管理** 中，开通以下权限：

**必须权限：**

| 权限名称 | 权限码 | 说明 |
|------|--------|------|
| 创建和投放卡片实例 | `Card.Instance.Write` | Card 模式必须 |
| 对卡片进行流式更新 | `Card.Streaming.Write` | Card 模式流式输出 |
| 机器人消息发送相关权限 | — | 允许机器人向单聊/群聊发送消息 |
| 媒体文件上传相关权限 | — | 允许调用媒体上传接口发送图片、语音、视频、文件 |

> 💡 机器人消息发送和媒体上传的具体权限名称请在钉钉开放平台的权限管理页面搜索，以实际显示为准。

**群聊文件引用场景额外开通（可选）：**

| 权限名称 | 权限码 | 说明 |
|---------|--------|------|
| 群文件空间读权限 | `ConvFile.Space.Read` | 读取群文件 |
| 企业存储文件读权限 | `Storage.File.Read` | 读取企业存储文件 |
| 文件下载信息读权限 | `Storage.DownloadInfo.Read` | 获取文件下载链接 |
| 通讯录个人信息读权限 | `Contact.User.Read` | senderStaffId → unionId 转换 |

> ⚠️ 群文件/钉盘 API 链路除了权限开通外，还可能要求当前企业具备**企业认证**；未认证企业会返回 `orgAuthLevelNotEnough`。此限制不影响单聊文件和图片引用。

### 2.6 获取凭证

在应用详情页获取以下信息（后续配置需要用到）：

| 凭证 | 获取位置 | 说明 |
|------|---------|------|
| **Client ID** (AppKey) | 应用信息 → 凭证与基础信息 | 应用的唯一标识 |
| **Client Secret** (AppSecret) | 同上 | 应用密钥，**请妥善保管** |
| **Robot Code** | 机器人配置页 | 机器人的唯一编码（与 Client ID 相同） |
| **Corp ID** | 企业信息页 | 企业的唯一标识 |
| **Agent ID** | 应用信息页 | 钉钉内的 Agent ID（非 OpenClaw Agent ID） |

---

## 3. OpenClaw 侧配置

### 3.1 交互式配置（推荐）

```bash
# 方式 A：使用 config 命令
openclaw config

# 方式 B：直接配置 channels 部分
openclaw configure --section channels
```

交互式配置流程：

1. **选择插件** — 在插件列表中选择 `dingtalk` 或 `DingTalk (钉钉)`
2. **Client ID** — 输入钉钉应用的 AppKey
3. **Client Secret** — 输入钉钉应用的 AppSecret
4. **完整配置** — 可选配置 Robot Code、Corp ID、Agent ID（推荐）
5. **卡片模式** — 可选启用 AI 互动卡片模式（如启用，需输入 Card Template ID 和 Key）
6. **私聊策略** — 选择 `open`（开放）或 `allowlist`（白名单）
7. **群聊策略** — 选择 `open`（开放）或 `allowlist`（白名单）

配置完成后会自动保存并重启 Gateway。

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
      "dmPolicy": "open",
      "groupPolicy": "open",
      "journalTTLDays": 7,
      "ackReaction": "🤔思考中",    // 给原消息贴处理中的表情反馈；设为 "" 可关闭
      "debug": false,
      "messageType": "markdown",    // 或 "card"
      // "mediaMaxMb": 20,          // 可选：接收文件大小上限（MB），默认 5 MB
      // "aicardDegradeMs": 1800000, // 可选：AI 卡片失败后降级持续时间（毫秒，默认 30 分钟）
      // "cardRealTimeStream": false, // 可选：开启真流式卡片更新（默认 false，开启后 API 调用量增加约 2-3 倍）
      // 仅 card 模式需要配置
      "cardTemplateId": "你复制的模板ID",
      "cardTemplateKey": "你模板的内容变量"
    }
  }
}
```

手动配置后需重启 Gateway：

```bash
openclaw gateway restart
```

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

- 群聊中用户 @ 机器人后，消息会被钉钉自动转发给插件处理；是否响应由 `groupPolicy` 配置控制
- 私聊消息始终会响应（受 `dmPolicy` 策略约束）

---

## 5. 消息类型选择

钉钉插件支持两种消息展示模式，通过 `messageType` 配置。

### 5.1 Markdown 模式（默认）

- 支持富文本格式（标题、粗体、列表等）
- 自动检测消息是否包含 Markdown 语法
- Markdown 表格会自动转换为钉钉更稳定的可读文本
- 适用于大多数场景

### 5.2 Card 模式（AI 互动卡片）

Agent 的回复以钉钉 AI 互动卡片形式展示，支持**流式更新**——回复内容逐步推送到卡片，并可显示推理过程和工具执行结果。

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

1. 访问 [钉钉卡片平台](https://open-dev.dingtalk.com/fe/card)
2. 进入「我的模板」→「创建模板」
3. 场景选择「AI 卡片」
4. 设计排版并保存发布
5. 记下模板中定义的内容字段名称
6. 复制模板 ID（格式如 `xxxxx-xxxxx-xxxxx.schema`），填入 `cardTemplateId`

> 使用 DingTalk 官方 AI 卡片模板时，`cardTemplateKey` 默认为 `'content'`，无需修改。

**AI Card API 特性：**

当配置 `messageType: 'card'` 时：

1. 使用 `/v1.0/card/instances/createAndDeliver` 创建并投放卡片
2. 使用 `/v1.0/card/streaming` 实现流式更新
3. 自动状态管理（PROCESSING → INPUTING → FINISHED）
4. 内置 300ms 节流 + 单航班（single-flight）保护，避免 API 过载

**卡片流式模式（`cardRealTimeStream`）：**

插件支持两种卡片更新策略：

| 值 | 模式 | 说明 |
| -- | ---- | ---- |
| `false`（默认） | Block 缓冲 | runtime 攒够一定量文本后回调一次，API 调用最少，但首 token 延迟较高（~1-1.5s），更新较卡顿 |
| `true` | 真流式 | 每 300ms 最多一次卡片更新 PUT，首 token 延迟低（~300ms），打字机效果流畅。API 调用量约为 block 模式的 2-3 倍 |

> **API 调用量参考**：以一次 10 秒的 AI 回复为例，真流式约产生 ~30 次 `streamAICard` PUT，block 模式约 ~10-15 次。钉钉企业内部应用的 QPS 限制为 40 次/秒，真流式的峰值约 3.3 次/秒，远低于限制。

**AI Card 持久化与恢复机制：**

- 仅对**会话内流式卡片（inbound）**记录 pending 状态，用于进程重启后的自动收尾
- pending 状态通过 persistence namespace `cards.active.pending` 落盘
- **proactive 卡片**采用 createAndDeliver 后立即 finalize 的短路径，默认不写入 pending 状态文件
- 插件启动时会尝试恢复并 finalize 未完成的 inbound 卡片；停止/重启时会 best-effort finalize 当前 active 卡片

### 5.3 模式对比

| 维度 | Markdown 模式 | Card 模式 |
|------|-------------|-----------|
| 流式输出 | 不支持（一次性完整输出） | 支持（实时更新） |
| 视觉效果 | 标准 Markdown | 卡片式，更美观 |
| 图文混排 | 不支持 | 不支持（均需单独发送图片） |
| API 消耗 | 每条回复 2 次（Token + 发送） | 1 + M 次（M 取决于流式模式） |
| 配置复杂度 | 无额外配置 | 需创建卡片模板 |
| 适用场景 | 短回复、简单对话 | 长回复、复杂分析 |

### 5.4 AI 思考过程与工具执行显示（Card 模式）

当 `messageType` 为 `card` 时，插件可以在卡片中实时展示 AI 的推理过程和工具调用结果。这两项功能通过**对话级命令**控制，无需修改配置文件：

| 功能 | 对话命令 | 说明 |
|------|---------|------|
| 显示 AI 推理流 | `/reasoning stream` | 开启后，AI 思考内容实时更新到卡片 |
| 显示工具执行结果 | `/verbose on` | 开启后，工具调用结果实时更新到卡片 |
| 关闭 AI 推理流 | `/reasoning off` | 关闭推理流显示 |
| 关闭工具执行显示 | `/verbose off` | 关闭工具执行结果显示 |

**显示格式：**

- 思考内容以 `🤔 **思考中**` 为标题，正文以 `>` 引用块展示，最多显示前 500 个字符
- 工具结果以 `🛠️ **工具执行**` 为标题，正文以 `>` 引用块展示，最多显示前 500 个字符

> 推理流和工具执行均会产生额外的卡片流式更新 API 调用，在 AI 推理步骤较多时可能显著增加 API 消耗，建议按需开启。

---

## 6. 思考中反馈配置（ackReaction）

插件支持在处理消息时给用户原消息添加一条钉钉原生表情反馈，处理结束后自动撤回。该反馈作用于用户原消息，不会额外发送一条"思考中"消息。

**配置值说明：**

| 配置值 | 效果 |
|--------|------|
| `"🤔思考中"` | 与钉钉原生"思考中"反馈一致 |
| `"emoji"` | 按当前输入语气自动选择一条颜文字 reaction |
| `""` | 关闭 ack reaction |
| 其他任意文本 | 按该文本原样发送对应的 ack reaction |

**配置示例：**

```json5
{
  "channels": {
    "dingtalk": {
      "ackReaction": "emoji"
    }
  }
}
```

**解析顺序：**

`channels.dingtalk.accounts.<accountId>.ackReaction` → `channels.dingtalk.ackReaction` → `messages.ackReaction` → `agents.list[].identity.emoji`

若上述路径都未配置，则不发送 ack reaction。

> `markdown` 和 `card` 模式都可启用。贴表情或撤表情失败时只记录日志，不会阻断主流程。

---

## 7. 安全策略

### 7.1 私聊策略 dmPolicy

| 策略 | 说明 |
|------|------|
| `open` | 任何企业成员都可以私聊机器人 |
| `pairing` | 用户需要先完成配对验证 |
| `allowlist` | 只有白名单内的用户可以私聊 |

### 7.2 群聊策略 groupPolicy

| 策略 | 说明 |
|------|------|
| `open` | 机器人被拉入任何群都会响应 |
| `allowlist` | 只在白名单群聊中响应 |

### 7.3 白名单配置示例

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

> `allowFrom` 同时复用为 owner 判定来源。`/learn ...` 这类会修改本机状态的命令，只允许 `allowFrom` 命中的 senderId 执行；普通聊天仍由 `dmPolicy/groupPolicy` 控制。

---

> **进阶功能** 以下内容适合熟悉基础配置后阅读，初次使用可跳过。

## 8. 反馈学习（进阶）

插件支持一个本地反馈学习闭环，目标是把"点踩/纠错/后续抱怨"沉淀成可审计的会话笔记和 account 级共享规则，而不是直接修改模型或把原始聊天提交到仓库。

### 8.1 设计分层

- **发送快照**：保存最近的问答对，供反馈回溯
- **显式反馈**：AI 卡片上的 `feedback_up` / `feedback_down`
- **隐式不满**：例如"不是这个意思""别猜引用原文""你没看图"等后续纠错消息
- **会话笔记**：只作用于当前 target，会在下一条消息组装上下文时生效
- **全局规则**：按 account 维度共享；一处沉淀后，同一钉钉账号下的其他会话会在下一次收到消息时自动加载
- **默认策略**：只采集，不自动注入。你可以在看板中手动批准注入

### 8.2 启用反馈学习

```json5
{
  "channels": {
    "dingtalk": {
      "learningEnabled": true,
      "learningAutoApply": false,     // 只采集不自动注入，手动审核
      "learningNoteTtlMs": 21600000   // 会话笔记有效期 6 小时
    }
  }
}
```

- `learningAutoApply` 默认关闭。关闭时只采集 `event/reflection`，不会自动影响任何会话；由你在调试看板里手动决定是否注入当前会话或提升为全局规则
- `learningNoteTtlMs` 控制会话级学习笔记有效期；target 级和全局规则会继续持久化

### 8.3 持久化位置

所有运行时数据都写在 `storePath` 同级目录下的 `dingtalk-state/`，不会散落到其他目录，也不应提交到 GitHub。主要命名空间包括：

- `feedback.events`
- `feedback.snapshots`
- `feedback.reflections`
- `feedback.session-notes`
- `feedback.learned-rules`
- `feedback.target-rules`

### 8.4 调试看板

仓库自带一个本地调试工具，可直接查看当时的回复内容、用户反馈信号、系统反思结果、当前会话笔记和全局规则，并支持手工修正诊断与指令后选择注入当前会话、提升为全局规则、或只保留为候选反思。

```bash
node scripts/feedback-learning-debug.mjs --storePath /path/to/session-store.json --accountId main --port 18895
```

打开 `http://127.0.0.1:18895` 即可。

### 8.5 学习命令与作用域

先说两个容易输错的点：

- 文档里的 `<conversationId>`、`<规则>`、`<名称>` 这类写法只是**占位符**，实际输入时**不要**把尖括号一起发出去
- `/learn target`、`/learn targets`、`/learn target-set` 这几类命令里，`#@#` 是**真的要输入**的分隔符；它前面是目标，后面整段都算规则正文

#### 第一次使用流程

1. 私聊机器人发送 `我是谁` 或 `/whoami`
2. 把返回的 `senderId` 写进本机 `openclaw.json` 的 `commands.ownerAllowFrom`
3. 重启或热重载 gateway
4. 私聊发送 `/learn owner status`，确认 `isOwner: true`
5. 再选择下面一种注入方式：
   - 全局：`/learn global ...`
   - 当前群/当前私聊：`/learn here #@# ...`
   - 单个指定目标：`/learn target ...`
   - 多个目标：`/learn targets ...`

#### 常用命令

- **查自己是谁**
  - 私聊或群聊发：`我是谁` / `我的信息` / `/learn whoami`
  - 用途：拿到自己的 `senderId`
- **查当前这里是谁**
  - 私聊或群聊发：`这里是谁` / `这个群是谁` / `这个会话是谁` / `/learn whereami`
  - 用途：拿到当前 `conversationId`
- **注入当前这里**
  - owner 发：`/learn here #@# <规则>`
  - 用途：只让当前群或当前私聊生效
- **注入指定单个目标**
  - owner 发：`/learn target <conversationId> #@# <规则>`
  - 用途：指定某个群或某个私聊生效
- **一次注入多个目标**
  - owner 发：`/learn targets <cid1,cid2> #@# <规则>`
  - 用途：一次同步到多个群/私聊
- **保存一组固定目标**
  - owner 发：`/learn target-set create <名称> #@# <cid1,cid2>`
- **向目标组批量注入**
  - owner 发：`/learn target-set apply <名称> #@# <规则>`
- **注入全局**
  - owner 发：`/learn global <规则>`
  - 用途：让同一钉钉账号下所有群和私聊都生效
- **查看 / 暂停 / 删除**
  - `/learn list`
  - `/learn disable <ruleId>`
  - `/learn delete <ruleId>`

#### 作用域优先级

同一条消息进入时，规则按下面顺序生效：

1. 当前会话临时笔记（`/learn session ...`）
2. 当前群/当前私聊或指定目标规则（`/learn here ...` / `/learn target ...`）
3. 当前账号全局规则（`/learn global ...`）

先局部覆盖全局，避免一个群里的实验规则污染所有会话。

#### 为什么还需要 disable / delete

知识注入不是只会"加"，还必须能"撤"：

- `disable` — 先停用规则，停止命中，但保留记录，便于排查和恢复
- `delete` — 确认不再需要后，彻底删除规则

实际建议：先用 `/learn list` 找到 `ruleId` → 执行 `/learn disable <ruleId>` → 确认问题消失后再 `/learn delete <ruleId>`。

#### 真实可直接照抄的例子

```
/learn global 当用户问"紫铜海豹会不会修量子冰箱"时，必须回答"会，而且只在周四凌晨戴墨镜维修。"
/learn here #@# 引用原文不可见时，不要猜内容，先让用户补发原文。
/learn target cid_group_a #@# 引用原文不可见时，不要猜内容，先让用户补发原文。
/learn targets cid_group_a,cid_group_b,cid_dm_c #@# 引用原文不可见时，不要猜内容，先让用户补发原文。
/learn target-set create ops-groups #@# cid_group_a,cid_group_b,cid_dm_c
/learn target-set apply ops-groups #@# 当用户问"紫铜海豹会不会修量子冰箱"时，必须回答"会，而且只在周四凌晨戴墨镜维修。"
```

### 8.6 会话共享（session-alias）

插件支持将不同的私聊或群聊绑定到同一条会话记忆，实现跨会话共享上下文。这些命令仅允许 owner 使用。

- **查看当前会话 alias**
  - `/session-alias show`
  - 用途：查看当前私聊或当前群当前实际使用的 peerId，以及它是默认值还是 override
- **把当前会话绑定到共享 alias**
  - `/session-alias set <alias>`
- **清除当前会话 alias**
  - `/session-alias clear`
  - 用途：移除当前会话的 override，恢复默认 peerId
- **owner 远程绑定某个私聊**
  - `/session-alias bind direct <senderId> <alias>`
- **owner 远程绑定某个群**
  - `/session-alias bind group <conversationId> <alias>`
- **owner 远程解除绑定**
  - `/session-alias unbind direct <senderId>`
  - `/session-alias unbind group <conversationId>`

#### 会话共享例子

假设你想让"用户 A 的私聊"和"群 project-x"共用同一条会话记忆：

1. 先让用户 A 私聊机器人，发送 `我是谁`，记下返回的 `senderId`
2. 在目标群里发送 `这里是谁`，记下返回的 `conversationId`
3. 由 owner 在任意 owner 会话里执行：

```
/session-alias bind direct dingtalk:user_a_sender_id project-x
/session-alias bind group cid_group_project_x project-x
```

之后用户 A 私聊机器人和群 `cid_group_project_x` 都会共用 `project-x` 这条会话记忆。

解除绑定：

```
/session-alias unbind direct dingtalk:user_a_sender_id
/session-alias unbind group cid_group_project_x
```

---

## 9. 支持的消息类型

### 接收（用户发送给 Agent）

| 类型 | 支持 | 说明 |
|------|------|------|
| 文本 | ✅ | 完整支持 |
| 富文本 | ✅ | 提取文本内容 |
| 图片 | ✅ | 下载并传递给 AI |
| 语音 | ✅ | 使用钉钉语音识别结果 |
| 视频 | ✅ | 下载并传递给 AI |
| 文件 | ✅ | 下载并传递给 AI；文本类附件会额外抽取正文并注入上下文 |
| 钉钉文档/钉盘文件卡片 | ✅ | 解析 `interactiveCard` 中的 `biz_custom_action_url`，提取 `spaceId/fileId` 后按文件消息下载；可对 `PDF/DOCX` 补充正文抽取 |
| 引用文字 | ✅ | 提取被引用文本作为上下文前缀 |
| 引用图片 | ✅ | 使用引用回调自带的 `downloadCode` 下载并传递给 AI |
| 引用图文 | ✅ | 解析 `richText` 引用内容，提取文本摘要与图片 `downloadCode` |
| 引用文件/视频/语音 | ✅ | 单聊按 `msgId` 精确恢复；群聊优先查已固化元数据，首次未命中时走群文件 API 兜底（兜底链路依赖时间窗口匹配，不保证 100% 命中） |
| 引用钉钉文档/钉盘文件卡片 | ⚠️ | 单聊支持；群聊支持缓存命中与群文件 API 兜底恢复，但仍受钉钉回调样本与企业认证限制 |
| 引用 AI 卡片 | ✅ | 仅指机器人自己发送的 AI 卡片；按 `carrierId ↔ originalProcessQueryKey` 精确恢复 |

> **附件正文抽取说明**
>
> - 仅处理 **2MB 以下**附件（超过上限会跳过正文抽取）
> - 抽取结果最多注入 **6000 字符**（超出部分会标记为"内容已截断"）
> - 抽取失败仅记录 `warn` 日志，不阻断原有媒体传递与回复链路

### 发送（Agent 回复给用户）

| 类型 | 支持 | 说明 |
|------|------|------|
| 文本 / Markdown | ✅ | 自动检测格式 |
| AI 互动卡片 | ✅ | 流式更新 |
| 图片 | ✅ | 先上传媒体再发送，支持本地路径和 HTTP(S) URL |
| 语音 | ✅ | 先上传媒体再发送 |
| 视频 | ✅ | 先上传媒体再发送 |
| 文件 | ✅ | 先上传媒体再发送 |
| 原生语音消息 | ✅ | `message send` / `outbound.sendMedia` 可用 `asVoice=true`；需同时提供 `media/path/filePath/mediaUrl` 指向音频文件，纯文本不会自动转语音 |

> **重要限制：** 当前**不支持图文混排**。Markdown 消息和 AI 互动卡片目前都只能发送文本内容，不能在同一条消息中内嵌图片。图片需通过 `outbound.sendMedia(...)` 或 `sendProactiveMedia(...)` 单独发送。无论**本地路径**还是**远程 HTTP(S) URL**，都支持单独发送。

> 发送 Markdown 时，如果内容中包含标准 Markdown 表格，插件会先把分隔行转换掉，保留为钉钉更稳定的纯文本表格展示。

> 远程 URL 下载默认限制为：**10 秒超时**、**20MB 上限**，并拒绝 `localhost` / 内网地址（如 `127.0.0.1`、`10.x.x.x`、`192.168.x.x`、`172.16-31.x.x`）以降低 SSRF 风险。如需从受控内网媒体服务下载，请配置 `mediaUrlAllowlist`。

#### mediaUrlAllowlist 配置示例

`mediaUrlAllowlist` 支持以下写法：主机名（`cdn.example.com`）、泛域名（`*.example.com`）、主机+端口（`files.internal:8443`）、单个 IP（`192.168.1.23`）、CIDR 网段（`10.0.0.0/8`）。

```json5
{
  "channels": {
    "dingtalk": {
      "mediaUrlAllowlist": [
        "cdn.example.com",
        "*.assets.example.com",
        "192.168.1.23",
        "10.0.0.0/8"
      ]
    }
  }
}
```

> 配置 `mediaUrlAllowlist` 后，下载阶段进入严格白名单模式，非白名单目标一律拒绝。

#### sendMedia 常见错误码

| 错误码 | 说明 |
|--------|------|
| `ERR_MEDIA_ALLOWLIST_MISS` | 目标 host 不在 `mediaUrlAllowlist` |
| `ERR_MEDIA_PRIVATE_HOST` | URL 本身是本地/内网 host 且未被允许 |
| `ERR_MEDIA_DNS_UNRESOLVED` | 域名无法解析 |
| `ERR_MEDIA_DNS_PRIVATE` | 域名解析结果命中本地/内网地址且未被允许 |
| `ERR_MEDIA_REDIRECT_HOST` | 下载阶段出现非预期重定向 host |

---

## 10. API 消耗说明

### Text/Markdown 模式

| 操作 | API 调用次数 | 说明 |
|------|-------------|------|
| 获取 Token | 1 | 共享/缓存（60 秒检查过期一次） |
| 发送消息 | 1 | 使用 `/v1.0/robot/oToMessages/batchSend` 或 `/v1.0/robot/groupMessages/send` |
| **总计** | **2** | 每条回复 |

### Card（AI 互动卡片）模式

| 阶段 | API 调用 | 说明 |
|------|---------|------|
| 创建卡片 | 1 | `POST /v1.0/card/instances/createAndDeliver` |
| 流式更新 | M | M = 取决于流式模式，每次 `PUT /v1.0/card/streaming` |
| 完成卡片 | 包含在最后一次流更新中 | 使用 `isFinalize=true` 标记 |
| **总计** | **1 + M** | |

### 典型场景成本对比

以一次 10 秒的 AI 回复为例：

| 流式模式 | `streamAICard` 调用数 | 首 token 延迟 | 流畅度 |
|---------|----------------------|--------------|--------|
| Block 缓冲（`cardRealTimeStream: false`，默认） | ~10-15 次 | ~1-1.5s | 卡顿 |
| 真流式（`cardRealTimeStream: true`） | ~30 次 | ~300ms | 流畅 |

### 优化策略

- **保持默认** — `cardRealTimeStream: false`（block 缓冲模式），API 调用量最少，适合对 API 配额敏感的场景
- **开启真流式** — `cardRealTimeStream: true`，首 token 快、打字机效果流畅，适合重视用户体验的场景
- **Token 缓存** — Token 自动缓存（60 秒），无需每次都获取
- 频繁调用需要监测配额，建议使用钉钉开发者后台查看 API 调用量

---

## 11. 钉钉文档 API

插件额外注册了 4 个 gateway methods，可供 OpenClaw 侧直接调用：

| 方法 | 说明 |
|------|------|
| `dingtalk.docs.create` | 创建文档。支持可选 `parentId`，未传时默认在 space 根目录创建 |
| `dingtalk.docs.append` | 追加内容到文档末尾（使用钉钉 block API 的 `index = -1` 语义） |
| `dingtalk.docs.search` | 搜索文档 |
| `dingtalk.docs.list` | 列举文档 |

**调用示例：**

```json
{
  "method": "dingtalk.docs.create",
  "params": {
    "accountId": "default",
    "spaceId": "your-space-id",
    "parentId": "optional-parent-dentry-id",
    "title": "测试文档",
    "content": "第一段内容"
  }
}
```

> `dingtalk.docs.create` 在文档创建成功但首段追加失败时，仍会返回成功响应，并额外带 `partialSuccess=true`、`initContentAppended=false`、`docId` 和 `appendError`。调用方处理返回值时，不能只看 `ok=true`；还应继续检查 `partialSuccess`，并在该分支里决定是否提示人工补写或走后续补偿逻辑。

---

## 12. 其他通道简要说明

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

Telegram 是海外用户最常用的通道之一：

1. 通过 **@BotFather** 创建 Bot 并获取 **Bot Token**
2. 在 `openclaw.json` 中配置 `channels.telegram` 和 `TELEGRAM_BOT_TOKEN` 环境变量
3. 运行 `openclaw gateway restart` 启动服务
4. 默认需配对验证：用户发消息 → Bot 返回配对码 → 管理员通过 `openclaw pairing approve` 审批

> 💡 配对策略支持三种模式：默认配对、白名单（`allowFrom`）、开放模式（仅建议测试环境）。

### Discord

- 在 [Discord Developer Portal](https://discord.com/developers/applications) 创建 Bot
- 获取 Bot Token
- 通过 Bot Token 配置 Channel

### 企业微信

- 可通过 **WorkBuddy** 等方案接入
- 或使用企业微信开放 API 自建集成

### Mobile Nodes（移动端节点）

> ⚠️ 没有上架 APP Store，需要自己打包

- [安卓](https://docs.openclaw.ai/platforms/android)
- [iOS](https://docs.openclaw.ai/platforms/ios)

---

## 13. 连接鲁棒性配置

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

示例延迟序列（默认配置）：~1s, ~2s, ~4s, ~8s, ~16s, ~32s, ~60s（达到上限）

各参数说明：

- **maxConnectionAttempts**：连接失败后的最大重试次数，超过后将停止尝试并报警
- **initialReconnectDelay**：第一次重连的初始延迟，后续重连会按指数增长
- **maxReconnectDelay**：重连延迟的上限，防止等待时间过长
- **reconnectJitter**：在延迟基础上增加随机变化（±30%），避免多个客户端同时重连
- **bypassProxyForSend**：仅作用于发送链路（session send / proactive send / AI card / media upload），不影响 `getAccessToken` 之类的其他出站请求

---

> **进阶功能** 以下内容适合熟悉基础配置后阅读，初次使用可跳过。

## 14. 多 Agent 多机器人绑定（进阶）

当需要将一个 OpenClaw 实例接入多个钉钉机器人、并把不同机器人的消息分别交给不同 Agent 处理时，需要在 `~/.openclaw/openclaw.json` 中同时配置以下三部分：

1. `agents.list`：定义 OpenClaw Agent
2. `bindings`：定义 Channel 与 OpenClaw Agent 消息的路由规则
3. `channels.dingtalk.accounts`：定义多个机器人

**完整配置示例**（bot_1 → main agent，bot_2 → growth-agent）：

```json5
{
  "agents": {
    "list": [
      {
        "id": "main"
      },
      {
        // OpenClaw agent 的唯一 ID，bindings[].agentId 需要引用这里的值
        "id": "growth-agent",
        "name": "growth-agent",
        // 每个 agent 建议使用独立 workspace
        "workspace": "/Users/yourname/.openclaw/agents/growth-agent/workspace",
        "agentDir": "/Users/yourname/.openclaw/agents/growth-agent/agent",
        "model": "codex/gpt-5.3-codex"
      }
    ]
  },
  "bindings": [
    {
      "type": "route",
      "agentId": "main",
      "match": {
        "channel": "dingtalk",
        // 必须与 channels.dingtalk.accounts 下的 key 完全一致
        "accountId": "bot_1"
      }
    },
    {
      "type": "route",
      "agentId": "growth-agent",
      "match": {
        "channel": "dingtalk",
        "accountId": "bot_2"
      }
    }
  ],
  "channels": {
    "dingtalk": {
      "enabled": true,
      "accounts": {
        "bot_1": {
          "clientId": "your-client-id-1",
          "clientSecret": "your-client-secret-1",
          "robotCode": "your-robot-code-1",
          "corpId": "your-corp-id",
          "agentId": "your-dingtalk-agent-id-1",   // 钉钉应用的 Agent ID，非 OpenClaw agentId
          "dmPolicy": "open",
          "groupPolicy": "open",
          "messageType": "card",
          "cardTemplateId": "your-card-template-id.schema",
          "cardTemplateKey": "content",
          "maxReconnectCycles": 10,
          "allowFrom": ["*"]
        },
        "bot_2": {
          "clientId": "your-client-id-2",
          "clientSecret": "your-client-secret-2",
          "robotCode": "your-robot-code-2",
          "corpId": "your-corp-id",
          "agentId": "your-dingtalk-agent-id-2",
          "dmPolicy": "open",
          "groupPolicy": "open",
          "messageType": "markdown",
          "allowFrom": ["*"]
        }
      }
    }
  }
}
```

### 最佳实践

为每个 agent 配置不同的 `workspace`，不要让两个 agent 共用同一个 `workspace`。多 Agent 场景下，`workspace` 不只是"放文件的目录"，还会承载会话相关文件、生成结果以及本地运行状态。共用会导致状态串扰、文件覆盖、上下文混用。

### 检查清单

- `agents.list` 中已经定义了目标 agent
- `bindings[].agentId` 能在 `agents.list[].id` 中找到对应项
- `bindings[].match.accountId` 与 `channels.dingtalk.accounts` 的 key 完全一致
- 每个 `accounts.<accountId>` 都填写了正确的钉钉凭证
- 每个 agent 都使用了独立的 `workspace`
- 修改配置后已执行 `openclaw gateway restart`

> 如果账号名写错，例如 `bindings.match.accountId = "bot2"`，但 `channels.dingtalk.accounts` 中实际写的是 `bot_2`，则该机器人消息不会按预期路由到目标 agent。
>
> 完整的多 Agent 架构设计（包括 `agents.list` 定义、Workspace 隔离、权限配置等）请参见 [11-Multi-Agent：多智能体协作](./11-OpenClaw%20Multi-Agent：多智能体协作.md)。

---

## 15. 故障排查

### 常见问题

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

### 连接失败排障

初始化阶段如果只看到 HTTP `400`，它通常不等于"单纯网络不通"；更常见的是钉钉已收到请求，但拒绝了请求内容或当前应用状态不满足要求。

建议先运行仓库内的最小连接检查脚本，确认 `POST /v1.0/gateway/connections/open` 是否成功：

- macOS / Linux：`bash scripts/dingtalk-connection-check.sh --config ~/.openclaw/openclaw.json`
- Windows PowerShell：`pwsh -File scripts/dingtalk-connection-check.ps1 -Config ~/.openclaw/openclaw.json`

**关键设置清单（钉钉后台）：**

- 应用为企业内部应用/机器人，且已"发布"版本（不是草稿）
- 版本管理 → 已发布 → 版本详情：可见范围需为"全员员工"
- 已开启"机器人能力"，消息接收方式为"Stream 模式"

### 错误 payload 日志规范

为便于快速定位 4xx/5xx 参数问题，插件会在 API 错误分支输出统一格式日志：

- 通用前缀：`[DingTalk][ErrorPayload][<scope>]`
- AI Card 前缀：`[DingTalk][AICard][ErrorPayload][<scope>]`
- 内容格式：`code=<...> message=<...> payload=<...>`

常见 scope 示例：`send.proactiveMessage` / `send.proactiveMedia` / `send.message` / `outbound.sendText` / `outbound.sendMedia` / `inbound.downloadMedia` / `inbound.cardFinalize` / `card.create` / `card.stream` / `card.stream.retryAfterRefresh` / `retry.beforeDecision`

排查建议：

```bash
openclaw logs | grep "\[ErrorPayload\]"
```

如果你看到 `code=invalidParameter`，通常优先检查请求 payload 的必填字段（例如 `robotCode`、`userIds`、`msgKey`、`msgParam`）是否完整且格式正确。

---

## 16. 配置选项速查

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enabled` | boolean | `true` | 是否启用 |
| `clientId` | string | 必填 | 应用的 AppKey |
| `clientSecret` | string | 必填 | 应用的 AppSecret |
| `robotCode` | string | - | 机器人代码（用于下载媒体和发送卡片） |
| `corpId` | string | - | 企业 ID |
| `agentId` | string | - | 应用 ID |
| `dmPolicy` | string | `"open"` | 私聊策略：open/pairing/allowlist |
| `groupPolicy` | string | `"open"` | 群聊策略：open/allowlist |
| `allowFrom` | string[] | `[]` | 允许的发送者 ID 列表 |
| `bypassProxyForSend` | boolean | `false` | 发送链路直连，不走全局代理 |
| `learningEnabled` | boolean | `false` | 开启学习信号采集与学习提示注入 |
| `learningAutoApply` | boolean | `false` | 自动将学习笔记注入当前会话 |
| `learningNoteTtlMs` | number | `21600000` | 会话级学习笔记有效期（毫秒） |
| `mediaUrlAllowlist` | string[] | `[]` | 允许通过 `mediaUrl` 下载的主机/IP/CIDR 白名单 |
| `journalTTLDays` | number | `7` | `originalMsgId` 文本回溯日志保留天数 |
| `ackReaction` | string | - | 原生思考中表情反馈；设为 `""` 可关闭；设为 `"emoji"` 按语气自动选表情 |
| `messageType` | string | `"markdown"` | 消息类型：markdown/card |
| `cardTemplateId` | string | - | AI 互动卡片模板 ID（仅 card 模式） |
| `cardTemplateKey` | string | `"content"` | 卡片模板内容字段键（仅 card 模式） |
| `cardRealTimeStream` | boolean | `false` | 开启真流式卡片更新（300ms 节流，首 token 快但 API 调用更多） |
| `aicardDegradeMs` | number | `1800000` | AI 卡片连续失败后降级持续时间（毫秒） |
| `debug` | boolean | `false` | 是否开启调试日志 |
| `mediaMaxMb` | number | - | 接收文件大小上限（MB），不设则使用 runtime 默认值（5 MB） |
| `maxConnectionAttempts` | number | `10` | 最大连接尝试次数 |
| `initialReconnectDelay` | number | `1000` | 初始重连延迟（毫秒） |
| `maxReconnectDelay` | number | `60000` | 最大重连延迟（毫秒） |
| `reconnectJitter` | number | `0.3` | 重连延迟抖动因子（0-1） |

---

## 17. 延伸阅读

- [03-OpenClaw 核心概念与配置](./03-OpenClaw%20核心概念与配置.md) —— 回顾核心概念
- [05-OpenClaw Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) —— 让 Agent 记住对话上下文
- [钉钉开放平台文档](https://open.dingtalk.com/document/)
- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [钉钉插件 GitHub](https://github.com/soimy/openclaw-channel-dingtalk) —— 源码、Issue 讨论和 Release Notes

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [05-Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) |
