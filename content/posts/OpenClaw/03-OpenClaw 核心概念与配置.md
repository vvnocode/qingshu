+++
date = '2026-03-15T00:03:00+08:00'
draft = false
title = 'OpenClaw 核心概念与配置'
tags = ['OpenClaw', '配置', 'Agent']
+++

## 本章导读

> **这篇文档回答以下问题：**
>
> 1. 配置文件长什么样？各个字段分别控制什么？
> 2. Agent 有哪几种类型？Workspace 里的文件分别干什么？
> 3. 消息是怎么路由到正确 Agent 的？权限和浏览器怎么配？

---

## 1. 配置文件体系

OpenClaw 的所有全局配置集中在一个文件中：

```
~/.openclaw/openclaw.json
```

它的核心结构如下：

```json
{
  "env": { ... },
  "gateway": { ... },
  "agents": {
    "defaults": { ... },
    "list": [ ... ]
  },
  "bindings": [ ... ],
  "channels": { ... },
  "models": { ... },
  "plugins": { ... },
  "browser": { ... },
  "skills": { ... }
}
```

各字段的作用一览：

| 字段 | 作用 | 说明 |
|------|------|------|
| `env` | 环境变量 | 注入全局环境变量，如 API Key |
| `gateway` | 网关配置 | 控制 OpenClaw 的 HTTP 网关端口、认证等 |
| `agents` | Agent 定义 | `agents.list` 声明所有 Agent；`agents.defaults` 设置全局默认值 |
| `bindings` | 路由绑定 | 将渠道消息路由到指定 Agent |
| `channels` | 渠道配置 | 钉钉、飞书、Telegram 等通道的连接参数 |
| `models` | 模型配置 | 配置可用的 LLM 模型（API 地址、Key、参数） |
| `plugins` | 插件管理 | 已安装插件及信任白名单 |
| `browser` | 浏览器配置 | 控制 Agent 能否使用浏览器及其运行模式 |
| `skills` | Skill 配置 | Skill 包的安装路径和加载规则 |

> 💡 **提示**：你可以用 `openclaw configure` 交互式编辑配置，也可以直接手动编辑该 JSON 文件。

---

## 2. Agent 概念与类型

### 2.1 Agent 的组成

一个 Agent 是 OpenClaw 中最核心的实体。你可以把它理解为一个**有名字、有工作空间、有工具权限的 AI 助手**。

一个 Agent 的典型配置：

```json
{
  "id": "main",
  "name": "Main Agent",
  "workspace": "~/.openclaw/workspace",
  "agentDir": "~/.openclaw/agents/main/agent",
  "model": "anthropic/claude-sonnet-4-5",
  "tools": {
    "allow": ["read", "write", "edit", "exec", "web_search", "memory_search"],
    "deny": []
  }
}
```

各字段含义：

| 字段 | 说明 |
|------|------|
| `id` | Agent 的唯一标识符，在 bindings 中引用 |
| `name` | Agent 的显示名称 |
| `workspace` | Agent 的工作目录，存放 AGENTS.md、Memory 等文件 |
| `agentDir` | Agent 配置目录（相对于 `~/.openclaw/`） |
| `model` | 使用的 LLM 模型 ID |
| `tools` | 工具权限配置（允许/拒绝的工具列表） |

### 2.2 四种 Agent 类型

OpenClaw 中有四种不同角色的 Agent：

| 类型 | 英文名 | 说明 | 典型用途 |
|------|--------|------|---------|
| 主 Agent | Main Agent | 系统默认 Agent，ID 为 `main` | 处理所有未特别绑定的消息，是"总管" |
| 配置 Agent | Configured Agent | 在 `agents` 数组中声明的 Agent | 专门处理某个渠道/场景的消息，如"钉钉专属 Agent" |
| 子会话 Agent | Sub-Agent Session | 由 Main Agent 在运行时动态创建 | 处理需要隔离上下文的子任务 |
| 拒绝 Agent | Denied Agent | 特殊 Agent，拒绝一切请求 | 用于 bindings 兜底，阻止未授权的消息 |

