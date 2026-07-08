---
name: ads-doc-comment
description: >
  Ads Doc Comment (文档评论系统) — add, reply, resolve, and list inline review comments
  in Markdown documents under docs/. Supports async document review, collaborative
  discussion, and AI-assisted review with severity markers.
  TRIGGER when: user mentions "doc comment", "add comment", "review doc", "comment on",
  "文档评论", "添加评论", "review 文档", "审查文档", "list comments", "列出评论",
  "resolve comment", "解决评论", "clean comments", "清理评论", or asks to review/comment
  on a markdown document in docs/.
  DO NOT TRIGGER when: reviewing bidding TDs (use ads-bidding-td-review),
  reviewing algorithm TDs (use ads-td-reviewer), syncing docs to Google Drive
  (use ads-workspace-gdoc-sync), or code review (use MR review workflow).
user-invocable: true
---

# Ads Doc Comment/文档评论系统

Adds Google Docs-like inline commenting to Markdown documents. Comments are stored as HTML comments with `@doc-comment` prefix — invisible in rendered Markdown, compatible with gdoc-sync.

**Before first use, read:**
1. [references/format-spec.md](references/format-spec.md) — comment format, placement rules, ID generation, parsing guide
2. [references/review-guidelines.md](references/review-guidelines.md) — severity levels, review focus areas, quality checklist

---

## Operations/操作

### 1. `add` — Add Comment/添加评论

**Input**: file path + target location + comment text + optional severity

**Target location** (one of):
- `--section "heading text"`: place after the heading matching the text (fuzzy match OK)
- `--after "text snippet"`: place after the first paragraph containing this text
- `--line N`: place after line N
- If none specified, ask user with `AskUserQuestion`

**Workflow**:
1. Read the file with `Read`
2. Detect author: `git config user.name` → `$USER` → `unknown`
3. Generate ID: scan file for existing `c-YYYYMMDD-*` IDs, use next sequential number
4. Locate the target line; if inside a fenced code block, move to after the closing fence
5. Insert the comment block after the target line, preceded and followed by blank lines
6. Write with `Edit` (replace the target line area to include the comment block)

**Comment block template**:
```html

<!-- @doc-comment id="ID" author="AUTHOR" date="YYYY-MM-DD" status="open" severity="SEVERITY" -->
<!-- COMMENT_TEXT -->
<!-- @/doc-comment -->
```

If no severity, omit the `severity="..."` attribute.

### 2. `reply` — Reply to Comment/回复评论

**Input**: file path + comment ID + reply text

**Workflow**:
1. Read the file, find the comment block with the given ID
2. If not found, report error
3. Detect author and date
4. Insert a reply block **before** the `<!-- @/doc-comment -->` close tag:

```html
<!-- @doc-reply author="AUTHOR" date="YYYY-MM-DD" -->
<!-- REPLY_TEXT -->
```

### 3. `resolve` — Resolve Comment/解决评论

**Input**: file path + comment ID

**Workflow**:
1. Find the comment block open tag
2. Change `status="open"` to `status="resolved"`
3. Use `Edit` to replace the open tag line

### 4. `list` — List Comments/列出评论

**Input**: file path + optional filters (`--status`, `--author`, `--severity`)

**Workflow**:
1. Read the file
2. Parse all comment blocks (see parsing guide in format-spec.md § 8)
3. Apply filters
4. Output a table:

```markdown
| ID | Severity | Author | Date | Location | Summary | Replies | Status |
|----|----------|--------|------|----------|---------|---------|--------|
| c-20260509-0001 | Major | luka.yang | 2026-05-09 | § 2.1 Architecture | Missing error handling | 1 | open |
```

**Location**: show the nearest preceding heading (e.g., `§ 2.1 Architecture`)

### 5. `delete` — Delete Comment/删除评论

**Input**: file path + comment ID

**Workflow**:
1. Find the entire comment block (from open tag to close tag, inclusive)
2. Confirm with user before deleting
3. Remove the block and any surrounding extra blank lines (keep at most one blank line)

### 6. `review` — AI Review/AI 审查

**Input**: file path + optional `--focus` (completeness | architecture | clarity)

**Workflow**:
1. Read the full document
2. Read [references/review-guidelines.md](references/review-guidelines.md) for severity definitions and quality checklist
3. Analyze the document with the specified focus (or general review if no focus)
4. For each finding:
   a. Determine severity: `blocker` > `major` > `minor` > `suggestion`
   b. Identify the best location (section heading)
   c. Write actionable comment text: `[Severity] Issue description → Suggested fix`
5. Insert all comment blocks into the document
6. Output a review summary table (see review-guidelines.md § 4)

**Rules**:
- Aim for 5–15 comments per document; if over 20, suggest a rewrite instead
- Always acknowledge positive aspects (at least one `[Suggestion]` for good parts)
- Each comment MUST be actionable — state what's wrong AND suggest a fix
- No duplicate findings on the same issue

### 7. `summary` — Comment Summary/评论摘要

**Input**: file path

**Workflow**: Same as `list` but:
- Only shows `status="open"` comments
- Groups by severity
- Adds a count line: `**Total**: X Blocker, Y Major, Z Minor, W Suggestion`

### 8. `clean` — Clean Comments/清理评论

**Input**: file path + mode

**Modes**:
- `--resolved-only` (default): remove only `status="resolved"` comment blocks
- `--all`: remove all comment blocks
- `--dry-run`: show what would be removed without modifying the file

**Workflow**:
1. Find all matching comment blocks
2. Show preview of blocks to be removed
3. If not `--dry-run`, confirm with user via `AskUserQuestion`
4. Remove blocks, clean up extra blank lines
5. Report how many blocks were removed

---

## Safety Rules/安全规则

1. **Scope**: Only operate on files under `docs/` directory. Refuse to add comments to files outside `docs/`.
2. **Code block protection**: Never insert comments inside fenced code blocks. Check for `` ``` `` boundaries before insertion.
3. **No content modification**: Comment operations MUST NOT modify the original document content — only add/remove comment blocks.
4. **Escape `-->`**: If comment text contains `-->`, automatically escape to `-- >`.
5. **Undo via git**: All changes are file edits tracked by git. Inform the user they can revert with `git checkout -- <file>`.
6. **Confirmation**: `delete` and `clean` (non-dry-run) require user confirmation before execution.

---

## Examples/使用示例

### Add a comment to a section

User: "给 docs/team/00.paid-ads-dev/03.sop/01.okr-sop.md 的 '## 3. OKR 评审流程' 添加一条评论：缺少评审频率的说明"

→ Skill reads the file, finds `## 3. OKR 评审流程`, inserts:

```html
<!-- @doc-comment id="c-20260509-0001" author="luka.yang" date="2026-05-09" status="open" -->
<!-- 缺少评审频率的说明 -->
<!-- @/doc-comment -->
```

### AI review a document

User: "review docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o3/kr1-kp1-202605091537/epic-file.md --focus completeness"

→ Skill reads the document, analyzes completeness, inserts inline comments at relevant locations, outputs a summary table.

### List and resolve

User: "list comments in docs/common/ads-overview.md --status open"

→ Outputs table of all open comments.

User: "resolve c-20260509-0001"

→ Changes status to resolved.

### Clean resolved comments

User: "clean comments in docs/common/ads-overview.md"

→ Removes all resolved comment blocks, reports count.
