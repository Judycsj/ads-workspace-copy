# Workspace 检查（ads-workspace-check）使用指南

> **语言**：[English](ads-workspace-check.md) | [中文](ads-workspace-check.zh-CN.md)

全量扫描 ads-workspace 文档一致性、目录结构和命名规范，发现问题后交互式修复。

**唤醒词**：「check workspace」、「workspace 检查」、「文档一致性」、「检查文档」、「naming check」、「命名检查」、「目录检查」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含 7 步检查工作流程 |

---

## 前置依赖

无外部依赖，仅读取本地文件。

---

## 流程概览

1. **收集基准** — 读取 `CLAUDE.md`，扫描实际目录结构
2. **Part A：文档一致性** — 交叉检查 README、CLAUDE.md、skills/README 描述是否一致
3. **Part B：命名规范** — 验证 kebab-case、≤30 字符、`name` 与目录名一致、TRIGGER 格式、无绝对路径
4. **Part C：Scope 约定** — 验证 `ads-` 前缀、guide 文件存在、tooling 软链已追踪
5. **输出问题清单** — 按 Part A / B / C 分组展示，标注严重程度
6. **用户选择修复范围** — 全部 / 仅 Part A / 仅 Part B / 仅 Part C / 仅查看
7. **执行修复** — Edit 文件、创建缺失 guide、提示运行 sync 脚本

---

## 使用示例

> 「/ads-workspace-check」或「帮我检查一下 workspace 规范」

Skill 会先展示完整问题清单，用户确认后才修改文件。

---

## 安装方式

本 skill 属于 common scope，打开 workspace 时自动加载，无需手动安装。
