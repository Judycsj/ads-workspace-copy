<!-- ads-workspace-gdoc-sync: gdoc_id=10o9tEZe6UUdkEBavFb_yS7wYdnckU60CldkcLmeVdkw gdoc_url=https://docs.google.com/document/d/10o9tEZe6UUdkEBavFb_yS7wYdnckU60CldkcLmeVdkw/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_exp_scene_general_upgrade_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `layer_id` + `mapping_general` + `is_ads` + `is_item_card` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次/访问频次：** 4106

---

## 业务描述

本表为搜推（S&R）数仓 **流量控制（TC）实验场景通用升级日汇总表**，以「实验组 × 场景 × 广告/卡片类型」为粒度，汇总 AB 实验各实验组在不同推荐/搜索场景下的核心电商指标与广告收入指标。

**核心业务场景：**
- 监控流量管控（Traffic Management）及商品推荐（MKP RCMD）相关 AB 实验的分场景实验效果；
- 支撑 TC Hold-out 层、全局优先级推荐 Hold-out、低价冷启动等特殊实验层的实验分析；
- 对搜索（Search）、You May Also Like、Daily Discover、Post Purchase、Shop 等多个场景分别计算曝光、点击、成交及广告收入，同时提供 RCMD（推荐汇总）及全场景（`__ALL__`）聚合视角；
- 提供 P99.5 截尾（995）口径的 GMV 和 UV 指标，用于过滤异常用户、提升实验统计功效。

**适合回答的问题：**
- 某实验组在 Daily Discover 场景下相较于对照组的 GMV/点击/成交提升幅度是多少？
- 流量管控实验各层各组在推荐场景的广告 ROI2.0 收入差异如何？
- 去除异常用户（995口径）后，实验组的 GMV 变化趋势如何？
- 各实验组分 is_ads / is_item_card 维度的场景曝光和购买转化情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`MY`、`TH` 等，分区键 |
| `local_date` | date | 业务日期（本地时区），分区键，格式 `yyyy-MM-dd` |

---

### 维度：实验组与层信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | AB 实验组 ID，来源于 `abtest.shopee_experiment_admin_db__group_dimension_tab` |
| `exp_group_type` | int | 实验组类型（如对照组、实验组等），来源于 TC 实验规则维表 |
| `layer_id` | bigint | 实验所在层 ID，用于标识 TC/RCMD 各实验层 |
| `rule_ids` | string | 实验规则 ID 列表；当前版本写入为 `null`，预留字段 |
| `scene_name` | string | 实验场景名称，来源于实验规则维表 `dim_sr_data_warehouse_tc_exp_rule` |

---

### 维度：场景与投放类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 场景通用分类，如 `Search`、`You May Also Like`、`Daily Discover`、`Post Purchase`、`Shop`、`RCMD`（推荐汇总）等 |
| `is_ads` | string | 是否广告流量，取值 `true`、`false`、`__ALL__`（全量汇总） |
| `is_item_card` | string | 是否商品卡片（Item Card），取值 `true`、`false`、`__ALL__`（全量汇总） |

---

### 指标：曝光与点击（当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_imp_pv` | bigint | 请求曝光 PV；当前版本写入为 `null`，预留字段 |
| `request_imp_uv` | bigint | 请求曝光 UV；当前版本写入为 `null`，预留字段 |
| `item_imp_pv` | bigint | 商品曝光 PV，即曝光次数之和 |
| `item_imp_uv` | bigint | 商品曝光 UV，有曝光行为的去重用户数 |
| `item_click_pv` | bigint | 商品点击 PV，即点击次数之和 |
| `item_click_uv` | bigint | 商品点击 UV，有点击行为的去重用户数 |
| `item_imp_uv_995` | bigint | P99.5 截尾口径下的商品曝光 UV（过滤高 GPO 异常用户后的去重曝光用户数） |

---

### 指标：曝光与点击（近7日窗口）

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_l7d` | bigint | 近 7 日商品曝光 PV；当前版本写入为 `null`，预留字段 |
| `item_click_l7d` | bigint | 近 7 日商品点击 PV；当前版本写入为 `null`，预留字段 |
| `item_imp_uv_l7d` | bigint | 近 7 日商品曝光 UV；当前版本写入为 `null`，预留字段 |
| `item_imp_uv_l7d_995` | bigint | 近 7 日 P99.5 截尾口径曝光 UV；当前版本写入为 `null`，预留字段 |

---

### 指标：成交（当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单数（成交笔数之和） |
| `order_uv` | bigint | 成交 UV，有成交行为的去重用户数 |
| `gmv` | double | 商品交易总额（本地货币） |
| `gmv_995` | double | P99.5 截尾口径 GMV（过滤高 GPO 异常用户后的 GMV 之和） |
| `pc2_gmv` | double | PC2 口径 GMV（特定成交归因口径） |
| `pc2_gmv_995` | double | PC2 口径 P99.5 截尾 GMV |

---

### 指标：成交（近7日窗口）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_l7d` | double | 近 7 日 GMV；当前版本写入为 `null`，预留字段 |
| `gmv_l7d_995` | double | 近 7 日 P99.5 截尾口径 GMV；当前版本写入为 `null`，预留字段 |
| `order_l7d` | double | 近 7 日订单数；当前版本写入为 `null`，预留字段 |
| `order_uv_l7d` | bigint | 近 7 日成交 UV；当前版本写入为 `null`，预留字段 |
| `pc2_gmv_l7d` | double | 近 7 日 PC2 口径 GMV；当前版本写入为 `null`，预留字段 |

