# Commit and Push (ads-workspace-commit-push) Guide

> **Language**: [English](ads-workspace-commit-push.md) | [中文](ads-workspace-commit-push.zh-CN.md)

Standard commit and push workflow for ads-workspace — branch safety check, stage files, validate, AI-generated conventional commit message, merge and push. Supports two merge modes: **master** (standard GitLab MR flow with CI/CD) and **pre-master** (fast merge — local merge to pre-master, auto-merged to master by scheduled task).

**Trigger keywords**: "commit", "push", "ads-workspace-commit-push", "commit and push", "commit 代码", "提交", "推送", "提交并推送", "create mr", "创建 mr"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with multi-phase workflow |
| `scripts/preflight.sh` | Pre-flight: branch check + working directory status (JSON output) |
| `scripts/stage-validate.sh` | Stage files + symlink maintenance + validation (JSON output) |
| `scripts/sync-and-preview.sh` | Fetch target branch + merge + diff preview + squash check (JSON output) |
| `scripts/mr-ops.sh` | MR check / create / poll-and-merge / post-merge (JSON output) |
| `scripts/local-merge.sh` | Local merge + push for pre-master fast merge (JSON output) |

---

## Prerequisites

| Dependency | Type | Purpose |
|------------|------|---------|
| Git remote access | Network | Required to fetch master and push to the remote repository |
| `scripts/validate.sh` | Local | CI/CD validation script (already in repo) |
| `glab` | CLI | GitLab CLI for creating Merge Requests (`brew install glab`) |

---

## Workflow Overview

The skill workflow adapts based on the **target branch** (master or pre-master):

```
Phase 1: Pre-flight       → Branch safety check + personal memory + show working directory status
Phase 2: Stage & Validate  → Select files + symlink tracking + validate + confirm scope
Phase 3: Commit            → Generate commit message + commit
Phase 4+5: Sync & Merge    → Depends on target branch:
  → target == master: Merge master + MR preview + push + Create MR + optional auto-merge
  → target == pre-master: Local merge + direct push (no MR, auto-merged to master by scheduled task)
```

### Phase 1: Pre-flight

1. **Branch safety check** — Blocks direct commits to the target branch (default: `master`/`main`); prompts to create a new branch (format: `<name>/<type>/<desc>`) or cancel
2. **Write personal memory** — If `docs/personal/<user>/memory/` exists, silently writes session context to daily memory file so it can be staged and committed
3. **Show working directory status** — `git status --short`; if clean, checks for unpushed local commits and jumps to Phase 4 if found
4. **Confirm-Once** — Collects all decisions in one interaction:
   - **Staging mode**: stage all files or select specific files
   - **Target branch**: pre-master (recommended, fast merge) or master (standard MR flow)
   - **MR action** (master only): create + auto-merge, create only, or push only

### Phase 2: Stage & Validate

5. **Stage, validate & confirm** — Displays all files in two groups (staged vs unstaged/untracked); auto-maintains common skill symlinks (adds for new, removes for deleted); runs `bash scripts/validate.sh`; user confirms current staging, adjusts files (`+file` to add, `-file` to unstage), stages all, or cancels — all in one interaction; on ERROR terminates

### Phase 3: Commit

6. **Generate commit message** — AI generates a conventional commit; user confirms, edits, or cancels
7. **Commit** — Execute `git commit`; show result

### Phase 4+5: Sync & Merge

#### Path A: target == master (standard MR flow)

8. **Merge latest master** — `git fetch origin master` + `git merge origin/master`; on conflict, offers Agent-driven auto-resolution, manual resolution, or abort
9. **MR preview & push** — Shows full MR scope vs master (`--name-status` + `--stat` + diff), user confirms push or cancels
10. **Create MR & merge** — Checks for existing open MR (offers auto-merge if found); if none, creates one via `glab mr create` with auto-generated title/description; optionally polls CI and auto-merges

#### Path B: target == pre-master (fast merge flow)

