+++
date = '2026-03-15T00:09:00+08:00'
draft = false
title = 'OpenClaw 自动化：Cron 与 Heartbeat'
tags = ['OpenClaw', '自动化', 'Cron']
+++

## 本章导读

> **这篇文档回答三个问题：**
>
> 1. Cron 和 Heartbeat 是什么？
> 2. 它们分别适合什么场景？
> 3. 怎么配置和使用？

OpenClaw 不只是"你问它答"的被动助手——它可以**按时自动执行任务**。

- **Cron**：定时任务，类比闹钟或日程表。"每天早上 8 点给我推送新闻摘要。"
- **Heartbeat**：周期巡检，类比保安巡逻或值班医生查房。"每 5 分钟检查一次服务状态。"
- **Hooks**：事件驱动，类比门铃或消防警报。"收到钉钉消息时自动分类处理。"

---

## 1. 自动化概览

OpenClaw 提供三种自动化方式：

| 机制 | 触发方式 | 类比 | 典型场景 |
|------|---------|------|---------|
| **Cron** | 精确时间点 | 闹钟 / 日程表 | 每天早上推送日报、每周一生成周报 |
| **Heartbeat** | 固定时间间隔 | 保安巡逻 / 查房 | 每 5 分钟检查服务状态、持续监控异常 |
| **Hooks** | 特定事件触发 | 门铃 / 消防警报 | 收到消息时分类、工具调用前审核 |

---

## 2. Cron 定时任务

### 概念

Cron 让 AI **按时间表自动执行任务**，无需人工触发。

就像你在手机上设置了一个"每天早上 8:00 提醒"的闹钟——**到了时间，Agent 自动开始工作**。

### Cron 表达式简介

Cron 使用五段式时间表达式：

```
┌───────────── 分钟 (0-59)
│ ┌───────────── 小时 (0-23)
│ │ ┌───────────── 日 (1-31)
│ │ │ ┌───────────── 月 (1-12)
│ │ │ │ ┌───────────── 星期几 (0-7, 0和7都是周日)
│ │ │ │ │
* * * * *
```

常用示例：

| 表达式 | 含义 |
|--------|------|
| `0 8 * * *` | 每天 08:00 |
| `0 8 * * 1-5` | 每个工作日 08:00 |
| `30 9 * * 1` | 每周一 09:30 |
| `0 */2 * * *` | 每 2 小时整点 |
| `10 0 * * *` | 每天 00:10 |
| `0 9 1 * *` | 每月 1 号 09:00 |

### 配置方式

#### 方式一：让 Agent 自己创建（推荐）

直接用自然语言告诉 Main Agent：

> "帮我创建一个定时任务，每天早上 8 点推送新闻摘要到钉钉群。"

Agent 会自动生成配置并注册。

#### 方式二：手动配置 JSON

在 Agent 配置文件中定义 Cron 任务：

```json
{
  "name": "morning-brief",
  "sessionTarget": "main",
  "schedule": {
    "kind": "cron",
    "expr": "0 8 * * 1-5",
    "tz": "Asia/Shanghai"
  },
  "payload": {
    "kind": "systemEvent",
    "text": "请执行以下任务：1. 查看今日新闻摘要 2. 整理成简报格式 3. 发送到钉钉工作群"
  }
}
```

字段说明：

| 字段 | 说明 |
|------|------|
| `name` | 任务名称（英文标识） |
| `sessionTarget` | 执行任务的目标 Agent ID |
| `schedule.kind` | 调度类型，固定为 `"cron"` |
| `schedule.expr` | Cron 表达式 |
| `schedule.tz` | 时区，推荐 `"Asia/Shanghai"` |
| `payload.kind` | 事件类型，`sessionTarget` 为 `main` 时**必须**设为 `"systemEvent"` |
| `payload.text` | 触发时发送给 Agent 的指令内容 |

### 典型场景与配置示例

#### 场景一：Morning Brief 早报（每天 08:00 推送）

```json
{
  "name": "morning-brief",
  "sessionTarget": "main",
  "schedule": {
    "kind": "cron",
    "expr": "0 8 * * 1-5",
    "tz": "Asia/Shanghai"
  },
  "payload": {
    "kind": "systemEvent",
    "text": "今日早报任务：1. 搜索今日科技新闻 2. 整理行业动态 3. 生成早报推送到钉钉群"
  }
}
```

#### 场景二：EOD Memory 补记（每天 00:10 执行）

EOD（End-of-Day）自动补记是 Memory 系统的重要组成部分，确保每日工作记录完整。完整的 EOD 配置、payload 结构和注意事项请参见 [05-Memory：让 AI 越用越聪明](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) 的"EOD 自动补记"章节。

简要配置示例：

