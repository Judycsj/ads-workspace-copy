<!-- ads-workspace-gdoc-sync: gdoc_id=1evbql5vaMHkmOyR-kjZXa_Kt8NG7GP7k9rm5omQJQN0 gdoc_url=https://docs.google.com/document/d/1evbql5vaMHkmOyR-kjZXa_Kt8NG7GP7k9rm5omQJQN0/edit -->

# srdi_mart.dws_sr_data_warehouse_rcmd_exp_upstream_level_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `feature_detail` + `upstream_feature` + `platform` + `is_ads`
**分区：** `grass_region`（地区）, `local_date`（业务日期）
**更新频率：** 每日一次（T+1 覆盖写入）
**引用频次 / 访问频次：** 721

---

## 业务描述

本表面向搜索与推荐（SRDI）**"猜你喜欢"（You May Also Like）** 推荐场景，以 **实验分组（exp_group_id）× 上游来源特征（upstream_feature）× 功能位（feature_detail）× 平台（platform）× 是否广告（is_ads）** 为粒度，汇总每日的曝光、点击、商品级互动、加购、PPV、下单及 GMV 等核心漏斗指标，同时提供对应的去重用户数（UU）。

**核心业务场景：**
- A/B 实验效果评估：对比不同实验组（exp_group_id）在推荐漏斗各环节的表现；
- 上游流量来源分析：通过 `upstream_feature` 拆解不同流量入口对推荐模块的贡献；
- 平台 / 广告维度下钻：支持按 `platform`、`is_ads` 进一步细分指标；
- 日常推荐业务监控：跟踪曝光→点击→加购→下单转化链路的每日趋势。

**适合回答的问题：**
- 某实验组在特定地区某天的曝光 UU、点击率、GMV 是多少？
- 不同上游来源（`upstream_feature`）在猜你喜欢模块的转化效果如何？
- 去除"返回行为"（is_back）后的 PPV 用户数趋势如何变化？
- 广告与非广告流量在各推荐功能位的点击行为差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，如 `SG`、`MY` 等，对应业务大区 |
| `local_date` | date | 业务日期分区，格式 `yyyy-MM-dd`，每日覆盖写入 |

### 维度：实验与功能位

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID；仅保留在推荐场景白名单（`is_rcmd_scene_whitelist = 1`）中的有效实验组 |
| `feature_detail` | string | 推荐功能位标识，取值形如 `product-you_may_also_like*`，标识"猜你喜欢"模块下的具体功能位 |
| `upstream_feature` | string | 流量上游来源特征，标识推荐流量的入口或上游链路 |

### 维度：平台与广告

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 访问平台，如 `android`、`ios`、`web` 等；当对应维度做全量聚合时填充为 `__ALL__` |
| `is_ads` | string | 是否为广告流量，取值 `true` / `false`；全量聚合时填充为 `__ALL__` |

### 指标：曝光与点击（次数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 推荐模块曝光总次数（`operation = 'impression'`） |
| `click_cnt` | bigint | 推荐模块点击总次数（`operation = 'click'`） |
| `item_imp_cnt` | bigint | 商品级曝光次数（`operation = 'impression'` 且 `feature_detail LIKE '%item'`） |
| `item_click_cnt` | bigint | 商品级点击次数（`operation = 'click'` 且 `feature_detail LIKE '%item'`） |

### 指标：曝光与点击（去重用户数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 有曝光行为的去重用户数（`imp_cnt > 0` 的 `user_id` distinct count） |
| `click_uu` | bigint | 有点击行为的去重用户数 |
| `item_imp_uu` | bigint | 有商品级曝光行为的去重用户数 |
| `item_click_uu` | bigint | 有商品级点击行为的去重用户数 |

### 指标：页面访问（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt_exclude_isback` | bigint | 排除"返回行为"（`is_back IS NOT TRUE`）后的 PPV 次数，用于更准确衡量主动页面访问 |
| `ppv_uu` | bigint | 有 PPV 行为（排除 is_back）的去重用户数 |

### 指标：加购

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | double | 加购次数（`operation = 'cart'`） |
| `atc_uu` | bigint | 有加购行为的去重用户数（Add-To-Cart UU） |

### 指标：下单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单次数（`operation = 'order'`） |
| `order_uu` | bigint | 有下单行为的去重用户数 |
| `gmv` | double | 下单产生的 GMV（`operation = 'order'` 时的 `place_order_gmv` 之和） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，避免全表扫描；该字段为首级分区，不加会扫全量地区数据。
- **`local_date`**：必须指定，避免跨日全量扫描；该字段为二级分区，通常取单日或指定日期范围。

