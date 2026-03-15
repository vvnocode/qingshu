+++
date = '2026-03-15T00:11:00+08:00'
draft = false
title = 'OpenClaw Multi-Agent：多智能体协作'
tags = ['OpenClaw', 'Multi-Agent', 'AI']
+++

## 本章导读

> **这篇文档回答三个问题：**
>
> 1. 为什么需要多个 Agent？
> 2. 多 Agent 怎么配置？
> 3. 它们之间怎么协作？

一个 Agent 就像一个"全能助手"——什么都能干，但什么都管容易出问题：权限太大、上下文混乱、响应变慢。

**多 Agent 的核心思想**：让不同的 Agent **各司其职**，就像一个公司有不同部门、不同岗位，各自负责各自的事，通过协作完成复杂工作。

---

## 1. 为什么需要多 Agent

| 场景 | 单 Agent 的问题 | 多 Agent 的解决方案 |
|------|----------------|-------------------|
| 多部门使用 | 权限无法差异化，所有人共享同一套权限 | 每个部门独立 Agent，各自配置权限 |
| 长链路任务 | 主会话被阻塞，用户等待时间长 | Main 调度 + Worker 后台执行，互不阻塞 |
| 不同模型需求 | 只能用一个模型，要么贵要么笨 | 不同角色绑定不同模型（简单任务用便宜模型，复杂任务用强模型） |
| 安全管控 | 全局权限过大，一个漏洞全面暴露 | 最小权限原则，每个 Agent 只给必要权限 |

---

## 2. 多 Agent 核心概念

### 四种 Agent 类型

> 详细定义参见 [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) 的 Agent 概念与类型章节。

| 类型 | 说明 | 用途 |
|------|------|------|
| **Main Agent** | 系统默认 Agent，ID 为 `main` | 处理所有未特别绑定的消息，是"总管"和调度中心 |
| **Configured Agent** | 在 `agents.list` 中显式定义的 Agent | 正式的工作角色（如 HR、Finance、DingTalk 专员） |
| **Sub-Agent Session** | 由 Main 临时 spawn 的子会话 | 临时任务、一次性工作 |
| **Denied Agent** | 配置为拒绝一切请求的 Agent | 兜底拦截，防止未知请求绕过管控 |

### 三件套

多 Agent 系统由三个核心配置文件组成：

| 配置 | 作用 | 类比 |
|------|------|------|
| **agents.list** | 定义所有 Agent 的角色、模型、权限 | 公司的"岗位编制表" |
| **bindings** | 定义消息路由规则（什么消息给哪个 Agent） | 公司的"分工制度" |
| **workspace** | 定义每个 Agent 的工作目录 | 每个部门的"办公室" |

---

## 3. 最小多 Agent 配置示例

以下是一个最简单的多 Agent 配置，包含三个 Agent：

- **Main**：主调度 Agent，处理通用请求
- **DingTalk**：钉钉专员，专门处理钉钉通道的消息
- **Denied**：兜底 Agent，拒绝所有未匹配的请求（完整配置参见 [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) 第 3 章）

### agents.list 配置

```json5
{
  "agents": {
    "list": [
      {
        "id": "main",
        "name": "Main Agent",
        "model": "anthropic/claude-sonnet-4-5",
        "description": "主调度 Agent，处理通用请求，协调其他 Agent",
        "tools": {
          "allow": [
            "read",
            "write",
            "web_search",
            "sessions_spawn",
            "sessions_send"
          ]
        }
      },
      {
        "id": "dingtalk-agent",
        "name": "DingTalk Agent",
        "model": "siliconflow/deepseek-v3",
        "description": "钉钉通道专员，处理来自钉钉群的消息",
        "tools": {
          "allow": [
            "read",
            "web_search",
            "message"
          ]
        }
      },
      {
        "id": "denied",
        "name": "Denied Agent",
        "model": "siliconflow/deepseek-v3",
        "description": "兜底 Agent，拒绝所有未匹配的请求",
        "tools": { "deny": ["*"] }
      }
    ]
  }
}
```

### bindings 配置

