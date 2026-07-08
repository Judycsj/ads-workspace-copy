<!-- ads-workspace-gdoc-sync: gdoc_id=1_XgQfSIVv7pVgDwW-n8OXktRVpXveDBUr7zok9h1270 gdoc_url=https://docs.google.com/document/d/1_XgQfSIVv7pVgDwW-n8OXktRVpXveDBUr7zok9h1270/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_ads_type_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `exp_group_id` + `entrance` + `placement` + `pricing_type`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1，覆盖写入）
**引用频次 / 访问频次：** 709

---

## 业务描述

本表是搜索广告 A/B 实验的**广告类型维度汇总宽表**，以"实验分组 × 入口 × 广告位 × 计费方式"为粒度，沉淀搜索广告每日核心效果指标与曝光展示指标。

**核心业务场景：**
- 搜索广告 A/B 实验效果评估：对比不同实验组在广告曝光、点击、加购、下单、GMV、广告收入方面的差异。
- 广告展示质量分析：通过 `display` / `not_display` 分类指标，判断广告是否被用户实际可见，辅助广告展位质量优化。
- 广告类型 × 计费方式的精细化运营：按 `pricing_type`（如 CPC、CPM）和 `placement`（广告位）拆解各实验组的变现能力。

**适合回答的典型问题：**
- 某实验组相比对照组，搜索广告 CTR / CVR / ROAS 是否显著提升？
- 不同计费类型（CPC vs CPM）在各实验组的广告收入和 GMV 表现如何？
- 广告展示广告（display）与非展示广告（not_display）的曝光/点击量在各实验组的占比？
- 特定广告位（placement）在 A/B 实验中的转化漏斗数据？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 `SG`、`MY`、`TH` 等；每个分区对应一个 Shopee 运营区域 |
| `local_date` | date | 业务日期（本地时间），格式 `yyyy-MM-dd`；ETL 按天覆盖写入 |

### 维度：实验与广告类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，仅含搜索白名单且已分配日志的用户所在分组 |
| `entrance` | int | 广告入口，ETL 中过滤 `entrance = 1`（搜索场景入口），已强制转换为 INT 类型 |
| `placement` | bigint | 广告位 ID，标识广告展示的具体位置 |
| `pricing_type` | string | 广告计费类型，如 CPC（按点击计费）、CPM（按千次曝光计费）等 |

### 指标：广告效果（Performance）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_imp_cnt` | bigint | 广告曝光总次数，对应广告效果表 `impression_cnt` 的聚合值 |
| `ads_clk_cnt` | bigint | 广告点击总次数，对应广告效果表 `click_cnt` 的聚合值 |
| `ads_cart_cnt` | bigint | 广告带来的加购次数，等于点击后加购（`add_to_cart_cnt`）与未点击加购（`add_to_cart_without_clicks_cnt`）之和 |
| `ads_direct_order_cnt` | double | 广告直接转化订单数（归因窗口内直接下单） |
| `ads_broad_order_cnt` | double | 广告宽泛转化订单数（含间接归因订单） |
| `ads_direct_gmv_usd` | double | 广告直接转化 GMV（USD），来源于广告效果表 `ads_order_gmv_usd` 字段 |
| `ads_broad_gmv_usd` | double | 广告宽泛转化 GMV（USD），由本地货币金额 `broad_gmv_amt_local` 除以当日汇率换算得出 |
| `ads_revenue_usd` | double | 广告收入（USD）；对于 CPM 广告（`entrance IN (27,28)` 且 `placement IN (3327,3328)`）使用 `expense_by_cpm / 100000.0`，其他使用 `expenditure_amt_usd` |

### 指标：广告展示质量（Display Traffic）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_impression_display_cnt` | bigint | 展示广告（`display_ad_tag = 1`）的曝光次数（`operation = 1`） |
| `ads_impression_not_display_cnt` | bigint | 非展示广告（`display_ad_tag = 0` 或为 NULL）的曝光次数（`operation = 1`） |
| `ads_click_display_cnt` | bigint | 展示广告（`display_ad_tag = 1`）的点击次数（`operation = 2`） |
| `ads_click_not_display_cnt` | bigint | 非展示广告（`display_ad_tag = 0` 或为 NULL）的点击次数（`operation = 2`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：查询时务必添加 `WHERE grass_region = '<region>' AND local_date = '<date>'`，避免全表扫描，否则将触发大量跨分区 IO。
- 若需跨日汇总，建议使用 `local_date BETWEEN '<start>' AND '<end>'` 而非省略分区过滤。

### 不可直接 SUM 的字段

