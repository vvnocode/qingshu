+++
date = '2026-03-15T11:00:00+08:00'
draft = false
title = 'OpenClaw 大模型配置与费用优化'
tags = ['OpenClaw', 'AI', 'Agent', '大模型']
+++

# OpenClaw 大模型配置与费用优化

本篇覆盖模型配置方法、国内主流模型对比、多 Agent 模型分配策略和费用控制。本篇是模型配置的完整参考，[02-安装与部署](./02-OpenClaw%20安装与部署.md) 第 6 节的快速配置为本篇的子集。

---

## 1. 模型配置基础

### 1.1 模型引用格式

OpenClaw 中引用模型时，使用 `provider/model-id` 的格式：

```
bailian/kimi-k2.5            # 百炼平台聚合的 Kimi 模型（推荐主力）
bailian/glm-5                # 百炼平台聚合的智谱 GLM-5（推荐执行型）
bailian/MiniMax-M2.5         # 百炼平台聚合的 MiniMax（推荐轻量/兜底）
bailian/qwen3.5-plus         # 百炼平台上的通义千问
```

其中 `provider` 是模型供应商/平台的标识，`model-id` 是该平台上具体模型的名称。

### 1.2 认证方式

OpenClaw 支持多种认证方式连接模型：

| 认证方式 | 适用场景 | 说明 |
|---------|---------|------|
| **OAuth 登录** | 通过浏览器登录模型提供商 | 适合个人使用，无需管理 API Key |
| **API Key** | 在 `openclaw.json` 中配置 | 企业推荐，便于统一管理 |
| **GitHub Copilot** | 已有 GitHub Copilot 订阅的用户 | 运行 `openclaw models auth login-github-copilot` 登录 |
| **环境变量** | 通过 `env` 字段或系统环境变量注入 | 适合 CI/CD 或自动化部署场景 |

### 1.3 设置默认模型

安装配置完成后，你可以通过命令设置全局默认模型：

```bash
openclaw models set bailian/kimi-k2.5
```

也可以在 `openclaw.json` 中手动指定：

```json
{
  "models": {
    "default": "bailian/kimi-k2.5"
  }
}
```

---

## 2. 国内主流模型对比

以下是截至 2026-03 国内主流大模型的对比（价格为按量计费参考价，实际以官网为准）：

| 模型                   | 提供商        | 推荐用途      | 上下文窗口 | 多模态  | 可通过百炼接入 | 特点            |
| -------------------- | ---------- | --------- | ----- | ---- | ------- | ------------- |
| **qwen3.5-plus**     | 阿里（通义千问）   | 综合任务、代码   | 1M    | ✅ 图片 | ✅       | 综合能力强，1M 上下文  |
| **qwen3-coder-plus** | 阿里（通义千问）   | 代码生成、技术任务 | 1M    | ❌    | ✅       | 代码专精，1M 上下文   |
| **qwen3-coder-next** | 阿里（通义千问）   | 代码生成      | 256K  | ❌    | ✅       | 代码专精          |
| **kimi-k2.5**        | 月之暗面（Kimi） | 推理、长文分析   | 256K  | ✅ 图片 | ✅       | 推理能力强，长上下文表现好 |
| **glm-5**            | 智谱 AI      | 综合任务      | ~200K | ❌    | ✅       | 国产老牌，生态成熟     |
| **MiniMax-M2.5**     | MiniMax    | 日常对话、轻量任务 | 192K  | ❌    | ✅       | 百炼包月下免费可用     |
| **DeepSeek-V3**      | 深度求索       | 综合任务      | 128K  | ❌    | ❌（硅基流动） | 性价比极高，开源可部署   |
| **DeepSeek-R1**      | 深度求索       | 深度推理      | 128K  | ❌    | ❌（硅基流动） | 推理能力强，价格低     |

> 💡 **OpenClaw 推荐三模型方案**：
> - **主力模型**：kimi-k2.5 — 推理能力强，支持图片输入，适合 Main Agent
> - **执行型模型**：glm-5 — 通用稳定，有 thinking 支持，适合标准化任务 Agent
> - **轻量/兜底模型**：MiniMax-M2.5 — 能力够用，适合 Denied Agent 和简单任务

---

## 3. 国内模型接入配置

### 3.1 阿里云百炼

