# Ads SQL Executor (ads-data-sql-executor) 使用指南

> **语言**: [English](ads-data-sql-executor.md) | [中文](ads-data-sql-executor.zh-CN.md)

Ads 技能统一 SQL 执行基础设施。接收 SQL + 可选引擎提示，选择执行路径（ClickHouse 直连 / Presto personal-query / DataSuite Playwright fallback），执行查询，处理错误重试，返回结构化结果。

**触发关键词**: "ads-data-sql-executor", "run sql", "execute sql", "执行SQL", "跑SQL", "帮我跑", "执行查询"

---

## 使用场景

- **直接使用**: `/ads-data-sql-executor SELECT count(*) FROM ...` — 已有 SQL 时直接执行
- **被委托调用**: 由 `ads-data-text2da` 在 SQL 生成确认后自动调用
- **作为基础设施**: 其他 skill（ads-diagnose、roi3 系列）直接引用脚本

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 技能定义：引擎选择、执行路径、错误处理 |
| `scripts/run_clickhouse_query.py` | ClickHouse runner：直连 HTTP + DataSuite API fallback |
| `scripts/run_personal_presto_query.py` | Presto runner：通过 `dataservice` SDK |
| `scripts/test_clickhouse_query.py` | ClickHouse runner 单元测试 |
| `references/setup.md` | 环境配置指南 |
| `references/config.example.json` | `~/.config/text2da/config.json` 配置模板 |
| `references/datasuite-ui-guide.md` | DataSuite Playwright fallback 操作说明 |

---

## 执行路径

| 路径 | 引擎 | 使用条件 |
|------|------|---------|
| 路径 0 | ClickHouse | SQL 目标为 ClickHouse 表、使用 `cluster()`、或用户指定 ClickHouse |
| 路径 A | Presto | SQL 目标为 Hive 表且 `~/.config/text2da/config.json` 存在 |
| 路径 B | DataSuite Playwright | 路径 0/A 配置缺失或执行失败时的 fallback |

---

## 配置

详见 `references/setup.md`。快速摘要：

1. 从 `references/config.example.json` 创建 `~/.config/text2da/config.json`
2. Presto：配置 `python_bin`、`personal_token`、`end_user`、`presto_queue`
3. ClickHouse：配置 `clickhouse.sg` section 的 `host`、`user`、`password`

---

## 关联技能

| 技能 | 关系 |
|------|------|
| `ads-data-text2da` | 编排者：生成 SQL 后委托本 skill 执行 |
| `ads-data-analyze` | 接收本 skill 的执行结果进行分析 |
| `ads-text2da` | 旧版本，也委托本 skill 执行 |
