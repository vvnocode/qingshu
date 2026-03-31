+++
date = '2026-03-15T10:50:00+08:00'
draft = false
title = 'OpenClaw Memory：让 AI 越用越聪明'
tags = ['OpenClaw', 'AI', 'Agent', 'Memory']
+++

# OpenClaw Memory：持久记忆系统

本篇讲解 OpenClaw 的两层记忆架构、Memory 写入规范、EOD 自动补记以及多 Agent 环境下的记忆管理。

---

## 1. Memory 是什么

Memory 是 OpenClaw 的持久化上下文系统。每次对话、完成任务后，Agent 将关键信息写入 Memory 文件。下次对话时读取这些记录，恢复之前的上下文。

随着使用时间增长，Agent 的回复会更贴合工作场景，根本原因在于**积累了越来越多关于你的工作记录**，而非模型本身在进化。

---

## 2. 两层记忆架构

OpenClaw 的 Memory 分为两层，各司其职：

### 2.1 MEMORY.md —— 长期记忆（策展记忆）

- **文件位置**：`<workspace>/MEMORY.md`（workspace 路径由 `openclaw.json` 中的 `workspace` 字段决定）
- **注入方式**：每次新会话开始时，**自动注入**到 System Prompt 中
- **适合存储**：核心偏好、长期决策、重要配置变更

```markdown
<!-- MEMORY.md 示例 -->
## 用户偏好
- 用户喜欢简洁的回复风格，不要过多寒暄
- 代码注释使用中文
- 日报格式：Markdown 表格，按项目分组

## 关键决策
- 2026-03-01：项目A 从 MySQL 迁移到 PostgreSQL，原因是需要 JSONB 支持
- 2026-03-05：统一使用 pnpm 代替 npm

## 配置记录
- Slack Webhook 地址：https://hooks.slack.com/xxx（2026-03-08 更新）
```

### 2.2 memory/YYYY-MM-DD.md —— 每日记忆

- **文件位置**：`<workspace>/memory/2026-03-10.md`
- **注入方式**：**不自动注入**，通过 `memory_search` 工具按需检索
- **适合存储**：每日工作事项、临时交办、阶段性记录

```markdown
<!-- memory/2026-03-10.md 示例 -->
## 2026-03-10 工作记录

### 完成事项
- 帮用户生成了项目A的周报，输出到 outputs/weekly-report-0310.md
- 修复了钉钉消息推送的格式问题（换行符需要用 \n\n）

### 待跟进
- 用户提到下周要做性能压测，需要准备测试脚本

### 学到的知识
- 项目A 的测试环境地址是 test.example.com
- 部署脚本在 /home/deploy/scripts/deploy.sh
```

### 2.3 两层记忆对比

| 维度 | MEMORY.md | memory/YYYY-MM-DD.md |
|------|-----------|----------------------|
| 文件位置 | Workspace 根目录 | `memory/` 子目录 |
| 注入方式 | 每次会话**自动注入** | 通过 `memory_search` **按需检索** |
| Token 开销 | 每次都消耗 Token | 仅检索时消耗 |
| 适合存什么 | 核心偏好、长期决策、身份认知 | 每日事项、临时交办、阶段性记录 |
| 定位 | 常驻上下文，每次会话必定加载 | 按需检索的历史归档 |

> 📌 **关于 Memory 插件**：Memory 功能由内置的 `memory-core` 插件提供。可通过 `plugins.slots.memory = "none"` 禁用 memory 插件。

---

## 3. Memory 记什么

### 应该记录 ✅

| 类别 | 示例 |
|------|------|
| **决策及理由** | "选择 PostgreSQL 是因为需要 JSONB 支持" |
| **配置变更** | "Webhook 地址更新为 https://xxx" |
| **交付物** | "周报输出到 outputs/weekly-report.md" |
| **故障修复** | "钉钉换行需要用 \\n\\n 而不是 \\n" |
| **用户偏好** | "用户不喜欢表情符号" |

### 不应记录 ❌

| 类别 | 原因 |
|------|------|
| **对话流水账** | "用户问了什么，我回了什么"——这是 Session 的事 |
| **中间推理步骤** | "我先试了方案A不行，又试了方案B"——只记结论 |
| **重复常规操作** | "帮用户查了天气"——除非包含重要偏好 |

