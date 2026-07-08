<!-- ads-workspace-gdoc-sync: gdoc_id=1Aaa8y7YsJagX4VqTgQFXAFRjRZula6iTpNW2q-Ms7nU gdoc_url=https://docs.google.com/document/d/1Aaa8y7YsJagX4VqTgQFXAFRjRZula6iTpNW2q-Ms7nU/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_other_scenario_nmv_metrics_7d

**分层：** dws_search
**主键：** grass_region, local_date, scenario_tag, platform, is_ads, exp_group_id
**分区：** grass_region, local_date
**更新频率：** 每日（每个分区按天覆盖写入）
**引用频次 / 访问频次：** 601

---

## 业务描述

本表为搜索 A/B 实验其他场景 NMV 指标汇总宽表（7 天滚动窗口），用于衡量各实验分组在搜索及关联推荐场景下的成交表现。

**核心业务场景：**

- 搜索与推荐 A/B 实验效果评估：按实验组（`exp_group_id`）拆分，对比不同策略在 NMV、净订单量、下单 UU 数上的差异；
- 多场景覆盖：除全局搜索（Global Search）外，还覆盖 Daily Discover、You May Also Like、Cart Recommendation、Buy Again 等推荐场景，并以 `scenario_tag` 加以区分；
- 多维度下钻：支持按平台（`platform`）、是否广告（`is_ads`）聚合，包含 `__ALL__` 汇总行，方便跨维度对比；
- 时效窗口：以 `local_date` 为截止日期、向前滚动 7 天（含当天）统计各实验分组的累计 NMV 数据。

**适合回答的问题举例：**

- 某实验组在过去 7 天内搜索场景的 NMV / 订单数 / 购买 UU 各是多少？
- 在某推荐场景（如 YMAL、Cart Recommendation）下，各实验组的成交表现差异如何？
- 广告流量与自然流量在同一实验组内的 NMV 分布情况？
- iOS / Android / PC 等不同平台的实验组 NMV 走势对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区（地区）分区，如 `ID`、`MY`、`TH` 等；所有查询必须指定此字段 |
| `local_date` | date | 统计截止日期（本地日期），滚动窗口以该日期为结束边界，向前覆盖 7 天数据 |

### 维度：实验与场景

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_group_id` | bigint | A/B 实验分组 ID，来源于实验分配日志，标识用户所属的实验桶 |
| `scenario_tag` | string | 场景标签，标识本行数据所属的业务场景，例如 `dpm module Global Search business line Search`、`DA_Daily Discover`、`DA_You May Also Like`、`__ALL__`（表示所有场景汇总）等 |

### 维度：流量属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform` | string | 用户下单所用平台，如 `ios`、`android`、`pc`；`__ALL__` 表示平台汇总；原始值为空时填充 `NULL` |
| `is_ads` | string | 是否广告流量，取值为 `true` / `false`；`__ALL__` 表示广告与自然流量合计；原始值为空时填充 `false` |

### 指标：成交指标（7 天滚动窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `nmv` | double | 净商品交易额（Net Merchandise Value），单位与平台货币一致，为 7 天内该分组在对应场景下的 NMV 求和 |
| `net_order_cnt` | double | 净订单数，7 天内该分组在对应场景下的净成交订单量求和 |
| `net_order_uu` | bigint | 净下单唯一用户数（UU），7 天内在对应场景下有净成交（`net_order_cnt > 0`）的去重用户数 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须作为分区过滤条件指定，否则将全表扫描所有大区分区，严重影响性能。
2. **`local_date`**：建议明确指定日期，避免扫描多个历史分区。该字段为每日全量覆盖写（`INSERT OVERWRITE`），每个 `(grass_region, local_date)` 分区对应一次完整的 7 天滚动计算结果。

```sql
-- 推荐写法示例
WHERE grass_region = 'ID'
  AND local_date = '2025-05-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `net_order_uu` | 去重 UU 数，跨行直接 SUM 会导致重复计数；如需汇总多 `exp_group_id` 或多 `scenario_tag` 的 UU，需回溯明细层 |
| `nmv`、`net_order_cnt` | 当 `is_ads` 或 `platform` 含 `__ALL__` 汇总行时，与明细行存在重叠，跨维度聚合前必须先过滤掉汇总行，避免重复计算 |

### 维度汇总行说明

- `is_ads = '__ALL__'`：`is_ads` 维度的汇总行，已包含所有广告与非广告流量之和；
- `platform = '__ALL__'`：`platform` 维度的汇总行，已包含所有平台之和；
- `scenario_tag = '__ALL__'`：来自 ETL 中额外的 `UNION ALL` 分支，表示不区分场景的全量汇总行；
- 以上汇总行由 ETL 通过 `CUBE(is_ads, platform)` 及 `UNION ALL` 预聚合生成，**不可与明细行混用后再次 SUM**。

### 时效性说明

- 本表为 **7 天滚动窗口**聚合表（`*_7d`），每个 `local_date` 分区覆盖 `[local_date - 7, local_date]` 共 8 天原始数据，**不代表单日数据**；
- 每日 ETL 完成后分区数据才可用，分区写入方式为 `INSERT OVERWRITE`，查询时需确认目标分区已落地；
- 实验用户映射（`is_assignment_log = 1` 且 `is_search_whitelist = 1`）限定为白名单内的有效实验分配用户，结果不含未被分配实验的用户 NMV。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维表，提供 `user_id` → `exp_group_id` 的映射关系；过滤有效实验分配日志（`is_assignment_log = 1`）及搜索白名单用户（`is_search_whitelist = 1`） |
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 平台 NMV 明细事实表，提供用户级别的净订单数、NMV、平台、是否广告、场景标签（reporting/algo_tag）等原始字段 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──────────────────────────────────┐
  （7天实验分组映射，过滤白名单用户）                                          │ JOIN on user_id + local_date
                                                                            ▼
dwd_sr_data_warehouse_platform_nmv  →  场景Tag展开 + CUBE维度补全  →  dws_platform_exp_*
  （7天NMV明细，过滤 user_id > 0）     （含 __ALL__ 汇总行）
                                                                            │ INSERT OVERWRITE
                                                                            ▼
              dws_sr_data_warehouse_search_abtest_other_scenario_nmv_metrics_7d
```

