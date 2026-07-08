# Markdown 文档规范/Markdown Docs Standards

## 双语写作/Bilingual Writing

- 所有 Markdown 标题**必须**中英双语：`中文标题/English Title`
- 专有名词中英双语标注：如 "Feature Store Engine（特征存储引擎）"

### 双语文件对/Bilingual File Pairs

命名：英文版 `<name>.md` + 中文版 `<name>.zh-CN.md`。双语文件**必须在同一提交中同步修改**。

以下位置的文件**必须**提供双语版本：
- `docs/` 路径**以外**的所有文件（如 `rules/`、`skills/`、`guides/`、`CLAUDE*.md`、`README*.md`）
- `docs/` 下的以下目录：
  - `docs/common/core-knowledge`
  - `docs/common/datamap`
  - `docs/common/readme`
  - `docs/team/00.paid-ads-dev/01.team-info`
  - `docs/team/00.paid-ads-dev/02.onboarding`
  - `docs/team/00.paid-ads-dev/03.sop`
  - `docs/team/00.paid-ads-dev/04.how-tos`
  - `docs/team/00.paid-ads-dev/05.okr-and-projects`

其他 `docs/` 路径（如 `docs/common/ops-log/questions/`、`docs/personal/`）不要求双语文件对。

## 文件存放/File Placement

- Scoped 文档：`docs/common/`、`docs/team/<team>/`、`docs/personal/<email-name>/`
- Skill 专属细节：各 skill 的 `references/`
- 图片：存放在 Markdown 文件同级的 `img/` 目录下，平铺不建子目录。引用路径：`./img/filename.png`
- Superpowers 生成的文件：仅放 `docs/personal/<email-name>/superpowers/`

## 文件移动与重命名/File Move & Rename

移动或重命名任何 Markdown 文件时，**必须**使用 `Grep` 搜索整个 workspace 中对旧文件路径（或文件名）的引用，并将所有引用更新为新路径。搜索范围包括其他 `.md` 文件、`CLAUDE.md`、`SKILL.md`、`README.md` 以及任何配置文件。

## 元信息头/Metadata Header

`docs/` 或 `guides/` 下的 Markdown（README 除外），在 `#` 标题后紧跟：

```
> **Contributors**: user.a, user.b ｜ **最后更新**：YYYY-MM-DD ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/<file-path>)
```

- **Contributors**：最近 3 位编辑者（最新在前）；就地更新，不重复添加
- **日期**：当天日期（`YYYY-MM-DD`）；每次编辑更新
- **新文档**：当前用户为唯一 Contributor
- **Language 行**：存在双语版本（`<name>.zh-CN.md` / `<name>.EN.md` 等）时，在元信息后添加：
  `> **Language**: [English](<英文文件名>) | [中文](<中文文件名>)` — 双语文件都必须有

## 文件大小限制/File Size Limit

单个 Markdown 文件**不得**超过 **500 KB**。超出此限制的文件将被 pre-commit hook 拒绝提交。如果文档超过 500 KB，请拆分为多个小文件，或将大体积内嵌内容（base64 图片、数据表格等）移至独立文件并引用。