```json
{
  "name": "Global EOD Trigger",
  "sessionTarget": "main",
  "schedule": { "kind": "cron", "expr": "10 0 * * *", "tz": "Asia/Shanghai" },
  "payload": { "kind": "systemEvent", "text": "End-of-day memory backfill..." }
}
```

> ⚠️ 当 Cron 的 `sessionTarget` 指向 `main` 时，`payload` 必须使用 `{ "kind": "systemEvent", "text": "..." }` 结构，否则可能不触发。

#### 场景三：定时数据采集（每小时执行一次）

```json
{
  "name": "hourly-data-collect",
  "sessionTarget": "main",
  "schedule": {
    "kind": "cron",
    "expr": "0 * * * *",
    "tz": "Asia/Shanghai"
  },
  "payload": {
    "kind": "systemEvent",
    "text": "执行数据采集脚本，获取最新业务指标，追加到 data/metrics.csv"
  }
}
```

#### 场景四：定时清理 / 归档

```json
{
  "name": "weekly-cleanup",
  "sessionTarget": "main",
  "schedule": {
    "kind": "cron",
    "expr": "0 2 * * 0",
    "tz": "Asia/Shanghai"
  },
  "payload": {
    "kind": "systemEvent",
    "text": "执行周清理任务：1. 归档超过 7 天的日志 2. 清理临时文件 3. 生成存储使用报告"
  }
}
```

### CLI 命令与 JSON 配置对照

两种配置方式本质等价，CLI 命令最终会生成对应的 JSON 配置：

| CLI 命令 | 对应 JSON 字段 |
|---------|---------------|
| `--agent <id>` | `"sessionTarget": "<id>"` |
| `--schedule "0 8 * * 1-5"` | `"schedule": { "kind": "cron", "expr": "0 8 * * 1-5", "tz": "Asia/Shanghai" }` |
| `--prompt "..."` | `"payload": { "kind": "systemEvent", "text": "..." }` |

**示例对照**：

```bash
# CLI 方式
openclaw cron add --agent main --schedule "0 8 * * 1-5" --prompt "生成早报"
```

等价于在 Cron 配置中添加：

```json
{
  "name": "auto-generated",
  "sessionTarget": "main",
  "schedule": { "kind": "cron", "expr": "0 8 * * 1-5", "tz": "Asia/Shanghai" },
  "payload": { "kind": "systemEvent", "text": "生成早报" }
}
```

> 💡 CLI 方式适合快速试用，JSON 方式适合团队统一管理和版本控制。

### Session 特点

> 每次 Cron 触发，Agent 会 **mint（创建）一个新的 sessionId**。
>
> 这意味着每次定时任务都是一次全新的会话，不会携带上一次的对话上下文。如需持续积累信息，请结合 **Memory 系统**使用。

---

## 3. Heartbeat 心跳

### 概念

Heartbeat 让 Agent **定期"巡检"**，持续关注某件事。

类比生活场景：
- 保安每小时巡逻一次
- 值班医生每 30 分钟查房一次
- 运维人员每 5 分钟刷新一次监控面板

### Heartbeat 与 Cron 的区别

| 维度 | Cron | Heartbeat |
|------|------|-----------|
| 触发方式 | 精确时间点（如每天 08:00） | 固定间隔（如每 5 分钟） |
| 适用场景 | 定时任务（日报、周报） | 持续监控（服务巡检、异常检测） |
| Session 行为 | 每次创建新 Session | **复用同一个 Session** |
| 上下文延续 | 不延续（独立会话） | 延续（同一会话持续积累） |
| 典型频率 | 每天 / 每周 / 每月 | 每分钟 / 每 5 分钟 / 每小时 |

> 💡 **关键区别**：Heartbeat 复用同一个 Session，这意味着 Agent 可以在多次心跳之间"记住"之前的状态，实现持续跟踪。

### 配置方式

在 `agents.defaults` 配置中添加 `heartbeat` 字段：

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "5m",
        "target": "last"
      }
    }
  }
}
```

| 字段 | 说明 |
|------|------|
| `heartbeat.every` | 心跳间隔，支持人类可读格式（如 `"5m"`、`"30m"`、`"1h"`） |
| `heartbeat.target` | 心跳目标，`"last"` 表示复用最近一次 Session |

### HEARTBEAT.md 文件

Agent 每次心跳执行时，会读取工作目录中的 `HEARTBEAT.md` 文件作为**检查清单**。

```markdown
# Heartbeat 检查清单

每次心跳请执行以下检查：