### 2.3 Multi-Agent vs Configured Agent

这两个概念经常混淆，区分如下：

- **Multi-Agent** 是一种**架构模式**——指多个 Agent 协作完成任务的工作方式
- **Configured Agent** 是一个**具体实体**——在 `openclaw.json` 的 `agents` 数组中声明的某个 Agent

打个比方：Multi-Agent 就像"团队协作"这个概念，而 Configured Agent 就是团队里的某个具体成员。你可以只有一个 Agent（单兵作战），也可以配置多个 Agent 实现 Multi-Agent 协作。

---

## 3. Workspace 目录结构

每个 Agent 都有自己的 Workspace（工作目录），这是 Agent 的"大本营"。Workspace 的实际路径由 `openclaw.json` 中的 `workspace` 字段决定（Main Agent 默认为 `~/.openclaw/workspace`，其他 Agent 在 `agents.list` 中各自指定）。以下是一个典型的 Workspace 目录树：

```
<workspace>/
├── AGENTS.md          # Agent 行为指令（核心配置文件）
├── SOUL.md            # Agent 人格/角色定义
├── USER.md            # 用户信息描述
├── IDENTITY.md        # Agent 身份声明
├── TOOLS.md           # 自定义工具声明
├── HEARTBEAT.md       # 心跳事件处理指令
├── BOOT.md            # 启动时执行的指令
├── MEMORY.md          # 长期记忆（每次会话自动注入）
├── memory/            # 每日记忆目录
│   ├── 2026-03-10.md
│   ├── 2026-03-11.md
│   └── ...
├── outputs/           # Agent 生成的输出文件
│   ├── reports/
│   └── ...
└── skills/            # 本地 Skill 包
    └── ...
```

各文件的作用和加载时机：

| 文件 | 作用 | 加载时机 |
|------|------|---------|
| `AGENTS.md` | 定义 Agent 的行为规则、工作流程、限制条件 | **每次会话开始时**自动注入 System Prompt |
| `SOUL.md` | 定义 Agent 的人格特质、沟通风格 | 每次会话开始时注入 |
| `USER.md` | 描述用户的角色、偏好等信息 | 每次会话开始时注入 |
| `IDENTITY.md` | 声明 Agent 的身份信息（名字、职责） | 每次会话开始时注入 |
| `TOOLS.md` | 声明 Agent 可使用的自定义工具 | 每次会话开始时注入 |
| `HEARTBEAT.md` | 定义收到 Heartbeat 事件时的处理逻辑 | 收到 Heartbeat 事件时 |
| `BOOT.md` | 定义 Agent 启动后立即执行的任务 | Agent 进程启动时 |
| `MEMORY.md` | 长期记忆，存储核心偏好和关键决策 | **每次会话开始时**自动注入 |
| `memory/*.md` | 每日记忆，按日期存储工作记录 | 通过 `memory_search` 工具**按需检索** |
| `outputs/` | 存放 Agent 生成的报告、文件等 | 不自动加载，按需读取 |
| `skills/` | 存放本地 Skill 包 | 按 Skill 配置加载 |

> ⚠️ **重要**：`AGENTS.md` **只对当前 Workspace 的 Agent 生效**。如果你有多个 Agent，每个 Agent 的 Workspace 里要各自维护自己的 `AGENTS.md`。

### 不在 Workspace 中的文件

以下文件位于 `~/.openclaw/` 全局配置目录下，不属于任何特定 Workspace：

| 路径 | 说明 |
|------|------|
| `~/.openclaw/openclaw.json` | 全局配置文件 |
| `~/.openclaw/credentials/` | 存储认证信息（auth-profiles.json 等） |
| `~/.openclaw/agents/` | 各 Agent 的状态目录（agentDir、sessions 等） |
| `~/.openclaw/agents/<agentId>/sessions/` | 会话记录存储（按 Agent 隔离） |

