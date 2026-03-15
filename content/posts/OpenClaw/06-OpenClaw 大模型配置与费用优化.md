+++
date = '2026-03-15T00:06:00+08:00'
draft = false
title = 'OpenClaw 大模型配置与费用优化'
tags = ['OpenClaw', 'LLM', '优化']
+++

## 本章导读

> **这篇文档回答以下问题：**
>
> 1. 大模型怎么配？在 OpenClaw 里配置一个模型需要哪些信息？
> 2. 多 Agent 下聪明模型和便宜模型怎么配合？
> 3. 怎么控制费用？Agent 一天调几百次 API，账单会不会吓人？

---

## 1. 模型配置基础

### 1.1 模型引用格式

OpenClaw 中引用模型时，使用 `provider/model-id` 的格式：

```
bailian/qwen3.5-plus        # 阿里云百炼平台上的通义千问
siliconflow/deepseek-v3      # 硅基流动上的 DeepSeek
kimi/kimi-k2.5               # Kimi 模型
openai/gpt-4o                # OpenAI GPT-4o
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
openclaw models set bailian/qwen3.5-plus
```

也可以在 `openclaw.json` 中手动指定：

```json
{
  "models": {
    "default": "bailian/qwen3.5-plus"
  }
}
```

---

## 2. 国内主流模型对比

以下是截至目前国内主流大模型的对比（价格为按量计费参考价，实际以官网为准）：

| 模型 | 提供商 | 推荐用途 | 上下文窗口 | 多模态 | 接入平台 | 特点 |
|------|--------|---------|-----------|--------|---------|------|
| **qwen3.5-plus** | 阿里（通义千问） | 综合任务、代码 | 128K | ✅ 图片/文件 | 百炼平台 | 综合能力强，国内接入最方便 |
| **qwen3-coder** | 阿里（通义千问） | 代码生成、技术任务 | 128K | ❌ | 百炼平台 | 代码专精，性价比高 |
| **kimi-k2.5** | 月之暗面（Kimi） | 推理、长文分析 | 128K | ✅ 图片 | Kimi API | 推理能力强，长上下文表现好 |
| **glm-5** | 智谱 AI | 综合任务 | 128K | ✅ 图片 | 智谱开放平台 | 国产老牌，生态成熟 |
| **DeepSeek-V3** | 深度求索 | 综合任务 | 128K | ❌ | 硅基流动/官方 | 性价比极高，开源可部署 |
| **DeepSeek-R1** | 深度求索 | 深度推理 | 128K | ❌ | 硅基流动/官方 | 推理能力接近 o1，价格仅为 1/10 |
| **MiniMax-M2.5** | MiniMax | 日常对话、轻量任务 | 128K | ✅ 图片 | MiniMax 平台 | **免费可用**，适合兜底 |

> 💡 **选型建议**：
> - **日常使用**：qwen3.5-plus 或 kimi-k2.5（能力强，上手快）
> - **追求性价比**：DeepSeek-V3（便宜且能力不差）
> - **需要推理**：DeepSeek-R1 或 kimi-k2.5
> - **零成本体验**：MiniMax-M2.5（免费）

---

## 3. 国内模型接入配置

### 3.1 阿里云百炼

阿里云百炼是接入通义千问系列模型最直接的方式。