```json5
{
  "bindings": [
    {
      "agentId": "dingtalk-agent",
      "match": { "channel": "dingtalk" }
    },
    {
      "agentId": "main",
      "match": { "channel": "cli" }
    },
    {
      "agentId": "denied",
      "match": { "channel": "*" }
    }
  ]
}
```

### Workspace 初始化

```bash
# 推荐方式：使用向导
openclaw agents add dingtalk-agent

# 手动方式
mkdir -p ~/.openclaw/workspace-dingtalk-agent

# 或者让 Agent 自动处理：
# 在对话中告诉 Agent：帮我初始化 dingtalk-agent 工作空间
```

> ⚠️ **重要**：如果有多个 agent，`agents.list` 必须显式定义 `id: "main"` 的 Agent。Main Agent 是整个系统的调度中心，缺少它系统无法正常工作。
>
> 也可以不手动配置workspace下的文件，当有用户第一次通过channel和agent聊天时，会自动创建workspace。等系统生成相应的文件后，再去增加相应的配置。

---

## 4. 五层隔离架构

### 为什么需要多层隔离？

仅做 Workspace 隔离时，仍存在三类残留风险：

1. **运行时污染**：exec 在宿主机执行，进程与环境互相影响
2. **会话态污染**：浏览器 Cookie/缓存/登录态跨 Agent 串扰
3. **路径暴露过宽**：容器挂载过大，敏感目录被误读/误写

结论：**隔离必须是多层组合，而非单点配置。**

### 五层隔离总览

多 Agent 系统通过**五层隔离**确保安全和稳定：

| 层级 | 边界类型 | 说明 | 实现方式 |
|------|---------|------|---------|
| **Agent / Session 层** | 逻辑边界 | 每个 Agent 有独立的身份和会话 | agentId + sessionId |
| **Workspace 层** | 数据边界 | 每个 Agent 只能访问自己的工作目录 | 独立 workspace 目录 |
| **Tool Policy 层** | 准入边界 | 每个 Agent 只能调用被授权的工具 | tools.allow 白名单 |
| **Exec Sandbox 层** | 运行时边界 | 命令执行在沙箱中隔离 | 容器化 / 沙箱运行 |
| **Browser Sandbox 层** | 会话态边界 | 浏览器操作在独立沙箱中 | 隔离的浏览器实例 |

> 💡 **简单理解**：每个 Agent 就像一个独立的"隔间办公"——有自己的桌子（Workspace）、自己的权限卡（Tool Policy）、自己的电脑（Sandbox），互不干扰。

> ⚠️ **最常见误解：`tools.deny: ["exec"]` ≠ 完整安全方案**
>
> - `tools.allow/deny`：**前置准入控制**——决定 Agent 能否调用某个工具
> - Exec Sandbox（`sandbox.mode`）：**运行时约束控制**——决定工具执行后在哪跑、能访问哪些路径
> - 单独只有其中一个都不够，两者配合才构成**纵深防御（Defense in Depth）**

---

## 5. 通信模式

Agent 之间通过两种方式通信：

### sessions_spawn vs sessions_send

| 维度 | `sessions_spawn` | `sessions_send` |
|------|-----------------|-----------------|
| 作用 | 创建一个新的子 Session | 向已有 Session 发送消息 |
| Session | 创建新 Session | 复用已有 Session |
| 类比 | 开一个新会议 | 在现有群里发消息 |
| 适用场景 | 新任务、独立工作流 | 追加信息、持续对话 |

### agentId 强约束

> ⚠️ **关键规则**：调用 `sessions_spawn` 或 `sessions_send` 时，**必须显式传 `agentId`**。

**禁止**使用 label + task 裸调（无 agentId），否则消息可能被路由到错误的 Agent。

#### 正确示例

```json
{
  "tool": "sessions_spawn",
  "params": {
    "agentId": "dingtalk-agent",
    "task": "请将以下内容发送到钉钉工作群：..."
  }
}
```

#### 错误示例

```json
{
  "tool": "sessions_spawn",
  "params": {
    "label": "钉钉消息",
    "task": "请将以下内容发送到钉钉工作群：..."
  }
}
```

> ❌ 缺少 `agentId`，系统无法确定由哪个 Agent 处理。

