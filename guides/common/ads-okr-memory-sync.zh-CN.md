# Ads 项目记忆同步 (ads-project-memory-sync) 使用指南

> **语言**: [English](./ads-project-memory-sync.md) | 中文

将项目 memory 目录下积累的每日工作记录（`memory/YYYY-MM-DD-person.md`）同步到 epic-file 的第五章（KP 执行与状态）。两阶段工作流：会话过程中 CLAUDE.md 规则自动积累 memory 文件，本技能负责将 memory 合并到 epic-file，需用户确认。

**触发关键词**：sync memory, 同步记忆, memory to epic, 记忆同步, project sync, 项目同步

---

## 技能文件

| 文件 | 用途 |
| --- | --- |
| `skills/common/ads-project-memory-sync/SKILL.md` | 技能定义和工作流 |

## 前置条件

| 依赖 | 类型 | 说明 |
| --- | --- | --- |
| 项目目录含 `epic-file.md` + `MEMORY.md` + `memory/` | 目录结构 | 模板参考 `templates/doc-template/project-memory.md` |

## 基本用法

1. 运行 `/ads-project-memory-sync` 或说「同步项目记忆」
2. 技能识别目标项目（从活跃项目或用户输入）
3. 读取 `memory/` 下所有未同步的文件
4. 将条目分类到 epic-file 的 5.1–5.5 章节
5. 以 diff 形式展示更新建议
6. 用户确认后写入 epic-file
7. 在已同步条目上标记 `<!-- [synced @YYYY-MM-DD] -->`
8. 在 epic-file 头部记录同步时间戳 `<!-- memory-sync: last=... -->`

## 示例 Prompt

- `/ads-project-memory-sync`
- `同步项目记忆到 epic-file`
- `sync memory for kr3-kp4`

## 注意事项

- 只做增量更新，不会覆盖 epic-file 中已有的手动编辑
- 5.5 下一步计划是活文档，同步时替换而非追加
- 无法明确分类的条目会询问用户归入哪个章节
- 至少有一个未同步的 memory 文件才会执行
- 绑定项目时（「启动项目 xxx」）会自动检查同步时间，超过 24 小时未同步会提示执行
