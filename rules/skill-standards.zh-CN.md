# Skill 规范/Skill Standards

## SKILL.md 要求/SKILL.md Requirements

每个 skill 必须包含：
- YAML frontmatter 含 `name`（kebab-case，与目录名一致）和 `description`（trigger keyword 格式）
- Body < 500 行；细节放 `references/` 和 `scripts/`
- 不使用绝对路径（skill 会被软链接）
- 存放于 `skills/common/`、`skills/team/<team>/` 或 `skills/personal/<email-name>/`，内部保持扁平结构

创建或修改 skill 时，还需同步更新：`guides/` 下对应说明、`docs/` 下相关文档（如适用）、`skills/README.md` + `skills/README.zh-CN.md`（规范变更时）、`config/credentials.template.json`（新增凭证时）。

## 技能文档联动更新/Skill Document Cross-Reference

修改 skill 相关文档（如 `skills/**/SKILL.md`、`skills/**/references/*`）时，**必须**同时检查并更新：

1. **Skill 使用指南**：`guides/` 下对应的文件（与 skill 同 scope：`common/`、`team/<team>/` 或 `personal/<email>/`）
2. **How-tos**：`docs/team/00.paid-ads-dev/04.how-tos/` 中引用该 skill 的文件
3. **SOPs**：`docs/team/00.paid-ads-dev/03.sop/` 中引用该 skill 的文件

完成修改前，使用 `Grep` 在上述目录中搜索 skill 名称（如 `ads-okr-memory-update`）以确认所有引用已同步更新。

新增/删除/重命名 common skill 后，执行 `bash scripts/sync-project-skills.sh`。

Description 格式、命名规范和贡献路径 → 见 `skills/README.md`。

## 禁止事项/Do NOT

- 添加 ad-hoc telemetry — 复用 vendored adapters：`bash scripts/install-telemetry.sh`
- `common` scope 内不允许重名 skill