---

### 指标：广告收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue_local` | double | 广告收入（本地货币），仅在 `is_ads='__ALL__'` 且 `is_item_card='__ALL__'` 时关联广告数据写入，其余维度组合为 `null` |
| `ads_revenue_usd` | double | 广告收入（美元），关联条件同上 |
| `ads_revenue_local_roi2` | double | ROI 2.0 广告收入（本地货币），关联条件同上 |
| `ads_revenue_usd_roi2` | double | ROI 2.0 广告收入（美元），关联条件同上 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须指定，该字段为物理分区键，不加会触发全分区扫描。
2. **`local_date`**：必须指定，该字段为物理分区键，务必按业务日期过滤。示例：
   ```sql
   WHERE grass_region = 'ID' AND local_date = '2025-05-16'
   ```
3. **`is_ads` / `is_item_card`**：若需要全量汇总口径，使用 `= '__ALL__'`；若需要广告/非广告拆分，使用 `= 'true'` 或 `= 'false'`。注意不同组合的广告收入字段含义不同（见下文）。
4. **`mapping_general`**：按场景过滤时注意 `RCMD` 为 You May Also Like + Daily Discover + Post Purchase 的汇总，`__ALL__` 暂未出现在本表，需确认使用的场景枚举值。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_imp_uv`、`item_click_uv`、`order_uv`、`item_imp_uv_995` | 去重 UV 指标，跨 `mapping_general` 或维度组合 SUM 会导致重复计数 |
| `item_imp_uv_l7d`、`order_uv_l7d`、`item_imp_uv_l7d_995` | 同上，当前为 null 预留字段 |
| `ads_revenue_local` 等广告收入字段 | 仅在 `is_ads='__ALL__' AND is_item_card='__ALL__'` 时有值，跨维度直接 SUM 会重复计算 |
| `gmv_995`、`pc2_gmv_995`、`item_imp_uv_995` | P99.5 截尾派生指标，截尾阈值来自独立维表，不可跨场景直接累加后等同于场景截尾结果 |

### 时效性说明

- 本表为 **T+1 日粒度**（`_1d` 后缀），每日覆盖写入（`INSERT OVERWRITE`），查询时应指定 `local_date` 为已产出日期。
- 近 7 日窗口字段（`_l7d` 后缀）**当前全部写入 `null`**，为预留扩展字段，暂不可用于分析。
- `request_imp_pv`、`request_imp_uv`、`rule_ids` 同样为 **null 预留字段**，不可用于计算。
- 广告收入字段（`ads_revenue_*`）**仅在 `is_ads='__ALL__' AND is_item_card='__ALL__'` 的行中有值**，在其他维度切分行中为 null，跨维度聚合时需注意。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_tc_exp_rule` | TC 实验规则维表，提供 `exp_group_type`、`rule_ids`、`scene_name` |
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | AB 实验组元数据，提供 `group_id`、`layer_id`、`project_name` |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户-实验组分配关系，提供用户维度实验分组信息 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | TC 场景用户级曝光/点击/成交/GMV 基础聚合日表，为核心指标来源 |
| `srdi_mart.dws_sr_data_warehouse_tc_scene_995_threshold_1d` | 各场景 P99.5 GPO 截尾阈值维表，用于计算 995 口径指标 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细，提供用户级广告消耗（本地货币/美元）及 ROI2.0 标识 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，提供广告产品类型（`product_type`，用于识别 ROI2.0） |
| `mp_paidads.dim_entry_point_mapping_v2` | 广告入口点与流量类型映射表，用于将广告入口映射到场景分类 |

---

## ETL 逻辑摘要

### 数据流

```
[实验组元数据] ─────────────────────────────┐
[TC实验规则维表] ──→ exp_info               │
[用户-实验组分配] ──→ user_exp              │
                                            ↓
[pb基础聚合表] ──→ every_scene_data (step1/step2) ──→ exp_civ (实验组×场景指标)
[995阈值维表] ─────────────────────────────→↑
                                            │
[广告明细] ──→ ads_raw ──→ ads (按场景聚合) ──→ exp_ads (实验组×场景广告收入)
[广告维表/入口映射] ──→↑
                                            │
                               exp_civ LEFT JOIN exp_ads
                                            │
                              INSERT OVERWRITE 目标表
```