百炼是阿里云的模型服务统一网关，聚合了 Qwen 系列及第三方模型（kimi-k2.5、MiniMax-M2.5、glm 系列等）。官方模型配置文档：[百炼模型配置](https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023085)

**第一步**：前往 [阿里云百炼控制台](https://bailian.console.aliyun.com/) 开通服务并获取 API Key。

**第二步**：在 `openclaw.json` 中添加模型配置：

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
            "id": "qwen3.5-plus",
            "name": "qwen3.5-plus",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 1000000,
            "maxTokens": 65536,
            "compat": { "thinkingFormat": "qwen" }
          },
          {
            "id": "qwen3-max-2026-01-23",
            "name": "qwen3-max-2026-01-23",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 262144,
            "maxTokens": 65536,
            "compat": { "thinkingFormat": "qwen" }
          },
          {
            "id": "qwen3-coder-next",
            "name": "qwen3-coder-next",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 262144,
            "maxTokens": 65536
          },
          {
            "id": "qwen3-coder-plus",
            "name": "qwen3-coder-plus",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 1000000,
            "maxTokens": 65536
          },
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
            "compat": { "thinkingFormat": "qwen" }
          },
          {
            "id": "glm-4.7",
            "name": "glm-4.7",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 202752,
            "maxTokens": 16384,
            "compat": { "thinkingFormat": "qwen" }
          },
          {
            "id": "kimi-k2.5",
            "name": "kimi-k2.5",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 262144,
            "maxTokens": 32768,
            "compat": { "thinkingFormat": "qwen" }
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
        "bailian/kimi-k2.5": {},
        "bailian/glm-5": {},
        "bailian/MiniMax-M2.5": {},
        "bailian/qwen3.5-plus": {},
        "bailian/qwen3-max-2026-01-23": {},
        "bailian/qwen3-coder-next": {},
        "bailian/qwen3-coder-plus": {},
        "bailian/glm-4.7": {}
      }
    }
  },
  "gateway": {
    "mode": "local"
  }
}
```

字段说明：

| 字段 | 说明 |
|------|------|
| `mode` | 配置合并模式，`"merge"` 表示与默认配置合并 |
| `providers` | Provider 对象（key 为 provider ID） |
| `baseUrl` | API 请求地址（百炼 Coding 专用：`https://coding.dashscope.aliyuncs.com/v1`） |
| `api` | API 协议，百炼使用 `"openai-completions"` |
| `models[].id` | 模型 ID |
| `models[].reasoning` | 是否启用推理模式输出（thinking 通过 `compat.thinkingFormat` 控制） |
| `models[].input` | 支持的输入类型数组（如 `["text", "image"]`） |
| `models[].cost` | 费用对象：`input`/`output`/`cacheRead`/`cacheWrite`（百炼包月模式下均为 0） |
| `models[].contextWindow` | 上下文窗口大小（Token 数） |
| `models[].maxTokens` | 单次最大输出 Token 数 |
| `models[].compat` | 兼容性配置，如 `thinkingFormat: "qwen"` 用于 Qwen 系列的 thinking 格式 |

> ⚠️ 模型配置中**不要添加 `contextLength` 字段**，OpenClaw 不支持该键。应使用 `contextWindow` 字段。如果从其他平台复制了含 `contextLength` 的配置，请手动改为 `contextWindow`。

### 3.2 火山方舟 Coding Plan

字节跳动旗下的火山方舟提供 Coding Plan 套餐，Lite 版本 **9.9 元/月** 起，适合轻量级使用场景。具体接入方式与百炼类似，将 `baseUrl` 替换为火山方舟的 API 地址即可：

```
baseUrl: https://ark.cn-beijing.volces.com/api/v3
```

