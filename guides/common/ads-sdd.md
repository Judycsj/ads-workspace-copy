# ads-sdd Skill Guide

> **Contributors**: luka.yang ｜ **Last updated**: 2026-07-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-sdd.md)

`ads-sdd` is the Spec-Driven Development toolchain. It covers the full lifecycle from spec directory scaffolding to implementation generation, plus structured incremental changes via Delta Spec (propose → apply → archive).

---

## Prerequisites

- Working directory is `ads-workspace` root
- For `init`: no existing spec directory for the target domain
- For `spec` / `review` / `implement`: a domain directory with at least `01-scope-and-workflow.md` and `02-*.md`
- For `propose` / `apply` / `archive`: an existing domain with completed specs

---

## When to use

| Mode | Use when... |
| --- | --- |
| `init` | Starting a new module/system — need to create the spec directory skeleton |
| `spec` | Adding a component spec or cross-component contract to an existing domain |
| `review` | Checking structural integrity before implementation or after edits |
| `implement` | Generating SKILL.md / code / doc templates from specs (full build or diff-based) |
| `propose` | Planning a structured change — creating delta specs with ADDED/MODIFIED/REMOVED/RENAMED markers |
| `apply` | Merging approved delta specs into the full specs |
| `archive` | Archiving applied changes to `changes/archive/` after implementation is complete |

---

## Quick Start

```
/ads-sdd init my-domain --type skill      # Scaffold a new spec directory
/ads-sdd spec my-domain/my-component      # Author a component spec
/ads-sdd spec my-domain/shared --contract # Author a cross-component contract
/ads-sdd review my-domain                 # Validate spec structure
/ads-sdd implement my-domain              # Generate implementation from full specs
/ads-sdd implement my-domain --diff       # Incremental update from spec diff
/ads-sdd propose my-domain/change-name    # Create a delta spec change proposal
/ads-sdd apply my-domain/change-name      # Merge delta specs into full specs
/ads-sdd archive my-domain/change-name    # Archive an applied change
```

---

## Two Incremental Change Paths

- **Path A (Spec-Diff)**: Edit full spec files directly, use `implement --diff` to propagate via git diff. Best for quick, small changes.
- **Path B (Delta Spec)**: Use `propose` to create structured delta specs, `apply` to merge them, then `implement --diff`. Best for reviewable, multi-file changes.

---

## Tips

- Specs live in `specs/common/{domain}/` — this is the authoritative source (Layer 1)
- SKILL.md uses **Pointer + Lazy-Load** — it declares spec paths and reads them on demand at runtime
- SKILL.md body must stay **≤ 500 lines**; overflow goes to `references/`
- Delta specs use `delta-` prefix and don't occupy the main numbering sequence
- Always `propose` before `apply` — the apply mode requires an existing change directory with delta files
- Always `apply` before `archive` — the archive mode requires an `.applied` marker
