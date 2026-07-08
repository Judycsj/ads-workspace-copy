---
name: ads-data-sql-executor
description: >
  Execute SQL queries via ClickHouse (direct HTTP + DataSuite API fallback), Presto (personal-presto SDK),
  or DataSuite Playwright. Takes SQL + optional engine hint, selects execution path, runs query, handles
  errors/retries, and returns structured results. Unified SQL execution infrastructure for all Ads skills.
  (SQL 执行器 — 统一查询执行入口)
  TRIGGER when: user mentions "ads-data-sql-executor", "run sql", "execute sql", "执行SQL", "跑SQL",
  "run this query", "execute this query", "帮我跑", "执行查询", or provides SQL and asks to run it.
  DO NOT TRIGGER when: user is generating SQL (use ads-data-text2da), analyzing results (use ads-data-analyze),
  or manually editing SQL in application code.
user-invocable: true
allowed-tools:
  - mcp__playwright__browser_navigate
  - mcp__playwright__browser_snapshot
  - mcp__playwright__browser_click
  - mcp__playwright__browser_type
  - mcp__playwright__browser_wait_for
  - mcp__playwright__browser_evaluate
  - mcp__playwright__browser_take_screenshot
  - mcp__playwright__browser_press_key
  - mcp__playwright__browser_tabs
  - mcp__playwright__browser_console_messages
  - mcp__playwright__browser_select_option
  - mcp__playwright__browser_handle_dialog
  - Read
  - Edit
  - Bash(python3 *)
  - AskUserQuestion
---

# SQL Executor: 统一查询执行入口

接收 SQL + 可选引擎提示，选择执行路径，运行查询，处理错误重试，返回结构化结果。

## 使用方式

```
/ads-data-sql-executor SELECT count(*) FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live WHERE grass_date = date('2026-06-16') AND grass_region = 'SG'
/ads-data-sql-executor --engine clickhouse --cluster sg SELECT ...
```

**被其他 skill 调用时**：由调用方传入 SQL 和引擎提示，本 skill 负责执行并返回结果。

## 输入契约

| 参数 | 必选 | 说明 |
|------|------|------|
| `SQL` | 是 | 待执行的 SQL 语句 |
| `engine` | 否 | `clickhouse` / `presto` / `auto`（默认 auto） |
| `cluster` | 否 | ClickHouse 集群：`sg` / `us-va2`（默认 sg） |
| `format` | 否 | 输出格式：`json` / `csv` / `table`（默认 json） |
| `output_file` | 否 | 导出文件路径（仅 csv 格式时有效） |
| `session_file` | 否 | 分析会话文件路径（由 ads-data-text2da 传入，执行后更新 §3 状态） |

## Step 1: 判断查询引擎

ClickHouse 和 Presto 是并列执行路径，不存在默认优先级；显式指定优先于自动判断。

- 如果用户或上游 skill 明确指定 ClickHouse，必须按 ClickHouse 引擎执行。首选 `SKILL_DIR/scripts/run_clickhouse_query.py`；直连和 DataSuite API fallback 都不可用时，回退到 DataSuite Playwright 的 ClickHouse engine，不能改用 Presto。
- 如果用户或上游 skill 明确指定 Presto，优先使用内置 personal-presto 执行器；配置缺失、环境不可用或运行失败时，回退到 DataSuite Playwright 的 Presto engine，不要改用 ClickHouse。
- 如果没有显式指定，但 SQL 使用 ClickHouse `cluster(...)`、`roi3_base_clickhouse`、`clickhouse` 表别名，或调用方提示 KB 表 `Storage Type = ClickHouse`，按 ClickHouse 处理。
- 如果没有显式指定且 SQL 语义是 Presto 常规查询，按 Presto 处理。
- 引擎语义不清时，根据 SQL dialect 判断；仍不确定时询问用户，不要静默切换。

### Presto 环境检查

选择 Presto 后，判断是否走内置 personal-presto：

1. **任务适合性**: 简单 adhoc、常规聚合、趋势对比、明细抽样 → 适合；明确需要 SparkSQL 或超大数据量 → DataSuite fallback
2. **环境检查**: 检测 `~/.config/text2da/config.json` 是否存在（含 `python_bin`、`personal_token`、`end_user`、`presto_queue`、`idc_region`、`priority`）
3. **策略**: config 存在 → 优先走 personal-presto；配置缺失或任务不适合 → DataSuite fallback

核心原则：**能走内置执行器就优先走；不能走时才走 DataSuite。**

## Step 2: 执行 SQL

### 路径 0：ClickHouse runner

条件：SQL 被指定或识别为 ClickHouse 查询，且为只读 SQL。

1. 使用 `python3 SKILL_DIR/scripts/run_clickhouse_query.py` 执行
2. 优先 `--format json`；用户需要导出时用 `--format csv --output ...`
3. 验证凭证和路由用 `--dry-run`

ClickHouse 凭证优先来自 `~/.config/text2da/config.json` 的 `clickhouse` section；兼容 `~/.config/ads-workspace/roi3-clickhouse.json`。`TEXT2DA_CLICKHOUSE_AUTH` / `CLICKHOUSE_SG_AUTH` / `ROI3_CLICKHOUSE_AUTH` 仅作临时 override。