**第一步**：前往 [阿里云百炼控制台](https://bailian.console.aliyun.com/) 开通服务并获取 API Key。

**第二步**：在 `openclaw.json` 中添加模型配置：

```json
{
  "models": {
    "default": "bailian/qwen3.5-plus",
    "providers": [
      {
        "id": "bailian",
        "name": "阿里云百炼",
        "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx",
        "models": [
          {
            "id": "qwen3.5-plus",
            "name": "通义千问3.5 Plus",
            "reasoning": true,
            "input": 0.004,
            "contextWindow": 131072,
            "maxTokens": 16384
          },
          {
            "id": "qwen3-coder",
            "name": "通义千问3 Coder",
            "reasoning": false,
            "input": 0.002,
            "contextWindow": 131072,
            "maxTokens": 16384
          }
        ]
      }
    ]
  }
}
```

字段说明：

| 字段 | 说明 |
|------|------|
| `id` | Provider 标识，在模型引用中使用（如 `bailian/qwen3.5-plus`） |
| `baseUrl` | API 请求地址 |
| `apiKey` | 你的 API 密钥 |
| `models[].id` | 模型 ID |
| `models[].name` | 模型显示名称 |
| `models[].reasoning` | 是否为推理模型（支持 chain-of-thought） |
| `models[].input` | 输入价格（元/千 Token，仅供参考） |
| `models[].contextWindow` | 上下文窗口大小（Token 数） |
| `models[].maxTokens` | 单次最大输出 Token 数 |

> ⚠️ 模型配置中**不要添加 `contextLength` 字段**，OpenClaw 不支持该键。应使用 `contextWindow` 字段。如果从其他平台复制了含 `contextLength` 的配置，请手动改为 `contextWindow`。

### 3.2 硅基流动

硅基流动聚合了多个开源模型，部分模型**免费**，适合低成本方案。

```json
{
  "env": {
    "SILICONFLOW_API_KEY": "sk-xxx"
  },
  "models": {
    "providers": [
      {
        "id": "siliconflow",
        "name": "硅基流动",
        "baseUrl": "https://api.siliconflow.cn/v1",
        "apiKey": "${SILICONFLOW_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "deepseek-ai/DeepSeek-V3",
            "name": "DeepSeek V3",
            "reasoning": false,
            "contextWindow": 131072,
            "maxTokens": 16384
          },
          {
            "id": "deepseek-ai/DeepSeek-R1",
            "name": "DeepSeek R1",
            "reasoning": true,
            "contextWindow": 131072,
            "maxTokens": 16384
          }
        ]
      }
    ]
  }
}
```

> 💡 硅基流动注册后会赠送免费额度，部分小模型永久免费，适合测试和兜底 Agent。

### 3.3 火山方舟 Coding Plan

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

理解 Token 消耗是控费的前提。以下是典型场景的 Token 估算：

| 使用场景 | 单次消耗（估算） | 说明 |
|---------|----------------|------|
| 简单问答 | 1,000 ~ 3,000 Token | 一问一答 |
| 带搜索的任务 | 3,000 ~ 8,000 Token | Agent 需要调用搜索工具 |
| 文档生成 | 5,000 ~ 15,000 Token | 生成长文档或报告 |
| 复杂多步骤任务 | 10,000 ~ 50,000 Token | Agent 多轮思考 + 多次工具调用 |
| 多 Agent 协作任务 | 50,000 ~ 100,000+ Token | 多个 Agent 轮流交互 |

假设你每天使用 20 次中等复杂度任务（每次约 5,000 Token），则每天消耗约 **10 万 Token**。按 qwen3.5-plus 的后付费价格（0.004 元/千 Token），每天约 **0.4 元**，看起来不多——但如果有 10 个同事同时使用，每天就是 **100 万 Token / 4 元**，一个月就是 **120 元**。而如果使用更贵的模型或更复杂的任务，费用会成倍增长。

### 4.2 包月套餐推荐

以下是几个主流的包月/套餐方案：

| 套餐 | 价格 | 包含内容 | 推荐场景 |
|------|------|---------|---------|
| **Kimi Allegretto 套餐** | 约 39 元/月起 | kimi-k2.5 大量 Token 额度 | 主力模型，推理任务多 |
| **阿里云百炼 Coding Plan** | 按量级不同 | qwen 系列模型额度 | 企业统一采购 |
| **火山方舟 Coding Plan** | **Lite 9.9 元/月** 起 | 基础模型额度 | 低预算场景 |
| **硅基流动** | 部分模型**免费** | DeepSeek 等开源模型 | 零成本兜底 |

> 💡 **企业推荐**：让 IT 部门统一采购阿里云百炼或 Kimi 的包月套餐，按团队分配 API Key，统一管理费用。

### 4.3 日常省钱技巧

1. **简单任务用便宜模型**：不需要深度推理的任务（如格式化、翻译、简单问答），用 DeepSeek-V3 或 MiniMax-M2.5 即可
2. **控制上下文长度**：避免把大量无关内容塞进对话，保持提示精简
3. **善用 Memory**：让 Agent 记住常用信息，避免每次都重新说明
4. **合理拆分任务**：一个超复杂的提示不如拆成几个清晰的小任务
5. **设置 Token 上限**：在模型配置中设置 `maxTokens`，防止单次输出过长

---

## 5. 多 Agent 模型分配策略

多 Agent 架构中，不同角色的 Agent 对模型能力的要求不同。核心原则：**让聪明的模型做聪明的事，让便宜的模型做标准的事。**

### 5.1 分配策略

| Agent 角色 | 职责 | 推荐模型 | 原因 |
|------------|------|---------|------|
| **主协调 Agent（Main / Tech Lead）** | 理解用户意图、拆解任务、分配工作、做决策 | claude-opus-4-5、qwen3.5-plus、kimi-k2.5 | 需要强推理和复杂决策能力 |
| **执行型 Agent** | 执行标准化任务（搜索、文件处理、格式化） | gemini-flash、MiniMax-M2.5、DeepSeek-V3 | 任务明确，不需要复杂推理 |
| **兜底 Agent（Denied）** | 拒绝未授权请求 | gemini-3-flash-preview 或任意最便宜模型 | 只需要返回固定回复 |

### 5.2 配置示例

在 `openclaw.json` 的 `agents.list` 中，为每个 Agent 指定不同的 `model`：

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "name": "Main Agent",
        "model": "bailian/qwen3.5-plus",
        "workspace": "~/.openclaw/workspace"
      },
      {
        "id": "search-agent",
        "name": "搜索执行 Agent",
        "model": "siliconflow/deepseek-ai/DeepSeek-V3",
        "workspace": "~/.openclaw/workspace-search-agent",
        "tools": { "allow": ["read", "web_search", "memory_search"] }
      },
      {
        "id": "report-agent",
        "name": "报告生成 Agent",
        "model": "siliconflow/deepseek-ai/DeepSeek-V3",
        "workspace": "~/.openclaw/workspace-report-agent"
      },
      {
        "id": "denied",
        "name": "Denied Agent",
        "model": "siliconflow/deepseek-ai/DeepSeek-V3",
        "workspace": "~/.openclaw/workspace-denied"
      }
    ]
  }
}
```

这样，只有 Main Agent 使用较贵的 qwen3.5-plus，其余 Agent 统一使用便宜的 DeepSeek-V3，大幅降低整体成本。

### 5.3 使用 primary + fallbacks 结构

建议为每个 Agent 配置 `model` 时使用 `primary` + `fallbacks` 结构，提升可用性：

```json
{
  "id": "main",
  "name": "Main Agent",
  "model": {
    "primary": "bailian/qwen3.5-plus",
    "fallbacks": ["kimi/kimi-k2.5", "siliconflow/deepseek-v3"]
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
        "primary": "bailian/qwen3.5-plus",
        "fallbacks": ["kimi/kimi-k2.5", "siliconflow/deepseek-ai/DeepSeek-V3"]
      }
    }
  }
}
```

这个配置表示：
1. 默认使用百炼的 qwen3.5-plus
2. 如果百炼限流或出错，自动切换到 Kimi
3. 如果 Kimi 也不可用，再切到硅基流动的 DeepSeek-V3

> ⚠️ **企业建议**：至少配置**两个不同提供商**作为 Fallback，避免单点故障导致 Agent 全部停工。

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
| **各平台控制台** | 定期查看阿里云百炼、Kimi、硅基流动等平台的用量统计面板 |
| **OpenClaw Dashboard** | 在 Web Dashboard 中查看各 Agent 的调用次数和 Token 消耗 |
| **设置用量告警** | 在模型平台设置日/月用量上限，超出时自动告警或停止服务 |
| **定期审计** | 每月 Review 各 Agent 的模型使用情况，淘汰不必要的调用 |

建议指定一位同事负责每月查看费用报表，确保费用在预算范围内。

---

## 8. 延伸阅读

- [03-核心概念与配置](./03-OpenClaw%20核心概念与配置.md) — 理解 Agent、Workspace 等基础概念
- [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) — 配置变更规范和安全加固
- [07-实战案例](./07-OpenClaw%20实战案例.md) — 非开发场景的落地案例
- [11-Multi-Agent：多智能体协作](./11-OpenClaw%20Multi-Agent：多智能体协作.md) — 多 Agent 架构设计详解
- [阿里云百炼官方文档](https://help.aliyun.com/product/2400256.html)
- [Kimi 开放平台](https://platform.moonshot.cn/)（如链接变更请访问 [kimi.moonshot.cn](https://kimi.moonshot.cn)）
- [硅基流动](https://siliconflow.cn/)
- [OpenClaw 如何免费切换到 MiniMax M2.5:cloud 模型](https://member.pathunfold.com/c/7c8b60/openclaw-minimax-m2-5-cloud)（第三方教程，链接如失效请搜索 "OpenClaw MiniMax M2.5"）
- [Ollama 本地部署 MiniMax-M2.5](https://ollama.com/library/minimax-m2.5)
- 有问题？联系内部 AI 基础设施团队或在钉钉群内提问

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [05-Memory：让 AI 越用越聪明](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [07-实战案例](./07-OpenClaw%20实战案例.md) |