> 🎯 **判断标准**：如果这条信息在**三天后**依然有参考价值，就值得记录。否则不要记。

---

## 4. Memory Discipline 硬规则

为了让 Memory 系统高效运转，**每个 Agent 的 AGENTS.md 中必须写入以下硬规则**。实际写入 AGENTS.md 的标准英文模板请参见 [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) 第 1.1 节，以下为中文解读版本：

```markdown
## Memory Discipline (Hard Rule)

1. 任何包含决策、配置变更或交付物的任务，完成后必须立即写入 memory/YYYY-MM-DD.md
2. **禁止在 Memory 写入之前回复"已完成/done/completed"**——先记录，再回复
3. 核心偏好和长期决策 → 写入 MEMORY.md
4. 当日工作事项和临时信息 → 写入 memory/YYYY-MM-DD.md
5. 不要记录对话流水账和中间推理步骤
6. 每条记录必须包含日期和上下文，方便后续检索
7. 定期审查 MEMORY.md，合并重复项，删除过时信息
```

### 为什么需要硬规则？

LLM 本身没有"主动记录"的意识。如果不在 AGENTS.md 中明确要求"干完活要记笔记"，它就不会主动写入 Memory。硬规则确保每次有价值的信息不会丢失。

---

## 5. 优化实践

### 5.1 只记关键信息

Memory 不是垃圾桶。每条记录都应该对未来的对话有帮助。写之前问自己：

- "如果我是另一个 Agent，看到这条记录，能从中获得有价值的信息吗？"
- "三天后还有用吗？"

### 5.2 去重与合并

随着时间推移，MEMORY.md 会越来越长。定期让 Agent 审查并合并：

- 多次记录的相同偏好 → 合并为一条
- 已过时的信息（如旧的 API 地址） → 删除或标记为废弃
- 冲突的记录 → 保留最新的

### 5.3 Token 控制

MEMORY.md 每次会话都会注入，因此**它越长，Token 消耗越大**。建议：

- MEMORY.md 控制在 **50-100 行以内**
- 单日记忆文件（memory/YYYY-MM-DD.md）也控制在 **50-100 行以内**
- 详细的输出内容（如完整报告）放 `outputs/` 目录，Memory 中只记录文件路径

### 5.4 memory_search 使用技巧

`memory_search` 是检索每日记忆的唯一方式。Agent 会基于语义搜索匹配相关记录。

- 搜索时使用**具体的关键词**，如"PostgreSQL 迁移"而不是"数据库"
- 如果需要查找特定日期的记录，可以指定日期范围
- 搜索结果会返回最相关的片段，而不是整个文件

---

## 6. EOD 自动补记机制

EOD（End of Day）自动补记是一个**让 Agent 每天自动回顾并记录当日工作**的机制。

### 6.1 工作原理

1. 每天 **00:10**（可自定义），通过 Cron 任务触发
2. **Main Agent** 收到触发信号
3. Main Agent 向各个 Configured Agent 发送"请回顾今天的工作并补充 Memory"的指令
4. 各 Agent 检查当日的会话记录，提取关键信息写入 `memory/YYYY-MM-DD.md`

### 6.2 配置方式

#### 方式一：让 Main Agent 创建（推荐）

直接在对话中给 Main Agent 下指令：

```
请创建一个每天 00:10（Asia/Shanghai）触发的 EOD cron 任务；如果已有同类任务（用于前一天 memory 补记 / EOD backfill 的 00:10 cron），则直接更新该任务而不是重复创建。

触发时请执行：
1. 先补全 Main 本地 memory/<target_date>.md（target_date=昨天，格式为 YYYY-MM-DD）；
2. 逐个通知所有活跃 Sub-Agent，并且使用下面这段固定模板原文下发（不要改写）；
3. 下发时必须显式带上 target_date（例如 2026-02-15）；
4. 最后必须向用户发送一条汇总消息，说明完成状态。

创建或更新成功后返回 jobId。

固定模板：
End-of-day memory backfill (Asia/Shanghai, target_date={{target_date}}):
1) Open file memory/{{target_date}}.md.
2) Review completed tasks for that target_date in this session/workspace.
3) Append only missing important items (decisions/config changes/deliverables/incidents).
4) Merge duplicates and keep concise.
5) If the target_date memory is complete, do nothing.
```

