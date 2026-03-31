+++
date = '2026-03-15T12:10:00+08:00'
draft = false
title = 'OpenClaw 故障排查手册'
tags = ['OpenClaw', 'AI', 'Agent', '故障排查']
+++

# OpenClaw 故障排查手册

本篇整合了各类常见故障的排查方法，适合运维人员和遇到问题的使用者快速定位。按故障类型分类，可跳转到对应章节。

---

## 目录

1. [Gateway 启动失败](#1-gateway-启动失败)
2. [Agent 无响应 / 超时](#2-agent-无响应--超时)
3. [钉钉消息收不到 / 发不出](#3-钉钉消息收不到--发不出)
4. [Memory 未写入 / 写入异常](#4-memory-未写入--写入异常)
5. [Skill 加载失败](#5-skill-加载失败)
6. [费用异常（Token 暴增）](#6-费用异常token-暴增)
7. [数据备份与恢复](#7-数据备份与恢复)

---

## 1. Gateway 启动失败

### 快速检查

```bash
# 查看 Gateway 状态
openclaw gateway status

# 查看错误日志（最近 100 行）
tail -100 ~/.openclaw/logs/error.log

# 重启 Gateway
openclaw gateway restart
```

### 常见原因与解决方法

| 现象 | 可能原因 | 解决方法 |
|------|---------|---------|
| `command not found: openclaw` | 环境变量未生效 | 重启终端，或 `source ~/.zshrc`（Mac）/ `source ~/.bashrc`（Linux） |
| `Error: Node.js version too old` | Node.js 版本不满足（需 22+） | `nvm install 24 && nvm use 24` |
| `EACCES: permission denied` | npm 全局安装权限不足 | `sudo npm install -g openclaw` 或配置 npm prefix |
| `connect ETIMEDOUT` | 网络超时 | 检查代理设置，或使用国内镜像：`npm config set registry https://registry.npmmirror.com` |
| 端口被占用（默认 18789） | 其他进程占用端口 | `lsof -i :18789` 找到占用进程，终止后重启 |
| 守护进程启动失败 | 日志路径权限问题 | 检查 `~/.openclaw/logs/` 目录权限 |

### 生产环境自动恢复

生产环境建议配置 systemd 或 Docker `restart: always`，确保 Gateway 进程崩溃后自动拉起：

```bash
# systemd 示例（Linux）
systemctl enable openclaw
systemctl start openclaw
```

---

## 2. Agent 无响应 / 超时

### 快速检查

```bash
# 查看 Gateway 日志，确认请求是否到达
tail -f ~/.openclaw/logs/gateway.log

# 检查模型连通性
openclaw doctor
```

### 常见原因

| 现象 | 可能原因 | 解决方法 |
|------|---------|---------|
| 长时间无回复 | 模型 API 超时或限流 | 检查模型平台的用量页面，切换到 Fallback 模型 |
| 返回空响应 | `maxTokens` 设置过低 | 调高 `models[].maxTokens` 配置 |
| 报错 `API Key invalid` | Key 失效或填写错误 | 重新获取 Key：`openclaw config set provider.apiKey "新Key"` |
| 回复截断 | 上下文窗口不足 | 开启 Compaction 或缩减 MEMORY.md 长度（建议 50-100 行以内） |
| 任务中途停止 | 会话压缩（Compaction）触发 | 正常现象，Compaction 后 Agent 会继续处理 |

### 验证实际运行的模型

当配置了 Failover 时，需确认 Agent 实际调用的是哪个模型：

```bash
# 在 Gateway 日志中搜索实际运行的模型
grep "embedded run start" ~/.openclaw/logs/gateway.log | tail -20
```

详见 [06-大模型配置与费用优化](./06-OpenClaw%20大模型配置与费用优化.md) 第 6.3 节。

---

## 3. 钉钉消息收不到 / 发不出

### 检查清单

1. **插件是否安装并启用**
   ```bash
   openclaw plugins list
   # 确认 dingtalk 在列表中且状态为 enabled
   ```

2. **插件是否加入白名单**（`openclaw.json` 中）
   ```json5
   {
     "plugins": {
       "enabled": true,
       "allow": ["dingtalk"]
     }
   }
   ```

3. **钉钉后台配置是否正确**
   - AppKey 和 AppSecret 填写无误
   - Stream 模式连接是否正常（查看 `~/.openclaw/logs/dingtalk.log`）

4. **Bindings 路由是否配置**
   - 确认 `bindings` 中有 `"channel": "dingtalk"` 的规则，且位于 `denied` 规则之前

5. **用户是否在白名单**
   - `dmPolicy` 和 `groupPolicy` 设为 `"allowlist"` 时，需要 `allowFrom` 包含该用户 ID

### 常见原因

| 现象 | 可能原因 | 解决方法 |
|------|---------|---------|
| 钉钉无任何回复 | Stream 连接未建立 | 检查 `dingtalk.log`，确认 WebSocket 连接日志 |
| 私聊有回复，群聊没有 | 群聊策略未配置 | 检查 `channels.dingtalk.groups` 配置和 `requireMention` 设置 |
| 群聊 @ 无响应 | `mentionPatterns` 未匹配 | 检查 `agents.list[].groupChat.mentionPatterns` 是否包含机器人名称 |
| 消息格式乱码 | 换行符格式错误 | 钉钉换行使用 `\n\n`（两个换行），不是单个 `\n` |
| Card 模式显示异常 | 卡片 schema 版本不匹配 | 检查钉钉开放平台文档，确认卡片 schema 版本 |

> → 钉钉详细配置参见 [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md)。

---

## 4. Memory 未写入 / 写入异常

### 常见原因

| 问题 | 可能原因 | 解决方法 |
|------|---------|---------|
| Agent 完成任务后不写 Memory | AGENTS.md 缺少 Memory Discipline 硬规则 | 在 AGENTS.md 添加 Memory Discipline 规则（见 [05-Memory](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) 第 4 节） |
| EOD 补记写入了错误日期的文件 | Cron payload 未使用 `{{target_date}}` 占位符 | 检查 EOD Cron 配置，显式传入 `{{target_date}}`，不让 Agent 自行判断日期 |
| `memory_search` 返回空 | 向量索引未构建或 Embedding 模型未配置 | 检查 `memorySearch.provider` 配置，确认 API Key 有效 |
| `memory_search` 结果不相关 | 搜索关键词过宽泛 | 使用具体词（如"PostgreSQL 迁移"），而非"数据库" |
| MEMORY.md 越来越长导致 Token 激增 | 未定期清理 | 让 Agent 定期审查 MEMORY.md，合并重复项，控制在 50-100 行以内 |
| Main Agent 写入了其他 Agent 的 Memory | 未遵守跨 Agent 隔离规则 | 每个 Agent 的 AGENTS.md 需单独加"只写自己 Workspace 的 Memory"规则 |
| 向量索引构建失败 | Embedding API Key 失效或网络不通 | 检查 `memorySearch.remote.apiKey`，或切换本地模式（`provider: "local"`） |

### EOD 补记未运行

检查 Cron 任务是否正常配置：

```bash
# 查看当前 Cron 任务列表
openclaw cron list

# 查看 Cron 执行日志
grep "cron" ~/.openclaw/logs/gateway.log | tail -30
```

> → Memory 完整配置和规范见 [05-Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md)。

---

## 5. Skill 加载失败

### 常见原因

| 现象 | 可能原因 | 解决方法 |
|------|---------|---------|
| Skill 未生效 | 安装路径不在加载路径中 | 确认 Skill 安装在 `~/.openclaw/skills/`（全局）或 `<workspace>/skills/`（当前 Agent） |
| Skill 功能不可用 | `SKILL.md` 的 `allowed-tools` 与 Agent 工具权限冲突 | 检查 Agent 配置中 `tools.allow` 是否包含 Skill 所需工具 |
| 安装超时 | 网络访问 npm registry 慢 | 使用国内镜像：`NPM_CONFIG_REGISTRY=https://registry.npmmirror.com clawhub install <skill>` |
| Skill 版本冲突 | 多个 Workspace 安装了不同版本 | 卸载冲突版本，统一安装到全局路径 |

### 查看已安装的 Skill

```bash
# 全局 Skill
ls ~/.openclaw/skills/

# 当前 Workspace 的 Skill
ls <workspace>/skills/
```

> → Skill 加载路径优先级详见 [08-Skills：扩展 AI 的业务能力](./08-OpenClaw%20Skills：扩展%20AI%20的业务能力.md)。

---

## 6. 费用异常（Token 暴增）

### 排查步骤

1. **确认是否使用包月套餐**（不要用后付费）
2. **查看 OpenClaw Dashboard** 中各 Agent 的 Token 消耗分布
3. **查看模型平台控制台**（百炼、Kimi 等）的用量详情
4. **检查 MEMORY.md 大小**：MEMORY.md 每次会话都注入，过长会显著增加费用

```bash
# 查看 MEMORY.md 行数
wc -l ~/.openclaw/workspace/MEMORY.md
# 建议控制在 50-100 行以内
```

### 常见高消耗原因

| 原因 | 说明 | 解决方法 |
|------|------|---------|
| MEMORY.md 过长 | 每次会话都注入全部内容 | 定期清理，合并重复项，长文放 `outputs/` 只记路径 |
| Cron 任务频率过高 | 每次触发都消耗 Token | 降低触发频率，简化任务提示词 |
| 复杂 Multi-Agent 任务 | 多个 Agent 轮流交互，Token 乘以 Agent 数 | 优化协作流程，减少不必要的 Agent 转发 |
| 模型选择不当 | 简单任务使用了高性能模型 | 按 [06-大模型配置](./06-OpenClaw%20大模型配置与费用优化.md) 第 5 节分配模型 |
| Failover 切换到更贵的模型 | 主模型限流后切到备用 | 查看日志确认实际运行的模型，调整 Fallback 顺序 |

### 设置用量告警

在模型平台（阿里云百炼、Kimi 等）设置日/月用量上限，超出时自动停止或告警。

---

## 7. 数据备份与恢复

### 关键数据位置

| 数据类型 | 路径 | 说明 |
|---------|------|------|
| 主配置 | `~/.openclaw/openclaw.json` | 所有 Agent 和通道配置 |
| 配置自动备份 | `~/.openclaw/backups/` | 最新 50 次配置变更（自动保留） |
| 长期记忆 | `<workspace>/MEMORY.md` | 每个 Agent 各一份 |
| 每日记忆 | `<workspace>/memory/` | 按日期存放的历史记录 |
| 会话记录 | `~/.openclaw/agents/*/sessions/` | `.jsonl` 格式，可追溯历史对话 |
| 运行日志 | `~/.openclaw/logs/` | Gateway、错误、通道日志 |

### 恢复配置

```bash
# 从自动备份恢复
ls ~/.openclaw/backups/                          # 查看备份列表
cp ~/.openclaw/backups/openclaw.json.back.<时间戳> ~/.openclaw/openclaw.json
openclaw gateway restart
```

### 磁盘空间清理

长期运行后，Session 文件可能占用大量磁盘空间：

```bash
# 查看 sessions 目录占用
du -sh ~/.openclaw/agents/*/sessions/

# 清理 30 天前的会话文件
find ~/.openclaw/agents/*/sessions/ -name "*.jsonl" -mtime +30 -delete
```

每日记忆文件（`memory/*.md`）体积较小，建议每季度归档一次三个月以前的记录。

---

## 延伸阅读

- [02-安装与部署](./02-OpenClaw%20安装与部署.md) — 环境安装和运维注意事项
- [04-通道配置（钉钉）](./04-OpenClaw%20通道配置（钉钉）.md) — 钉钉接入详细配置
- [05-Memory：持久记忆系统](./05-OpenClaw%20Memory：让%20AI%20越用越聪明.md) — Memory 完整配置规范
- [06-大模型配置与费用优化](./06-OpenClaw%20大模型配置与费用优化.md) — 费用控制和 Failover 配置
- [10-规范与安全准则](./10-OpenClaw%20规范与安全准则.md) — 安全加固和配置规范

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [12-架构与原理（进阶）](./12-OpenClaw%20架构与原理（进阶）.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | |
