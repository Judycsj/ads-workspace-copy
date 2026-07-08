---
name: ads-kb-datamap
description: >
  为 Hive 表构建知识库：从代码库 (from-code) 和 DataSuite DataMap (from-di) 提取表元信息、列定义和 SQL 模式
  (Table KB builder from codebase and DataMap UI).
  TRIGGER when: "build table kb", "表KB构建", "datamap kb", "extract table kb",
  "SQL模式提取", "sql pattern", "table lineage", "表血缘", "表知识库",
  "建表KB", "抓取表信息", "添加表元数据".
  DO NOT TRIGGER when: writing new SQL, querying data, text2da, diagnosing ads.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(python3 *)
  - Bash(wc *)
  - AskUserQuestion
  - mcp__playwright__browser_navigate
  - mcp__playwright__browser_snapshot
  - mcp__playwright__browser_click
  - mcp__playwright__browser_evaluate
  - mcp__playwright__browser_run_code_unsafe
  - mcp__playwright__browser_wait_for
  - mcp__playwright__browser_take_screenshot
  - mcp__playwright__browser_press_key
  - mcp__playwright__browser_tabs
  - mcp__playwright__browser_type
  - mcp__playwright__browser_select_option
  - mcp__playwright__browser_handle_dialog
---

# 表知识库构建

为 Hive 表构建知识库，供 `ads-text2da` 等下游技能使用。

**数据源优先级**：from-code 为主（常规例行），from-di 为补充（按需）。

- **from-code**（主）：扫描 `projects/gitlab/paidads-alg/studio_tasks/` 代码库 → 生成/更新**全部三个文件**
- **from-di**（补）：抓取 DataSuite DataMap UI → 补充 from-code 无法获取的字段

## 使用方式

```
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source from-code
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source from-di
/ads-kb-datamap   # 自动扫描 docs/common/datamap/ 下已有 KB 的表
```

- 表名格式：`{database}.{table_name}`，支持逗号分隔多表
- `--source`：`from-code`（默认） | `from-di` | `both`
- 如未指定参数，通过 AskUserQuestion 询问

## 输出文件

写入 `docs/common/datamap/{db}.{table_name}/` 目录：

| 文件 | 用途 | from-code 产出 | from-di 补充 |
|------|------|:---:|:---:|
| `table_info.md` | 搜索索引 — 定位表 | Description, Use Case, Key Metrics/Dimensions, Technical Props (DDL), Region Coverage | DQC, Table Size, Business Props, Popularity |
| `column_info.md` | 列参考 — 理解字段 | Column name/type (DDL), 非累加标注, 枚举映射, 常见 WHERE 值 | Column description, Query Frequency, MAX 采样 |
| `sql_patterns.md` | 编码上下文 — 写 SQL | WHERE/JOIN/Aggregation 模式, SQL 片段, Write Lineage, Derived Metrics | — |

## 脚本文件

`SKILL_DIR/scripts/` 下的可复用脚本（仅 from-di 使用）：

| 文件 | 用途 | 执行方式 |
|------|------|----------|
| `extract_table_info.js` | 从 DataMap 提取表元信息 | `browser_evaluate` |
| `extract_all_columns.js` | 批量分页提取所有列 | `browser_run_code` |
| `extract_column_info.js` | 单页列提取（fallback） | `browser_evaluate` |
| `set_and_run_sql.js` | 在 DataSuite 设置并执行 SQL | `browser_evaluate` |
| `extract_sql_results.js` | 提取 DataSuite 查询结果 | `browser_evaluate` |
| `extract_latest_partition.js` | 提取最新分区日期 | `browser_evaluate` |
| `generate_table_info.py` | 从 JSON 生成 table_info.md | `Bash(python3)` |
| `generate_column_info.py` | 从 JSON 生成 column_info.md | `Bash(python3)` |

## 工作流程

### Step 1: 解析输入

1. 解析表名列表（`{database}.{table_name}` 格式）
2. 解析 `--source` 参数，默认 `from-code`
3. **前置检查（from-code 必需）**：用 Glob 检查 `projects/gitlab/paidads-alg/studio_tasks/` 是否存在。如不存在，用 AskUserQuestion 提示用户：
   > paidads-alg 代码库未在 `projects/gitlab/paidads-alg/` 找到。请提供 studio_tasks 所在路径（如 `projects/gitlab/xxx/studio_tasks/`），或先 clone 到 `projects/gitlab/` 下。
