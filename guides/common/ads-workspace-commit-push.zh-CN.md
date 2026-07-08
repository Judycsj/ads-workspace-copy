# 提交推送（ads-workspace-commit-push）使用指南

> **语言**：[English](ads-workspace-commit-push.md) | [中文](ads-workspace-commit-push.zh-CN.md)

ads-workspace 标准提交推送流程 — 分支安全检查、选择暂存文件、运行校验、AI 生成 conventional commit message、合并并推送。支持两种合并模式：**master**（标准 GitLab MR 流程，需走 CI/CD）和 **pre-master**（快速合并 — 本地 merge 到 pre-master，由定时任务自动合并 master）。

**唤醒词**：「commit」、「push」、「ads-workspace-commit-push」、「commit and push」、「commit 代码」、「提交」、「推送」、「提交并推送」、「create mr」、「创建 mr」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含多阶段工作流程 |
| `scripts/preflight.sh` | 预检：分支安全检查 + 工作区状态（JSON 输出） |
| `scripts/stage-validate.sh` | 暂存 + 软链维护 + 校验（JSON 输出） |
| `scripts/sync-and-preview.sh` | 拉取目标分支 + merge + diff 预览 + squash 判断（JSON 输出） |
| `scripts/mr-ops.sh` | MR 检查 / 创建 / 轮询合并 / 合并后清理（JSON 输出） |
| `scripts/local-merge.sh` | pre-master 快速合并的本地 merge + push（JSON 输出） |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|------|------|------|
| Git remote 访问 | 网络 | 拉取最新 master 及 push 到远端仓库需要 |
| `scripts/validate.sh` | 本地 | CI/CD 校验脚本（已在仓库中） |
| `glab` | CLI | GitLab CLI，用于创建 Merge Request（`brew install glab`） |

---

## 流程概览

Skill 的工作流程根据**目标分支**（master 或 pre-master）自适应：

```
阶段一：预检       → 分支安全检查 + 个人记忆写入 + 展示工作区状态
阶段二：暂存与校验 → 选文件 + 软链追踪 + 校验确认
阶段三：提交       → 生成 commit message + 执行 commit
阶段四+五：同步与合并 → 根据目标分支分流：
  → target == master：合并 master + MR 预览 + push + 创建 MR + 可选自动 merge
  → target == pre-master：本地 merge + 直接 push（无 MR，由定时任务自动合并 master）
```

### 阶段一：预检

1. **分支安全检查** — 阻止直接向目标分支（默认 `master`/`main`）提交；提示创建新分支（格式：`<名字>/<类型>/<描述>`）或取消
2. **写入个人记忆** — 若 `docs/personal/<user>/memory/` 存在，静默写入当日记忆文件，使其可被暂存提交
3. **展示工作区状态** — `git status --short`；若工作区干净，检查未推送的本地 commit，若有则跳至阶段四
4. **一次性确认** — 一次收集所有决策：
   - **暂存方式**：全部暂存或选择特定文件
   - **目标分支**：pre-master（推荐，快速合并）或 master（标准 MR 流程）
   - **MR 操作**（仅 master）：创建并自动 merge、仅创建、仅 push

### 阶段二：暂存与校验

5. **暂存、校验与确认** — 将所有文件分两组展示（已暂存 vs 未暂存/未跟踪）；自动维护 common skill 软链（新增时追踪、删除时移除）；运行 `bash scripts/validate.sh`；用户一次确认当前暂存内容、调整文件（`+file` 新增暂存、`-file` 移除暂存）、全部暂存或取消；ERROR 终止

### 阶段三：提交

6. **生成 commit message** — AI 生成 conventional commit；用户确认、修改或取消
7. **提交** — 执行 `git commit`；展示结果

### 阶段四+五：同步与合并

#### 路径 A：target == master（标准 MR 流程）

8. **合并最新 master** — `git fetch origin master` + `git merge origin/master`；冲突时提供 Agent 自动解决、手动解决或放弃 merge 三个选项
9. **MR 预览与 push** — 展示完整 MR 范围（`--name-status` + `--stat` + diff），用户确认 push 或取消
10. **创建 MR 与 Merge** — 检查是否已有 open MR（已有则提供自动 merge 选项）；若无，通过 `glab mr create` 创建（自动生成标题和描述）；可选轮询 CI 并自动 merge