#### 方式二：手动配置 Cron JSON（进阶）

> Cron 的完整语法和更多场景示例参见 [09-自动化：Cron 与 Heartbeat](./09-OpenClaw%20自动化：Cron%20与%20Heartbeat.md)。

在 Agent 配置中添加 Cron 任务：

```json
{
  "name": "Global EOD Trigger",
  "sessionTarget": "main",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "10 0 * * *",
    "tz": "Asia/Shanghai"
  },
  "payload": {
    "kind": "systemEvent",
    "text": "【EOD触发】现在是00:10，请执行前一天补记流程。先计算target_date=昨天（YYYY-MM-DD）；先补全Main本地memory/<target_date>.md；随后逐个通知所有活跃Sub-Agent，并原文下发以下模板（不得改写，且附带同一个target_date）：\n\nEnd-of-day memory backfill (Asia/Shanghai, target_date={{target_date}}):\n1) Open file memory/{{target_date}}.md.\n2) Review completed tasks for that target_date in this session/workspace.\n3) Append only missing important items (decisions/config changes/deliverables/incidents).\n4) Merge duplicates and keep concise.\n5) If the target_date memory is complete, do nothing.\n\n最后汇总完成状态。"
  }
}
```

> ⚠️ 当 `sessionTarget` 为 `main` 时，`payload.kind` **必须**设为 `"systemEvent"`，否则 Cron 可能不触发或行为异常。

#### 方案 A/B 本质等价

上述两种配置方式（方式一：让 Main 自己创建 vs 方式二：手动配置 JSON）**本质等价**——最终都会在调度层生成相同的 Cron 配置。区别在于：

| 维度 | 方式一（让 Main 创建） | 方式二（手动 JSON） |
|------|----------------------|-------------------|
| 适用场景 | 快速试用、不熟悉 JSON 格式 | 精确控制、团队统一配置 |
| 可审计性 | 依赖 Main 执行日志 | JSON 可版本控制、Code Review |
| 推荐场景 | 个人使用、首次搭建 | 生产环境、多人协作 |

#### 为什么选 00:10 而不是 23:59？

- **覆盖临界时段**：23:50~00:00 之间仍可能有工作产出，选 00:10 能将这段"尾巴"纳入当日补记
- **降低漏记风险**：如果选 23:59，Agent 可能在执行过程中跨越日期边界，导致日期混乱
- **单次日触发简洁**：00:10 只触发一次，无需处理"当天补记 + 次日预览"的复杂逻辑

### 6.3 EOD 标准补记指令模板

以下为标准化的 EOD 补记指令文本（此模板由 Main 原文下发给所有 Sub-Agent，不得改写）：

```
End-of-day memory backfill (Asia/Shanghai, target_date={{target_date}}):
1) Open file memory/{{target_date}}.md.
2) Review completed tasks for that target_date in this session/workspace.
3) Append only missing important items (decisions/config changes/deliverables/incidents).
4) Merge duplicates and keep concise.
5) If the target_date memory is complete, do nothing.
```

### 6.4 `{{target_date}}` 占位符解析机制

`{{target_date}}` 是 OpenClaw Cron 调度器内置的**模板变量**，在触发时由调度器自动替换为**前一天的日期**（格式 `YYYY-MM-DD`）。

| 变量 | 解析方 | 值 | 示例 |
|------|--------|-----|------|
| `{{target_date}}` | Cron 调度器 | 触发时刻的**前一天**日期 | 00:10 触发 → 值为前一天日期 |
| `{{now}}` | Cron 调度器 | 触发时刻的当前日期时间 | 2026-03-15T00:10:00 |

> ⚠️ **必须显式使用 `{{target_date}}`**
>
> 如果不使用此占位符而让 Agent 自行判断日期，Agent 可能会使用当前日期（00:10 已经是新的一天）而非前一天的日期，导致记录到错误的文件中。
>
> 正确做法：在 payload 中使用 `{{target_date}}` 占位符，调度器会自动替换为前一天的日期。