4. 如未指定表名：Glob `docs/common/datamap/*/table_info.md`，列出已有 KB 的表让用户选择
5. 如未指定 source：用 AskUserQuestion 让用户选择 `from-code` / `from-di` / `both`

### Step 2: from-code — 从代码库提取（主流程）

> 跳过条件：`--source from-di`

#### 2.1 搜索表引用

**代码库根路径**：`projects/gitlab/paidads-alg/`（由 Step 1 确认或用户提供）

**读引用搜索**：
- 主要来源：`{代码库根路径}/studio_tasks/`
- 补充来源：`{代码库根路径}/sql/`、`{代码库根路径}/notebook/`、`{代码库根路径}/personal/`、`{代码库根路径}/services/ads_diagnosis/sql/`
- 使用 Grep 搜索完整表名

**写引用搜索**：
- `INSERT OVERWRITE TABLE.*{table_name_without_db}`
- `CREATE.*TABLE.*{table_name}`
- 按来源分类优先级：`workflows/` > `scheduled_tasks/` > `manual_tasks/` > `playground/`

#### 2.2 过滤有效 SQL 文件

- 跳过首行为 `#!/`、`cd `、`bash `、`python `、`import ` 的文件
- 保留包含 SQL 关键词的文件
- Python 文件中嵌入的 SQL 也提取

#### 2.3 提取信息

将文件分为**读文件**和**写文件**两组处理。

**Part A: 查询模式（从读文件提取）→ sql_patterns.md**

- **JOIN 模式**: 提取 `JOIN ... ON` 子句，记录 JOIN 对象表和条件
- **WHERE 过滤**: 提取分区列和业务过滤条件
- **聚合模式**: 提取 `GROUP BY` 维度和聚合函数
- **代表性 SQL 片段**: 选取 5-8 个多样化示例（每个 ≤50 行，去重）

**Part B: 生产信息（从写文件提取）→ 分发到三个文件**

- **Write Lineage** → sql_patterns.md：从 workflow INSERT 文件提取上游表、workflow 路径、分区写入策略
- **DDL 元信息** → table_info.md Technical Properties：存储格式、分区列、HDFS 路径、保留策略、列数、地域覆盖
- **Dimension Mappings** → column_info.md Column Usage Notes：CASE-WHEN 枚举映射（需 2+ 个文件出现）
- **Non-Additive Fields** → column_info.md Column Usage Notes：从 `SUM(DISTINCT ...)` 模式识别非累加字段
- **Derived Metrics** → sql_patterns.md：SELECT 表达式归纳指标公式（需 2+ 个文件出现）

**Part C: 推理填充 → table_info.md + column_info.md**

from-code 能推理的 table_info 字段：
- **Description.Desc**: 从 SQL 用途 + 上游表推理表的内容和定位
- **Description.Granularity**: 从 GROUP BY 最细粒度推理（如 "daily × entry_point × pricing_type × region"）
- **Description.Use Case**: 从实际 SQL 场景归纳（如 "OKR Take Rate 日报"、"Live Ads tracker"）
- **Description.Update Frequency**: 从 workflow 调度推理（通常 "Daily"）
- **Key Metrics**: 从 SUM/聚合表达式提取核心指标列表
- **Key Dimensions**: 从 WHERE/GROUP BY 提取核心分析维度

from-code 能推理的 column_info 字段：
- **Column name + type**: 从 CREATE TABLE DDL 提取
- **常见 WHERE 值**: 从 WHERE 子句提取（如 `pricing_type in (9,10,14)` → Live Ads）

#### 2.4 规模限制

- 读文件：最多处理 30 个（优先 `workflows/` > `scheduled_tasks/` > 其他）
- 写文件：不受限制（通常 <10 个），全部处理

#### 2.5 生成三个文件

**table_info.md**:

````markdown
# {db}.{table_name}

## Description

- **Desc:** {from-code 推理，或保留已有 from-di 内容}
- **Granularity:** {from-code: GROUP BY 最细粒度}
- **Use Case:** {from-code: 实际 SQL 场景归纳，3-5 个}
- **Update Frequency:** {from-code: workflow 调度频率}

## Key Metrics

{from-code: 从 Common Aggregations 归纳}
- 收入类: ads_rev_usd, net_ads_rev_usd, net_ads_rev_excl_sip_usd_1d
- 平台类: platform_gmv, platform_gmv_excl_testorder (⚠️ SUM DISTINCT)
- 效果类: ads_imp, ads_click, ads_order, ads_gmv_usd
- 券成本: ads_voucher_ads_nmv_cost_usd, ads_voucher_omni_platform_nmv_cost_usd (⚠️ MAX/SUM DISTINCT)

