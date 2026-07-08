<!-- ads-workspace-gdoc-sync: gdoc_id=1C2A87TNmkjwqZNagTYoOaQ2w6549UNTN8FyYfrMxGBQ gdoc_url=https://docs.google.com/document/d/1C2A87TNmkjwqZNagTYoOaQ2w6549UNTN8FyYfrMxGBQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_core_metrics_v2_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** `grass_region` + `local_date` + `experiment_id` + `exp_group_id` + `feature_type` + `sort_type` + `is_ads` + `target_type`
**分区：** `grass_region`（大区），`local_date`（日期）
**更新频率：** 每日（T+1）全量覆盖写入（INSERT OVERWRITE）
**引用频次/访问频次：** 2843

---

## 业务描述

本表是搜索域 A/B 实验（ABTest）核心指标的日粒度汇总宽表，服务于搜索业务线的实验效果评估与多维度指标对比分析。表中数据按实验组（`experiment_id` + `exp_group_id`）、功能场景（`feature_type`）、排序类型（`sort_type`）、广告标记（`is_ads`）、目标类型（`target_type`）进行多维度聚合，覆盖以下三类核心业务场景：

1. **搜索结果页（search_result）**：覆盖 SRP 页面的曝光、点击、加购、下单、GMV 等核心电商指标，以及广告相关 ROI 指标（revenue、ads GMV、broad GMV）、搜索词维度的搜索量/成功率指标、以及 ABS（平均篮子大小）分位数截尾指标。
2. **搜索引导页（search_guide）**：覆盖搜索引导场景下的曝光、点击、浏览指标以及关键词类目多样性指标（人均三级类目数）。
3. **平台全域（platform_wide）**：覆盖实验组用户在全平台维度的 Omni 曝光、点击、下单、GMV 等指标，以及 UDF（用户定义漏斗）口径的平台 DAU、订单数、GMV、买家数。

**适合回答的问题举例：**
- 某实验组相比对照组，搜索结果页的 CTR、CVR、GMV 是否有显著提升？
- 广告（Paid Ads）实验组的 Revenue、Ads GMV 及截尾后（999 分位）的变化情况如何？
- 搜索引导实验的曝光类目多样性（人均 L3 类目数）表现如何？
- 实验组用户在全平台的购买行为（platform_wide）是否受搜索实验影响？
- 特定排序方式（`sort_type`）或广告/自然流量（`is_ads`）下的实验效果对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，例如 `SG`、`MY`、`TH` 等；分区键，查询时必须指定 |
| `local_date` | date | 数据日期（本地日期）；分区键，查询时必须指定 |

---

### 维度：实验分组维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来自实验维度表 `dim_sr_data_warehouse_abtest_group` |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验组 ID（对照组/实验组） |
| `exp_group_name` | string | 实验组名称 |

---

### 维度：功能与流量分层维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_type` | string | 功能场景类型，固定取值：`search_result`（搜索结果页）、`search_guide`（搜索引导页）、`platform_wide`（平台全域）；不同取值下部分指标字段为 NULL |
| `sort_type` | string | 排序类型（如默认排序、价格排序等）；`__ALL__` 表示全量汇总；`search_guide` 和 `platform_wide` 场景固定为 `__ALL__` |
| `is_ads` | string | 是否为广告流量：`true`（广告）、`false`（自然流量）、`__ALL__`（全量汇总） |
| `target_type` | string | 目标类型，标识页面内容类型，如 `item`、`video`、`livestream`、`item+video+live`（聚合类型）、`buy_together_card` 等；`search_guide` 场景下为具体引导 feature 标识；`__ALL__` 表示全量汇总 |

---