#### 路径 B：target == pre-master（快速合并流程）

8. **本地 merge + push** — 运行 `local-merge.sh`，将改动 merge 到 pre-master（由定时任务自动合并 master）：
   - 推送源分支到 origin
   - 拉取 pre-master，本地 checkout
   - 将源分支 merge 到 pre-master 并推送
   - 切回源分支，将 pre-master merge 回源分支
   - 推送源分支到 origin（三方同步）
   - 删除本地 pre-master 分支
   - 展示 pre-master 与 master 的 diff 供审查

---

## 使用示例

> 「ads-workspace-commit-push」或「帮我 commit 并 push 当前改动」

Skill 会以交互方式引导整个流程，无需额外参数。

### 快速模式

> 「commit push mr」、「--fast」或「快速提交」

跳过所有确认步骤，使用默认值：自动 `git add -A`、自动生成 commit message、目标分支 = pre-master、自动本地 merge 并 push。仅在以下情况暂停：目标分支上、校验 ERROR、merge 冲突。

### pre-master 快速合并

默认推荐 merge 到 `pre-master` 而非 `master`。`pre-master`（分支名：`luka.yang/feat/pre-master`）是一个暂存分支，由**定时任务自动合并到 master**，开发者无需每次都走完整的 CI/CD + MR 流程。

选择 `pre-master` 时：

- 不创建 MR（改动在本地 merge 后直接 push）
- 源分支本地 merge 到 pre-master 后 push 到 origin
- merge 完成后展示 pre-master 相对 master 的 diff 供审查
- push 成功后展示远端分支 GitLab 链接，方便查看代码
- 本地源分支、origin 源分支、origin pre-master 三方保持一致
- 定时任务负责最终将 pre-master 合并到 master

如需使用标准 MR 流程，在目标分支选择步骤中选择 `master`。

### 实战演练：部分暂存文档改动

**场景**：你修改了 2 个 kickoff 文档（中文 + 英文），但 `skills/personal/` 下还有其他不想一起提交的改动。

```
阶段一 — 预检
  ✓ 分支：luka.yang/feat/add-ads-skill（功能分支，安全）
  ✓ 工作区：2 个文档已修改 + 5 个其他无关改动

阶段二 — 暂存与校验
  ? 「全部暂存还是指定文件？」
  → 用户选择「我来指定文件」，输入：ads-ai-agent-workspace-kickoff.*
  ✓ 2 个文件已暂存（M ads-ai-agent-workspace-kickoff.md, M ...EN.md）
  ✓ validate.sh 通过
  ✓ 展示暂存文件清单，用户确认「全部保留」

阶段三 — 提交
  ✓ AI 生成：docs(kickoff): update §6.5 meeting transcription status...
  ? 用户确认 → git commit → 114f821（2 个文件，+16/-8）

阶段四 — 同步推送
  ✓ git fetch origin master → master 上有 10 个新 commit
  ✓ git merge origin/master → 自动合并，无冲突
  ✓ MR 预览：2 个文件（+16/-8），用户确认 push
  ✓ git push → 成功

阶段五 — MR
  ✓ 未找到已有的 open MR
  ✓ glab mr create → 创建 MR !562
  ✓ CI 通过 → glab mr merge → 已合并
  ✓ master 已更新，luka.yang/feat/add-ads-skill 已 merge master
```

**要点**：你不必一次提交所有改动 — 用 glob 模式选择特定文件，skill 会自动处理后续流程。

---

## Commit Message 格式

遵循 CLAUDE.md 要求的 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <description>

<body — 说明 why，不是 what>

Co-Authored-By: Claude <noreply@anthropic.com>
```

支持的 type：`feat`、`fix`、`docs`、`refactor`、`chore`、`style`、`perf`、`ci`、`build`、`revert`

---

## 分支命名规范

```
<用户名>/<类型>/<描述>
```

示例：`luka.yang/feat/add-skill`、`tom.chen/docs/update-readme`

不允许直接向 `master` 或 `main` 提交 — Skill 会强制引导创建新分支。

---

## 安装方式

本 skill 属于 common scope，打开 workspace 时自动加载，无需手动安装。
