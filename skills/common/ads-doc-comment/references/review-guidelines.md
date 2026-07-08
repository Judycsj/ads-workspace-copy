# AI Review Guidelines/AI 审查指南

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-09 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/skills/common/ads-doc-comment/references/review-guidelines.md)

---

## 1. Severity Definitions/严重级别定义

Consistent with existing review skills (`ads-bidding-td-review`, `ads-td-reviewer`):

| Severity | Label | Definition/定义 | Action Required/要求 |
|----------|-------|-----------------|---------------------|
| `blocker` | `[Blocker]` | Critical issue that blocks approval; factual errors, missing essential sections, security risks | Must fix before merge/approval |
| `major` | `[Major]` | Significant gap or unclear area that should be addressed | Should fix; justify if skipped |
| `minor` | `[Minor]` | Non-critical improvement; wording, formatting, minor omissions | Nice to fix; can defer |
| `suggestion` | `[Suggestion]` | Optional enhancement; alternative approach, additional context | At author's discretion |

## 2. Review Focus Areas/审查重点

When `--focus` is specified, the AI reviewer concentrates on the corresponding area:

### `completeness` — 完整性

- Are all required sections present per the template?
- Are acceptance criteria / success metrics defined?
- Are edge cases and error scenarios covered?
- Are dependencies and risks listed?

### `architecture` — 架构设计

- Is the system design sound and scalable?
- Are component boundaries and interfaces clearly defined?
- Are data flows and state management explained?
- Are non-functional requirements (performance, availability) addressed?

### `clarity` — 清晰度

- Is the writing clear and unambiguous?
- Are diagrams / tables used where they improve understanding?
- Are domain terms defined or linked?
- Is the document self-contained enough for the target audience?

### General (no focus) — 通用审查

When no focus is specified, review all three areas above with equal weight.

## 3. Review Quality Checklist/审查质量清单

Before outputting review comments, verify:

- [ ] Each comment is placed at the **most relevant location** in the document
- [ ] Severity accurately reflects the impact (`blocker` is reserved for truly blocking issues)
- [ ] Comment body is **actionable** — states what's wrong and suggests how to fix
- [ ] No duplicate comments on the same issue
- [ ] Positive aspects are acknowledged (not only criticism)
- [ ] Total comments are reasonable: aim for 5–15 per document; over 20 suggests the document needs a rewrite rather than inline fixes

## 4. Review Output Format/审查输出格式

After inserting all inline comments, output a summary table to the conversation:

```markdown
## Review Summary/审查摘要

| # | Severity | Location | Finding |
|---|----------|----------|---------|
| 1 | [Blocker] | § 2.1 Architecture | Missing error handling for service timeout |
| 2 | [Major] | § 3.2 Data Flow | Data consistency guarantee not specified |
| 3 | [Minor] | § 4 Testing | No load testing plan mentioned |

**Total**: X Blocker, Y Major, Z Minor, W Suggestion
```

## 5. Comment Body Format/评论正文格式

- Start with severity label: `[Blocker]`, `[Major]`, `[Minor]`, or `[Suggestion]`
- Follow with a concise description of the issue
- Optionally include a suggested fix after a `→` separator

Example:

```html
<!-- [Major] Missing retry strategy for external API calls → Consider adding exponential backoff with 3 retries -->
```

For non-review (human discussion) comments, the severity label and `→` separator are optional.
