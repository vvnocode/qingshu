+++
date = '2026-03-15T10:30:00+08:00'
draft = false
title = 'OpenClaw 核心概念与配置'
tags = ['OpenClaw', 'AI', 'Agent', '配置']
+++

# OpenClaw 核心概念与配置

本篇介绍 OpenClaw 的配置文件体系、Agent 类型、Workspace 结构、Bindings 路由、权限控制和浏览器配置。

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

> 💡 **提示**：你可以用 `openclaw configure`（或其别名 `openclaw config`）交互式编辑配置，也可以直接手动编辑该 JSON 文件。配置文件支持 JSON5 格式（允许注释和尾逗号）。

---

## 2. Agent 概念与类型

### 2.1 Agent 的组成

一个 Agent 是 OpenClaw 中最核心的实体。可以把它理解为一个**有名字、有工作空间、有工具权限的 AI 执行单元**。

一个 Agent 的典型配置：

```json
{
  "id": "main",
  "name": "Main Agent",
  "workspace": "~/.openclaw/workspace",
  "agentDir": "~/.openclaw/agents/main/agent",
  "model": "bailian/kimi-k2.5",
  "tools": {
    "allow": ["read", "write", "edit", "exec", "web_search", "memory_search"],
    "deny": []
  }
}
```

各字段含义：

| 字段          | 说明                                  |
| ----------- | ----------------------------------- |
| `id`        | Agent 的唯一标识符，在 bindings 中引用         |
| `name`      | Agent 的显示名称                         |
| `workspace` | Agent 的工作目录，存放 AGENTS.md、Memory 等文件 |
| `agentDir`  | Agent 配置目录                          |
| `model`     | 使用的 LLM 模型 ID                       |
| `tools`     | 工具权限配置（允许/拒绝的工具列表）                  |

### 2.2 四种 Agent 类型

OpenClaw 中有四种不同角色的 Agent：

| 类型 | 英文名 | 说明 | 典型用途 |
|------|--------|------|---------|
| 主 Agent | Main Agent | 系统默认 Agent，ID 为 `main` | 处理所有未特别绑定的消息，作为默认入口 |
| 配置 Agent | Configured Agent | 在 `agents` 数组中声明的 Agent | 专门处理某个渠道/场景的消息，如"钉钉专属 Agent" |
| 子会话 Agent | Sub-Agent Session | 由 Main Agent 在运行时动态创建 | 处理需要隔离上下文的子任务 |
| 拒绝 Agent | Denied Agent | 特殊 Agent，拒绝一切请求 | 用于 bindings 兜底，阻止未授权的消息 |

### 2.3 Multi-Agent vs Configured Agent

这两个概念经常混淆，区分如下：

- **Multi-Agent** 是一种**架构模式**——指多个 Agent 协作完成任务的工作方式
- **Configured Agent** 是一个**具体实体**——在 `openclaw.json` 的 `agents` 数组中声明的某个 Agent

Configured Agent 是 Multi-Agent 架构中的具体成员。你可以只有一个 Agent（单 Agent 模式），也可以配置多个 Agent 实现 Multi-Agent 协作。

---

## 3. Workspace 目录结构

每个 Agent 都有自己的 Workspace（工作目录）。Workspace 的实际路径由 `openclaw.json` 中的 `workspace` 字段决定（Main Agent 默认为 `~/.openclaw/workspace`，其他 Agent 在 `agents.list` 中各自指定）。以下是一个典型的 Workspace 目录树：

> Memory 文件的详细机制（含 `MEMORY.md` 与 `memory/` 目录的检索方式）参见 [05-Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md)。

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

1. **最具体优先**：使用确定性匹配，更具体的规则优先级更高。
2. **首个命中生效**：一旦匹配成功，后续规则不再检查。
3. **建议兜底**：最后一条规则用 Denied Agent 兜底，防止未预期的消息进入系统。

> → 实际案例参见 [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) 第 1 节。

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

> **标签页管理建议**：Agent 每次查询都倾向于打开新标签页，不及时清理会导致内存溢出。建议在 `AGENTS.md` 中明确规定：操作完成后关闭标签页。

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

## 7. Dashboard Web UI 与 HTTP API

OpenClaw 内置了一个 Web 控制面板（Dashboard），可通过浏览器管理 Gateway、查看会话、审批设备配对等。同时，Gateway 还可以对外暴露标准 HTTP API 接口（chatCompletions / responses），供前端应用或其他系统调用。