### 指标：实验组规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_uu` | bigint | 实验组内的总去重用户数（UV），基于用户级分流表统计 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（PV）；`search_result` 为 SRP 曝光，`platform_wide` 为 Omni 口径曝光 |
| `imp_uu` | bigint | 有曝光行为的去重用户数（UV）；`search_result` 场景有值，`platform_wide` 为 NULL |
| `click_cnt` | bigint | 点击次数；`platform_wide` 为 Omni 口径点击 |
| `click_uu` | bigint | 有点击行为的去重用户数；`search_result` 和 `search_guide` 场景有值 |
| `view_cnt` | bigint | 搜索页面浏览次数；`search_result` 场景仅在 `is_ads='__ALL__'` 且 `target_type='__ALL__'` 时有值；`search_guide` 场景有值 |
| `view_uu` | bigint | 有浏览行为的去重用户数；含义同 `view_cnt` |
| `view_not_back_cnt` | bigint | 搜索后未返回（即深度浏览）的次数；仅 `search_result` 且 `is_ads='__ALL__'`、`target_type='__ALL__'` 时有值 |
| `ppv_cnt` | bigint | 商品详情页浏览（PPV）次数 |
| `ppv_uu` | bigint | 有 PPV 行为的去重用户数 |

---

### 指标：搜索场景专项曝光

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_scene_imp_cnt` | bigint | 搜索全场景（含 global_search、search_in_pdp 等）下的曝光总量；仅 `search_result` 场景有值 |
| `search_scene_top20_imp_cnt` | bigint | 搜索全场景中位置前 20（location < 20）的曝光量；仅 `search_result` 场景有值 |

---

### 指标：加购与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数；仅 `search_result` 场景有值 |
| `cart_uu` | bigint | 有加购行为的去重用户数；仅 `search_result` 场景有值 |
| `order_cnt` | double | 下单量（含小数，因聚合方式为 SUM(order_cnt)）；`search_result` 和 `platform_wide` 场景有值 |
| `order_uu` | double | 有下单行为的去重用户数；仅 `search_result` 场景有值 |
| `algo_order_cnt` | double | 算法口径订单数，当前版本固定为 NULL（预留字段） |
| `squared_user_order_sum` | double | 用户下单量的平方和（∑ order_cnt²），用于 Delta 方法方差估计，**不可直接 SUM 使用**；仅 `search_result` 场景有值 |

---

### 指标：GMV 与收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 搜索场景 GMV（本地货币）；`search_result` 和 `platform_wide` 场景有值 |
| `pc2_gmv` | double | P+C2（含二次确认）口径 GMV；仅 `search_result` 场景有值 |

---

### 指标：ABS 截尾后的搜索结果页核心指标（995 分位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_search_abs_995` | double | 全局搜索 ABS（平均篮子大小）的 99.5% 分位数阈值，用于识别截尾边界；**不可直接 SUM**；仅 `search_result` 场景有值 |
| `imp_uu_995` | bigint | ABS ≤ 995 分位的有曝光去重用户数；仅 `search_result` 场景有值 |
| `imp_cnt_995` | bigint | ABS ≤ 995 分位用户的曝光总量；仅 `search_result` 场景有值 |
| `order_cnt_995` | double | ABS ≤ 995 分位用户的下单量；仅 `search_result` 场景有值 |
| `gmv_995` | double | ABS ≤ 995 分位用户的 GMV；仅 `search_result` 场景有值 |
| `pc2_gmv_995` | double | ABS ≤ 995 分位用户的 P+C2 口径 GMV；仅 `search_result` 场景有值 |

---

### 指标：广告效果（Paid Ads）

| 字段 | 类型 | 说明 |
|---|---|---|
| `paidads_item_imp_cnt` | bigint | 付费广告商品曝光次数（含义对应 ETL 中 `paidads_imp_cnt`）；仅 `search_result` 且 `is_ads IN ('true','__ALL__')` 时有值 |
| `paidads_top20_item_imp_cnt` | bigint | 付费广告位置前 20 的商品曝光次数（对应 ETL 中 `paidads_top20_imp_cnt`）；含义同上 |
| `revenue_usd` | double | 广告收入（USD）；仅 `search_result` 场景有值 |
| `revenue_usd_999` | double | 广告收入（USD），经 999 分位 ABS 截尾后的口径；仅 `search_result` 场景有值 |
| `ads_gmv_usd` | double | 直接广告 GMV（USD，Direct Ads GMV）；仅 `search_result` 场景有值 |
| `ads_gmv_usd_999` | double | 直接广告 GMV（USD），经 999 分位 ABS 截尾后的口径；仅 `search_result` 场景有值 |
| `broad_gmv_usd` | double | 广泛匹配广告 GMV（USD，Broad Ads GMV）；仅 `search_result` 场景有值 |
| `broad_gmv_usd_999` | double | 广泛匹配广告 GMV（USD），经 999 分位 ABS 截尾后的口径；仅 `search_result` 场景有值 |

