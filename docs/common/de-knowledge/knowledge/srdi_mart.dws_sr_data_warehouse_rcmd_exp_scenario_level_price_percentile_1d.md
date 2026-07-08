<!-- ads-workspace-gdoc-sync: gdoc_id=1f602NAVwuciemQaLSbtL05JMhOFsTEr_rPadhPr5J30 gdoc_url=https://docs.google.com/document/d/1f602NAVwuciemQaLSbtL05JMhOFsTEr_rPadhPr5J30/edit -->

# srdi_mart.dws_sr_data_warehouse_rcmd_exp_scenario_level_price_percentile_1d

**分层：** DWS（数据汇总层）
**主键：** `local_date` + `grass_region` + `exp_group_id` + `is_ads` + `feature_group` + `operation` + `percentile`
**分区：** `local_date`（日期）、`grass_region`（大区）
**更新频率：** 每日一次（T+1 全量覆写分区）
**引用频次 / 访问频次：** 713

---

## 业务描述

本表面向**推荐实验（A/B Test）场景**，在**价格分位数**维度下，汇总各推荐场景（Daily Discover、You May Also Like、Cart Unify）的曝光、点击、订单、GMV 等核心指标，用于评估不同价格区间内推荐效果的分布情况。

**核心业务场景：**
- **实验组价格分布分析：** 按实验组（`exp_group_id`）、场景（`feature_group`）、操作类型（`operation`）和价格分位数（`percentile`），观察各分位阈值以下的商品流量和 GMV 贡献。
- **价格阈值效果评估：** 通过 p50/p70/p90/p99/p99.5/p99.9/p100 等分位点，分析推荐实验中商品价格的集中程度及离散情况。
- **广告 vs 自然流量对比：** 通过 `is_ads` 维度拆分广告流量与自然推荐流量的价格分位数表现。

**适合回答的问题示例：**
- 在某推荐实验组中，哪个价格分位以下的商品贡献了 90% 的曝光量？
- Daily Discover 场景下，广告和自然推荐的价格中位数（p50）分别是多少？
- 不同 A/B 实验组之间，订单 GMV 的价格分位分布有何差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `local_date` | date | 数据日期（本地时区），按天分区 |
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），按大区分区 |

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `exp_group_id` | bigint | A/B 实验组 ID，仅包含推荐场景白名单实验或指定实验（ID 19602、19850）中的分组 |
| `is_ads` | string | 广告标识；`'true'` 表示广告流量，`'false'` 表示自然推荐，`'__ALL__'` 表示全量（广告+自然聚合） |
| `feature_group` | string | 推荐场景名称，取值：`'Daily Discover'`、`'You May Also Like'`、`'Cart Unify'`、`'all'`（跨场景聚合） |
| `operation` | string | 操作类型：`'impression'`（曝光）、`'click'`（点击）、`'order'`（下单，按商品标价）、`'order_paid'`（下单，按实际支付价格） |

### 维度：价格分位维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `percentile` | double | 价格分位点，取值：0.5（p50）、0.7（p70）、0.9（p90）、0.99（p99）、0.995（p99.5）、0.999（p99.9）、1.0（p100） |
| `price_thres` | double | 对应分位点的价格阈值（USD），即在该 `operation` 下价格累计分布达到 `percentile` 时对应的商品价格上限 |
| `avg_price` | double | 加权平均价格（USD），按 `operation` 次数加权，`SUM(price_usd × cnt) / SUM(cnt)`；**不可直接 SUM** |

### 指标：商品规模指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_cnt` | bigint | 价格 ≤ `price_thres` 的商品去重数量（`COUNT DISTINCT item_id`）；**不可直接 SUM** |

### 指标：流量漏斗指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_cnt` | bigint | 价格 ≤ `price_thres` 的商品曝光次数 |
| `click_cnt` | bigint | 价格 ≤ `price_thres` 的商品点击次数 |
| `ppv_cnt` | bigint | 价格 ≤ `price_thres` 的商品 PPV（Product Page View）次数，来源字段为 `ppv_cnt_exclude_isback`（已排除返回行为） |
| `cart_cnt` | bigint | 价格 ≤ `price_thres` 的商品加购次数 |

