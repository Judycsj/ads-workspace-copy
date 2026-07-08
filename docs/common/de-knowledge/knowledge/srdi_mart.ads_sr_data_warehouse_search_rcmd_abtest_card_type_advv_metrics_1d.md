<!-- ads-workspace-gdoc-sync: gdoc_id=1NhlV0nlEekroxdVPh_xawX-Xjbn5gdvctt7F5_AoMpY gdoc_url=https://docs.google.com/document/d/1NhlV0nlEekroxdVPh_xawX-Xjbn5gdvctt7F5_AoMpY/edit -->

# srdi_mart.ads_sr_data_warehouse_search_rcmd_abtest_card_type_advv_metrics_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `domain` + `outlier` + `exp_group_id` + `feature_group` + `main_product_type` + `product_type` + `voucher_type` + `card_type`
**分区：** `grass_region` / `local_date` / `domain` / `outlier`
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 5,344

---

## 业务描述

本表为搜索（Search）与推荐（RCMD）广告 A/B 实验的每日汇总宽表，以**实验分组 × 卡片类型 × 产品类型 × 优惠券类型 × Feature Group** 为粒度，统计广告曝光、点击、订单、GMV、Advv 成本等核心广告效果指标。

**核心业务场景：**

- **A/B 实验评估**：对比不同实验分组（`exp_group_id`）在 Search 或 RCMD 域下的广告关键指标，支撑实验上线决策。
- **卡片类型效果分析**：按 `card_type`（item、video、mix_feed_card 等）细分广告投放效果。
- **异常值对比**：同一实验条件提供原始值（`outlier = '1'`）与去除 P99.9 异常用户后的值（`outlier = '0.999'`），便于统计显著性分析时剔除极值干扰。
- **Advv 成本与 GMV 效率衡量**：追踪广义/直接 Advv 成本、广义/直接 GMV、padvv、deepadvv 等 Advv 体系指标。

**适合回答的问题：**

- 某实验分组在 Search/RCMD 域下的日曝光量、点击率、GMV 是多少？
- 去除 P99.9 异常用户后，实验组与对照组的广告 ROI 差异是否显著？
- 不同卡片类型（item vs video）的广告效果对比？
- 各 feature group 和产品类型下的 padvv、deepadvv 成本分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/站点标识，如 ID、TH、MY 等，每次查询必须指定 |
| `local_date` | date | 本地日期（数据统计日），每次查询必须指定 |
| `domain` | string | 业务域，取值为 `'Search'` 或 `'RCMD'`，分别由两个独立 ETL 文件写入 |
| `outlier` | string | 异常值处理标识：`'1'` 表示原始全量数据；`'0.999'` 表示剔除用户 P99.9 异常值后的数据 |

### 维度：实验与分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，关联实验平台的实验组配置 |
| `feature_group` | string | 实验特征分组，用于细分不同流量特征下的实验效果；`'__ALL__'` 表示全量汇总 |

### 维度：流量分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 广告卡片类型，如 `item`、`video`、`item_mix_feed_card`、`repurchase_mix_feed_card` 等；`'__ALL__'` 表示全卡片类型汇总。Search 域仅包含 `item`、`video`、`others`、`__ALL__`；RCMD 域包含更丰富的内外流卡片类型 |
| `main_product_type` | string | 主产品类型，对应广告商品的主分类；`'__ALL__'` 表示全类型汇总 |
| `product_type` | string | 产品子类型，对主产品类型的进一步细分；`'__ALL__'` 表示全类型汇总 |
| `voucher_type` | string | 优惠券类型，用于区分不同促销券场景；`'__ALL__'` 表示全类型汇总 |

### 指标：广告曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_imp_cnt` | bigint | 广告曝光次数（impression count） |
| `ads_imp_uu` | bigint | 有广告曝光的用户数（去重用户，基于 `ads_imp_cnt > 0` 聚合计算） |
| `ads_click_cnt` | bigint | 广告点击次数 |
| `ads_click_uu` | bigint | 有广告点击的用户数（去重用户，基于 `ads_click_cnt > 0` 聚合计算） |
| `valid_ads_imp_cnt` | bigint | 有效广告曝光次数（仅统计 `deduction_reason = 0` 的曝光，即正常扣费曝光） |
| `top20_ads_imp_cnt` | bigint | 位于前 20 位（location ≤ 19）的广告曝光次数 |
| `ads_total_location` | double | 广告展示位置累计值，用于计算平均广告位 |
| `top20_ads_total_location` | bigint | 前 20 位广告的展示位置累计值 |

