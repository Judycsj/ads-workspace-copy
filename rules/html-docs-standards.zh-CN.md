# HTML 文档规范/HTML Docs Standards

## 何时使用 HTML/When to Use HTML

当 Markdown 和 HTML 都能满足需求时，**强烈推荐使用 Markdown**。仅在 Markdown 无法实现时才使用 HTML，例如：

- 需要 SVG / Canvas / JavaScript 的交互式可视化或架构图
- 具有复杂布局的幻灯片或演示文稿
- 包含图表、筛选器或动态渲染的数据看板
- 需要超出 Markdown 能力的自定义 CSS 样式的页面

## 元信息头/Metadata Header

HTML 文件需要在**两处**包含元信息 — 注释块供源码阅读者查看，渲染元素供浏览器查看者使用。

### （A）注释块/Comment Block

在文件最顶部、`<!DOCTYPE html>` **之前**放置 HTML 注释：

```html
<!--
  Preview: https://shopee.git-pages.garena.com/search_recommend/ai-copilot/ads-workspace/<file-path>
  Contributors: user.a, user.b
  Last Updated: YYYY-MM-DD
  GitLab: https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/<file-path>
-->
```

### （B）可渲染元信息栏/Rendered Metadata Bar

在 `<body>` 内、主要内容之前，包含一个可见的元信息元素，包含相同字段。样式不强制统一，但四个字段（Preview、Contributors、Last Updated、GitLab）**必须**全部存在且用户可读：

```html
<div class="doc-meta">
  <span>Contributors: user.a, user.b</span>
  <span>Last Updated: YYYY-MM-DD</span>
  <span><a href="https://git.garena.com/.../blob/master/<file-path>">GitLab</a></span>
  <span><a href="https://shopee.git-pages.garena.com/.../<file-path>">Preview</a></span>
</div>
```

### 字段规则/Field Rules

- **Contributors**：最近 3 位编辑者（最新在前）；就地更新，不重复添加
- **日期**：当天日期（`YYYY-MM-DD`）；每次编辑更新
- **新文档**：当前用户为唯一 Contributor
- **Preview URL**：GitLab Pages 地址 — `https://shopee.git-pages.garena.com/search_recommend/ai-copilot/ads-workspace/<file-path>`
- **GitLab URL**：源文件地址 — `https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/<file-path>`
- **Language 行**：存在双语版本（`<name>.zh-CN.html` / `<name>.html`）时，在渲染元信息栏中添加指向对应版本的可见链接

## 双语写作/Bilingual Writing

- 页面 `<title>` 和主要可见标题**建议**中英双语：`中文标题/English Title`
- 专有名词中英双语标注：如 "Feature Store Engine（特征存储引擎）"

### 双语文件对/Bilingual File Pairs

命名：英文版 `<name>.html` + 中文版 `<name>.zh-CN.html`。双语文件**必须在同一提交中同步修改**。

以下位置的文件**必须**提供双语版本：
- `docs/` 路径**以外**的所有文件（如 `rules/`、`skills/`、`guides/`、`specs/`）
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

- 可视化 HTML 文件（架构图、交互式图表）：存放在相关文档同级的 `img/` 子目录下
- 独立 HTML 页面：存放在与 Markdown 文档相同的 scoped 目录下（`docs/common/`、`docs/team/<team>/`、`docs/personal/<email-name>/`）
- 所有 HTML 文件在 merge 到 master 后通过 GitLab Pages 发布

## 引用 HTML 文件/Referencing HTML Files

在 Markdown 或其他文档中引用 HTML 文件时，**必须使用 Preview URL**（GitLab Pages 链接），不要使用本地文件路径或 GitLab 源码路径。Preview URL 能在浏览器中正确渲染页面，而 GitLab 源码链接只会显示原始 HTML 代码。

- **正确**：`[架构图](https://shopee.git-pages.garena.com/search_recommend/ai-copilot/ads-workspace/<file-path>)`
- **错误**：`[架构图](./img/architecture.html)` 或 `[架构图](https://git.garena.com/.../blob/master/<file-path>)`

## 文件移动与重命名/File Move & Rename

移动或重命名任何 HTML 文件时，**必须**使用 `Grep` 搜索整个 workspace 中对旧文件路径（或文件名）的引用，并将所有引用更新为新路径。搜索范围包括 `.md` 文件、`.html` 文件、`CLAUDE.md`、`SKILL.md`、`README.md` 以及任何配置文件。此外，还需更新注释块和渲染元信息栏中的 Preview URL 和 GitLab URL。

## 文件大小限制/File Size Limit

单个 HTML 文件**不得**超过 **500 KB**。超出此限制的文件将被 pre-commit hook 拒绝提交。如果文档超过 500 KB，请拆分为多个小文件，或将大体积内嵌内容（内联图片、数据表格、SVG 图形等）移至独立文件并引用。