### subagents.allowAgents 白名单

可以通过 `subagents.allowAgents` 白名单限制某个 Agent 只能 spawn 指定的 worker Agent，防止误调度：

```json
{
  "id": "tech-lead",
  "subagents": {
    "allowAgents": ["planner", "implementer", "verifier", "tester", "reviewer"]
  }
}
```

未出现在白名单中的 Agent 将无法被该调度方 spawn，从而避免任务被路由到错误的角色。

### 使用规范

在实际多 Agent 架构中，`sessions_spawn` / `sessions_send` 的使用应遵循以下原则：

- **Main session = Coordinator ONLY**：主会话仅负责调度，所有实际执行交给 subagent
- **Main session 工具调用最小化**：0–2 次 tool calls（仅限 `spawn` / `send`），不在主会话做执行逻辑
- **Task agents 可 spawn sub-subagents**：执行层 Agent 可以再 spawn 子 Agent 完成并行子任务
- **模型使用**：使用配置的 primary model，不可用时按配置的 fallback 行为回退

---

## 6. 典型协作模式

### 模式一：Main + 钉钉专员（按通道分工）

```
用户 ──→ [CLI] ──→ Main Agent
                       ↓ (sessions_spawn)
用户 ──→ [钉钉] ──→ DingTalk Agent
```

- **Main Agent**：处理 CLI 通道的开发/管理类请求
- **DingTalk Agent**：处理钉钉通道的业务类请求
- **适用场景**：技术团队用 CLI，业务团队用钉钉

### 模式二：Main + HR + Finance + IT（按部门分工）

```
                    ┌──→ HR Agent（简历、考勤）
                    │
Main Agent ────────┼──→ Finance Agent（报表、发票）
  (调度中心)         │
                    └──→ IT Agent（运维、部署）
```

- **Main Agent**：接收所有请求，根据内容分发给对应部门 Agent
- **部门 Agent**：各自拥有独立的 Workspace、权限和 Skill
- **适用场景**：企业级多部门 AI 助手

### 模式三：Coordinator + Specialists（复杂项目分工）

```
                    ┌──→ Frontend Dev（前端开发）
                    │
Coordinator ───────┼──→ Backend Dev（后端开发）
  (项目协调)        │
                    ├──→ QA Agent（测试验证）
                    │
                    └──→ Doc Agent（文档撰写）
```

- **Coordinator**：拆解需求，分配任务，汇总结果
- **Specialist Agents**：各自专注一个领域，并行执行
- **适用场景**：Feature 开发团队、复杂项目交付

### 进阶：开发团队 Agent 架构实战

这是一个经过实际验证的完整开发团队架构，包含六个角色，适用于中大型项目的自动化开发流程。

#### 六角色设计与权限矩阵

| 角色 | 模型建议 | tools.allow | tools.deny |
|------|---------|-------------|------------|
| tech-lead | 高质量模型（如 anthropic/claude-opus-4-6） | read, message, sessions_spawn, sessions_send, memory_search | gateway |
| planner | 高质量模型 | read, write, edit, web_search, memory_search | gateway, exec |
| implementer | 编码模型（如 dashscope/qwen-coder-plus） | read, write, edit, exec, process, memory_search | gateway |
| verifier | 低成本模型 | read, write, edit, exec, process, memory_search | gateway |
| tester | 低成本模型 | read, write, edit, exec, process, memory_search | gateway |
| reviewer | 高质量模型 | read, write, edit, memory_search | gateway, exec |

> 💡 **设计思路**：Tech Lead 只有调度权，不直接写代码；Planner 可搜索但禁止执行；Implementer 拥有完整的代码写入与执行权限；Reviewer 只读代码不执行，确保审查独立性。

#### 异步两次确认模式（Async Two-Checkpoint）

解决"Agent 一直 typing"问题的根本方案——让用户只在关键节点参与：

```
用户 ──→ Tech Lead ──→ Planner ──→ [Checkpoint A: Plan 确认]
                                         ↓ 用户确认
                                    Implementer ──→ Verifier ──→ Tester ──→ Reviewer
                                                                              ↓
                                                                 [Checkpoint B: Final Review 确认]
                                                                              ↓ 用户确认
                                                                         完成 / 合并
```

**核心流程：**
1. Tech Lead 接单后立即返回"任务已启动"（不阻塞主会话）
2. 仅两个 Checkpoint 打扰用户：**Checkpoint A（Plan 确认）** 和 **Checkpoint B（Final Review 确认）**
3. 中间步骤（Implementer → Verifier → Tester → Reviewer）自动推进
4. 每步最多重试 2 次，超出返回 `STATUS: blocked`

#### Tech Lead 关键铁律

1. 接单后立即返回"任务已启动"
2. 仅两个 Checkpoint 打扰用户：Plan / Final Review
3. Implementer/Verifier/Tester 自动推进
4. 每步最多重试 2 次，超出 `STATUS: blocked`
5. 输出契约统一：`STATUS`, `ARTIFACTS`, `SUMMARY`, `NEXT_ACTION`
6. 面向用户与文档必须中文
7. 所有 `sessions_spawn` 必须显式 `agentId`，禁止仅用 label + task

### Multi-Agent 架构升级策略

按复杂度渐进升级，不必一步到位：

| 层级 | 策略 | 适用场景 |
|------|------|---------|
| **L1 轻量默认** | 合并主开发链（Plan + Implement + 自测），保留独立验收 | 小/中任务，日常开发 |
| **L2 治理增强** | 完整链路：Planner → Implementer → Verifier → Tester → Reviewer | 高风险改动、需完整文档审计 |
| **L3 自动化并行** | 大任务执行层交给外部工具，保留 Plan/Review 护栏 | 大型项目 |

> 核心原则：**不按"人事岗位"机械拆 Agent，而按"上下文边界 + 交互成本"拆分。**

---

## 7. 落地步骤

推荐按以下顺序搭建多 Agent 系统：

### 第一步：拆 Workspace

为每个 Agent 创建独立的工作目录：

```bash
# 推荐方式：使用向导创建 Agent
openclaw agents add hr-agent
openclaw agents add finance-agent

# 手动方式：创建独立工作目录
mkdir -p ~/.openclaw/workspace-hr-agent
mkdir -p ~/.openclaw/workspace-finance-agent
```

每个目录是该 Agent 的"数据边界"，Agent 只能访问自己的目录。

### 第二步：配置 agents.list + bindings

定义所有 Agent 的角色、模型、权限，以及消息路由规则。参考上文的配置示例。

### 第三步：补齐 AGENTS.md

在每个 Agent 的 Workspace 中放置 `AGENTS.md` 文件，用自然语言描述：

- 你是谁
- 你负责什么
- 你的工作流程
- 你不应该做什么

```markdown
# HR Agent

你是人力资源专员 Agent。

## 职责
- 处理简历筛选请求
- 生成考勤统计报表
- 回答 HR 政策相关问题

## 限制
- 不要修改任何系统文件
- 不要执行 Shell 命令
- 涉及薪资的问题，请转交给 Finance Agent
```

### 第四步：收紧 Tool Policy

为每个 Agent 配置最小权限：

```json5
{
  "id": "hr-agent",
  "tools": {
    "allow": ["read", "write", "web_search"]
  }
}
```

- HR Agent 不需要 Shell 权限
- Finance Agent 不需要网络请求权限
- 按需分配，宁紧勿松

### 第五步：启用 Sandbox

先从非主 Agent 开始隔离，逐步扩大范围：

1. 设置 `sandbox.mode: "non-main"`（仅 Configured Agent 隔离），观察稳定性
2. 稳定后评估是否升级到 `sandbox.mode: "all"`（包括 Main Agent）
3. 分离 Browser/Exec 挂载路径，避免共享敏感目录

```json
{
  "sandbox": {
    "mode": "non-main",
    "exec": {
      "binds": ["/project/src:rw", "/project/tests:rw"]
    },
    "browser": {
      "binds": ["/project/browser-data"]
    }
  }
}
```

### 第六步：共享工作区设计

多角色需要共享代码目录时，可通过 `project` 软链实现：

```bash
# 在各 Agent workspace 中创建指向共享代码的软链
ln -s /project/src workspace/implementer/project
ln -s /project/src workspace/verifier/project
ln -s /project/src workspace/tester/project
```