---

## 4. Bindings 路由机制

Bindings 决定了**来自某个渠道的消息，应该由哪个 Agent 处理**。

### 4.1 路由规则要点

> [官方文档：路由匹配规则](https://docs.openclaw.ai/concepts/multi-agent#routing-rules-how-messages-pick-an-agent)

1. **最具体优先**使用确定性匹配，更具体的规则优先级更高。
2. **首个命中生效**——一旦匹配成功，后续规则不再检查
3. **建议兜底**——最后一条规则用 Denied Agent 兜底，防止未预期的消息进入系统

### 4.2 配置示例

```json5
{
  "bindings": [
    {
      "agentId": "main",
      "match": {
        "channel": "telegram",
        "peer": {"kind": "group", "id": "-52688366"
        }
      }
    },
    {
      "agentId": "sm",
      "match": {
        "channel": "telegram",
        "peer": {"kind": "direct", "id": "123456"
        }
      }
    },
    {
      "agentId": "denied",
      "match": { "channel": "*" }
    }
  ]
}
```

### 4.3 群聊配置

如果你希望 Agent 在群聊中**只响应 @ 它的消息**（而不是群里所有消息），需要在**渠道配置**和**Agent 配置**中分别设置，而非在 bindings 中配置：

```json5
{
  "agents": {
    "list": [
      {
        "id": "dingtalk-agent",
        "groupChat": {
          "mentionPatterns": ["@openclaw", "@AI助手"]
        }
      }
    ]
  },
  "channels": {
    "dingtalk": {
      "groups": { "*": { "requireMention": true } }
    }
  }
}
```

- `channels.dingtalk.groups.*.requireMention`：在渠道级别声明"群聊消息必须 @ 才响应"
- `agents.list[].groupChat.mentionPatterns`：在 Agent 级别定义识别哪些 @ 关键词

---

## 5. 权限体系

### 5.1 tools.allow / tools.deny

每个 Agent 都可以精细控制其工具权限：

```json
{
  "tools": {
    "allow": ["read", "write", "edit", "web_search", "memory_search"],
    "deny": ["exec", "sessions_spawn"]
  }
}
```

- `allow`：允许使用的工具列表
- `deny`：禁止使用的工具列表
- 如果两个列表都配置了，`deny` 优先级更高

### 5.2 常用工具列表

| 工具名 | 说明 |
|--------|------|
| `read` | 读取文件内容 |
| `write` | 写入/创建文件 |
| `edit` | 编辑已有文件 |
| `exec` | 执行终端命令（⚠️ 高权限） |
| `gateway` | 调用 OpenClaw Gateway API |
| `web_search` | 搜索互联网 |
| `memory_search` | 搜索 Agent 的历史记忆 |
| `message` | 向用户/其他 Agent 发送消息 |
| `sessions_spawn` | 创建子会话 |
| `sessions_send` | 向其他会话发送消息 |
| `cron` | 创建/管理定时任务 |

### 5.3 macOS 权限授予

在 macOS 上，OpenClaw 可能需要以下系统权限：

- **完全磁盘访问权限**：如果 Agent 需要读写受保护的目录
- **辅助功能权限**：如果使用浏览器自动化功能
- **网络权限**：首次运行时系统会提示
- **录屏与系统录音（node）**：当让助手截图时，macOS 会弹出此权限请求
- **APP 管理（node）**：当让助手打开自带浏览器时，macOS 会弹出此权限请求

授予方式：**系统设置 → 隐私与安全性 → 对应权限类别 → 添加 OpenClaw 或终端应用**

> 💡 如果权限弹窗中显示的应用名为 `node`，这是正常的——OpenClaw 基于 Node.js 运行，系统会以 `node` 进程名请求权限。

---

## 6. Browser 配置

OpenClaw 支持让 Agent 使用浏览器完成网页操作（搜索、填表、截图等）。

### 6.1 核心参数

企业级多 Profile 配置模板：

```json
{
  "browser": {
    "enabled": true,
    "evaluateEnabled": true,
    "headless": true,
    "defaultProfile": "default",
    "profiles": {
      "default": {
        "userDataDir": "~/.openclaw/browser/default",
        "cdpPort": 9222
      },
      "work": {
        "userDataDir": "~/.openclaw/browser/work",
        "cdpPort": 9223
      }
    }
  }
}
```

> 💡 每个 Profile 使用独立的 `cdpPort`（如上例中的 9222、9223），实现物理隔离；`color` 用于在 Dashboard 界面上区分不同 Profile。更多 Profile 高级配置详见 [12-架构与原理](./12-OpenClaw%20架构与原理（进阶）.md) 的 Sandbox 章节。

| 参数 | 类型 | 说明 |
|------|------|------|
| `enabled` | boolean | 是否启用浏览器功能 |
| `evaluateEnabled` | boolean | 是否允许执行任意 JavaScript。设为 `true` 才能让 Agent 在网页内执行复杂自动化脚本（如模拟点击、提取动态数据）。⚠️ 启用后风险较高，建议搭配 Sandbox 使用 |
| `headless` | boolean | 是否无头模式运行（不显示浏览器窗口）。**注意：这是全局参数，所有 Profile 统一使用此设置，不支持 per-Profile 单独配置** |
| `defaultProfile` | string | 默认使用的浏览器 Profile。默认值为 `"openclaw"`（OpenClaw 管理的独立隔离浏览器）。如需使用本地 Chrome 插件中继模式，可设置为 `"chrome"` |
| `profiles` | object | 多个 Profile 配置，用于隔离不同场景的浏览数据 |
| `noSandbox` | boolean | 是否禁用 Chromium 沙箱（某些 Linux 环境需要设为 `true`） |
| `executablePath` | string | 自定义 Chrome/Chromium 可执行文件路径（默认使用内置的 Chromium） |
| `attachOnly` | boolean | 仅连接已运行的 Chrome 实例，不自动启动新进程（用于本地 Chrome 插件模式） |
| `cdpUrl` | string | 远程浏览器实例的 CDP WebSocket URL（如 `ws://remote-host:9222`），用于连接远程浏览器 |

> 🗂️ **标签页管理建议**：Agent 每次查询都倾向于打开新标签页，不及时清理会导致内存溢出。建议在 `AGENTS.md` 中明确规定：操作完成后关闭标签页。

> 💡 **默认 Profile 行为**：当未显式配置 `defaultProfile` 时，默认值为 `"openclaw"`——OpenClaw 启动独立隔离浏览器实例，与个人浏览器完全分离。此外，OpenClaw 内置了一个名为 `chrome` 的硬编码 Profile，即使配置中没有显式定义 `chrome` 这个 key，设置 `"defaultProfile": "chrome"` 依然有效——系统会自动补全一个"连接本地 Chrome 插件"的配置。**建议：为了透明化和可维护性，显式定义每一个 Profile，不要依赖隐式行为。**

### 6.2 连接模式

OpenClaw 支持四种浏览器连接模式：

| 模式 | 说明 | 配置特征 |
|------|------|---------|
| `openclaw`（管理模式） | OpenClaw 启动独立隔离浏览器实例，与个人浏览器完全分离（**默认**） | 独立 `cdpPort`，自动分配 |
| `chrome`（插件中继） | 通过 Chrome 扩展插件操作当前浏览器标签页，共享登录状态 | `defaultProfile: "chrome"`，需安装 OpenClaw 浏览器扩展 |
| `existing-session`（现有会话） | 通过 Chrome DevTools MCP 直连已运行的 Chrome，复用标签页和登录状态 | `driver: "existing-session"` |
| `remote`（远程 CDP） | 连接运行在远程服务器上的浏览器实例 | `cdpUrl: "http://remote:9222"` |

### 6.3 多 Agent Browser 隔离

每个 Agent 可以使用不同的 Browser Profile，实现**数据隔离**：

- Agent A 使用 `default` Profile → 有自己的 Cookie、登录状态
- Agent B 使用 `work` Profile → 完全独立的浏览器环境

这样多个 Agent 同时使用浏览器时不会互相干扰。

---

## 7. Dashboard Web UI

OpenClaw 内置了一个 Web 控制面板（Dashboard），可通过浏览器管理 Gateway、查看会话、审批设备配对等。

### 访问方式

Gateway 启动后，Dashboard 默认运行在 `http://127.0.0.1:18789/`。

如果启用了 Token 认证，需要在 URL 中携带 Token：

```bash
TOKEN=$(openclaw config get gateway.auth.token 2>/dev/null | tr -d ' ')
echo "http://127.0.0.1:18789/?token=$TOKEN"
```

也可以去配置文件openclaw.json中查询token

```json
{
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "xxxxxxxxxxx"
    }
  }
}
```

### 核心功能

| 功能 | 说明 |
|------|------|
| **会话列表** | 查看所有活跃 Session，包含 Agent ID、通道类型、消息数、Token 用量 |
| **会话详情** | 查看某个 Session 的完整对话记录、工具调用日志 |
| **设备配对** | 批准/拒绝新设备的连接请求 |
| **Agent 状态** | 查看各 Agent 的运行状态、绑定关系 |
| **通道状态** | 查看各 IM 通道的连接状态（在线/离线/错误） |
| **Cron 任务** | 查看已注册的定时任务及执行记录 |

> 💡 Dashboard 是只读管理界面，不支持直接编辑配置文件。配置修改请通过 `openclaw configure` 命令或直接编辑 `openclaw.json`。

---

## 8. 常用命令速查

### Gateway 管理

```bash
openclaw gateway start        # 启动网关
openclaw gateway stop         # 停止网关
openclaw gateway status       # 查看网关状态
```

### 渠道管理

```bash
openclaw channels list        # 列出已配置的渠道
openclaw channels status      # 查看渠道连接状态
```

### 配置诊断

```bash
openclaw configure            # 交互式配置
openclaw config               # 同上
openclaw doctor               # 运行诊断，检查配置问题
```

### 会话管理

```bash
openclaw sessions             # 列出活跃会话
```

### Telegram 配对

```bash
openclaw pair telegram        # 生成 Telegram 配对链接
```

---

## 9. 常见问题（FAQ）

### 9.1 Dashboard 提示 `gateway token missing`

**错误信息**：`disconnected (1008): unauthorized: gateway token missing`

这通常是因为 Gateway 开启了 Token 认证，但访问 Dashboard 时未携带 Token。

**方案 A（推荐）：生成并配置 Token**

```bash
TOKEN=$(openssl rand -hex 32)
openclaw config set gateway.auth.mode token
openclaw config set gateway.auth.token "$TOKEN"
openclaw gateway restart
# 用带 Token 的 URL 访问 Dashboard
echo "http://127.0.0.1:18789/?token=$TOKEN"
```

**方案 B（仅限开发调试）：关闭认证**

```bash
openclaw config set gateway.auth.mode none
```

**Token 管理命令**

```bash
# 查看当前 Token
openclaw config get gateway.auth.token
# 生成带 Token 的 Dashboard URL
TOKEN=$(openclaw config get gateway.auth.token 2>/dev/null | tr -d ' ')
echo "http://127.0.0.1:18789/?token=$TOKEN"
```

---

## 10. 延伸阅读

- [04-OpenClaw 通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) —— 实战：把 Agent 接入钉钉
- [05-OpenClaw Memory：让 AI 越用越聪明](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) —— 深入理解记忆系统
- [OpenClaw 官方文档](https://docs.openclaw.ai)
- 有问题？联系内部 AI 基础设施团队或在钉钉群内提问

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [02-安装与部署](./02-OpenClaw%20安装与部署.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) |