### 指标：订单与 GMV 指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | double | 价格 ≤ `price_thres` 的订单数量（对 `operation='order'` 或 `'order_paid'` 有效） |
| `gmv` | double | 价格 ≤ `price_thres` 的自然推荐 GMV（USD），来源于推荐平台归因 |
| `pc2_gmv` | double | 价格 ≤ `price_thres` 的 PC2 口径 GMV（USD） |

### 指标：广告收益指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_order_gmv_usd` | double | 价格 ≤ `price_thres` 的广告订单 GMV（USD），来源于广告请求基准表 `ads_gmv_usd` |
| `broad_gmv_usd` | double | 价格 ≤ `price_thres` 的广告宽口径 GMV（USD），来源于广告请求基准表 `broad_gmv_usd` |
| `revenue_usd` | double | 价格 ≤ `price_thres` 的广告收入（USD），来源于广告请求基准表 `revenue_usd` |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤为强制要求**，每次查询必须同时指定 `local_date` 和 `grass_region`，否则将触发全表扫描：
  ```sql
  WHERE local_date = '2025-05-16'
    AND grass_region = 'SG'
  ```
- `operation` 字段建议显式过滤，不同操作类型的计量基准不同（曝光用商品标价，`order_paid` 用实际支付价格），混用将导致分析偏差。
- `percentile` 建议明确指定，避免将所有分位点数据错误聚合。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `percentile` | 分位点标识，为维度值，不应参与汇总 |
| `price_thres` | 价格分位阈值，为预聚合结果，不同分组直接相加无业务意义 |
| `avg_price` | 加权均值，跨分组直接 SUM 会造成双重计数，需重新用原始数据计算 |
| `item_cnt` | 基于 `COUNT DISTINCT` 计算，跨 `feature_group`/`exp_group_id` 聚合存在重复计数风险 |
| `order_cnt` | 类型为 `double`（聚合自 SUM），跨不同 `operation` 求和无意义 |

### `is_ads` 的 CUBE 聚合说明

- `is_ads = '__ALL__'` 行是对 `'true'` 和 `'false'` 的聚合汇总，查询时若不过滤 `is_ads`，将导致数据重复统计。建议根据分析目的选择其中一个维度值，或在 `WHERE` 条件中排除 `'__ALL__'` 行后手动聚合。

### `feature_group = 'all'` 说明

- `feature_group = 'all'` 为跨场景聚合行（源自 `scenario_tag = '__ALL__'`），与各具体场景行之间存在包含关系，不可与其他 `feature_group` 行简单叠加。

### 时效性说明

- 本表为 `_1d` 后缀的**日粒度快照表**，每日 T+1 全量覆写当日分区，数据反映自然日内的汇总结果，无实时/准实时能力。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_item` | 获取商品维度信息，关联商品标价（`price_usd`） |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 获取推荐场景白名单实验组过滤条件 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户与实验组的归属映射，用于广告指标关联 |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 提供用户维度的曝光（impression）和点击（click）行为明细 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供订单（order）行为明细，含算法 tag 归因 |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | 获取订单实际支付价格（`order_price_pp_usd`），用于 `order_paid` 口径 |
| `srdi_mart.dws_sr_data_warehouse_platform_item_exp_level_benchmark_1d` | 提供商品-实验组粒度的流量漏斗指标（曝光、点击、加购、订单、GMV 等） |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 提供广告维度的宽口径 GMV、广告收入、广告订单 GMV |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_item             ─┐
dim_sr_data_warehouse_abtest_group     ─┤─→ 价格分位数计算管道（曝光/点击/订单）
dwm_sr_data_warehouse_platform_user_item  ─┤   → price_pct_explode（分位点展开）
dwd_sr_data_warehouse_platform         ─┤
mp_order.dwd_order_item_...            ─┘

dws_sr_data_warehouse_platform_item_exp_level_benchmark_1d ─┐
dim_sr_data_warehouse_abtest_user_group                    ─┤─→ 商品特征汇总（sr_features, ads_features）
dws_sr_data_warehouse_ads_request_benchmark_advv_1d       ─┘

price_pct_explode × joined_features → price_pct_with_features
price_pct_explode LEFT JOIN price_pct_with_features → INSERT OVERWRITE 目标表
```

