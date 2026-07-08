# Skill Install (ads-workspace-skill-install) Guide

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-workspace-skill-install.md)
>
> **Language**: [English](ads-workspace-skill-install.md) | [中文](ads-workspace-skill-install.zh-CN.md)

Install skills from `skills/team/`, `skills/personal/` and `sra-toolkit/skills/` into the project-local `.tooling/skills/` mirror on demand. If the target skill declares `skill_dependencies`, the installer installs those dependencies automatically. Dependency resolution order: reuse already-installed skills in `.tooling/skills/` → look up the local `sra-toolkit` checkout → fetch from the remote `sra-toolkit` Git repository.

**Trigger keywords**: "install skill", "add skill", "enable skill", "安装技能", "添加技能", "启用技能"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with interactive install workflow |
| `scripts/install_skill.py` | Python script for listing and installing skills |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| uv | Tool | Required to run the Python script via `uv run` |

---

## Usage

### Scenario 1: Interactive selection

> "Install a skill" or "安装技能"

The skill lists all available skills from team, personal and sra-toolkit scopes, then prompts you to select which ones to install.

### Scenario 2: Install by name

> "Install sra-find-skills"

Directly installs the named skill by creating a relative symlink in `.tooling/skills/`.

### Scenario 3: Install by directory path

> "Install my-skill from /path/to/skill-dir"

Installs a skill from an arbitrary directory path (must contain `SKILL.md`).

---

## CLI Reference

```bash
# List available skills
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py list

# List with JSON output
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py list --json

# Install by name
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install <name>

# Install by directory
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install <name> --dir <path>

# Force overwrite existing link
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install <name> --force
```

After installing one or more skills, run the repo-level post-install hook once
to refresh the shared tool environment, similar to `npx sra-toolkit update`:

```bash
bash scripts/post-install.sh
```

Do not call this hook inside each individual `install_skill.py install`
invocation. Install all requested skills first, then run the hook once.

`scripts/post-install.sh` records the latest commit of the `sra-toolkit`
`release` branch. If that commit is unchanged and the installed artifacts are
still present, the hook skips automatically. To force a refresh:

```bash
ADS_WORKSPACE_FORCE_POST_INSTALL=1 bash scripts/post-install.sh
```

---

## Notes

- Only `skills/common/` is auto-loaded — team, personal and sra-toolkit skills require manual install
- Manually installed links are preserved across `bash scripts/sync-project-skills.sh` runs
