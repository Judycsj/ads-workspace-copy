# HTML Docs Standards

## When to Use HTML

When both Markdown and HTML can meet the requirements, **strongly prefer Markdown**. Only use HTML when there is a clear reason that Markdown cannot fulfill, for example:

- Interactive visualizations or architecture diagrams requiring SVG / Canvas / JavaScript
- Slide decks or presentations with complex layouts
- Rich data dashboards with charts, filters, or dynamic rendering
- Pages that require custom CSS styling beyond Markdown capabilities

## Metadata Header

HTML files require metadata in **two places** — a comment block for source-code readers and a rendered element for browser viewers.

### (A) Comment Block

Place an HTML comment at the very top of the file, **before** `<!DOCTYPE html>`:

```html
<!--
  Preview: https://shopee.git-pages.garena.com/search_recommend/ai-copilot/ads-workspace/<file-path>
  Contributors: user.a, user.b
  Last Updated: YYYY-MM-DD
  GitLab: https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/<file-path>
-->
```

### (B) Rendered Metadata Bar

Inside `<body>`, before the main content, include a visible metadata element containing the same fields. Style is not enforced, but all four fields (Preview, Contributors, Last Updated, GitLab) MUST be present and human-readable:

```html
<div class="doc-meta">
  <span>Contributors: user.a, user.b</span>
  <span>Last Updated: YYYY-MM-DD</span>
  <span><a href="https://git.garena.com/.../blob/master/<file-path>">GitLab</a></span>
  <span><a href="https://shopee.git-pages.garena.com/.../<file-path>">Preview</a></span>
</div>
```

### Field Rules

- **Contributors**: most recent 3 editors (newest first); update in place, don't duplicate
- **Date**: today's date (`YYYY-MM-DD`); update on every edit
- **New doc**: current user as sole contributor
- **Preview URL**: GitLab Pages URL — `https://shopee.git-pages.garena.com/search_recommend/ai-copilot/ads-workspace/<file-path>`
- **GitLab URL**: source file URL — `https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/<file-path>`
- **Language line**: if a bilingual counterpart exists (`<name>.zh-CN.html` / `<name>.html`), add a visible link to the counterpart in the rendered metadata bar

## Bilingual Writing

- Page `<title>` and the main visible heading SHOULD be bilingual: `中文标题/English Title`
- Bilingual annotation for proper nouns: e.g. "Feature Store Engine (特征存储引擎)"

### Bilingual File Pairs

Naming: English `<name>.html` + Chinese `<name>.zh-CN.html`. Both MUST be updated together in the same commit.

Files MUST have bilingual pairs when located in:
- Any path **outside** `docs/` (e.g. `rules/`, `skills/`, `guides/`, `specs/`)
- The following `docs/` directories:
  - `docs/common/core-knowledge`
  - `docs/common/datamap`
  - `docs/common/readme`
  - `docs/team/00.paid-ads-dev/01.team-info`
  - `docs/team/00.paid-ads-dev/02.onboarding`
  - `docs/team/00.paid-ads-dev/03.sop`
  - `docs/team/00.paid-ads-dev/04.how-tos`
  - `docs/team/00.paid-ads-dev/05.okr-and-projects`

Other `docs/` paths (e.g. `docs/common/ops-log/questions/`, `docs/personal/`) do NOT require bilingual pairs.

## File Placement

- HTML files for visualizations (architecture diagrams, interactive charts): store in `img/` subdirectory alongside related documents
- Standalone HTML pages: store in the same scoped directory as Markdown docs (`docs/common/`, `docs/team/<team>/`, `docs/personal/<email-name>/`)
- All HTML files are published to GitLab Pages on merge to master

## Referencing HTML Files

When linking to an HTML file from Markdown or other documents, **always use the Preview URL** (GitLab Pages link), not a local file path or GitLab source URL. The Preview URL renders the page correctly in the browser, while GitLab source links display raw HTML code.

- **Correct**: `[Architecture Diagram](https://shopee.git-pages.garena.com/search_recommend/ai-copilot/ads-workspace/<file-path>)`
- **Wrong**: `[Architecture Diagram](./img/architecture.html)` or `[Architecture Diagram](https://git.garena.com/.../blob/master/<file-path>)`

## File Move & Rename

When moving or renaming any HTML file, you MUST use `Grep` to search the entire workspace for references to the old file path (or filename) and update all occurrences to the new path. This includes links in `.md` files, `.html` files, `CLAUDE.md`, `SKILL.md`, `README.md`, and any configuration files. Additionally, update the Preview URL and GitLab URL in both the comment block and the rendered metadata bar.

## File Size Limit

A single HTML file MUST NOT exceed **500 KB**. Files over this limit will be rejected by the pre-commit hook. If a document grows beyond 500 KB, split it into smaller files or move large embedded content (inline images, data tables, SVG graphics) into separate files and reference them.
