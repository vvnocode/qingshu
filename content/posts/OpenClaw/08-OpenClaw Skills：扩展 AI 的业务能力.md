+++
date = '2026-03-15T00:08:00+08:00'
draft = false
title = 'OpenClaw Skills：扩展 AI 的业务能力'
tags = ['OpenClaw', 'Skills']
+++

## 本章导读

> **这篇文档回答三个问题：**
>
> 1. Skills 是什么？
> 2. 怎么安装和使用 Skill？
> 3. 怎么把 Skill 扩展到业务部门的实际工作中？

如果把 OpenClaw 比作一位新同事，那 **Skill 就是你给他装的"插件"或教他的"新技能"**。

装上"简历筛选"Skill，他就能帮 HR 筛选简历；装上"发票识别"Skill，他就能帮财务识别发票信息。**不需要写代码，不需要改系统，只需要一个 Markdown 文件。**

---

## 1. Skill 的定位

### 类比理解：给 AI 装插件 / 学新技能

| 生活类比 | 对应 Skill |
|---------|-----------|
| 给手机装 App | 给 Agent 装 Skill |
| 教新同事一套 SOP | 写一份 SKILL.md |
| 通用员工 → 专业岗位 | 通用 Agent → 领域专家 |

### Skill 的本质

每个 Skill **本质上就是一个文件夹**，核心是一个 `SKILL.md` 文件，里面用**自然语言**告诉 Agent：

- 你的角色是什么
- 你要做什么
- 你的输入是什么、输出是什么
- 你应该调用哪些工具

```
my-skill/
├── SKILL.md        ← 核心：用自然语言描述 Skill 的行为
├── scripts/        ← 可选：辅助脚本
├── references/     ← 可选：参考资料、模板
└── assets/         ← 可选：图片、配置文件等
```

### 跨平台复用

Skill 采用**开放标准格式**，一次编写，可在 20+ 平台使用：

- OpenClaw
- Claude Code
- Cursor
- Gemini CLI
- Windsurf
- Codex CLI
- 以及更多兼容 SKILL.md 标准的平台

> 💡 **关键认知**：Skill 不是某个平台的"私有插件"，而是一种通用的 AI 能力描述格式。

---

## 2. Skill 与 Plugin 的区别

很多同事会混淆 Skill 和 Plugin，它们的定位完全不同：

- **Skill** = 告诉 Agent "**做什么**"（自然语言 Markdown），**零代码门槛**
- **Plugin** = 改变 Agent "**能做什么**"（JS/TS 代码），**需要开发能力**

| 维度 | Skill | Plugin |
|------|-------|--------|
| 实现语言 | Markdown（自然语言） | JavaScript / TypeScript |
| 加载方式 | Agent 读取 SKILL.md，理解后执行 | 运行时加载代码模块 |
| 扩展能力 | 任务流程、SOP、知识库 | 新工具、新通道、新 Hook |
| 安装方式 | 放入 skills/ 目录或 CLI 安装 | npm install 或 plugin 注册 |
| 门槛 | 零代码，会写文档就行 | 需要 JS/TS 开发能力 |
| 典型例子 | 日报生成、简历筛选、数据分析 | 钉钉通道、数据库连接、OCR 服务 |

> 💡 **简单记忆**：Skill 是"教 Agent 做事的说明书"，Plugin 是"给 Agent 装的新器官"。

---

## 3. SKILL.md 文件结构与规范

### Frontmatter 字段说明

每个 SKILL.md 文件以 YAML frontmatter 开头，声明元信息：

```yaml
---
name: daily-report-generator
description: 根据当日工作内容自动生成日报
version: 1.0.0
metadata:
  author: your-team
homepage: https://example.com    # 可选，技能主页链接

# 是否可由用户直接调用（设为 true 表示用户可以在对话中请求使用此 Skill）
user-invocable: true

# 设为 true 则禁止模型自动调用（仅手动触发时使用）
disable-model-invocation: false

# 允许此 Skill 使用的工具列表（最小权限原则）
# 支持细粒度模式，如 Bash(pdftotext:*) 仅允许执行 pdftotext 命令
allowed-tools:
  - Read
  - Write
  - Bash(pdftotext:*)

# 兼容的平台列表（可选）
compatibility:
  - openclaw
  - claude-code
  - cursor

# 系统依赖声明（可选，声明运行此 Skill 所需的外部工具）
dependencies:
  - python3
  - poppler-utils
---
```