---

## 7. 多 Workspace 记忆管理

当你有多个 Agent（Multi-Agent 架构）时，Memory 管理需要遵循以下原则。

### 为什么需要这些规则？

多 Agent + 多 Workspace 时，记忆系统容易出现三类故障：

1. **漏记**：任务完成了，但当天 `memory/*.md` 没有补记
2. **串写**：Main 或其他 Agent 错误地写入了别人 Workspace 的 memory
3. **假一致**：Main 以为"都记了"，但子工作区的 memory 实际是空的

这些问题**不是"模型更聪明"能解决的**，必须靠制度化的硬规则约束。

### 7.1 责任边界

- **Main Agent 负责调度，不代写 Memory**——Main Agent 可以告诉其他 Agent "请记录今天的工作"，但不应该替它们写 Memory
- **每个 Agent 只写自己的 Memory**——DingTalk Agent 不应该写到 Main Agent 的 Memory 里，反之亦然

### 7.2 规则本地化

**每个 Workspace 的 AGENTS.md 都要加上 Memory Discipline 规则**。

不要以为在 Main Agent 的 AGENTS.md 里写了规则，其他 Agent 就会自动遵守。每个 Agent 只读自己 Workspace 里的 AGENTS.md。

### 7.3 常见误区

| 误区 | 正确做法 |
|------|---------|
| ❌ 只在 Main Agent 加 Memory Discipline 规则 | ✅ 每个 Agent 的 AGENTS.md 都要加 |
| ❌ Main Agent 代替其他 Agent 写 Memory | ✅ Main 只调度，让各 Agent 自己写 |
| ❌ EOD Cron 不传 `target_date` | ✅ 必须显式传前一天日期 |
| ❌ 所有信息都往 MEMORY.md 塞 | ✅ 核心偏好放 MEMORY.md，日常事项放 `memory/*.md` |
| ❌ Memory 从不清理 | ✅ 定期审查、去重、合并 |

### 7.4 验收标准

搭建完 Multi-Agent Memory 体系后，可以用以下标准检查：

- [ ] 每个 Agent 的 AGENTS.md 都包含 Memory Discipline 规则
- [ ] 每个 Agent 都能正确写入自己的 MEMORY.md 和 `memory/*.md`
- [ ] EOD Cron 配置正确，传入了 `target_date`
- [ ] MEMORY.md 行数在合理范围内（50-100 行）
- [ ] `memory_search` 能正确检索到历史记录
- [ ] Main Agent 不会越权写其他 Agent 的 Memory

### 7.5 每日运行验收

EOD 机制上线后，每天应做以下运行层面的检查：

1. **Main 补记检查**：Main 的 `memory/<target_date>.md` 是否出现 EOD 补记内容
2. **Sub-Agent 同步检查**：每个 Sub-Agent 同一日期的 `memory/<target_date>.md` 是否已更新
3. **质量抽查**：是否出现明显的重复条目或流水账式记录（违反 Memory Discipline 规则）

> 💡 建议前两周每日人工抽查一次；稳定后可改为每周抽检。

---

## 8. 进阶：记忆搜索与优化

### 向量记忆搜索（Vector Memory Search）

