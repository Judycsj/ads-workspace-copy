<!-- ads-workspace-gdoc-sync: gdoc_id=1VYvMvcV89hFfjj8WUL4xE3WwxeRPhUyqWnZtet1i42c gdoc_url=https://docs.google.com/document/d/1VYvMvcV89hFfjj8WUL4xE3WwxeRPhUyqWnZtet1i42c/edit -->

# srdi_mart.ads_sr_data_warehouse_search_rcmd_abtest_advv_metrics_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `domain` + `outlier` + `exp_group_id` + `feature_group` + `product_type` + `voucher_type`
**分区：** `grass_region`（站点/大区）、`local_date`（业务日期）、`domain`（业务域，Search / RCMD）、`outlier`（是否去极值，'1' 表示不去极值，'0.999' 表示去 99.9% 分位极值）
**更新频率：** 每日一次（T+1）
**引用频次/访问频次：** 2202

---

## 业务描述

本表为搜索（Search）与推荐（RCMD）广告 A/B 实验的每日广告价值（ADVV）核心指标汇总表，面向搜推广告实验分析场景。

**核心业务场景：**
- 按 A/B 实验分组（`exp_group_id`）、功能特征组（`feature_group`）、广告产品类型（`product_type`）、优惠券类型（`voucher_type`）等维度，汇总搜索/推荐广告在各实验组下的广告花费、GMV、收入、ADVV 相关指标；
- 同时提供"原始"（`outlier = '1'`）和"去极值后"（`outlier = '0.999'`，按 99.9% 分位 ABS 阈值过滤）两套指标，支持实验数据的稳健性分析与对比；
- 适合回答的典型问题：
  - 某实验组相比对照组的广告花费、GMV、ROI 差异是什么？
  - 去极值前后实验结论是否一致？
  - 不同产品类型（如 ROAS、CPC 等）在各实验组下的 ADVV 表现如何？
  - 实验期间各组的平均出价、平均扣费、扣费出价比等价格健康度指标？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区，如 MY、TW、ID 等 |
| `local_date` | date | 业务日期（本地时区） |
| `domain` | string | 业务域，取值为 `'Search'`（搜索）或 `'RCMD'`（推荐） |
| `outlier` | string | 极值处理标识：`'1'` 表示原始数据（不去极值）；`'0.999'` 表示已按 99.9% 分位 ABS 阈值过滤极值用户 |

### 维度：实验与分组维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验组 ID |
| `feature_group` | string | 功能特征组标识，对应实验功能模块；`'__ALL__'` 表示全量汇总 |
| `product_type` | string | 广告产品类型，如 `manual_cpc`、`manual_ecpc`、`itemboost`、`new_product_boost`、`video_max_view`、`__ALL__` 等 |
| `voucher_type` | string | 优惠券类型，`'__ALL__'` 表示全量汇总 |

### 指标：广告收入与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue_usd` | double | 广告收入（USD），即平台从广告主处收取的费用 |
| `ads_gmv_usd` | double | 广告直接 GMV（USD），广告直接带来的成交金额 |
| `broad_gmv_usd` | double | 广告宽口径 GMV（USD），包含广告相关联的宽泛归因 GMV |

### 指标：ADVV（广告价值）相关费用

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_advv_cost` | double | 直接归因口径下的广告 ADVV 花费（USD） |
| `broad_advv_cost` | double | 宽口径归因下的广告 ADVV 花费（USD） |
| `broad_advv_cost_excl_outlier` | double | 宽口径 ADVV 花费（排除极值广告主，USD） |
| `broad_advv_cost_7d` | double | 宽口径 ADVV 花费（7 天归因窗口，USD） |
| `padvv` | double | pADVV 花费指标（USD），代表预测 ADVV 花费 |
| `deepadvv` | double | Deep ADVV 花费指标（USD），深度转化口径的 ADVV 花费 |

### 指标：ADVV GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_advv_gmv` | double | 直接归因口径下的广告 ADVV GMV（USD） |
| `broad_advv_gmv` | double | 宽口径归因下的广告 ADVV GMV（USD） |