### 指标：广告订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_order_cnt` | double | 广告直接带来的订单数（直接归因） |
| `ads_order_uu` | bigint | 有广告订单的用户数（去重用户，基于 `ads_order_cnt > 0` 聚合计算） |
| `ads_gmv_usd` | double | 广告直接 GMV（USD，直接归因） |
| `ads_broad_order_cnt` | double | 广告广义订单数（broad 归因，含间接转化） |
| `broad_gmv_usd` | double | 广义归因 GMV（USD） |
| `revenue_usd` | double | 广告收入（USD），即实际扣费金额 |

### 指标：Advv 成本体系

| 字段 | 类型 | 说明 |
|---|---|---|
| `broad_advv_cost` | double | 广义 Advv 成本（broad 归因口径） |
| `broad_advv_cost_excl_outlier` | double | 广义 Advv 成本（已在上游预先剔除异常值后的版本） |
| `broad_advv_cost_7d` | double | 广义 Advv 成本（7 天归因窗口） |
| `broad_advv_gmv` | double | 广义 Advv GMV |
| `padvv` | double | pAdvv（产品级 Advv 指标，取自上游单次请求 max 聚合，不可直接 SUM） |
| `deepadvv` | double | deepAdvv 成本（深度转化 Advv 指标） |
| `target_cir` | double | 目标 CIR（Cost-Income Ratio），由 `sum(target_cir) / sum(target_cir_cnt)` 计算得出，为加权均值，**不可直接 SUM** |

### 指标：出价与扣费

| 字段 | 类型 | 说明 |
|---|---|---|
| `sum_bid_price_usd` | double | 出价金额累计（USD） |
| `sum_deduction_price_usd` | double | 实际扣费金额累计（USD） |
| `cnt_bid_price` | double | 出价记录数 |
| `cnt_deduction_price` | double | 扣费记录数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定站点，该字段为第一分区键，跨区查询会导致全表扫描，严重影响性能。
- **`local_date`**：必须指定日期范围，避免全量历史扫描。
- **`domain`**：根据分析场景选择 `'Search'` 或 `'RCMD'`，两者由不同 ETL 文件独立写入，卡片类型定义有所不同。
- **`outlier`**：明确选择 `'1'`（原始数据）或 `'0.999'`（去除 P99.9 异常用户后数据），两套数据共存于同一表中，混合查询会导致重复计数。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `target_cir` | 为加权均值（`sum(target_cir) / sum(target_cir_cnt)`），跨行 SUM 无意义；如需再聚合，须回溯原始分子分母 |
| `padvv` | 上游以 `max` 方式聚合到请求粒度，再次 SUM 会产生重复计算 |
| `ads_imp_uu` / `ads_click_uu` / `ads_order_uu` | 用户去重计数，按实验组/卡片类型等维度聚合计算，跨维度 SUM 不等于真实 UU，存在重复 |
| `cnt_bid_price` / `cnt_deduction_price` | 上游部分场景以 `max` 方式聚合，跨行 SUM 可能失真 |

### 时效性说明

- 本表为 **T+1 每日全量覆盖写入**（`INSERT OVERWRITE`），当天数据通常于次日早间可用。
- 数据覆盖范围为单日（`_1d` 后缀），不包含滚动 N 天累计，如需多日汇总需在查询层自行聚合。
- 表为 `multi-writer` 结构，同一 `grass_region` + `local_date` 分区下 `domain = 'Search'` 和 `domain = 'RCMD'` 由两个独立 Spark job 并发写入，两个 job 写不同 `domain` 分区值，正常情况不冲突，但须关注调度时序依赖。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维表，提供用户与实验组的映射关系，以及 Search/RCMD 白名单过滤 |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 广告请求级别的 Advv 基准宽表，包含曝光、点击、订单、GMV、Advv 成本、出价扣费等核心广告指标，为本表主要事实来源 |
| `srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d` | 各 feature group 的广告异常值阈值表（P99.9），用于区分 broad/direct 两种口径的异常用户判定 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group          ──┐
                                                    │
dws_sr_data_warehouse_ads_request_benchmark_advv_1d ─┼─► [card_type / feature_group explode]
                                                    │       ─► [用户级 ABS 计算]
