# Skill Factory

> 一份 skill 源码，分发到 N 个异构 AI agent。一套"skill 工厂"的方法论 + 机制。

## 一个痛点

我同时用着好几个 AI agent（Claude Code、Cursor、QoderWork、Qoder……）。它们各有各的 skills 目录（`~/.claude/skills/`、`~/.cursor/skills/`、`~/.qoderwork/skills/`……），格式相近却各自为政。

于是我写了一个方法论 skill，想在所有 agent 里都用上。问题来了：**难道每个 agent 都复制一份？** 复制即分裂——改一处忘改其他，很快各份就不一致了。

我想要的是：**写一份，处处生效。**

## 核心思想

把"skill 的开发"和"skill 的分发"分开：

- **一份源码**住在一个地方（你的 skill 工厂），是唯一的 SSOT；
- **一个注册表**（`publish.map`）声明"哪个 skill → 分发到哪些 agent"；
- **一个安装器**（`install.sh`）按注册表，给每个目标 agent 的 skills 目录建一个**软链接**，指回那份唯一源码。

软链接是关键：所有 agent 用的是**同一份文件**。改一处，所有 agent 立刻生效。没有复制，就没有分裂。

```
你的 skill 工厂（唯一源码）
        │
   publish.map（注册表：skill → 哪些 agent）
        │
   install.sh（按注册表建软链）
        │
   ├──→ ~/.claude/skills/my-skill      ─┐
   ├──→ ~/.cursor/skills/my-skill       ├─ 全是软链，指向同一份源码
   ├──→ ~/.qoderwork/skills/my-skill    │
   └──→ ~/.qoder/skills/my-skill       ─┘
```

## 两种安装模式

| 模式 | 软链指向 | 适用 |
|------|---------|------|
| **直链模式** | skill 源码根目录 | 自用 skill。改了源码立刻生效，无需构建 |
| **构建模式** | `dist/` 构建产物 | 要分发给别人、需过滤开发文件（evals/docs 等）时 |

安装器优先找 `dist/`，没有就链源码根目录——所以直链模式零配置，构建模式 `build` 一下即可。

## 三个文件

| 文件 | 作用 |
|------|------|
| `publish.map` | 注册表。格式 `skill名=项目路径\|目标agent`，`all` 表示所有 agent |
| `agents.conf` | agent 抽象。`agent名=skills目录路径`，把各家 agent 的目录差异收敛到一处 |
| `install.sh` | 安装器。读注册表 + agent 配置，建软链。支持 `--all` / `--list` / `--agent` |

## 配套：四个元 skill（skill 的方法论）

工厂不只有分发机制，还有一套"怎么做 skill"的完整方法论，本身也是 skill：

```
skill-bootstrap  →  项目结构初始化（在哪做、怎么发布、选哪种安装模式）
       ↓ 项目就绪
skill-creator    →  SKILL.md 内容编写（从 0 到 1 怎么写好）
       ↓ 初版完成
skill-iterating  →  持续迭代优化（从 1 到 N）
       ↓ 成熟可发布
skill-publish    →  开源发布（脱敏、补发布文件、发文审计、独立成库、发 release）
```

- **[skill-bootstrap](skill-bootstrap/SKILL.md)**：新建 skill 项目时的引导——目录结构、安装模式选择、发布映射注册。
- **[skill-creator](skill-creator/SKILL.md)**：编写 SKILL.md 的完整流程——捕获意图、访谈细化、渐进式披露、触发描述优化。
- **[skill-iterating](skill-iterating/SKILL.md)**：已有 skill 的持续迭代——冒烟测试、commit 检查点、跨会话恢复。
- **[skill-publish](skill-publish/SKILL.md)**：把私有 skill 整理成可开源形态——脱敏扫描、补发布文件、README 发文审计、独立成库、打 tag 发 release。

## 快速开始

```bash
# 1. 配置你的 agent（编辑 agents.conf，填你的 agent 和 skills 目录）
cp agents.conf.example agents.conf

# 2. 注册一个 skill（编辑 publish.map）
echo "my-skill=my-skill|all" >> publish.map

# 3. 安装到所有 agent
./install.sh --all

# 查看安装状态
./install.sh --list
```

## License

[MIT](LICENSE)
