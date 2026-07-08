# Markdown Docs Standards

## Bilingual Writing

- All markdown headings MUST be bilingual: `中文标题/English Title`
- Bilingual annotation for proper nouns: e.g. "Feature Store Engine (特征存储引擎)"

### Bilingual File Pairs

Naming: English `<name>.md` + Chinese `<name>.zh-CN.md`. Both MUST be updated together in the same commit.

Files MUST have bilingual pairs when located in:
- Any path **outside** `docs/` (e.g. `rules/`, `skills/`, `guides/`, `CLAUDE*.md`, `README*.md`)
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

- Scoped docs: `docs/common/`, `docs/team/<team>/`, `docs/personal/<email-name>/`
- Skill-specific details: each skill's `references/`
- Images: store in `img/` subdirectory alongside the Markdown file; flat structure, no nested subdirectories. Reference via `./img/filename.png`
- Superpowers-generated files: `docs/personal/<email-name>/superpowers/` only

## File Move & Rename

When moving or renaming any Markdown file, you MUST use `Grep` to search the entire workspace for references to the old file path (or filename) and update all occurrences to the new path. This includes links in other `.md` files, `CLAUDE.md`, `SKILL.md`, `README.md`, and any configuration files.

## Metadata Header

For any Markdown under `docs/` or `guides/` (excluding READMEs), add immediately after the `#` heading:

```
> **Contributors**: user.a, user.b ｜ **最后更新**：YYYY-MM-DD ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/<file-path>)
```

- **Contributors**: most recent 3 editors (newest first); update in place, don't duplicate
- **Date**: today's date (`YYYY-MM-DD`); update on every edit
- **New doc**: current user as sole contributor
- **Language line**: if a bilingual counterpart exists (`<name>.zh-CN.md` / `<name>.EN.md` / etc.), add after metadata:
  `> **Language**: [English](<en-file>) | [中文](<zh-file>)` — both files must have it

## File Size Limit

A single Markdown file MUST NOT exceed **500 KB**. Files over this limit will be rejected by the pre-commit hook. If a document grows beyond 500 KB, split it into smaller files or move large embedded content (base64 images, data tables) into separate files and reference them.