### 指标：ROI 比率

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_cost_ratio` | double | 直接口径广告 ROI，计算方式为 `revenue_usd / direct_advv_cost`；**不可直接 SUM** |
| `broad_cost_ratio` | double | 宽口径广告 ROI，计算方式为 `revenue_usd / broad_advv_cost`；**不可直接 SUM** |
| `direct_gmv_ratio` | double | 直接口径 GMV 归因率（`ads_gmv_usd / direct_advv_gmv`）；CPC 等产品类型固定为 1；`product_type = '__ALL__'` 时为 NULL；**不可直接 SUM** |
| `broad_gmv_ratio` | double | 宽口径 GMV 归因率（`broad_gmv_usd / broad_advv_gmv`）；CPC 等产品类型固定为 1；`product_type = '__ALL__'` 时为 NULL；**不可直接 SUM** |

### 指标：目标 CIR

| 字段 | 类型 | 说明 |
|---|---|---|
| `target_cir` | double | 广告主目标 CIR（Cost-Income Ratio）加权均值，计算方式为 `sum(target_cir) / count(target_cir)`；**不可直接 SUM** |

### 指标：出价与扣费价格

| 字段 | 类型 | 说明 |
|---|---|---|
| `sum_bid_price_usd` | double | 出价总金额（USD），用于计算均值 |
| `cnt_bid_price` | double | 有效出价计数，用于计算均值 |
| `avg_bid_price_usd` | double | 平均出价（USD），计算方式为 `sum_bid_price_usd / cnt_bid_price`；**不可直接 SUM** |
| `sum_deduction_price_usd` | double | 扣费总金额（USD），用于计算均值 |
| `cnt_deduction_price` | double | 有效扣费计数，用于计算均值 |
| `avg_deduction_price_usd` | double | 平均扣费（USD），计算方式为 `sum_deduction_price_usd / cnt_deduction_price`；**不可直接 SUM** |
| `deduction_bid_ratio` | double | 扣费出价比，计算方式为 `avg_deduction_price_usd / avg_bid_price_usd`；**不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则全表扫描；该字段为分区键之一。
- **`local_date`**：必须指定，否则全表扫描；该字段为分区键之一。
- **`outlier`**：通常需要明确指定。使用原始数据取 `outlier = '1'`；使用去极值数据取 `outlier = '0.999'`。混用两个分区会导致指标重复计算。
- **`domain`**：明确指定 `'Search'` 或 `'RCMD'`，避免跨域混聚。

### 不可直接 SUM 的字段

以下字段为比率、均值或预聚合派生值，**不能直接对多行求 SUM**，需回溯分子分母重新计算：

| 字段 | 原因 |
|---|---|
| `direct_cost_ratio` | 比率，需用 `SUM(revenue_usd) / SUM(direct_advv_cost)` 重算 |
| `broad_cost_ratio` | 比率，需用 `SUM(revenue_usd) / SUM(broad_advv_cost)` 重算 |
| `direct_gmv_ratio` | 比率，需用 `SUM(ads_gmv_usd) / SUM(direct_advv_gmv)` 重算 |
| `broad_gmv_ratio` | 比率，需用 `SUM(broad_gmv_usd) / SUM(broad_advv_gmv)` 重算 |
| `avg_bid_price_usd` | 均值，需用 `SUM(sum_bid_price_usd) / SUM(cnt_bid_price)` 重算 |
| `avg_deduction_price_usd` | 均值，需用 `SUM(sum_deduction_price_usd) / SUM(cnt_deduction_price)` 重算 |
| `deduction_bid_ratio` | 二阶派生比率，需先重算两个均值再取比 |
| `target_cir` | 加权均值，ETL 中以 `SUM(target_cir) / COUNT(target_cir)` 聚合，不可直接 SUM |

### 极值处理说明

- `outlier = '1'`：原始全量数据，不做任何极值过滤；
- `outlier = '0.999'`：基于各 `feature_group` 在当日的 99.9% 分位 ABS（平均订单金额）阈值，过滤掉超出阈值的用户后再聚合；宽口径指标（`broad_*`）和直接口径指标（`direct_*`）使用各自独立的阈值。

### 时效性说明

- 本表为 **T+1 日更新**，数据代表前一自然日（本地时区）的汇总快照；
- 每次写入使用 `INSERT OVERWRITE`，同一分区（`grass_region` + `local_date` + `domain` + `outlier`）每日全量覆盖。

### 其他注意事项

- `product_type = '__ALL__'` 时，`direct_gmv_ratio` 和 `broad_gmv_ratio` 字段值为 NULL，查询时需注意 NULL 处理；
- `feature_group = '__ALL__'` 表示全量特征组汇总，与具体特征组数据存在包含关系，交叉聚合时需注意重复计数；
- `voucher_type = '__ALL__'` 同上，表示全量优惠券类型汇总；
- ETL 中用户通过 `is_search_whitelist` / `is_rcmd_whitelist` 白名单过滤，仅统计进入实验白名单的用户。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取实验用户与实验分组（exp_group_id）映射，分别按 Search / RCMD 白名单过滤 |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 广告请求级别的 ADVV 基准指标明细，包含花费、GMV、出价扣费、ADVV 各口径数据，通过 lateral view explode 展开 feature_group / product_type / voucher_type |
| `srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d` | 各 feature_group 的极值阈值（99.9% 分位 ABS），分别用于宽口径（`broad_ads_abs`）和直接口径（`direct_ads_abs`）的极值判断 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group
        │
        ▼
user_exp（Search + RCMD 白名单用户及实验组映射）
                                                    ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d
                                                         │
                                          ┌──────────────┴──────────────┐
                                          ▼                             ▼
dws_sr_data_warehouse_ads_request_benchmark_advv_1d   ads_outlier_broad   ads_outlier_direct
        │                                                  （broad 99.9% 阈值） （direct 99.9% 阈值）
        ▼
dws_advv_request_raw（展开 feature_group/product_type/voucher_type，request 级聚合）
        │
        ▼
dws_advv_abs（计算每用户×feature_group 的直接/宽口径 ABS，用于极值判断）
        │
        ▼
dws_advv_request（关联 ABS 和极值阈值，输出原始及 _999 去极值双套指标，user 级聚合）
        │
        ▼
ads_exp（关联实验用户分组，按 exp_group_id × feature_group × product_type × voucher_type × domain 聚合，计算比率类指标）
        │
        ▼
INSERT OVERWRITE（UNION ALL 写入 outlier='1' 原始 + outlier='0.999' 去极值两个分区）
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `user_exp` | 从实验用户分组维表中，分别按 Search 白名单和 RCMD 白名单过滤用户，UNION ALL 合并，得到 `(user_id, exp_group_id, domain)` 映射 |
| Step 2 | `ads_outlier_broad` | 从极值阈值表中取 `outlier_type = 'broad_ads_abs'` 且 `percentile = 0.999` 的记录，按 feature_group 取最大 abs，作为宽口径极值上限 |
| Step 3 | `ads_outlier_direct` | 同上，取 `outlier_type = 'direct_ads_abs'`，作为直接口径极值上限 |
| Step 4 | `dws_advv_request_raw` | 读取广告请求基准宽表，通过 `lateral view explode` 展开三个数组维度（feature_group / product_type / voucher_type），按 `(user_id, feature_group, product_type, voucher_type, ads_id, item_id, campaign_id, request_id)` 聚合，输出请求级汇总指标 |
| Step 5 | `dws_advv_abs` | 基于 Step 4 结果，在 `product_type = '__ALL__'` 且 `voucher_type = '__ALL__'` 条件下，计算每个用户×feature_group 的直接口径 ABS（`ads_gmv_usd / ads_order_cnt`）和宽口径 ABS（`broad_gmv_usd / ads_broad_order_cnt`） |
| Step 6 | `dws_advv_request` | 将 Step 4 与 Step 5 的用户 ABS 关联，再与 Step 2/3 的极值阈值关联，输出原始指标与 `_999` 后缀的去极值指标（通过 `IF(abs <= 阈值, 指标, null)` 实现），按用户×维度聚合 |
| Step 7 | `ads_exp`（CACHE TABLE） | 将 Step 6 结果与 Step 1 的实验分组关联（`user_id` 匹配），按 `(exp_group_id, feature_group, product_type, voucher_type, domain)` 聚合，计算所有比率类指标（ROI、GMV 归因率、均值价格、扣费出价比等），同时产出 `_999` 版本；结果缓存以支持后续两次 SELECT |
| Step 8 | INSERT OVERWRITE | 从 `ads_exp` UNION ALL 取两组数据：原始指标（`outlier = '1'`）和去极值指标（`outlier = '0.999'`），写入目标表分区，`REPARTITION(8)` 控制输出文件数 |

### 注意事项

- **单 Writer 写入**：本表仅有 1 个 ETL 文件写入，无多文件并发写入风险。
- **INSERT OVERWRITE 覆盖写**：每次执行按 `(grass_region, local_date, domain, outlier)` 分区覆盖，重跑当日任务是安全的。
- **CACHE TABLE**：Step 7 使用 `CACHE TABLE` 缓存中间结果，两次 UNION ALL SELECT 共享同一份计算结果，避免重复计算；需确保 Spark Session 内存充足。
- **`feature_group = '__ALL__'` 映射**：上游阈值表中 `feature_group = 'all'` 会被转换为 `'__ALL__'`，与业务维度值保持对齐。
- **`product_type` 产品特殊逻辑**：`manual_cpc`、`manual_ecpc`、`itemboost`、`new_product_boost`、`video_max_view` 等 CPC 类产品，`direct_gmv_ratio` 和 `broad_gmv_ratio` 的分子分母相同，固定为 1，需注意此类产品的比率字段无归因分析意义。
- **极值阈值 Broadcast Join**：Step 6 使用 `/*+ BROADCAST(c,d) */` 提示广播极值阈值小表，提升 Join 性能。
- **用户过滤**：上游 `dws_advv_request_raw` 中过滤 `user_id > 0`，排除匿名或无效用户。

---

*文档生成时间：2026-05-17*