## Key Dimensions

{from-code: 从 WHERE/GROUP BY 归纳}
- 分区: grass_date, grass_region, tz_type
- 业务: entry_point, traffic_type, pricing_type, main_product_type, seller_type_1p

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | {from-code DDL} |
| Partition Columns | {from-code DDL} |
| HDFS Path | {from-code DDL} |
| Retention | {from-code DDL} |
| Column Count | {from-code DDL} |
| Region Coverage | {from-code: 从文件名/变量推断} |
| DQC Status | {from-di, 或 "-"} |
| Table Size | {from-di, 或 "-"} |

## Business Properties

{from-di, 或标注 "未抓取 DataMap，请运行 --source from-di 补充"}

| Property | Value |
|----------|-------|
| Technical PIC | {from-di} |
| Team | {from-di} |
| Business Domain | {from-di} |
| DW Layer | {from-di} |

## Popularity

- Studio Tasks References: {from-code: N files}
- L7D Query Count: {from-di, 或 "-"}
- Completeness: {from-di, 或 "-"}
- Popularity: {from-di, 或 "-"}
````

**column_info.md**（from-code only 时为精简版）:

````markdown
# Columns: {db}.{table_name}

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

{from-code: 从 SUM(DISTINCT) 模式识别}
跨 entry_point/pricing_type 聚合时必须用 SUM(DISTINCT)：
- `platform_gmv`, `platform_gmv_excl_testorder`, `platform_imp`, `entry_point_imp`
- `ads_voucher_omni_platform_nmv_cost_usd` — 全维度只有一个总值，只能 MAX 或 SUM(DISTINCT)

### 枚举值映射 (Value Mappings)

{from-code: 从 CASE-WHEN 提取，需 2+ 文件出现}

| Column | Value | Meaning |
|--------|-------|---------|
| pricing_type | 1,2 | Manual |
| pricing_type | 3,4 | Simple |
| ... | ... | ... |

### 常见 WHERE 值 (Common Filter Values)

{from-code: 从 WHERE 子句提取}
- `tz_type`: 'regional' (~70% 查询) / 'local' (ROI3/Live Ads)
- `pricing_type`: 9,10,14 (Live Ads) / 18 (ROI3)
- `seller_type_1p`: OKR 排除 'Local SCS','SCS','Lovito'
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')

## All Columns

{from-code DDL 有列名+类型; from-di 补充 description/query frequency/MAX}

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entry_point | string | {from-di, 或 "-"} | {from-di, 或 "-"} | {from-di, 或 "-"} |
| ... | ... | ... | ... | ... |
````

**说明**: from-code only 模式下，column_info.md 没有 "Top 20 Most Queried Columns" 和 "查询频率分析" section（依赖 from-di 的 query frequency 数据）。运行 from-di 后会补充这些 section。

**sql_patterns.md**:

````markdown
# SQL Patterns: {db}.{table_name}

*Auto-generated by ads-kb-datamap (from-code) — {N} references ({W} write, {R} read)*
*Generated on: {date}*

## Common WHERE Filters
## Common JOIN Patterns
## Common Aggregations
## Representative SQL Snippets
## Write Lineage (生产血缘)
## Derived Metrics (派生指标)
````

**注意**: DDL Summary 和 Dimension Mappings 不再出现在 sql_patterns.md 中：
- DDL 信息 → table_info.md Technical Properties
- Dimension Mappings → column_info.md Column Usage Notes

### Step 3: from-di — 从 DataSuite DataMap 补充

> 跳过条件：`--source from-code`

读取参考文件：
- `SKILL_DIR/../ads-data-sql-executor/references/datasuite-ui-guide.md`
- `SKILL_DIR/scripts/` 下按需使用的脚本

from-di 补充的字段（from-code 无法获取）：

| 目标文件 | 补充字段 |
|----------|----------|
| table_info.md | DQC Status, Table Size, Business Properties (PIC/Team/Domain/DW Layer), L7D Query Count, Completeness, Popularity |
| column_info.md | Column description (中英文), L7/14/30D Query Frequency, MAX(column) 采样值, Top 20 + 查询频率分析 |

#### 3.1 导航到 DataMap 表页面