### 关键步骤

1. **维度准备（Temporary Views）**
   - `dim_item_price`：从 `dim_sr_data_warehouse_item` 获取当日商品标价。
   - `dim_exp_group_filter`：从 `dim_sr_data_warehouse_abtest_group` 过滤推荐场景白名单实验组。
   - `dim_user_exp_group_mapping`：从 `dim_sr_data_warehouse_abtest_user_group` 获取用户-实验组映射。

2. **曝光/点击价格分位数计算**
   - 关联商品价格后按 `(is_ads, scenario_tag, operation, exp_group_id)` 分组聚合操作次数。
   - CUBE 展开 `is_ads` 以生成全量聚合行（`'__ALL__'`）。
   - 利用窗口函数计算价格累计分布，提取 p50/p70/p90/p99/p99.5/p99.9/p100 分位阈值及加权均价。
   - 生成临时视图 `dws_data_imp_click_pct`。

3. **订单价格分位数计算**
   - 同时生成 `order`（商品标价口径）和 `order_paid`（实际支付价格口径）两类记录。
   - 与订单价格表（`mp_order`）LEFT JOIN 获取实际支付价格。
   - 同样通过窗口函数计算分位阈值，生成临时视图 `dws_data_order_pct`。

4. **分位点展开（CACHE TABLE）**
   - 将 `dws_data_imp_click_pct` 和 `dws_data_order_pct` 中的 p50～p100 数组通过 `posexplode` 拆成行记录，标准化 `scenario_tag` 为 `feature_group` 标签。
   - 结果缓存至 `price_pct_explode`（`MEMORY_AND_DISK_2`），用于后续多次关联。

5. **商品特征汇总**
   - 从 `dws_sr_data_warehouse_platform_item_exp_level_benchmark_1d` 汇总商品级别的曝光、点击、加购、订单、GMV 指标（`sr_features`）。
   - 从 `dws_sr_data_warehouse_ads_request_benchmark_advv_1d` 关联用户-实验组映射，汇总广告 GMV/收入（`ads_features_inter`）。
   - 合并为 `joined_features`，含商品标价与实际支付均价。

6. **价格分位数与特征关联**
   - 以 `price_pct_explode` 为驱动，INNER JOIN `joined_features`，按"价格 ≤ 分位阈值"条件过滤，聚合各流量漏斗指标，生成 `price_pct_with_features`。
   - `order_paid` 使用实际支付价格（`order_price_usd`）与阈值比较，其余操作类型使用商品标价（`price_usd`）。

7. **写入目标表**
   - `INSERT OVERWRITE` 以 `(local_date, grass_region)` 为分区，将 `price_pct_explode` LEFT JOIN `price_pct_with_features` 的结果写入目标表，`COALESCE` 将 NULL 指标补 0。

### 注意事项

- **单写入文件**：本表仅有 1 个 ETL 源文件，无 multi-writer 风险。
- **分区写入策略**：采用 `INSERT OVERWRITE PARTITION (local_date, grass_region)` 方式，每次运行覆盖指定日期和大区分区，不同大区之间的分区互相独立。
- **`is_ads` CUBE 双重计数风险**：ETL 中使用 `CUBE(is_ads)` 生成全量聚合行，下游查询时若不显式过滤 `is_ads`，将导致数据重复叠加。
- **`order_cnt` 类型为 double**：原始 `order_cnt` 在上游 benchmark 表中为聚合后的 `double`，ETL 中通过 `SUM` 继续聚合，查询时需注意精度及与 `bigint` 字段混用的问题。
- **CACHE TABLE 依赖**：`price_pct_explode` 被 CACHE，若 Spark 内存不足导致 CACHE 降级，可能影响执行性能，但不影响结果正确性（策略为 `MEMORY_AND_DISK_2`）。
- **`mp_order` 分区边界**：订单表过滤条件为 `grass_date >= local_date - 1 day AND date(create_datetime) = local_date`，存在跨天补偿逻辑，需注意与其他表日期对齐的口径差异。

---

*文档生成时间：2026-05-17*