1. 检查 services/ 目录下所有服务的健康状态
2. 如果有服务异常，记录到 logs/alerts.md
3. 如果连续 3 次检查同一服务异常，发送告警到钉钉群
4. 更新 status/dashboard.md 中的状态面板
```

> ⚠️ **HEARTBEAT.md 要保持简短**——每次心跳都会消耗 Token，冗长的检查清单会显著增加成本。

### 典型场景

#### 场景一：服务监控（每 5 分钟检查）

```json
{
  "id": "service-monitor",
  "heartbeat": {
    "every": "5m",
    "target": "last"
  }
}
```

HEARTBEAT.md：
```markdown
检查以下服务状态：
1. 请求 http://internal-api:8080/health，确认返回 200
2. 检查磁盘空间使用率，超过 85% 告警
3. 如有异常，发送钉钉告警
```

#### 场景二：异常告警

Agent 在同一个 Session 中持续运行，能够感知**趋势变化**：

- 第一次心跳：CPU 使用率 60%（正常）
- 第二次心跳：CPU 使用率 75%（上升趋势）
- 第三次心跳：CPU 使用率 90%（触发告警）

因为 Heartbeat 复用 Session，Agent 可以对比历史数据，判断是瞬时波动还是持续异常。

#### 场景三：定期汇总

每小时汇总一次团队工作进展，自动更新进度看板。

---

## 4. Hooks 事件钩子

### 概念

Hooks 是**事件驱动**的自动化机制——当特定事件发生时，自动触发回调。

类比生活场景：
- **门铃**：有人按门铃 → 你去开门
- **消防警报**：烟雾传感器触发 → 喷淋系统启动
- **快递签收**：快递到达 → 短信通知你

### 关键 Hook 点

Plugin 可以 Hook 进 Agent 执行的每个关键节点：

| Hook 点 | 触发时机 | 典型用途 |
|---------|---------|---------|
| `gateway_start` | 网关启动时 | 初始化资源、加载配置 |
| `session_start` | 新会话开始时 | 加载用户画像、设置上下文 |
| `before_tool_call` | 工具调用前 | 权限检查、参数审核 |
| `after_tool_call` | 工具调用后 | 结果记录、审计日志 |
| `message_sending` | 消息发送前 | 内容审核、敏感信息过滤 |
| `message_sent` | 消息发送后 | 日志记录、统计计数 |

> ⚠️ Hooks 需要通过 **Plugin（JS/TS 代码）** 实现，门槛高于 Cron 和 Heartbeat。非开发者可以请技术同事协助。

---

## 5. 三种机制对比

| 维度 | Cron | Heartbeat | Hooks |
|------|------|-----------|-------|
| **触发方式** | 时间表（cron 表达式） | 固定间隔（毫秒） | 事件驱动 |
| **典型用途** | 日报、周报、定时采集 | 服务监控、异常巡检 | 权限检查、消息审核 |
| **Session** | 每次创建新 Session | 复用同一 Session | 在当前 Session 内 |
| **Token 消耗** | 每次完整执行 | 每次心跳消耗 | 仅触发时消耗 |
| **配置方式** | JSON + cron 表达式 | JSON + every/target | Plugin 代码 |
| **技术门槛** | 低（了解 cron 表达式即可） | 低（配置 + HEARTBEAT.md） | 高（需要 JS/TS 开发） |

---

## 6. 注意事项与最佳实践

### 时区设置

Cron 任务务必明确设置时区，推荐 `Asia/Shanghai`：

```json
{
  "schedule": {
    "tz": "Asia/Shanghai"
  }
}
```

不设置时区可能导致任务在错误的时间触发（如 UTC 时间与北京时间差 8 小时）。

### Heartbeat 保持简短

HEARTBEAT.md 每次心跳都会被读取并消耗 Token：

- 保持 **50 行以内**
- 只写关键检查项
- 详细说明放到 references/ 目录

### 避免过于频繁的调度

| 频率 | Token 消耗估算（每月） | 建议 |
|------|---------------------|------|
| 每分钟 | 极高（约 43,200 次/月） | 仅用于关键服务监控 |
| 每 5 分钟 | 高（约 8,640 次/月） | 重要服务巡检 |
| 每小时 | 中等（约 720 次/月） | 数据采集、汇总 |
| 每天 | 低（约 30 次/月） | 日报、清理 |

### 结合 Memory 实现持续积累

- Cron 每次都是新 Session，无法保留上下文 → 将重要信息写入 **Memory**
- Heartbeat 虽然复用 Session，但 Session 也有上限 → 关键发现写入 Memory
- 这样即使 Session 重置，Agent 也能从 Memory 中恢复历史信息

---

## 7. 延伸阅读

- [OpenClaw 自动化文档](https://docs.openclaw.ai/automation) — Cron、Heartbeat、Hooks 完整 API
- [Cron 表达式在线生成器](https://crontab.guru) — 可视化编辑 cron 表达式

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [08-Skills：扩展 AI 的业务能力](./08-OpenClaw%20Skills：扩展%20AI%20的业务能力.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) |