1. 构造 URL：`https://datasuite.shopee.io/datamap/data-warehouse/HIVE/{btoa('hive@prod@{db}@{table}')}/Table_Info`
2. 用 `browser_navigate` 打开
3. 检查认证：如重定向到登录页，提示用户登录后继续
4. 等待数据填充：用 `browser_evaluate` 验证 Technical Properties 至少有一个非 "-" 值

#### 3.2 提取表级信息 → 补充 table_info.md

1. 读取 `SKILL_DIR/scripts/extract_table_info.js`，传给 `browser_evaluate`
2. 从 JSON 中提取 from-di 独有字段：DQC Status, Table Size, Business Properties, Completeness, Popularity, L7D Query Count
3. 用 `Edit` 工具更新 table_info.md 中对应字段（将 "-" 替换为实际值）

#### 3.3 提取列信息 → 补充 column_info.md

1. 点击 "Column Info" tab，等待 2.5s
2. 读取 `SKILL_DIR/scripts/extract_all_columns.js`，传给 `browser_run_code`
3. 如失败，回退到 `extract_column_info.js` 逐页提取
4. 持久化列数据到 `/tmp/columns_{db}_{table}.json`

**列名后缀处理**：
- 分区列带 "PARTITION" 后缀 → Python 脚本自动去掉并标注 `[PARTITION]`
- Biz Primary Key 列带后缀 → 同理自动处理
- 构造 MAX() SQL 时需手动去掉后缀

#### 3.4 获取最新分区日期

1. 点击 "Partition" tab，等待 2.5s
2. 读取 `SKILL_DIR/scripts/extract_latest_partition.js`，传给 `browser_evaluate`
3. 获取 `latest_grass_date`，如失败回退使用 yesterday

#### 3.5 获取样本数据

1. 构造 MAX() SQL（对 struct/array/map 用 `JSON_FORMAT(CAST(... AS JSON))`，对 decimal 用 `CAST(... AS DOUBLE)`）
2. 导航到 `https://datasuite.shopee.io/studio`
3. 读取 `SKILL_DIR/scripts/set_and_run_sql.js`，替换 `__SQL_PLACEHOLDER__` 后执行
4. 提取结果：优先用 API（`/datastudio/api/v1/execution/adhoc/history/result`），fallback 用 `extract_sql_results.js`

#### 3.6 更新 column_info.md

1. 读取现有 column_info.md（from-code 已生成的骨架）
2. 将 from-di 的 description、query frequency、MAX 值合并到 All Columns 表格中
3. 插入 "Top 20 Most Queried Columns" section（基于 L30D 排序）
4. 用 Edit 将 `<!-- ANALYSIS_PLACEHOLDER -->` 替换为中文查询频率分析

### Step 4: 汇报结果

列出每个表的处理结果：
- 数据源（from-code / from-di / both）
- 生成/更新的文件路径
- from-code: 读引用 / 写引用数量、DDL 是否找到
- from-di: 列数、样本数据覆盖率

## 容错处理

- **元素找不到**：用 `browser_snapshot` 重新获取页面快照，自适应查找
- **页面加载超时**：等待 5 秒后重试
- **认证失效**：提示用户重新登录
- **表不存在**：跳过并报告
- **beforeunload 弹窗**：用 `browser_handle_dialog` accept
- **MAX() 查询超时**：列数过多时分批查询
- **DataSuite 代码比较弹窗**：用 `browser_press_key` Escape 关闭
- **DOM 结果不可访问**：宽表 (50+ 列) 必须用 API 提取
- **数据未加载（显示 "-"）**：等待 3 秒后验证数据已填充
- **代码库无写引用**：Write Lineage 标注"未在代码库中找到生产逻辑"
- **代码库无 DDL**：Technical Properties 中 from-code 字段标注 "-"，提示运行 from-di 补充

## 注意事项

- 幂等运行：from-code 每次覆盖 sql_patterns.md，增量更新 table_info.md 和 column_info.md 中 from-code 字段
- from-di 运行时保留已有 from-code 内容，只补充 from-di 独有字段
- 代码库默认路径 `projects/gitlab/paidads-alg/`，不存在时必须询问用户提供路径后才能执行 from-code
- `studio_tasks/` 中的文件通常没有 `.sql` 扩展名，按内容判断
- PySpark 文件中的 SQL 在三引号字符串中，需特殊处理
- 枚举映射和派生指标只提取在 2+ 个文件中重复出现的模式，避免噪音
- 写文件优先分析 `workflows/` 路径（正式调度），`manual_tasks/` 和 `playground/` 仅作参考