| 字段 | 必填 | 说明 |
|-----|------|------|
| `name` | ✅ | Skill 的唯一标识名（英文，kebab-case，最多 64 字符） |
| `description` | ✅ | 一句话描述 Skill 功能 + 触发条件（决定 Agent 何时自动调用） |
| `version` | 建议 | 语义化版本号 |
| `metadata` | 可选 | 附加元信息（作者、标签等），JSON 对象 |
| `homepage` | 可选 | 技能主页链接 |
| `user-invocable` | 建议 | 用户是否可以直接调用，默认 true |
| `disable-model-invocation` | 可选 | 设为 true 禁止模型自动调用，仅手动触发 |
| `allowed-tools` | 建议 | Skill 可调用的工具白名单，支持细粒度模式如 `Bash(pdftotext:*)` |
| `compatibility` | 可选 | 兼容平台列表（如 `openclaw`、`claude-code`、`cursor`） |
| `dependencies` | 可选 | 系统依赖声明（如 `python3`、`poppler-utils`） |

> ⚠️ **工具名命名规范**：`SKILL.md` 的 `allowed-tools` 字段使用 **PascalCase** 命名（如 `Read`、`Write`、`Bash`），这与 `openclaw.json` 中 `tools.allow` 使用的 **小写** 命名（如 `read`、`write`、`exec`）不同。两者属于不同的命名体系：前者是 Skill 标准规范，后者是 Agent 配置规范。最终 Agent 执行 Skill 时，系统会自动映射两种命名。

### 格式兼容性与进阶特性

SKILL.md 采用 **AgentSkills 兼容格式**，YAML frontmatter 是必须的，其中 `name` 和 `description` 为必填字段。

**`{baseDir}` 占位符**：在 SKILL.md 的指令正文中，可以使用 `{baseDir}` 引用当前技能文件夹的路径。Agent 加载时会自动替换为实际路径，方便引用 `scripts/`、`references/` 等子目录中的文件：

```markdown
请读取 `{baseDir}/references/template.md` 作为输出模板。
执行 `{baseDir}/scripts/extract.sh` 进行数据提取。
```

**`user-invocable` 与斜杠命令**：当 `user-invocable: true` 时，该技能会出现在用户的斜杠命令列表中（如 `/daily-report-generator`），用户可以在对话中直接通过斜杠命令触发。设为 `false` 则仅允许模型根据上下文自动调用。

### 目录结构详解

```
my-skill/
├── SKILL.md            ← 必须：Skill 主文件，Agent 读取并执行
├── scripts/            ← 可选：Shell/Python 辅助脚本
│   └── extract.sh
├── references/         ← 可选：详细文档、模板（Skill过长时拆分到这里）
│   ├── template.md
│   └── examples.json
└── assets/             ← 可选：图片、配置文件
    └── logo.png
```

### Token 优化建议

Agent 读取 SKILL.md 会消耗 Token，建议：

- **主文件控制在 500 行以内**
- 详细的参考资料、模板放到 `references/` 目录，在 SKILL.md 中通过 `read_file` 引用
- 避免在 SKILL.md 中嵌入大段 JSON/CSV 数据
- 使用简洁明确的自然语言，避免冗余描述

---

## 4. Skill 安装方式

### 方式一：ClawHub CLI（推荐）

ClawHub 是 OpenClaw 官方 Skill 仓库，通过 CLI 一行命令安装：

```bash
# 安装 Skill
clawhub install <slug>

# 示例：安装 find-skills
clawhub install find-skills

# 更新已安装的 Skill
clawhub update <slug>

# 更新全部
clawhub update --all

# 强制更新（覆盖本地修改，注意备份 .env 文件）
clawhub update <slug> --force

# 查看已安装列表
clawhub list

# 其他常用命令
clawhub login        # 登录账号
clawhub search       # 搜索 Skill
clawhub uninstall    # 卸载 Skill
clawhub publish      # 发布 Skill
clawhub sync         # 扫描本地 Skill 并发布新增/更新
```