- `ads_broad_gmv_usd`：由本地货币金额通过汇率换算所得，**跨 region 不可直接累加**（汇率不同）；同一 region 内跨日 SUM 需注意汇率日变动。
- `ads_revenue_usd`：CPM 与非 CPM 广告使用不同计算逻辑合并写入，**跨 `pricing_type` SUM 时需确认业务口径一致性**。
- `ads_direct_order_cnt` / `ads_broad_order_cnt`：类型为 double（源自浮点归因系数），**不建议直接 COUNT/SUM 作为精确订单数**，如需整数化请使用 `ROUND` 或 `CAST`。
- CTR、CVR、ROAS 等比率指标**未在本表预计算**，需在查询层由对应分子分母字段自行计算，不可对预算出的比率再做聚合。

### 时效性说明

- 本表为 **`_1d` 天级汇总表**，每日 T+1 更新，`INSERT OVERWRITE` 分区写入，最新数据通常为昨日。
- 无近 N 天滚动窗口，需要多日数据时请在查询层自行按日期范围聚合。
- 上游广告效果表（`dwd_advertise_performance_di`）及流量明细表（`dwd_advertise_tracking_item_hi`）均为准实时数仓，本表加工后数据已固化为快照，不随上游实时刷新。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取搜索 A/B 实验用户与分组映射（过滤搜索白名单 + 已分配日志用户） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 获取每日各区域汇率，用于将本地货币 GMV 换算为 USD |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告效果明细（曝光、点击、加购、订单、GMV、广告收入） |
| `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` | 广告流量追踪明细（展示/非展示标签、曝光/点击行为） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──────────────────────────────┐
                                                                        ▼
dwd_advertise_performance_di  ──►  dwd_ads_performce  ──►  dws_performance_metrics ──┐
dim_exchange_rate (汇率换算) ──────────────────────────────────────────────────────┘   │
                                                                                       ├──► FULL OUTER JOIN ──► 目标表
dwd_advertise_tracking_item_hi ──►  dwd_ads_traffic   ──►  dws_display_metrics   ────┘
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `user_exp_mapping` | 从实验用户分组维度表中筛选当日、当前 region、搜索白名单且已分配日志的用户及其实验分组 ID |
| 2 | `exchange_rate` | 读取当日当前 region 汇率，供后续 GMV 换算使用 |
| 3 | `dwd_ads_performce` | 从广告效果明细表中读取搜索入口（`entrance = 1`）的曝光、点击、加购、订单、GMV、广告收入；`broad_gmv_amt_local` 除以汇率换算为 USD；CPM 广告收入使用 `expense_by_cpm / 100000.0`，其他使用 `expenditure_amt_usd` |
| 4 | `dwd_ads_traffic` | 从广告流量追踪明细表中读取搜索入口（`ads_entrance = '1'`）的展示标签与操作类型，生成 display / not_display 的曝光与点击分类计数 |
| 5 | `dws_performance_metrics` | 将 `dwd_ads_performce` INNER JOIN `user_exp_mapping`，按 `exp_group_id + entrance + placement + pricing_type` 聚合广告效果指标 |
| 6 | `dws_display_metrics` | 将 `dwd_ads_traffic` INNER JOIN `user_exp_mapping`，按相同维度聚合展示质量指标 |
| 7 | INSERT OVERWRITE | 以 `FULL OUTER JOIN` 合并 `dws_performance_metrics` 与 `dws_display_metrics`（使用 `<=>` 安全等值处理 NULL），覆盖写入目标表对应 `grass_region` + `local_date` 分区 |

### 注意事项

- **Multi-writer：** 本表仅由单个 ETL 文件写入（`multi_writer = false`），无并发写入风险。
- **分区覆盖写入：** 使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，重跑时会完全替换当天当 region 分区数据，幂等安全。
- **FULL OUTER JOIN 空值处理：** Performance 指标与 Display 指标分别从不同上游表聚合，两侧均可能存在对方无对应记录的情况；目标表中对应指标字段可能为 NULL，使用时请添加 `COALESCE` 处理。
- **`placement` 与 `pricing_type` NULL 安全连接：** JOIN 条件使用 `<=>` 运算符，允许 NULL = NULL 匹配，避免因 NULL 导致数据丢失，但查询时需注意这些维度字段可能存在 NULL 值行。
- **`entrance` 过滤差异：** `dwd_ads_performce` 中 `entrance` 为数值 `1`，而 `dwd_ads_traffic` 中 `ads_entrance` 为字符串 `'1'`，ETL 已分别处理并统一转换为 INT，使用方无需关注。
- **`ads_direct_order_cnt` / `ads_broad_order_cnt` 精度：** 源字段为浮点类型（double），含小数部分，反映广告归因模型的分配系数，业务使用时需注意精度语义。

---

*文档生成时间：2026-05-17*