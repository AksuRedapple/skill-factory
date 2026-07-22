---
name: skill-publish
description: 把私有 skill 工厂里的 skill 整理成可开源发布的形态——脱敏扫描、补发布文件（README/LICENSE/.gitignore）、README 发文审计、insights 联动、独立成库、打 tag 发 release。当用户说"发布 skill"、"开源这个 skill"、"把这个 skill 发出去"、"整理成可发布的形态"时触发。元 skill 家族最后一环：bootstrap（建）→ creator（写）→ iterating（迭代）→ publish（发布）。
---

# Skill Publish —— 从私有工厂到开源发布

## 角色定义

把私有 skill 工厂里的 skill 整理成可开源发布的形态。元 skill 家族的最后一环：

```
skill-bootstrap  →  建（项目结构、安装模式、发布映射）
skill-creator    →  写（SKILL.md 内容，0→1）
skill-iterating  →  迭代（1→N）
skill-publish    →  发布（私有→公开）  ← 本 Skill
```

## 触发场景

- "发布这个 skill" / "开源这个 skill" / "把这个 skill 发出去"
- "整理成可发布的形态" / "这个 skill 可以开源了"

## 核心流程

```
脱敏扫描 → 补发布文件 → README 发文审计 → insights 联动 → 独立成库 → 发布
```

### 第一步：脱敏扫描（从严）

grep 扫全部文件，抓内部信息。**把下面的占位符换成你公司的内部关键词**：

```bash
# 换成你公司的：公司名、内部系统/平台名、项目代号、职级体系、业务指标、内网域名
grep -rniE '你的公司名|内部系统名|项目代号|职级|花名|工号|业务指标|内网域名' .
```

**注意误报**：RT / QPS / P99 是通用性能词，须保留（不是内部指标）。逐条甄别真敏感 vs 通用词。

**脱敏原则**：方法论本身是普适的（可公开）；私有证据（项目代号、内部案例）归项目仓库或 memo，不进开源 skill。

### 第二步：补发布文件

- **README.md**（给人看的入口）：定位 + 解决什么问题 + 核心想法 + 文件结构 + 安装（skill 工厂方式为主、手动软链兜底）+ 用法 + 配套。三层文档分工：README（给人）/ SKILL.md（给 agent）/ DESIGN.md（给想懂设计的人，可选）。
- **LICENSE**：MIT（或用户指定）。
- **.gitignore**：忽略本地配置（agents.conf / publish.map）、构建产物（dist/）、.DS_Store、.memory/。

### 第三步：README 发文审计（从严）

用 insights-guide 四红线 + SWG 三硬红线审 README：

- **四红线**：不贴标签（开创性/独创/核心竞争力）、不煽情（噩梦/令人兴奋/致命）、不客套（希望能给读者启发）、不预设观众（面试时可以这样讲 / 体现了 XX 特质）、不谦逊叙事（不是提前设计的）
- **SWG 三硬红线**：脱敏泄露 / 戏剧性造假 / 技术白皮书腔

**最易犯**：结尾忍不住抒情总结一句（"这大概也是大多数有用工具的样子"）——这种"写完夸自己一句"最该删。描述事实和推理，不评价自己。

### 第四步：insights 联动

- 检查有无配套 insight（skill 的设计思考）→ 有则更新到当前状态 + 脱敏
- 无则考虑写一篇（skill 的设计推理，遵循 insights-guide）
- insight 与 GitHub 仓库互链（博客讲"为什么"，仓库放"东西本身"）

### 第五步：独立成库

- `git init`（skill 独立成库；父目录非 git 则无嵌套问题，零迁移零复制）
- **noreply 署名**（`<id>+<username>@users.noreply.github.com`，避免暴露真实邮箱）
- 单条干净的 "Initial release" commit

### 第六步：发布

- semver tag（v0.1.0 起步，0.x 表示仍在迭代）
- Conventional Commits（feat / fix / docs 前缀）
- keepachangelog CHANGELOG
- `gh release create`（GitHub Release）
- **坑**：后建/补建的旧版本 tag 会被误标 Latest，须 `gh release edit <newer-tag> --latest` 修回

## 关键原则

- **脱敏从严**：宁可多删，不漏内部信息
- **README 过发文审计**：描述事实和推理，不评价自己
- **单一 SSOT**：方法论脱敏后公开作为唯一版本，私有证据归项目仓库 / memo
- **noreply 署名**：避免暴露真实邮箱
- **展示版反哺真实版**：打磨对外脱敏版本时顺手揪出真实版 bug——对外发布是倒逼内部质量的机会

## 与其他元 Skill 的关系

```
skill-bootstrap  →  建（项目结构）
       ↓
skill-creator    →  写（SKILL.md 内容）
       ↓
skill-iterating  →  迭代（1→N）
       ↓
skill-publish    →  发布（私有→公开）  ← 本 Skill
```

详见 `_meta/insights/` 的 skill 工程化系列（#17 是本 skill 的设计推理）。