详情参见 [火山方舟官网](https://www.volcengine.com/product/ark)。

---

## 4. 费用优化策略

> ⚠️ **重要警告：不要用后付费（按量计费），用包月套餐！**
>
> Agent 会大量调用 API，一个简单任务可能消耗数千到数万 Token。后付费模式下，一天的使用可能产生**上百元费用**。包月套餐可以将成本控制在可预期范围内。

### 4.1 Token 消耗估算

>Token 是 AI 处理语言时使用的最小文本单位。一个汉字字、单词、标点、被拆分的单个图片小方块都是1个token。

理解 Token 消耗是控费的前提。以下是典型场景的 Token 估算：

| 使用场景 | 单次消耗（估算） | 说明 |
|---------|----------------|------|
| 简单问答 | 1,000 ~ 3,000 Token | 一问一答 |
| 带搜索的任务 | 3,000 ~ 8,000 Token | Agent 需要调用搜索工具 |
| 文档生成 | 5,000 ~ 15,000 Token | 生成长文档或报告 |
| 复杂多步骤任务 | 10,000 ~ 50,000 Token | Agent 多轮思考 + 多次工具调用 |
| 多 Agent 协作任务 | 50,000 ~ 100,000+ Token | 多个 Agent 轮流交互 |

假设你每天使用 20 次中等复杂度任务（每次约 5,000 Token），则每天消耗约 **10 万 Token**。按后付费价格估算，看起来不多——但如果有 10 个同事同时使用，每天就是 **100 万 Token**，一个月费用可能超预期。建议使用包月套餐控制成本。

### 4.2 包月套餐推荐

以下是几个主流的包月/套餐方案（截至 2026-03，以各平台官网为准）：

| 套餐                     | 价格         | 包含内容                  | 推荐场景       |
| ---------------------- | ---------- | --------------------- | ---------- |
| **阿里云百炼 Coding Plan**  | 40元/月起     | kimi-k2.5、glm-5、MiniMax-M2.5 等全部模型 | 企业推荐，一站式覆盖 |
| **Kimi Allegretto 套餐** | 49元/月起     | kimi-k2.5 大量 Token 额度 | 主力模型，推理任务多 |
| **火山方舟 Coding Plan**   | Lite 9.9元/月起，标准 40元/月起 | 基础模型额度                | 低预算场景      |

> 💡 **企业推荐**：让 IT 部门统一采购阿里云百炼或 Kimi 的包月套餐，按团队分配 API Key，统一管理费用。

### 4.3 日常省钱技巧

1. **简单任务用便宜模型**：不需要深度推理的任务（如格式化、翻译、简单问答），用 MiniMax-M2.5 即可
2. **控制上下文长度**：避免把大量无关内容塞进对话，保持提示精简
3. **善用 Memory**：让 Agent 记住常用信息，避免每次都重新说明
4. **合理拆分任务**：一个超复杂的提示不如拆成几个清晰的小任务
5. **设置 Token 上限**：在模型配置中设置 `maxTokens`，防止单次输出过长
6. **不要频繁切换模型**：频繁切换模型会导致无法命中厂商的缓存

---

## 5. 多 Agent 模型分配策略

多 Agent 架构中，不同角色的 Agent 对模型能力的要求不同。核心原则：**让聪明的模型做聪明的事，让便宜的模型做标准的事。**

### 5.1 分配策略

| Agent 角色 | 职责 | 推荐模型 | 原因 |
|------|------|------|------|
| **主协调 Agent（Main）** | 理解用户意图、拆解任务、分配工作、做决策 | bailian/kimi-k2.5 | 推理能力强，支持多模态 |
| **执行型 Agent** | 执行标准化任务（搜索、文件处理、格式化） | bailian/glm-5 | 通用稳定，有 thinking 支持 |
| **兜底 Agent（Denied）** | 拒绝未授权请求 | bailian/MiniMax-M2.5 | 只需返回固定回复，成本最低 |

### 5.2 配置示例

在 `openclaw.json` 的 `agents.list` 中，为每个 Agent 指定不同的 `model`：

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "name": "Main Agent",
        "model": "bailian/kimi-k2.5",
        "workspace": "~/.openclaw/workspace"
      },
      {
        "id": "search-agent",
        "name": "搜索执行 Agent",
        "model": "bailian/glm-5",
        "workspace": "~/.openclaw/workspace-search-agent",
        "tools": { "allow": ["read", "web_search", "memory_search"] }
      },
      {
        "id": "report-agent",
        "name": "报告生成 Agent",
        "model": "bailian/glm-5",
        "workspace": "~/.openclaw/workspace-report-agent"
      },
      {
        "id": "denied",
        "name": "Denied Agent",
        "model": "bailian/MiniMax-M2.5",
        "workspace": "~/.openclaw/workspace-denied"
      }
    ]
  }
}
```

Main Agent 使用推理能力最强的 kimi-k2.5，执行型 Agent 使用通用稳定的 glm-5，Denied Agent 使用最轻量的 MiniMax-M2.5，按需分配控制成本。

### 5.3 使用 primary + fallbacks 结构

建议为每个 Agent 配置 `model` 时使用 `primary` + `fallbacks` 结构，提升可用性：

```json
{
  "id": "main",
  "name": "Main Agent",
  "model": {
    "primary": "bailian/kimi-k2.5",
    "fallbacks": ["bailian/glm-5", "bailian/MiniMax-M2.5"]
  }
}
```

对高优先级节点（架构决策、最终审查），建议固定使用同一主模型，减少因模型切换导致的"结论漂移"——不同模型对相同问题的推理路径和结论可能不一致，频繁切换会导致决策不连贯。

---

## 6. 模型 Failover 机制

生产环境中，单一模型提供商可能出现**限流、宕机、额度耗尽**等问题。OpenClaw 提供了 Failover（故障转移）机制来保障可用性。

### 6.1 两阶段 Failover

| 阶段 | 机制 | 说明 |
|------|------|------|
| 第一阶段 | **Auth Profile 轮换** | 同一模型配置多个 API Key，一个 Key 限流后自动切换下一个 |
| 第二阶段 | **Model Fallback** | 主模型不可用时，自动切换到备用模型 |

### 6.2 Fallback 配置示例

```json5
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "bailian/kimi-k2.5",
        "fallbacks": ["bailian/glm-5", "bailian/MiniMax-M2.5"]
      }
    }
  }
}
```

这个配置表示：
1. 默认使用 kimi-k2.5 作为主力模型
2. 如果 kimi-k2.5 限流或出错，自动切换到 glm-5
3. 如果 glm-5 也不可用，再切到 MiniMax-M2.5

> ⚠️ **注意**：三个模型都通过百炼网关接入，共享同一个 Provider。如果需要更高可用性，可以额外配置其他 Provider（如火山方舟）作为跨平台 Fallback。

### 6.3 如何验证实际运行的模型？

使用 Failover 后，必须区分两个概念：

| 概念 | 含义 | 来源 |
|------|------|------|
| **配置模型** | `openclaw.json` 中 `agents.list[].model` 写的值 | 配置文件 |
| **实际运行模型** | 日志中 `embedded run start` 记录的实际 provider/model | Gateway 日志 |

当 provider 冷却/限流时会触发自动回退。如果不做区分，容易将 provider 回退误判为"配置失效"。

**验证方法**：对比 `openclaw.json` 中的配置与 Gateway 日志中实际使用的模型。在日志中搜索 `embedded run start` 关键字即可查看每次请求实际调用了哪个 provider 和 model。

---

## 7. 费用监控建议

| 监控手段 | 说明 |
|---------|------|
| **各平台控制台** | 定期查看阿里云百炼等平台的用量统计面板 |
| **OpenClaw Dashboard** | 在 Web Dashboard 中查看各 Agent 的调用次数和 Token 消耗 |
| **设置用量告警** | 在模型平台设置日/月用量上限，超出时自动告警或停止服务 |
| **定期审计** | 每月 Review 各 Agent 的模型使用情况，淘汰不必要的调用 |

建议指定一位同事负责每月查看费用报表，确保费用在预算范围内。

---

## 8. 延伸阅读

- [百炼官方模型配置文档](https://bailian.console.aliyun.com/cn-beijing/?tab=doc#/doc/?type=model&url=3023085) — 百炼支持的模型列表与配置参数
- [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) — 理解 Agent、Workspace 等基础概念
- [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) — 配置变更规范和安全加固
- [07-实战案例](./07-OpenClaw%20实战案例.md) — 非开发场景的落地案例
- [11-Multi-Agent：多智能体协作](./11-OpenClaw%20Multi-Agent：多智能体协作.md) — 多 Agent 架构设计详解
- [阿里云百炼官方文档](https://help.aliyun.com/product/2400256.html)
- [Kimi 开放平台](https://platform.moonshot.cn/)（如链接变更请访问 [kimi.moonshot.cn](https://kimi.moonshot.cn)）
- [OpenClaw 如何免费切换到 MiniMax M2.5:cloud 模型](https://member.pathunfold.com/c/7c8b60/openclaw-minimax-m2-5-cloud)（第三方教程，链接如失效请搜索 "OpenClaw MiniMax M2.5"）
- [Ollama 本地部署 MiniMax-M2.5](https://ollama.com/library/minimax-m2.5)

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [05-Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [07-实战案例](./07-OpenClaw%20实战案例.md) |