---

### 指标：搜索词维度指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_volume` | bigint | 搜索次数（基于 device_id + keyword 去重）；`search_result` 和 `search_guide` 场景有值 |
| `search_success_result_volume` | bigint | 有商品结果的搜索次数（有 PPV 且 target_type='item' 且非 page_section）；同上 |
| `search_non_result_volume` | bigint | 无结果搜索次数（触发 no_recall_general）；同上 |
| `direct_search_success_volume` | bigint | 有直接点击（item/video/livestream）的搜索次数；同上 |
| `broad_search_success_volume` | bigint | 有广泛点击（含 shop、creator 等）的搜索次数；同上 |

---

### 指标：搜索引导类目多样性

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_l3_cat_per_uu` | double | 搜索引导场景下，每个有效曝光用户平均覆盖的三级关键词类目数（L3 Category）；**不可直接 SUM**；仅 `search_guide` 场景有值 |
| `clk_l3_cat_per_uu` | double | 搜索引导场景下，每个有效点击用户平均覆盖的三级关键词类目数；**不可直接 SUM**；仅 `search_guide` 场景有值 |

---

### 指标：平台全域 UDF 口径指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_dau_udf` | bigint | UDF（用户定义漏斗）口径的平台日活用户数（DAU）；仅 `platform_wide` 场景有值 |
| `platform_order_cnt_udf` | double | UDF 口径的平台订单数；仅 `platform_wide` 场景有值 |
| `platform_gmv_udf` | double | UDF 口径的平台 GMV；仅 `platform_wide` 场景有值 |
| `platform_buyer_udf` | bigint | UDF 口径的平台买家数（有订单用户去重数）；仅 `platform_wide` 场景有值 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段必须同时指定**，避免全表扫描：
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2025-05-16'
   ```
2. **`feature_type` 通常需要指定**，不同场景下大量字段为 NULL，混合 feature_type 聚合会产生误导性结果：
   ```sql
   AND feature_type = 'search_result'  -- 或 'search_guide' / 'platform_wide'
   ```
3. **维度组合注意**：`sort_type`、`is_ads`、`target_type` 均存在 `__ALL__` 汇总行，避免与具体维度值行重复计算，查询前须明确所需粒度。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `global_search_abs_995` | 分位数阈值，为标量参考值，不可求和 |
| `imp_l3_cat_per_uu` | 预聚合均值（SUM(l3_cnt) / COUNT(uu)），跨组 SUM 无意义 |
| `clk_l3_cat_per_uu` | 同上 |
| `squared_user_order_sum` | 用户订单量平方和，用于方差估计（Delta 方法），业务含义不适合直接 SUM 后用于其他计算 |
| `exp_group_uu` | 去重用户数，跨实验组不可加总 |
| `imp_uu`、`click_uu`、`order_uu` 等 `_uu` 类字段 | 去重 UV 计数，不同维度切分后不可直接相加 |
| `imp_uu_995`、`order_cnt_995` 等 `_995` 截尾系列字段 | 截尾口径预聚合结果，需对应使用截尾基准值 |
| `platform_dau_udf`、`platform_buyer_udf` | 去重用户数，跨组不可汇总 |

### 时效性说明

- 本表为 **日粒度（`_1d`）** 离线表，数据通常在 T+1 凌晨完成计算并写入，当日数据不可用。
- 无历史累计（`_td`）或滑动窗口（`_nd`）语义，每个分区为当日独立快照，**跨日趋势分析需自行按 `local_date` 聚合**。

### 其他注意事项

- `feature_type = 'search_result'` 的广告指标（`revenue_usd`、`ads_gmv_usd`、`broad_gmv_usd` 等）**仅在 `is_ads IN ('true', '__ALL__')` 时有业务意义**，`is_ads = 'false'` 行此类字段为 NULL。
- `view_cnt`、`view_not_back_cnt`、`view_uu` 在 `search_result` 场景中**仅当 `is_ads = '__ALL__'` 且 `target_type = '__ALL__'` 时填值**，其他维度组合为 NULL。
- `paidads_item_imp_cnt` 与 `paidads_top20_item_imp_cnt` 对应 ETL 中的 `paidads_imp_cnt` / `paidads_top20_imp_cnt`，字段命名与 DataMap 一致，注意区分。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验维度信息（scene、layer、experiment、group 映射），仅取搜索白名单实验 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户与实验组的分流映射，仅取命中 assignment log 且在搜索白名单的记录 |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词到三级类目（L3 Category）的映射维度表 |
| `srdi_mart.dws_sr_data_warehouse_search_guide_user_benchmark_1d` | 搜索引导场景下用户级别的曝光、点击、浏览行为基准数据 |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 搜索结果页（SRP）及平台全域用户-商品-关键词级别的行为基准数据，是最核心的上游宽表 |
| `srdi_mart.dws_sr_data_warehouse_search_srp_other_feature_metrics_1d` | 非标准 SRP Feature（如 Other features）的用户级别指标 |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 广告请求级别的 Revenue、Ads GMV、Broad GMV 等 ROI 指标 |
| `srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d` | 广告 ABS 异常值（999 分位）参考基准，用于 ROI 指标截尾处理 |
| `srdi_mart.dim_sr_data_warehouse_search_user_udf` | UDF 口径的平台活跃用户集合，用于 platform_wide UDF 指标计算 |
| `mp_foa.dim_search_domain_map__reg_live` | 搜索域页面类型映射，过滤非搜索场景（排除 shop_browsing 等） |

---

## ETL 逻辑摘要

### 数据流

```
dim_abtest_group + dim_abtest_user_group
         │
         ├──► 实验组维度 + 用户分流映射
         │