脚本会自动追加 `FORMAT JSONEachRow`（SQL 未显式指定 FORMAT 时），标准化为 JSON rows。直连不可用时自动 fallback 到 DataSuite ClickHouse engine 34。

ClickHouse runner 只执行只读 SQL；不提交 `INSERT`、`UPDATE`、`DELETE`、`DROP`、`TRUNCATE`、`ALTER`、`CREATE` 等写入或 DDL。

### 路径 A：Presto personal-presto runner

条件：SQL 被指定或识别为 Presto 查询，且 `~/.config/text2da/config.json` 存在。

1. 使用 `python3 SKILL_DIR/scripts/run_personal_presto_query.py` 执行
2. 优先 `--format json`；用户需要导出时用 `--format csv --output ...`
3. 复用脚本已有的配置校验、token 安全、re-exec、执行与结果标准化能力

### 路径 B：DataSuite Playwright fallback

条件：personal query 配置缺失、环境错误、运行失败，或任务明确需要 SparkSQL / DataSuite UI。

读取 `SKILL_DIR/references/datasuite-ui-guide.md`，按以下步骤执行：

1. **导航到 DataSuite**: 打开 `https://datasuite.shopee.io/studio`
2. **检查认证**: 重定向到登录页（URL 含 `login`/`sso`）时提示用户手动登录
3. **输入 SQL**: 通过 `browser_evaluate` 操作 Monaco 编辑器：
   ```javascript
   const ph = document.querySelector('.editor-placeholder.visible');
   if (ph) ph.style.display = 'none';
   window.ShopeeCDNMonacoEditor.editor.getEditors()[0].setValue(sql);
   ```
4. **配置执行参数**: Project 默认 `mkplpaidads_data`，Engine 按已选引擎选择（Presto / SparkSQL / ClickHouse）
5. **点击 Run**: 用 `browser_snapshot` 找到 Run 按钮并 `browser_click`
6. **监控执行**: 每 5-10 秒 `browser_snapshot` 检查状态，最长等待 5 分钟

导航离开时可能弹出 beforeunload 确认框，用 `browser_handle_dialog` accept: true 处理。

## Step 3: 提取结果

将结果标准化为统一结构：

- `headers`: 列名列表
- `rows`: 行数据列表
- `row_count`: 结果行数

**script 路径**（路径 0/A）：使用脚本的 `json` 输出直接解析。

**DataSuite 路径**（路径 B）：用 `browser_evaluate` 提取结果表：

```javascript
const tables = document.querySelectorAll('table');
let bestTable = null, bestScore = 0;
tables.forEach(t => {
  const score = t.querySelectorAll('thead th').length + t.querySelectorAll('tbody tr').length;
  if (score > bestScore) { bestTable = t; bestScore = score; }
});
const headers = [...bestTable.querySelectorAll('thead th')].map(th => th.textContent.trim());
const rows = [...bestTable.querySelectorAll('tbody tr')].map(tr => {
  const cells = [...tr.querySelectorAll('td')].map(td => td.textContent.trim());
  return cells.slice(0, -1); // 去掉 "View Row" cell
});
```

将结果格式化为 Markdown 表格呈现给用户。

## Step 4: 更新会话文件

如果传入了 `session_file` 路径，用 Edit 更新 §3 对应子任务的执行状态：
- 执行状态: 成功 / 失败(已重试)
- 结果行数: N

## Step 5: 错误处理与重试

| 错误类型 | 修复策略 |
|----------|----------|
| Table not found | 提示调用方检查表名 |
| Column not found | 提示调用方检查字段名 |
| Syntax error | 修正 SQL 语法后重新执行 |
| Partition not found | 提示调整日期范围 |
| Permission denied | 告知用户，无法自动修复 |
| Timeout | 添加 `LIMIT` 或提示优化查询 |
| clickhouse auth missing | 自动尝试 DataSuite ClickHouse engine 34；临时 override 可用 `TEXT2DA_CLICKHOUSE_AUTH` / `CLICKHOUSE_SG_AUTH` / `ROI3_CLICKHOUSE_AUTH` |
| clickhouse authentication failed | 自动尝试 DataSuite ClickHouse engine 34；直连时提醒 username 需含 cluster suffix（如 `UserName-ClusterName`） |
| personal query config error | 直接切换到 DataSuite fallback |
| personal query env/runtime error | 直接切换到 DataSuite fallback |

**重试原则**：

- **SQL 本身问题**: 修复 SQL 后重新执行，最多重试 3 次
- **环境或配置问题**: 不重试，直接切换到 DataSuite fallback
- **DataSuite 登录或 UI 问题**: 提示用户处理认证后继续

## 输出契约

成功时返回：
- 结构化结果 `{headers, rows, row_count}`
- Markdown 表格形式展示
- 使用的引擎和执行路径

失败时返回：
- `{error_type, message, suggestion}`
- 已执行的重试记录

## 参考资料

- `SKILL_DIR/references/setup.md` — 内置执行器的环境准备
- `SKILL_DIR/references/config.example.json` — 配置示例
- `SKILL_DIR/references/datasuite-ui-guide.md` — DataSuite UI 操作说明
- `SKILL_DIR/scripts/run_clickhouse_query.py` — ClickHouse 只读查询脚本
- `SKILL_DIR/scripts/run_personal_presto_query.py` — Presto personal-query 脚本