这样每个 Agent 仍在自己的 Workspace 中工作，但可以通过软链访问共享的项目代码目录。

> ⚠️ **安全注意**：软链会绕过 Workspace 隔离的文件边界。如果某个 Agent 有 `write` 权限且通过软链能写入共享代码目录，可能影响其他 Agent 的工作成果。建议：
> - 仅对**需要写入**的 Agent（如 Implementer）创建可写软链
> - 对只需读取的 Agent（如 Verifier、Reviewer）使用**只读挂载**或在 AGENTS.md 中声明只读约束
> - 结合 `sandbox.exec.binds` 配置控制容器内的可写路径

### 第七步：验证与回归

参照下一节的验证清单，逐项确认系统行为符合预期。

---

## 8. 验证清单

| 验证项 | 检查方法 | 预期结果 |
|--------|---------|---------|
| **路由命中** | 通过钉钉发消息 | DingTalk Agent 响应，而不是 Main |
| **权限命中** | HR Agent 尝试执行 Shell 命令 | 被 Tool Policy 拒绝 |
| **模型命中** | 查看 Agent 日志 | 各 Agent 使用配置的模型 |
| **兜底命中** | 通过未配置的通道发消息 | Denied Agent 拦截并回复拒绝信息 |
| **Workspace 隔离** | HR Agent 尝试读取 Finance 目录 | 被 Workspace 边界拒绝 |
| **通信正确** | Main spawn 子任务给 HR Agent | HR Agent 正确收到并执行 |
| **登录态隔离** | 不同 Agent 分别访问需登录的网页 | 浏览器 session 互不干扰，Cookie/缓存完全独立 |
| **写入边界** | Agent 尝试写入其他 Agent 的 Workspace | 被路径约束拒绝，仅能写入自己的 Workspace 范围 |
| **越权调用** | Agent 尝试调用 `tools.deny` 中的工具 | 工具调用被前置拦截，返回权限拒绝 |

### 跨机器复现检查清单

在不同环境部署时，按以下清单逐项确认一致性：

| 检查项 | 说明 |
|--------|------|
| **agents.list 一致** | 所有环境使用相同的 Agent 定义（角色、模型、权限） |
| **bindings 路由一致** | 通道路由规则与生产环境保持同步 |
| **sandbox.mode 一致** | 开发/测试/生产环境的沙箱模式统一 |
| **AGENTS.md 同步** | 每个 Agent 的行为说明书已同步更新 |
| **软链/挂载路径有效** | 共享工作区的软链在目标机器上存在且可访问 |
| **模型 API Key 有效** | 各 Agent 配置的模型在目标环境可用 |
| **Plugin 状态正常** | 钉钉/Telegram 等通道 Plugin 已启动且 Webhook 配置正确 |

---

## 9. 常见问题

### 群消息不响应

**现象**：钉钉群里发消息，Agent 没有任何反应。

**排查**：
1. 检查 `bindings` 是否配置了 `"channel": "dingtalk"` 的路由
2. 检查目标 Agent 是否在 `agents.list` 中正确定义
3. 检查钉钉 Plugin 是否正常运行（查看 Plugin 日志）
4. 确认钉钉机器人的 Webhook 配置是否正确

### Agent 一直 typing

**现象**：Agent 显示正在输入，但长时间没有回复。

**排查**：
1. 检查 Agent 的模型配置是否正确（API Key 是否有效）
2. 查看 Agent 日志，是否卡在某个工具调用上
3. 检查网络连接（模型 API 是否可达）
4. 如果任务过于复杂，考虑拆分为更小的子任务

### 无 exec 权限

**现象**：Agent 尝试执行命令时提示权限不足。

**排查**：
1. 检查 `tools.allow` 是否包含 `exec` 工具
2. 确认 Exec Sandbox 是否正确配置
3. 如果是非技术 Agent（如 HR），不需要 exec 权限是正常的

### 明明给了 exec 权限，却提示"无权限"

**现象**：已在 `tools.allow` 中添加了 exec，Agent 执行时仍报权限不足。