dws_platform_user_item_keyword_benchmark_1d (核心宽表)
         │
         ├──► [search_result] SRP 用户行为聚合 (srp_cube)
         │         └── JOIN 用户分流 → srp_exp (实验组级别 SRP 指标)
         │
         ├──► [search_scene] 全搜索场景曝光/搜索量统计
         │         └── → search_scene_cube, exp_search_volumn
         │
         ├──► [platform_wide] 全平台 Omni 指标
         │         └── JOIN 用户分流 → dws_platform_exp_metric
         │
dws_search_srp_other_feature_metrics_1d
         └──► Other Feature 指标 → 合并入 srp_cube
         
dws_search_guide_user_benchmark_1d + dim_keyword_l3
         └──► [search_guide] 引导页曝光/点击/L3类目多样性
                   └── JOIN 用户分流 → guide_exp

dws_ads_request_benchmark_advv_1d + ads_outlier
         └──► [ads] 广告 ROI 指标 (经 ABS 截尾) → exp_ads_performance

dim_search_user_udf + platform_user_metric
         └──► [platform_wide UDF] DAU/GMV/Buyer UDF 口径指标

── INSERT OVERWRITE ──────────────────────────────────────
三路 UNION ALL → dws_sr_data_warehouse_search_abtest_core_metrics_v2_1d
  Branch 1: feature_type = 'search_result'
  Branch 2: feature_type = 'search_guide'
  Branch 3: feature_type = 'platform_wide'