### 7.1 本地访问（默认）

Gateway 启动后，Dashboard 默认仅监听本机回环地址，运行在 `http://127.0.0.1:18789/`，外部无法访问。

如果启用了 Token 认证，需要在 URL 中携带 Token：

```bash
TOKEN=$(openclaw config get gateway.auth.token 2>/dev/null | tr -d ' ')
echo "http://127.0.0.1:18789/?token=$TOKEN"
```

也可以去配置文件 `openclaw.json` 中查询 token：

```json
{
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "<your-generated-token>"
    }
  }
}
```

### 7.2 局域网访问配置

> ⚠️ **开放前提**：局域网开放必须同时启用 Token 认证，绝不可在无认证状态下暴露 Gateway。

默认配置下 Gateway 只绑定 `127.0.0.1`，若需要让**同一内网**的其他设备（如前端开发机、团队成员）访问 Dashboard 或调用 HTTP API，需将 `bind` 改为 `lan`，并配置 CORS 允许来源。

**最小局域网开放配置：**

```json
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "<your-generated-token>"
    }
  }
}
```

**关键字段说明：**

| 字段 | 可选值 | 说明 |
|------|--------|------|
| `bind` | `loopback`（默认）/ `lan` / `tailnet` / `auto` | `loopback` 仅绑定 127.0.0.1；`lan` 绑定所有网卡（0.0.0.0），局域网可访问；`tailnet` 仅绑定 Tailscale 网段 |
| `mode` | `local` / `remote` | `local` 表示本地运行模式；`remote` 用于通过远程网关中继访问 |
| `port` | 整数 | Gateway 监听端口，默认 18789 |
| `auth.mode` | `token` / `none` | 开放局域网时**必须**使用 `token` |

> 💡 **更安全的替代方案**：官方推荐优先考虑 **Tailscale Serve**（`tailscale.mode: "serve"`）而非直接 `bind: "lan"`。Tailscale Serve 通过 Tailscale 的身份层处理授权，Gateway 本身仍可维持 `loopback` 绑定，安全性更高。`bind: "lan"` 适合已有稳定内网管控、无法使用 Tailscale 的场景。

**带 CORS 的完整局域网配置示例：**

如果前端页面（如 Vue 开发服务器、内网 Web 应用）需要直接调用 Gateway 的 HTTP API，还需配置 `controlUi.allowedOrigins` 白名单，否则浏览器会因跨域被拒绝：

```json
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "<your-generated-token>"
    },
    "controlUi": {
      "allowedOrigins": [
        "http://<gateway-host>:18789",
        "ws://<gateway-host>:18789",
        "http://<frontend-dev-host>:5173",
        "http://localhost:18789",
        "http://127.0.0.1:18789"
      ]
    }
  }
}
```

> 💡 **占位符说明**：`<gateway-host>` 替换为运行 OpenClaw 的机器在局域网中的 IP（如 `10.100.4.115`）；`<frontend-dev-host>` 替换为前端开发机的 IP。只需将实际需要访问的来源加入白名单，无需添加所有设备。

> ⚠️ **`dangerouslyDisableDeviceAuth`**：该字段设为 `true` 时，controlUi（Dashboard Web 界面）无需走设备配对流程即可直接访问——通常用于**前端开发调试场景**，生产部署请谨慎评估。详见 [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) 第 2.4 节。

### 7.3 HTTP API 接口（chatCompletions / responses）

Gateway 支持对外暴露两个标准 HTTP 接口，供外部系统以 OpenAI 兼容方式调用 Agent：

```json
{
  "gateway": {
    "http": {
      "endpoints": {
        "chatCompletions": {
          "enabled": true
        },
        "responses": {
          "enabled": true
        }
      }
    }
  }
}
```

| 接口 | 路径 | 说明 |
|------|------|------|
| `chatCompletions` | `POST /v1/chat/completions` | OpenAI Chat Completions 兼容接口，适合已有 OpenAI SDK 集成的场景 |
| `responses` | `POST /v1/responses` | OpenAI Responses API 兼容接口，适合支持工具调用的场景 |

**调用示例（curl）：**

```bash
curl -X POST http://<gateway-host>:18789/v1/chat/completions \
  -H "Authorization: Bearer <your-generated-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "main",
    "messages": [
      {"role": "user", "content": "帮我查一下今天的待办事项"}
    ]
  }'
```

