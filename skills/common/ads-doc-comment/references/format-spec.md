# Doc Comment Format Specification/文档评论格式规范

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-09 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/skills/common/ads-doc-comment/references/format-spec.md)

---

## 1. Overview/概述

Doc comments are stored as **inline HTML comments** within Markdown files. Each comment block uses the `@doc-comment` prefix to distinguish from regular HTML comments (e.g., `<!-- Fields: ... -->` used in templates).

评论以**内联 HTML 注释**形式存储在 Markdown 文件中。每个评论块使用 `@doc-comment` 前缀，与模板中的普通 HTML 注释区分。

## 2. Block Structure/块结构

```html
<!-- @doc-comment id="c-20260509-0001" author="luka.yang" date="2026-05-09" status="open" severity="major" -->
<!-- [Major] This architecture section needs more detail on error handling -->
<!-- @doc-reply author="john.doe" date="2026-05-10" -->
<!-- Good point, I'll add a retry logic section -->
<!-- @/doc-comment -->
```

### Grammar/语法

```
COMMENT_BLOCK :=
  OPEN_TAG
  BODY_LINE+
  REPLY_BLOCK*
  CLOSE_TAG

OPEN_TAG    := <!-- @doc-comment id="ID" author="AUTHOR" date="DATE" status="STATUS" [severity="SEVERITY"] -->
BODY_LINE   := <!-- COMMENT_TEXT -->
REPLY_BLOCK := REPLY_TAG REPLY_BODY
REPLY_TAG   := <!-- @doc-reply author="AUTHOR" date="DATE" -->
REPLY_BODY  := <!-- REPLY_TEXT -->
CLOSE_TAG   := <!-- @/doc-comment -->
```

### Field Definitions/字段定义

| Field/字段 | Required/必填 | Format/格式 | Description/说明 |
|------------|:---:|------------|------------------|
| `id` | Yes | `c-YYYYMMDD-NNNN` | Unique comment ID; date + 4-digit sequential counter |
| `author` | Yes | email-name (e.g., `luka.yang`) | Comment author |
| `date` | Yes | `YYYY-MM-DD` | Creation date |
| `status` | Yes | `open` \| `resolved` | Comment status |
| `severity` | No | `blocker` \| `major` \| `minor` \| `suggestion` | Severity level for review comments |

## 3. ID Generation/ID 生成规则

1. Format: `c-YYYYMMDD-NNNN` where `YYYYMMDD` is today's date and `NNNN` is a 4-digit zero-padded sequential counter
2. Counter starts at `0001` for each date
3. Before assigning an ID, scan the file for existing IDs with today's date and use the next available number
4. If a collision is detected (concurrent reviewers), append a 4-char random alphanumeric suffix: `c-20260509-0001-a3f2`

## 4. Placement Rules/放置规则

### MUST/必须

- Comment blocks MUST be placed on **standalone paragraph lines** — preceded and followed by blank lines (or other comment blocks)
- Comment blocks are placed **immediately after** the target content (heading, paragraph, list item)

### MUST NOT/禁止

- MUST NOT be placed inside fenced code blocks (`` ``` ``). If the target is inside a code block, place the comment after the closing fence
- MUST NOT be placed inside other HTML comments
- MUST NOT be embedded inline within a paragraph (e.g., `Some text <!-- @doc-comment ... --> more text`)

### Example Placement/放置示例

```markdown
## 2. Architecture/架构设计

The system uses a microservice architecture with three main components.

<!-- @doc-comment id="c-20260509-0001" author="luka.yang" date="2026-05-09" status="open" severity="major" -->
<!-- [Major] Missing description of inter-service communication protocol -->
<!-- @/doc-comment -->

### 2.1 Service A
```

Multiple comment blocks on the same location are stacked:

```markdown
## 3. Error Handling/错误处理

<!-- @doc-comment id="c-20260509-0002" author="luka.yang" date="2026-05-09" status="open" severity="minor" -->
<!-- [Minor] Consider adding a retry strategy diagram -->
<!-- @/doc-comment -->

<!-- @doc-comment id="c-20260509-0003" author="jane.smith" date="2026-05-09" status="open" -->
<!-- Is there a timeout configuration for external API calls? -->
<!-- @/doc-comment -->
```

## 5. Escape Rules/转义规则

- Comment text MUST NOT contain the literal string `-->`. If needed, escape as `-- >` (space before `>`)
- Comment text lines MUST NOT start with `@doc-comment`, `@doc-reply`, or `@/doc-comment`
- No other escaping is required; all UTF-8 text (including Chinese) is allowed in comment body

## 6. Author Detection/作者检测

Detection order:

1. `git config user.name` — reads from git config (most reliable)
2. `$USER` environment variable — fallback
3. If neither available, use `unknown`

Format: email-name style with dots (e.g., `luka.yang`, `john.doe`)

## 7. gdoc-sync Compatibility/gdoc-sync 兼容性

- Block-level HTML comments on standalone lines are **silently dropped** by `md_to_gdoc_engine.py` (no `html_block` handler exists), so doc-comments will be invisible in synced Google Docs — this is the desired behavior
- This only works when comment blocks are standalone paragraphs. If mistakenly placed inline within text, the engine's `html_inline` handler would strip tags and expose comment text as visible content
- **Rule**: Always follow the placement rules in Section 4 to ensure gdoc-sync compatibility

## 8. Parsing Guide/解析指南

To locate all comment blocks in a file:

1. Search for lines matching `<!-- @doc-comment ` — each marks the start of a block
2. The block extends until a matching `<!-- @/doc-comment -->` line
3. Within a block, lines matching `<!-- @doc-reply ` mark reply boundaries
4. All other `<!-- ... -->` lines within the block are body/reply text

Regex patterns:

```
OPEN:  ^<!-- @doc-comment id="([^"]+)" author="([^"]+)" date="([^"]+)" status="([^"]+)"(?: severity="([^"]+)")? -->$
REPLY: ^<!-- @doc-reply author="([^"]+)" date="([^"]+)" -->$
CLOSE: ^<!-- @\/doc-comment -->$
BODY:  ^<!-- (.+) -->$
```