ads_sr_data_warehouse_platform_feature_group_       │           ─► [P99.9 异常值过滤]
  ads_outlier_1d                               ──┘               ─► [JOIN 实验用户组]
                                                                      ─► INSERT OVERWRITE
                                                              ads_sr_data_warehouse_search_rcmd_
                                                              abtest_card_type_advv_metrics_1d
                                                              (outlier='1' UNION ALL outlier='0.999')
```

### 关键步骤

**Step 1 — `user_exp`（Temporary View）**
从实验用户分组维表中过滤当日有效实验用户，按 domain 白名单（`is_search_whitelist` 或 `is_rcmd_whitelist`）筛选，输出 `(user_id, exp_group_id, domain)`。

**Step 2 — `ads_outlier_broad` / `ads_outlier_direct`（Temporary View）**
从异常值阈值表中分别获取 broad 口径和 direct 口径在 P99.9 分位数的绝对值阈值（`abs_999`），按 feature_group 粒度，用于后续异常用户过滤。

**Step 3 — `dws_request_advv_base`（Temporary View）**
从广告请求基准表中读取当日数据，预聚合到 `(main_product_types, product_types, voucher_types, feature_groups, card_types, user_id, ads_id, item_id, campaign_id, request_id)` 粒度，减少后续 explode 数据量。同时依据 entrance / target_type / page_type 等字段构建 `card_types` 数组（RCMD 域包含内外流卡片区分；Search 域仅区分 item/video/others）。

**Step 4 — `dws_request_advv_explode_first`（Temporary View）**
对 `main_product_types`、`product_types`、`voucher_types` 三个数组字段执行 `lateral view explode` 展开，并应用过滤逻辑：非 `__ALL__` 维度展开后保留明细行；全为 `__ALL__` 时保留汇总行，避免重复计数。

**Step 5 — `dws_request_advv_explode_final`（Temporary View）**
对 `feature_groups` 和 `card_types` 数组进一步 `lateral view explode`，并过滤 Livestream、含 `#` 号的异常 feature_group 值，聚合到最终维度粒度（含 `user_id`）。

**Step 6 — `dws_advv_abs`（Temporary View）**
在全维度汇总（`main_product_type = '__ALL__'` 且其他维度均为 `__ALL__'`）下，计算每个用户每个 feature_group 的 `direct_abs`（直接客单价）和 `broad_abs`（广义客单价），用作异常用户判定依据。

**Step 7 — `dws_advv_request`（Temporary View）**
将 Step 5 结果 JOIN Step 6 的用户 ABS 和 Step 2 的 P99.9 阈值，同时计算：
- 原始汇总指标（所有用户）
- `_999` 后缀异常值过滤指标（仅聚合 ABS ≤ P99.9 阈值的用户数据）

**Step 8 — `ads_exp`（CACHE TABLE）**
JOIN 实验用户表，将请求级别数据关联到实验分组，聚合到最终输出粒度，并计算 UU 类指标（`ads_order_uu`、`ads_imp_uu`、`ads_click_uu`）及 `target_cir` 加权均值。

**Step 9 — INSERT OVERWRITE（最终写入）**
将 `ads_exp` 缓存表通过 `UNION ALL` 写出两套数据：
- `outlier = '1'`：原始全量指标
- `outlier = '0.999'`：P99.9 异常用户剔除后指标

使用 `/*+REPARTITION(8)*/` hint 控制输出文件数。

### 注意事项

- **Multi-writer 风险**：本表由两个独立 ETL 文件（`_rcmd.sql` 和 `_search.sql`）分别写入 `domain='RCMD'` 和 `domain='Search'` 分区。两个 Spark Job 同时运行时需确保调度系统保证写入的是不同 `domain` 分区值，避免相互覆盖。
- **card_type 含义差异**：RCMD 域的 `card_type` 区分内外流（如 `video (internal)` vs `video (external)`），Search 域仅有 `item`/`video`/`others`/`__ALL__`，跨 domain 对比时需注意口径对齐。
- **`__ALL__` 汇总行**：`main_product_type`、`product_type`、`voucher_type`、`feature_group`、`card_type` 均存在 `__ALL__` 值表示该维度全量汇总，聚合时需避免将汇总行与明细行重复叠加。
- **`target_cir` 精度**：最终写入的 `target_cir` 为 `sum(target_cir) / sum(target_cir_cnt)` 的加权均值，二次聚合时需将原始分子分母单独处理。
- **`padvv` 聚合方式**：上游单请求粒度以 `max` 聚合，再逐层 `sum`，语义上为请求级 padvv 的汇总，不同于标准均值 padvv，使用时需明确口径。

---

*文档生成时间：2026-05-17*