```

### 关键步骤

| 步骤序号 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `dim_exp` | 从实验维度表拉取当日搜索白名单实验组信息（scene/layer/experiment/group） |
| 2 | `user_exp_mapping` | 从用户分流表拉取当日实验命中用户（is_assignment_log=1，搜索白名单） |
| 3 | `dim_keyword_l3` | 关键词→L3类目映射，用于 search_guide 多样性计算 |
| 4 | `search_guide_raw` → `hot_kw` → `search_guide_raw_salted` → `dim_keyword_l3_salted` | 热词加盐处理，解决关键词 JOIN 数据倾斜问题（基于 xxhash64 + posexplode 64份） |
| 5 | `search_guide` → `search_guide_with_keyword_l3` → `guide_exp` | 计算 search_guide 场景下实验组的曝光/点击及 L3 类目多样性指标 |
| 6 | `dim_search_domain` | 过滤合法搜索场景页面类型（排除 shop_browsing 等） |
| 7 | `exp_uu` | 计算各实验组的总用户数 |
| 8 | `dws_search_srp` | 从核心宽表提取 SRP 用户-关键词级行为数据（global_search 业务线） |
| 9 | `dws_search_srp_other` | 提取 Other Feature 的 SRP 指标 |
| 10 | `search_srp_benchmark` → `search_abs` → `global_search_abs995_benchmark` | 计算全局 ABS（GMV/order_cnt）并取 99.5% 分位数，CACHE 为后续截尾阈值 |
| 11 | `srp_cube` (CACHE) | 对 SRP 数据按 GROUPING SETS (sort_type × is_ads × target_type) 多维聚合，包含三段 UNION ALL（标准 target_type、buy_together_card 聚合、other feature） |
| 12 | `srp_exp` | SRP 多维聚合结果 JOIN 用户分流，计算实验组级别指标，含 ABS 995 截尾指标 |
| 13 | `srp_all_search_scene` → `search_scene_cube` | 全搜索域曝光（JOIN dim_search_domain 过滤），计算实验组级搜索场景曝光量及 Top20 曝光量 |
| 14 | `search_view` → `exp_search_view` | 计算 global_search 系列页面的浏览数/未返回数/浏览 UU |
| 15 | `search_volume` → `exp_search_volumn` | 基于 device_id+keyword 去重，计算搜索量、成功搜索量、无结果量、直接/广泛成功搜索量 |
| 16 | `platform_user_metric` → `dws_platform_exp_metric` | 全平台 Omni 口径指标（is_direct=TRUE），按实验组聚合 |
| 17 | `active_user_experiment_group_mapping` → `dwm_sr_data_warehouse_platform_user` → `dwm_search_user_exp_platform_udf` | UDF 口径平台指标：以 UDF 活跃用户集合为基础，计算 DAU/订单/GMV/买家数 |
| 18 | `ads_outlier` | 读取广告 ABS 异常值（999 分位），用于 ROI 指标截尾 |
| 19 | `dwd_ads` → `ads_performance` → `exp_ads_performance` | 广告 ROI 指标（revenue/ads_gmv/broad_gmv）聚合及 999 分位截尾，按实验组汇总 |
| 20 | **INSERT OVERWRITE** | 三路 UNION ALL 写入目标表分区：Branch1（search_result）、Branch2（search_guide）、Branch3（platform_wide） |

### 注意事项

1. **单 Writer，无 multi-writer 风险**：本表仅有 1 个 ETL 文件写入，不存在多文件并发写入同一分区的问题。
2. **CACHE TABLE 使用**：`srp_cube` 和 `global_search_abs995_benchmark` 使用了 `CACHE TABLE`，在 Spark Session 生命周期内缓存，需注意大数据量时内存压力。
3. **热词倾斜处理**：search_guide 的 keyword JOIN 采用了 xxhash64 加盐（64 份）+ posexplode 展开的技巧处理数据倾斜，`dim_keyword_l3_salted` 需与 `search_guide_raw_salted` 的 salt 值精确匹配。
4. **多维 GROUPING SETS 导致行数膨胀**：`srp_cube`、`search_scene_cube`、`ads_performance` 等中间视图均使用 GROUPING SETS/CUBE，会产生包含 `__ALL__` 的汇总行，写入目标表时应注意避免重复聚合。
5. **`feature_type` 决定字段填充规则**：三类 feature_type 的字段填充模式不同，大量字段存在 NULL，下游使用时必须按 `feature_type` 分支处理。
6. **广告指标 JOIN 条件**：`exp_ads_performance` 仅在 `is_ads IN ('true', '__ALL__')` 时关联，`is_ads = 'false'` 的行广告指标全为 NULL，符合业务语义。
7. **`search_volume` 等搜索词指标**：同时出现在 search_result 和 search_guide 两个分支中，两个分支引用同一个 `exp_search_volumn` 视图，数据一致，属于冗余填充设计。

---

*文档生成时间：2026-05-17*