**隐蔽根因**：调度方（如 Tech Lead）在 `sessions_spawn` 时未显式传 `agentId`，导致任务落到了**默认子代理**（权限更小），而不是目标 Agent。

**修复**：
1. `sessions_spawn` 强制带 `agentId: "target-agent-id"`
2. 检查日志中实际的 session/model/tool 调用记录，以日志为准（而非 AGENTS.md 的描述）
3. 为调度方配置 `subagents.allowAgents` 白名单，避免误派：

```json
{
  "id": "tech-lead",
  "subagents": {
    "allowAgents": ["planner", "implementer", "verifier", "tester", "reviewer"]
  }
}
```

> 💡 **经验**：90% 的"权限明明有却不生效"问题，都是 spawn 时没带 agentId，任务被路由到了错误的 Agent。

### 模型回退

**现象**：Agent 没有使用配置的模型，而是回退到默认模型。

**排查**：
1. 检查 `agents.list` 中该 Agent 的 `model` 字段是否正确
2. 确认配置的模型是否可用（API Key 额度、模型名称拼写）
3. 查看日志中是否有模型降级的警告信息

### Sub-Agent 不遵守规则

**现象**：子 Agent 没有按照预期的行为工作。

**排查**：
1. 检查该 Agent Workspace 下的 `AGENTS.md` 是否清晰明确
2. 确认 `systemPrompt` 是否设置了正确的角色定义
3. 尝试在 AGENTS.md 中增加"不应该做什么"的负面约束
4. 如果问题持续，考虑更换为更强的模型（如从 Haiku 升级到 Sonnet）

### Telegram 群入口不响应

**现象**：Telegram 群里发消息，Agent 完全无反应。

**根因**：群路由被 `denied` 兜底规则提前命中 + 群可见性/免@配置不完整。

**修复**：
1. 将目标 Agent 的群 binding **前置**到 denied binding 之前（bindings 按顺序匹配，先匹配先生效）
2. 群策略通过 `channels.telegram.groups` 或 agent 级别的 `groupChat.mentionPatterns` 配置，不在 bindings 中设置。
3. 校验 Telegram 侧隐私模式与管理员可见性

```json5
{
  "bindings": [
    {
      "agentId": "my-agent",
      "match": {
        "channel": "telegram",
        "peer": { "kind": "group", "id": "target-group-id" }
      }
    },
    {
      "agentId": "denied",
      "match": { "channel": "*" }
    }
  ]
}
```

> ⚠️ 注意 binding 顺序：具体路由规则必须在 `"channel": "*"` 兜底规则之前。

### 五个常见误区

| 误区 | 说明 | 正确做法 |
|------|------|---------|
| **只做 Workspace 隔离不做运行时隔离** | Workspace 隔离只是数据边界，exec 仍在宿主机裸跑 | 配合 `sandbox.mode` 启用运行时隔离 |
| **误把 `tools.deny` 当完整安全方案** | `tools.deny` 是前置准入控制，不管运行时行为 | 搭配 Exec Sandbox + Browser Sandbox 构成纵深防御 |
| **多 Agent 共用浏览器 profile** | Cookie/缓存/登录态跨 Agent 串扰，导致数据泄漏 | 每个 Agent 使用独立的 Browser Sandbox 实例 |
| **将 `binds` 误解为唯一可见路径** | `binds` 控制的是挂载到容器内的路径，但容器本身可能有其他可见路径 | 结合 Workspace 隔离 + Sandbox binds 双重约束 |
| **忽略 `scope: "shared"` 对 per-agent 配置的影响** | `scope: "shared"` 会将某些配置在所有 Agent 间共享，覆盖 per-agent 设定 | 需要独立配置时使用 `scope: "agent"`，仅共享通用配置时用 `shared` |

---

## 10. 延伸阅读

- [OpenClaw Multi-Agent 文档](https://docs.openclaw.ai/concepts/multi-agent) — 完整的多 Agent API 参考
- [Agent Builder Skill](https://clawhub.ai/skills/agent-builder) — 辅助设计多 Agent 架构的 Skill

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [12-架构与原理（进阶）](./12-OpenClaw%20架构与原理（进阶）.md) |
