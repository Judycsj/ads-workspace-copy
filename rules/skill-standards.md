# Skill Standards

## SKILL.md Requirements

Every skill MUST have:
- YAML frontmatter with `name` (kebab-case, matches directory) and `description` (trigger keyword format)
- Body < 500 lines; use `references/` and `scripts/` for details
- No absolute paths (skills are symlinked)
- Live in `skills/common/`, `skills/team/<team>/`, or `skills/personal/<email-name>/` with flat structure

When creating or modifying a skill, also update: matching guide under `guides/`, shared docs under `docs/` if needed, `skills/README.md` + `skills/README.zh-CN.md` for convention changes, `config/credentials.template.json` for new credential usage.

## Skill Document Cross-Reference

When modifying skill-related documents (e.g. `skills/**/SKILL.md`, `skills/**/references/*`), you MUST also check and update:

1. **Skill guides**: the corresponding file under `guides/` (same scope: `common/`, `team/<team>/`, or `personal/<email>/`)
2. **How-tos**: files in `docs/team/00.paid-ads-dev/04.how-tos/` that reference this skill
3. **SOPs**: files in `docs/team/00.paid-ads-dev/03.sop/` that reference this skill

Use `Grep` to search for the skill name (e.g. `ads-okr-memory-update`) across these directories before completing the change.

After adding/removing/renaming common skills, run `bash scripts/sync-project-skills.sh`.

Description format, naming rules, and contribution path → see `skills/README.md`.

## Do NOT

- Add ad-hoc telemetry — reuse vendored adapters via `bash scripts/install-telemetry.sh`
- Duplicate skill names within `common` scope