```sql
-- 推荐写法示例
WHERE grass_region = 'SG'
  AND local_date = '2025-05-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`item_imp_uu`、`item_click_uu`、`ppv_uu`、`atc_uu`、`order_uu` | 去重用户数（Distinct Count），跨维度聚合会导致重复计数，不可直接累加 |
| `gmv`、`cart_cnt`、`order_cnt` | 类型为 `double`，存在小数，直接 SUM 需注意精度问题 |

### 多粒度聚合说明

ETL 使用 `GROUPING SETS` 生成多个维度组合的聚合行：

| 聚合粒度 | `platform` | `is_ads` |
|---|---|---|
| is_ads + platform + upstream_feature + feature_detail + exp_group_id | 原始值 | 原始值 |
| is_ads + upstream_feature + feature_detail + exp_group_id（跨平台汇总） | `__ALL__` | 原始值 |
| platform + upstream_feature + feature_detail + exp_group_id（跨广告汇总） | 原始值 | `__ALL__` |
| upstream_feature + feature_detail + exp_group_id（全量汇总） | `__ALL__` | `__ALL__` |

**使用时需明确 `platform` 和 `is_ads` 的过滤条件**，否则会出现重复叠加。例如只取最细粒度：

```sql
WHERE platform != '__ALL__'
  AND is_ads   != '__ALL__'
```

### 时效性说明

- 本表为 **日表（`_1d`）**，当日数据次日产出（T+1），每次以 `INSERT OVERWRITE` 全量覆盖对应分区。
- 无近 N 天滑动窗口，每个分区代表单日聚合结果。

### 业务范围限制

- 仅覆盖 `feature_detail LIKE 'product-you_may_also_like%'` 且 `reporting_object = 'you may also like'` 的推荐曝光行为。
- 仅包含实验白名单中的分组（`is_rcmd_scene_whitelist = 1`）。
- 仅统计登录用户（`user_id > 0`）的行为。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 原始用户行为明细，提供曝光、点击、加购、PPV、下单等事件记录及 GMV 数据 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | A/B 实验分组维表，过滤出推荐场景白名单实验组（`is_rcmd_scene_whitelist = 1`） |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
        │  过滤推荐场景、登录用户、有效实验组
        ▼
raw_tracking（用户×维度×exp_group_ids 级聚合）
        │  LATERAL VIEW EXPLODE(exp_group_ids)
        ▼
base_table_exploded（用户×维度×单个 exp_group_id 展开）
        │  INNER JOIN
srdi_mart.dim_sr_data_warehouse_abtest_group ──▶ exp_filter（白名单实验组）
        ▼
base_table_exploded_exp_filtered（白名单过滤后的明细）
        │  GROUPING SETS 多维聚合
        ▼
metrics_agg（多粒度 UU + SUM 指标）
        │  COALESCE NULL → '__ALL__'
        ▼
srdi_mart.dws_sr_data_warehouse_rcmd_exp_upstream_level_metrics_1d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `raw_tracking_*` | 从 DWD 明细表按地区、日期过滤推荐场景（you_may_also_like）和有效实验组（exp_group_ids 中存在 > 0 的值），按用户×维度×exp_group_ids 聚合各操作次数 |
| 2 | `base_table_exploded_*` | 使用 `LATERAL VIEW EXPLODE` 将 `exp_group_ids` 数组展开为单行，每个实验组 ID 独立一行 |
| 3 | `exp_filter_*` | 从实验分组维表中查询当日推荐场景白名单实验组 ID 列表 |
| 4 | `base_table_exploded_exp_filtered_*` | INNER JOIN 过滤，仅保留白名单实验组的用户行为数据 |
| 5 | `metrics_agg_*` | 使用 `GROUPING SETS` 对 4 个维度组合分别计算去重 UU（COUNT DISTINCT）和累计次数（SUM），生成多粒度聚合结果 |
| 6 | INSERT OVERWRITE | 将 `metrics_agg` 结果写入目标表分区，`NULL` 的 `platform` 和 `is_ads` 用 `COALESCE` 替换为 `__ALL__` |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，不存在 multi-writer 冲突风险。
- **分区覆盖写入**：每次执行 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 对单个地区日期分区全量覆盖，重跑幂等安全。
- **`__ALL__` 占位符**：`platform` 和 `is_ads` 为 `NULL` 时（来自 `GROUPING SETS` 汇总行）被替换为字符串 `__ALL__`，查询时务必用 `!= '__ALL__'` 或 `= '__ALL__'` 明确过滤，避免重复统计。
- **`ppv_cnt_exclude_isback` 无对应 `ppv_cnt` 列**：原始数据中计算了 `ppv_cnt`（含 is_back）和 `ppv_cnt_exclude_isback`（排除 is_back），但目标表中仅保留了 `ppv_cnt_exclude_isback`，使用时注意该指标已排除返回行为。
- **`cart_cnt`、`order_cnt`、`gmv` 为 double 类型**：源自 DWD 层聚合后的浮点值，精度敏感场景建议使用 `ROUND` 或转换为 `decimal`。

---

*文档生成时间：2026-05-17*