> 💡 `model` 字段填写 Agent 的 `id`（如 `main`），Gateway 会自动将请求路由到对应的 Agent 处理。

> ⚠️ **安全提示**：开放 HTTP API 后，任何能访问该端口的设备均可调用 Agent。务必通过 `auth.token` 认证，并将端口限制在内网范围（`bind: lan`），不要直接暴露到公网。

### 7.4 禁用用户命令菜单（安全加固）

#### 默认行为

OpenClaw 有两套命令入口，它们的权限是**完全独立**的：

| 入口 | 示例 | 默认状态 | 受 `commands` 配置控制？ |
|------|------|---------|------------------------|
| **TUI/CLI**（终端） | 终端输入 `/new` | ✅ 始终可用 | ❌ 不受影响，客户端原生处理 |
| **IM 通道**（钉钉、Telegram 等） | 聊天框发送 `/new` | ✅ 默认开启 | ✅ 由 `commands.text` 控制 |

默认情况下，IM 通道用户同样可以发送 `/new`（开新会话）、`/reset`（重置会话）、`/config`（修改配置）、`/restart`（重启 Gateway）等命令。在团队部署中，这存在安全隐患——普通用户可能误操作甚至恶意重置他人会话或篡改配置。

#### 推荐：只保留 TUI 可用，关闭所有 IM 通道命令

> ⚠️ **注意**：`commands.text: false` 对钉钉等**无原生命令的通道**无效——这类通道强制走文本命令解析，无论该配置如何设置。正确的做法是使用 `allowFrom` 白名单。

```json
{
  "gateway": { ... },
  "agents": { ... },
  "commands": {
    "allowFrom": {
      "dingtalk": [],
      "*": []
    }
  }
}
```

`allowFrom` 的 value 为空数组 `[]` 时，表示该通道没有任何用户被允许执行命令。`"*": []` 兜底所有其他 IM 通道。**TUI/CLI 不受 `allowFrom` 影响**，管理员仍可在终端正常使用所有命令。

#### 精细控制（仅对特定用户开放命令）

如果需要保留少数管理员在 IM 通道中使用命令的能力：

```json
{
  "gateway": { ... },
  "agents": { ... },
  "commands": {
    "allowFrom": {
      "dingtalk": ["admin_user_id"],
      "*": []
    }
  }
}
```

value 填写允许执行命令的用户 ID（钉钉为用户的 openId），其余用户一律拦截。

#### commands 字段速查

| 配置项 | 说明 |
|--------|------|
| `commands.text` | `false` 对部分通道可禁用文本斜杠命令，但对钉钉等通道无效 |
| `commands.allowFrom` | 按通道设置可执行命令的用户白名单，空数组表示全部拦截 |
| `commands.config` | `false` 禁用 `/config` 配置修改（高危） |
| `commands.restart` | `false` 禁用 `/restart` 重启 Gateway（高危） |
| `commands.debug` | `false` 禁用 `/debug` 调试信息输出 |
| `commands.bash` | `false` 禁用 `!` 前缀的 bash 快捷命令（高危） |

> 💡 **团队部署建议**：使用 `allowFrom` 做全通道白名单是最可靠的方式，比 `text: false` 更彻底；同时单独关闭 `config`、`restart`、`bash` 三项高危命令作为双重保险。

### 7.5 核心功能

| 功能 | 说明 |
|------|------|
| **会话列表** | 查看所有活跃 Session，包含 Agent ID、通道类型、消息数、Token 用量 |
| **会话详情** | 查看某个 Session 的完整对话记录、工具调用日志 |
| **设备配对** | 批准/拒绝新设备的连接请求 |
| **Agent 状态** | 查看各 Agent 的运行状态、绑定关系 |
| **通道状态** | 查看各 IM 通道的连接状态（在线/离线/错误） |
| **Cron 任务** | 查看已注册的定时任务及执行记录 |

> ⚠️ Dashboard 拥有**完整的管理权限**，包括在线编辑 `openclaw.json`、管理 Cron 任务、审批执行权限等。务必通过 Token 严格管控谁能访问 Dashboard。

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
- [05-OpenClaw Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) —— 深入理解记忆系统
- [OpenClaw 官方文档](https://docs.openclaw.ai)

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [02-安装与部署](./02-OpenClaw%20安装与部署.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) |