8. **Local merge + push** — Runs `local-merge.sh` to merge into pre-master (which is auto-merged to master by scheduled task):
   - Pushes source branch to origin
   - Fetches pre-master, checks it out locally
   - Merges source into pre-master and pushes to origin
   - Checks out source branch, merges pre-master back into source
   - Pushes source to origin (three-way sync)
   - Deletes local pre-master branch
   - Shows diff between pre-master and master for review

---

## Usage Example

> "ads-workspace-commit-push" or "帮我 commit 并 push 当前改动"

The skill guides you through the full flow interactively — no flags or arguments needed.

### Fast Mode

> "commit push mr", "--fast", or "快速提交"

Skips all confirmations and uses defaults: auto `git add -A`, auto-generate commit message, target branch = pre-master, auto local merge and push. Only stops on: target branch, validation ERROR, or merge conflict.

### pre-master Fast Merge

By default, the skill recommends merging to `pre-master` instead of `master`. The `pre-master` branch (`luka.yang/feat/pre-master`) is a staging branch that is **automatically merged into master by a scheduled task**, eliminating the need for developers to go through the full CI/CD + MR flow for every change.

When `pre-master` is selected:

- No MR is created (changes are merged locally and pushed directly)
- Source is merged into pre-master locally and pushed to origin
- After merge, a diff of pre-master vs master is displayed for review
- Remote branch GitLab links are provided for code review after push
- Local source, origin source, and origin pre-master are kept in sync
- A scheduled task handles the final merge from pre-master into master

To use the standard MR flow instead, select `master` during the target branch step.

### Real-World Walkthrough: Partial Staging of Doc Changes

**Scenario**: You modified 2 kickoff documents (Chinese + English) and also have unrelated changes in `skills/personal/` that you don't want to commit yet.

```
Phase 1 — Pre-flight
  ✓ Branch: luka.yang/feat/add-ads-skill (feature branch, safe)
  ✓ Working tree: 2 modified docs + 5 other unrelated changes

Phase 2 — Stage & Validate
  ? "Stage all files or specify?"
  → User picks "specify" and types: ads-ai-agent-workspace-kickoff.*
  ✓ 2 files staged (M ads-ai-agent-workspace-kickoff.md, M ...EN.md)
  ✓ validate.sh passed
  ✓ Staged file list shown, user confirms "keep all"

Phase 3 — Commit
  ✓ AI generates: docs(kickoff): update §6.5 meeting transcription status...
  ? User confirms → git commit → 114f821 (2 files, +16/-8)

Phase 4 — Sync & Push
  ✓ git fetch origin master → 10 new commits on master
  ✓ git merge origin/master → auto-merged, no conflicts
  ✓ MR preview: 2 files (+16/-8), user confirms push
  ✓ git push → success

Phase 5 — MR
  ✓ No existing open MR found
  ✓ glab mr create → MR !562 created
  ✓ CI passed → glab mr merge → merged
  ✓ master updated, luka.yang/feat/add-ads-skill merged master
```

**Key takeaway**: You don't have to commit everything — pick specific files with glob patterns, and the skill handles the rest automatically.

---

## Commit Message Format

Follows [Conventional Commits](https://www.conventionalcommits.org/) as required by `CLAUDE.md`:

```
<type>(<scope>): <description>

<body — explain why, not what>

Co-Authored-By: Claude <noreply@anthropic.com>
```

Supported types: `feat`, `fix`, `docs`, `refactor`, `chore`, `style`, `perf`, `ci`, `build`, `revert`

---

## Branch Naming Convention

```
<username>/<type>/<description>
```

Examples: `luka.yang/feat/add-skill`, `tom.chen/docs/update-readme`

Direct commits to `master` or `main` are not allowed — the skill will prompt you to create a new branch.

---

## Install via ads-workspace-skill-install

This is a common skill and is auto-loaded when the workspace is opened. No manual install needed.
