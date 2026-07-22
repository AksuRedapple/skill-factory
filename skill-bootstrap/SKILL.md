---
name: skill-bootstrap
description: Skill 开发环境初始化与规范引导。当用户说"创建新 Skill"、"新建 Skill 项目"、"Skill 开发规范"、"发布流程是什么"、"目录结构怎么弄"时触发。本 Skill 仅负责项目结构初始化、安装模式选择和发布映射注册，不负责 SKILL.md 内容的具体编写——内容编写请使用 skill-creator。
---

# Skill Bootstrap —— Skill 开发前置引导

在开始开发任何新 Skill 之前，先读以下规范，确保在正确的地方、用正确的方式工作。

## 第一步：确认开发位置

新 Skill 的开发目录必须在 skill 工厂下，而不是直接在某个 agent 的 skills 目录里。

```
✅ 正确：~/skill-factory/my-new-skill/SKILL.md
❌ 错误：~/.claude/skills/my-new-skill/SKILL.md（这是安装目录，不是开发目录）
```

开发目录是源码的 SSOT；agent 的 skills 目录里放的是指向它的软链（由 install.sh 建）。

## 第二步：确定安装模式

**在创建项目结构之前，必须先问用户选哪种模式：**

> "这个 Skill 是自己用还是要发布给其他人？自己用走直链模式（改了立刻生效），给别人用走构建模式（需要 build）。"

| 模式 | 适用场景 | 特征 |
|------|---------|------|
| **直链模式** | 自用 Skill（绝大多数） | 软链直接指向项目根目录，改了 SKILL.md 立刻生效，无需构建 |
| **构建模式** | 需分发给他人 / 有复杂构建产物 | 需 build → dist/，安装指向 dist/ 子目录，用于过滤开发文件 |

**判据**：自己用 → 直链；给别人用 / 有需过滤的开发文件 → 构建。

### 直链模式（推荐，自用默认）

项目结构最简：

```
my-new-skill/
├── SKILL.md          ← 主文件（必须）
├── references/       ← 参考文档（可选）
├── docs/             ← 开发文档（可选）
└── evals/            ← 测试用例（可选）
```

不需要 Makefile、VERSION、scripts/build.sh、dist/。

### 构建模式（分发 / 复杂项目）

```
my-new-skill/
├── SKILL.md
├── Makefile          ← 构建和发布命令
├── VERSION           ← 版本号
├── scripts/build.sh  ← 打包脚本（把运行时文件复制到 dist/）
├── dist/             ← 构建产物（build.sh 生成，不手动编辑）
├── references/       ← 参考文档（随 Skill 发布）
├── docs/             ← 开发文档（不发布）
└── evals/            ← 测试用例（不发布）
```

## 第三步：注册发布映射

在 `publish.map` 末尾添加一行：

```
my-new-skill=my-new-skill|all
```

格式：`skill名=项目路径|目标agent`，多个 agent 用逗号分隔，`all` 表示所有 agent（见 agents.conf）。

## 第四步：安装

### 直链模式

install.sh 会自动建软链（优先 dist/，没有就链源码根）：

```bash
./install.sh my-new-skill          # 装到 publish.map 声明的 agent
./install.sh my-new-skill --agent claude   # 只装到某个 agent
./install.sh --list                # 查看安装状态
```

安装完成后，修改 SKILL.md 立即生效，无需额外步骤。

### 构建模式

```bash
make build              # 构建 dist 产物
./install.sh my-new-skill   # 安装（软链到 dist/）
```

每次改源文件后需重新 build + install 才生效。

## 下一步

项目结构就绪后，用 **skill-creator** 编写 SKILL.md 内容；后续迭代用 **skill-iterating**。

```
skill-bootstrap  →  项目结构初始化（在哪做、怎么发布）  ← 本 Skill
       ↓ 项目就绪
skill-creator    →  SKILL.md 内容编写（怎么写好）
       ↓ 初版完成
skill-iterating  →  持续迭代优化（从 1 到 N）
```