>[官方文档：Vector Memory Search](https://docs.openclaw.ai/concepts/memory#vector-memory-search)

OpenClaw 可以在 `MEMORY.md` 和 `memory/*.md` 上构建向量索引，实现语义搜索——即使措辞不同也能找到相关笔记。

**配置方式**（在 `~/.openclaw/openclaw.json` 中）：

```json5
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "gemini",      // 或 "openai" / "voyage" / "mistral" / "ollama" / "local"
        "model": "gemini-embedding-001",
        "remote": {
          "apiKey": "YOUR_API_KEY"
        }
      }
    }
  }
}
```

**Provider 自动选择优先级**（未显式配置时）：
1. Mistral（如果有 Mistral key）
2. Voyage（如果有 Voyage key）
3. Gemini（如果有 Gemini key）
4. OpenAI（如果有 OpenAI key）
5. Local（本地 GGUF 模型，需 node-llama-cpp）

**本地模式**：设置 `provider: "local"` 使用本地 GGUF 嵌入模型（约 0.6 GB），无需网络。

### 混合检索（Hybrid Search）

>[官方文档：Hybrid Search](https://docs.openclaw.ai/concepts/memory#hybrid-search-bm25-%2B-vector)

OpenClaw 支持 BM25 关键词检索 + 向量语义检索的混合模式，兼顾精确匹配和语义理解：

- **BM25**：擅长精确匹配（错误码、变量名、ID 等）
- **向量**：擅长语义匹配（"防抖文件更新" vs "避免每次写入都索引"）

```json5
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "query": {
          "hybrid": {
            "enabled": true,
            "vectorWeight": 0.7,
            "textWeight": 0.3
          }
        }
      }
    }
  }
}
```

### 时间衰减（Temporal Decay）

日积月累的每日笔记会越来越多。时间衰减让旧记忆的排名自然下降，优先浮现最新内容：

- 今天的笔记：100% 原始得分
- 7 天前：约 84%
- 30 天前：50%（半衰期）
- 90 天前：12.5%

`MEMORY.md` 和非日期命名的文件（如 `memory/projects.md`）不受衰减影响——它们是"常青"知识。

```json5
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "query": {
          "hybrid": {
            "temporalDecay": {
              "enabled": true,
              "halfLifeDays": 30
            }
          }
        }
      }
    }
  }
}
```

### 自动记忆刷新（Pre-Compaction Flush）

>[官方文档：Automatic memory flush (pre-compaction ping)](https://docs.openclaw.ai/concepts/memory#automatic-memory-flush-pre-compaction-ping)

当会话接近上下文压缩（compaction）阈值时，OpenClaw 会自动触发一个静默的提醒轮次，让模型将持久记忆写入磁盘，避免重要信息因 compaction 而丢失。

```json5
{
  "agents": {
    "defaults": {
      "compaction": {
        "memoryFlush": {
          "enabled": true,
          "softThresholdTokens": 4000
        }
      }
    }
  }
}
```

此过程对用户透明——模型通常回复 `NO_REPLY`，用户不会看到这个轮次。

---

## 9. 常见问题排查

| 问题 | 可能原因 | 解决方法 |
|------|---------|---------|
| Agent 不写 Memory | AGENTS.md 中缺少 Memory Discipline 规则 | 在 AGENTS.md 中添加第 4 节的硬规则模板 |
| Memory 写入了错误日期的文件 | EOD Cron 未使用 `{{target_date}}` 占位符 | 使用 `{{target_date}}` 代替让 Agent 自行判断日期 |
| `memory_search` 返回空 | 向量索引未构建或 Embedding 模型未配置 | 检查 `memorySearch.provider` 配置，确认 API Key 有效 |
| `memory_search` 结果不相关 | 搜索关键词过于宽泛 | 使用具体的关键词（如"PostgreSQL 迁移"而不是"数据库"） |
| MEMORY.md 越来越长导致 Token 激增 | 未定期清理和合并 | 让 Agent 定期审查 MEMORY.md，合并重复项，控制在 50-100 行 |
| Main Agent 写入了其他 Agent 的 Memory | 未遵守跨 Agent 隔离规则 | 在每个 Agent 的 AGENTS.md 中添加 "只写自己 Workspace 的 Memory" 规则 |
| 向量索引构建失败 | Embedding 模型 API Key 失效或网络不通 | 检查 `memorySearch.remote.apiKey`，或切换到本地模式（`provider: "local"`） |

---

## 10. 延伸阅读

- [03-OpenClaw 核心概念与配置](./03-OpenClaw%20核心概念与配置.md) —— 回顾 Workspace 目录结构
- [11-Multi-Agent：多智能体协作](./11-OpenClaw%20Multi-Agent：多智能体协作.md) —— 了解 Multi-Agent 架构
- [09-自动化：Cron 与 Heartbeat](./09-OpenClaw%20自动化：Cron%20与%20Heartbeat.md) —— 深入了解 Cron 配置
- [OpenClaw 官方文档：memory]([https://docs.openclaw.ai](https://docs.openclaw.ai/concepts/memory))

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [06-大模型配置与费用优化](./06-OpenClaw%20大模型配置与费用优化.md) |