### 关键步骤

**Step 1 — `user_exp_mapping_7d`（Temporary View）**

从实验用户分组维表中抽取过去 7 天内的有效实验分配记录，条件：`is_assignment_log = 1` 且 `is_search_whitelist = 1`。输出字段：`user_id`、`exp_group_id`、`local_date`。

**Step 2 — `dwm_platform_nmv`（Temporary View）**

从 NMV 明细表读取过去 7 天数据（`user_id > 0`），按用户、平台、is_ads、日期进行汇总，同时：
- **场景 Tag 计算**：通过 `build_scenario_tags` UDF 从三路来源（主路径、source1、source2）的 `reporting_business_line / reporting_module / reporting_object / algo_tag` 字段生成候选标签数组，再与目标场景白名单做 `array_intersect` 过滤，得到 `union_algo_tags`；
- **`__ALL__` 分支**：通过 `UNION ALL` 追加一路以 `array('__ALL__')` 作为 `union_algo_tags` 的全量汇总行，表示不区分场景的成交数据。

**Step 3 — `dwm_platform_nmv_explode`（Temporary View）**

对 Step 2 结果使用 `LATERAL VIEW EXPLODE(union_algo_tags)` 将数组列展开为行，每个场景 tag 独立成一行，并按 `user_id`、`is_ads`、`platform`、`scenario_tag`、`local_date` 再次聚合求和。

**Step 4 — `dwm_platform_nmv_grouping_sets`（Temporary View）**

对展开后的明细使用 `CUBE(is_ads, platform)` 进行维度补全，生成以下组合：
- `(is_ads 明细, platform 明细)`
- `(is_ads 明细, '__ALL__' platform)`
- `('__ALL__' is_ads, platform 明细)`
- `('__ALL__' is_ads, '__ALL__' platform)`

保留用户粒度，按各维度组合分别求和 NMV 和 net_order_cnt。

**Step 5 — `dws_platform_exp`（Temporary View）**

将 Step 4 的用户粒度数据与 Step 1 的实验分组映射 JOIN（`user_id + local_date`），关联实验分组 ID，随后按 `scenario_tag`、`platform`、`is_ads`、`exp_group_id`、`local_date` 聚合，计算：
- `nmv`：SUM 求和；
- `net_order_cnt`：SUM 求和；
- `net_order_uu`：`SUM(IF(net_order_cnt > 0, 1, NULL))`，统计有成交的用户数。

**Step 6 — INSERT OVERWRITE（最终写入）**

将 Step 5 结果以 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 方式写入目标表，按大区和日期分区覆盖。

### 注意事项

1. **单文件单 Writer**：该表仅有一个 ETL 文件（`multi_writer = false`），无多路并发写入风险。
2. **分区覆盖写**：采用 `INSERT OVERWRITE` 按 `(grass_region, local_date)` 分区覆盖，重跑特定分区安全，但需避免同一分区并发写入。
3. **场景白名单硬编码**：`array_intersect` 中的目标场景列表在 SQL 中硬编码，新增场景需同步修改 ETL；注意原始注释代码中有一行字符串拼接缺少逗号（`'DA_Cart_Unify' 'DA_Buy Again (Me Page)'`），与白名单数组保持一致即可。
4. **7 天窗口含义**：`DATE_SUB(${local_date}, 7)` 到 `${local_date}` 实际覆盖 8 个自然日，字段命名为 `_7d` 是业务习惯，查询时需注意实际范围。
5. **`__ALL__` 汇总行重叠**：由于 CUBE 和 UNION ALL 均会产生汇总行，直接对全表 SUM 时会出现多重计算，查询必须先确定维度过滤策略（明细行或汇总行二选一）。
6. **JOIN 类型**：Step 5 使用 INNER JOIN，仅保留能匹配到实验分组的用户 NMV，未参与任何实验的用户成交数据不会进入本表。

---

*文档生成时间：2026-05-17*