### 关键步骤

1. **`tc_exp_rule`（Temporary View）**：从 TC 实验规则维表读取当日实验规则，包含 `exp_group_type`、`rule_ids`、`scene_name`。

2. **`exp_info`（CACHE TABLE）**：关联实验组元数据与 TC 规则，筛选属于 Traffic Management / MKP RCMD 项目或特定白名单层（TC Hold-out、低价冷启动、sr_vitem 等）的实验组，并排除黑名单层 ID。

3. **`user_exp_raw` / `user_exp`（Temporary View）**：从用户-实验组分配表中取 `is_assignment_log=1` 的分配记录，与 `exp_info` 内连接，得到参与目标实验的用户-实验组映射。

4. **`scene_995_threshold`（Temporary View）**：读取各场景 P99.5 GPO 截尾阈值。

5. **`every_scene_data_step1`（Temporary View）**：从 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d` 读取用户级场景聚合数据（排除 Video、Live Streaming），通过 `GROUPING SETS` 生成 `is_ads × is_item_card` 的多维聚合（含 `__ALL__` 汇总行）。

6. **`every_scene_data_step2`（Temporary View）**：在 step1 基础上，将 You May Also Like + Daily Discover + Post Purchase 合并为 `RCMD` 汇总场景。

7. **`every_scene_data`（Temporary View）**：UNION ALL step1 与 step2，关联 995 阈值（用于后续截尾计算），内连接 `user_exp` 将用户映射到实验组，形成用户-实验组-场景明细。

8. **`exp_civ`（Temporary View）**：对 `every_scene_data` 按 `exp_group_id × mapping_general × is_ads × is_item_card` 分组聚合，计算 PV 类指标（SUM）、UV 类指标（COUNT DISTINCT）、GMV、PC2 GMV，以及 995 截尾口径下的 UV 和 GMV。

9. **`ads_raw_step1` / `ads_raw_step2`（Temporary View / CACHE TABLE）**：从广告投放明细读取用户级广告消耗，关联广告维表识别 ROI2.0 类型，关联入口点映射确定流量场景（Search / YMAL / DD / PP / Shop / Live Streaming / Other），按用户×场景聚合广告本地收入、USD 收入及 ROI2.0 收入。

10. **`ads`（Temporary View）**：在 ads_raw_step2 基础上，生成四类广告场景汇总：各场景单独、S&R 汇总（Search+RCMD范围）、`__ALL__`（全场景）、`RCMD`（推荐三场景合并），UNION ALL 拼接。

11. **`exp_ads`（Temporary View）**：`user_exp` LEFT JOIN `ads`，将用户广告收入归因到实验组，按 `exp_group_id × common_feature` 聚合广告收入。

12. **`INSERT OVERWRITE`（目标写入）**：将 `exp_civ` LEFT JOIN `exp_info`（补充实验元数据）、LEFT JOIN `exp_ads`（关联条件：`exp_group_id` 相同 AND `mapping_general = common_feature` AND `is_ads='__ALL__'` AND `is_item_card='__ALL__'`），写入目标分区。近 7 日字段、`request_imp_*`、`rule_ids` 等预留字段统一写入 `null`。

### 注意事项

1. **广告收入字段仅在特定维度行有值**：`exp_ads` 仅在 `is_ads='__ALL__' AND is_item_card='__ALL__'` 时被 JOIN，因此广告收入四字段在其他维度组合的行中均为 `null`，查询时需注意过滤条件。

2. **CACHE TABLE 使用**：`exp_info` 和 `ads_raw_step2` 被 CACHE，在后续多次引用中复用，实际分析时应注意两者的数据量对 Spark executor 内存的影响。

3. **预留字段全部为 null**：`rule_ids`、`request_imp_pv`、`request_imp_uv` 及所有 `_l7d` 后缀字段在当前版本 ETL 中均写入 `null`，不可用于分析计算。

4. **INSERT OVERWRITE 覆盖写入**：每次执行覆盖对应 `grass_region + local_date` 分区，重跑幂等；但若上游数据存在延迟重跑，需确保目标分区数据一致性。

5. **Video / Live Streaming 场景排除**：`every_scene_data_step1` 明确排除了 `mapping_general in ('Video','Live Streaming')`，本表不包含此类场景的场景指标。

6. **实验层白名单维护**：`exp_info` 中硬编码了特定 `layer_id` 白名单和黑名单，若有新实验层需纳入，需同步更新 ETL SQL。

---

*文档生成时间：2026-05-17*