> 使用 `--force` 更新会替换整个 Skill 目录，可能清除 `.env` 中的 API 密钥。更新前请备份敏感配置。

### 方式二：npx skills（Skills.sh 生态）

Skills.sh 是跨平台 Skill 社区，兼容 OpenClaw：

```bash
# 安装 Skill
npx skills add <slug>

# 示例
npx skills add technical-writing

# 搜索可用 Skill
npx skills search "data analysis"

# 更新所有已安装的 Skill
npx skills update
```

> `npx skills update` 偶有静默失败的报告，建议在更新后用 `npx skills list` 确认版本。

### 方式三：手动下载安装

1. 从 GitHub 或其他来源下载 Skill 文件夹
2. 放入以下任一目录：
   - 项目级：`<workspace>/skills/`
   - 用户级：`~/.openclaw/skills/`
3. 重启 Agent 或执行 reload

> 对 Git 仓库来源的 Skill，推荐用 git submodule 管理版本，详见 [Skill 管理策略](#12-skill-管理策略)。

### 方式四：Agent 代装（最便捷）

直接在聊天中告诉 Agent：

> "帮我安装 technical-writing 这个 Skill"
>
> "从 https://github.com/xxx/my-skill 安装这个 Skill"

Agent 会自动下载、验证并安装，全程无需命令行。

---

## 5. Skill 资源平台

| 平台 | 说明 | 地址 |
|------|------|------|
| **ClawHub** | OpenClaw 官方 Skill 仓库 | [clawhub.ai](https://clawhub.ai) |
| **Skills.sh** | 跨平台 Skill 社区（兼容 20+ 平台） | [skills.sh](https://skills.sh) |
| **SkillsMP** | Skill 市场与发现平台 | [skillsmp.com](https://skillsmp.com) |

> 💡 建议优先在 ClawHub 搜索官方审核过的 Skill，安全性更有保障。

---

## 6. Skill 加载路径与优先级

OpenClaw 按以下顺序加载 Skill（优先级从高到低）：

| 位置 | 路径 | 说明 |
|------|------|------|
| Workspace skills（最高） | `<workspace>/skills/` | 仅对当前 Agent 生效 |
| Managed/local skills | `~/.openclaw/skills/` | 所有 Agent 共享 |
| Bundled skills（最低） | 随 OpenClaw 安装包附带 | 内置技能 |

如果同名技能存在于多个位置，高优先级覆盖低优先级。

**多 Agent 场景**：每个 Agent 有自己的 workspace，因此 workspace skills 天然按 Agent 隔离。如果需要多个 Agent 共享同一组技能，可以通过 `skills.load.extraDirs` 配置额外的技能目录。

- 项目级 Skill 适合团队协作，可以通过 Git 共享
- 用户级 Skill 适合个人常用工具

### 多 Agent 下的 Skill 隔离

如果某个 Skill 只想给特定 Agent 使用而不给其他 Configured Agent 使用，将其放入该 Agent 专属的 `workspace/skills/` 目录中，不要放到全局 `~/.openclaw/skills/` 或通过 `skills.load.extraDirs` 配置的共享路径中。

`skills.load.extraDirs` 是一个可选配置项，用于指定额外的 Skill 加载目录。未被 `extraDirs` 覆盖的路径中的 Skill 不会被其他 Agent 加载，从而实现 Skill 级别的隔离。

| 放置位置 | 可见范围 | 适用场景 |
|---------|---------|---------|
| `<workspace>/skills/` | 仅当前 Agent | 专属 Skill，不想共享 |
| `~/.openclaw/skills/` | 当前用户的所有 Agent | 个人通用 Skill |
| `skills.load.extraDirs` 指定路径 | 配置了该路径的 Agent | 跨 Agent 选择性共享 |

> 💡 **隔离原则**：默认不共享，按需开放。先放 Workspace 级别，确认需要跨 Agent 使用后再提升到用户级或 `extraDirs`。

### 技能门控（Gating）

OpenClaw 在加载时根据 `SKILL.md` 中的 `metadata` 字段过滤技能：

```yaml
---
name: nano-banana-pro
description: Generate or edit images via Gemini
metadata: {"openclaw": {"requires": {"bins": ["uv"], "env": ["GEMINI_API_KEY"]}, "primaryEnv": "GEMINI_API_KEY"}}
---
```

门控条件：

| 条件 | 说明 |
|------|------|
| `requires.bins` | 要求 PATH 中存在指定的可执行文件 |
| `requires.env` | 要求指定的环境变量已设置 |
| `requires.config` | 要求 `openclaw.json` 中的指定路径为 truthy |
| `requires.anyBins` | 至少一个可执行文件存在即可 |
| `os` | 限定操作系统（`darwin` / `linux` / `win32`） |

不满足门控条件的技能会被跳过，不会出现在 Agent 的可用技能列表中。

> [官方文档：gating-load-time-filters](https://docs.openclaw.ai/tools/skills#gating-load-time-filters)

---

## 7. 推荐必装 Skill

以下 Skill 经过验证，建议所有用户安装：

| Skill | 说明 | 安装方式 |
|-------|------|---------|
| **Skill Vetter** | 自动审核 Skill 安全性，检查是否有危险工具调用 | `clawhub install skill-vetter` |
| **Find Skills** | 在终端内搜索和安装 Skill，不用离开对话 | `clawhub install find-skills` |
| **Skill Creator** | 内置 Skill，引导你创建新 Skill | 系统预装 |
| **Self-Improving Agent** | Agent 自动反思执行结果并优化后续行为 | `clawhub install self-improving-agent` |
| **Technical Writing** | 生成高质量技术文档，自动排版 | `npx skills add technical-writing` |
| **Mermaid Diagrams** | 用自然语言生成流程图、架构图 | `npx skills add mermaid-diagrams` |
| **Agent Builder** | 辅助设计和构建多 Agent 架构 | `clawhub install agent-builder` |

> 💡 **新手建议**：先装 `Find Skills` 和 `Skill Vetter`，然后用 Find Skills 在对话中搜索你需要的 Skill。

### Skill Creator 使用说明

Skill Creator 是 OpenClaw 内置的 Skill 创建工具，用于引导 Agent 生成规范的 SKILL.md 文件：

```
# 在对话中告诉 Agent
帮我创建一个新的 Skill，用于 xxx

# 或使用斜杠命令
/skill-creator
```

Agent 会询问 Skill 的用途和触发条件，自动生成含 frontmatter 和指令正文的 SKILL.md 文件到当前 Workspace 的 `skills/` 目录下。

### Self-Improving Agent 说明

Self-Improving Agent 让 Agent 在每次任务后自动反思执行过程，提取可复用的经验并写入自身规则，逐步积累领域知识。推荐全局安装：

```bash
npx skills add charon-fan/agent-playbook/self-improving-agent
# 安装后将 Skill 目录移到 ~/.openclaw/skills/，所有 Agent 共享
```

---

## 8. 企业场景扩展示例

Skill 的价值不仅在技术领域，更在于**让每个业务部门都能拥有自己的 AI 专家**。

### HR 部门

| Skill 想法 | 功能描述 |
|-----------|---------|
| 简历筛选 Skill | 读取简历文件，按岗位要求打分、提取关键信息、生成候选人对比表 |
| 考勤统计 Skill | 读取考勤数据，自动统计异常（迟到、早退、缺卡），生成月度报表 |

### 财务部门

| Skill 想法 | 功能描述 |
|-----------|---------|
| 发票识别 Skill | 结合 OCR 工具（如 PaddleOCR）识别发票图片，提取金额、日期、税号等字段，自动填入报销表。参考苍何 PaddleOCR 案例实现 |
| 报表生成 Skill | 读取财务数据，按模板生成月度/季度财务报表，自动计算同比环比 |

### 运营部门

| Skill 想法 | 功能描述 |
|-----------|---------|
| 数据分析 Skill | 读取 CSV/Excel 数据，自动分析趋势、异常值，生成可视化图表和分析报告 |
| 舆情监控 Skill | 定期抓取指定平台的品牌相关内容，分析情感倾向，生成舆情日报 |

### 行政部门

| Skill 想法 | 功能描述 |
|-----------|---------|
| 会议纪要 Skill | 读取会议录音转文字稿，提取要点、待办事项，按模板生成会议纪要 |
| 日报汇总 Skill | 收集团队成员日报，自动汇总关键进展和问题，生成团队周报 |

### 自建 Skill 示例：日报生成 Skill

以下是一个完整的 SKILL.md 示例，可直接使用或参考修改：

```markdown
---
name: daily-report-generator
description: 根据当日工作内容自动生成结构化日报
version: 1.0.0
metadata:
  author: internal-team
  department: general
user-invocable: true
allowed-tools:
  - read_file
  - write_file
  - list_directory
compatibility:
  - openclaw
  - claude-code
  - cursor
---

# 日报生成 Skill

## 角色

你是一位日报撰写助手。根据用户提供的工作内容，生成结构化的日报。

## 输入

用户会以自然语言描述当天的工作内容，可能包括：
- 口语化的工作描述
- 会议记录片段
- Git commit 记录
- 聊天记录摘要

## 输出格式

请按以下模板生成日报：

### 📅 日报 - {日期}

**今日完成：**
1. [具体事项1] — 完成情况说明
2. [具体事项2] — 完成情况说明

**进行中：**
1. [事项] — 当前进度 / 阻塞点

**明日计划：**
1. [计划事项]

**需要协调：**
- [如有跨部门协调需求，列在这里]

## 注意事项

- 语言风格：简洁专业，避免口语化
- 每条事项控制在一行以内
- 如果用户没有提供"明日计划"，主动询问
- 输出为 Markdown 格式
```

---

## 9. 自建 Skill 的基本流程

1. **明确需求**：这个 Skill 要帮谁解决什么问题？
2. **创建目录**：在 `~/.openclaw/skills/` 下创建文件夹
3. **编写 SKILL.md**：
   - 写好 frontmatter（name, description, allowed-tools）
   - 用自然语言描述角色、输入、输出、注意事项
4. **测试验证**：在对话中调用 Skill，检查输出是否符合预期
5. **迭代优化**：根据实际使用反馈调整提示词
6. **分享推广**：好用的 Skill 可以通过 Git 或 ClawHub 分享给团队

> 💡 也可以直接告诉 Agent："帮我创建一个 xxx 的 Skill"，Agent 会使用内置的 Skill Creator 引导你完成。

---

## 10. Skill 权限与 Agent 权限的关系

Skill 的 `allowed-tools` 和 Agent 的 `tools.allow` 是两层独立的权限控制，最终生效的工具列表取**两者的交集**：

| 层级 | 配置位置 | 控制对象 | 说明 |
|------|---------|---------|------|
| **Agent 层** | `openclaw.json` → `agents.list[].tools.allow` | Agent 能调用的所有工具 | 硬约束，优先级最高 |
| **Skill 层** | `SKILL.md` → `allowed-tools` | 该 Skill 可使用的工具 | 在 Agent 权限范围内进一步收窄 |

**示例**：如果 Agent 的 `tools.allow` 只包含 `["read", "write", "web_search"]`，而某个 Skill 的 `allowed-tools` 声明了 `["Read", "Write", "Bash"]`，那么该 Skill 实际只能使用 `Read`（read）和 `Write`（write），`Bash`（exec）会被 Agent 层拦截。

> 💡 **核心原则**：Skill 不能突破 Agent 的权限边界。Agent 权限是"天花板"，Skill 权限是在此基础上的"最小权限声明"。

---

## 11. Skill 安全审计

安装第三方 Skill 前，请注意以下安全检查：

### 检查 allowed-tools 字段

确认 Skill 声明的工具权限是否合理：

```yaml
# ✅ 合理：日报生成只需要读写文件
allowed-tools:
  - read_file
  - write_file

# ⚠️ 警惕：一个日报 Skill 不应该需要 Shell 执行权限
allowed-tools:
  - read_file
  - write_file
  - shell           # ← 为什么需要执行命令？
  - http_request    # ← 为什么需要发网络请求？
```

### 检查 scripts/ 目录

如果 Skill 包含 `scripts/` 目录，仔细审查脚本内容：

- 是否有网络请求（数据外发风险）
- 是否有文件删除操作
- 是否有权限提升操作

### 使用 Skill Vetter 自动审核

强烈推荐安装 **Skill Vetter**，它会自动检查：

- 工具权限是否超出合理范围
- 脚本是否包含危险操作
- 是否有已知安全问题

```bash
# 安装
clawhub install skill-vetter

# 使用：在对话中要求审核
# "请用 Skill Vetter 检查 my-skill 是否安全"
```

---

## 12. Skill 管理策略

### 目录规划

| 目录 | 用途 | 适用场景 |
|------|------|---------|
| `~/.openclaw/skills/` | 全局 Skill，所有 Agent 共享 | 通用工具类（find-skills、skill-vetter） |
| `<workspace>/skills/` | 项目级 Skill，仅当前 Agent 使用 | 业务专属（日报、审查、特定流程） |
| `skills.load.extraDirs` | 额外加载目录 | 团队共享目录、挂载卷 |

### 版本管理

推荐使用 Git Submodule 管理 Skill 版本：

```bash
git submodule add https://github.com/owner/skill-repo.git skills/skill-name
git submodule update --remote
```

注意事项：

- `--force` 更新会替换整个目录，可能清除 `.env` 中的 API 密钥，更新前备份
- 使用 `npx skills list` 或 `clawhub list` 确认版本
- 重要 Skill 建议锁定版本，避免自动更新引入 breaking change

### 技能配置（openclaw.json）

在 `~/.openclaw/openclaw.json` 中可以对已安装技能进行配置：

```json5
{
  "skills": {
    "entries": {
      "nano-banana-pro": {
        "enabled": true,
        "apiKey": "YOUR_API_KEY",
        "env": {
          "GEMINI_API_KEY": "YOUR_KEY"
        }
      },
      "sag": { "enabled": false }
    },
    "load": {
      "extraDirs": ["~/shared-skills"],
      "watch": true
    }
  }
}
```

- `enabled: false`：禁用指定技能
- `apiKey`：为技能注入 API Key
- `env`：为技能注入环境变量
- `load.extraDirs`：添加额外的技能搜索目录
- `load.watch`：自动监听技能文件变更并热更新

---

## 13. MCP 工具集成

除了 Skill 和 Plugin，OpenClaw 还支持通过 **MCP（Model Context Protocol）** 接入外部工具。MCP 是一种标准化的 AI 工具接口协议，允许 Agent 调用第三方服务提供的工具。

### MCP 与 Skill 的区别

| 维度 | Skill | MCP 工具 |
|------|-------|---------|
| **定义方式** | Markdown 自然语言 | JSON Schema（协议标准） |
| **运行位置** | Agent 理解后自主执行 | 外部 MCP Server 执行 |
| **适用场景** | 工作流程、SOP、知识库 | 数据库查询、API 调用、文件系统操作 |
| **门槛** | 零代码 | 需要部署 MCP Server |

### 配置方式

在 `openclaw.json` 中配置 MCP Server：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    },
    "database": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "/path/to/db.sqlite"]
    }
  }
}
```

配置后，Agent 即可在对话中使用 MCP Server 提供的工具（如文件读写、数据库查询等），无需额外 Skill 或 Plugin。

### 何时用 MCP vs Skill

- **需要访问外部系统**（数据库、API、文件系统）→ 用 MCP
- **需要定义工作流程**（SOP、审核规则、报告模板）→ 用 Skill
- **两者结合**：用 Skill 定义"怎么做"，用 MCP 提供"用什么工具做"

> 更多 MCP 工具可浏览 [MCP Server 目录](https://github.com/modelcontextprotocol/servers)。

---

## 14. 延伸阅读

- [Skills.sh 官方文档](https://skills.sh/docs) — Skill 标准规范与最佳实践
- [ClawHub Skill 仓库](https://clawhub.ai) — 浏览和安装官方 Skill
- [OpenClaw Plugin 开发文档](https://docs.openclaw.ai/plugins) — 需要更深度扩展时参考

---

| ← 上一篇 | 返回总览 | 下一篇 → |
|:---|:---:|---:|
| [07-实战案例](./07-OpenClaw%20实战案例.md) | [00-总览](./00-OpenClaw%20系列教程：总览.md) | [09-自动化：Cron 与 Heartbeat](./09-OpenClaw%20自动化：Cron%20与%20Heartbeat.md) |
