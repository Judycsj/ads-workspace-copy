<!-- ads-workspace-gdoc-sync: gdoc_id=146OQV3DG8Kp-tP4KxDZnGcJbm-y-BVy-U5DHJ2x3td0 gdoc_url=https://docs.google.com/document/d/146OQV3DG8Kp-tP4KxDZnGcJbm-y-BVy-U5DHJ2x3td0/edit -->

# mp_paidads.dim_shop_info

**分层：** DIM（维度层）
**主键：** `shop_id`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（T+1）
**引用频次：** 3 次（候选表范围内）

---

## 业务描述

`mp_paidads.dim_shop_info` 是付费广告域的核心店铺维度表，整合了平台店铺基础属性、广告主状态、卖家经营状态、分层分级、广告投放行为等多维信息，为广告分析、卖家运营及商业智能报表提供统一的店铺视角宽表。

该表广泛应用于付费广告效果分析（按卖家类型/分级拆解广告消耗与 ROI）、卖家激活与流失监测（通过 `seller_status` / `advertiser_status` 追踪卖家生命周期状态）、KA 管理（通过 `key_seller_90` / `key_seller_95` 识别头部卖家）以及跨境/本土卖家分层运营。

各地区通过参数化调度（`${region}`、`${grass_date}`）生成各自分区数据，实现全球多市场统一管理。tz_type 固定写入 `local` 分区，确保各地区数据均按本地时区口径计算。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区键。当前 ETL 仅写入 `'local'`，即各地区本地时区口径。查询时必须指定 `tz_type = 'local'`，否则触发全分区扫描。 |
| `grass_region` | string | 地区分区键，如 `'MY'`、`'TH'`、`'VN'` 等，大写形式存储。查询时必须指定目标地区。 |
| `grass_date` | date | 数据日期分区键（格式 `YYYY-MM-DD`）。每日更新，查询时必须指定。 |

---

### 维度：主键与店铺基础信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 店铺唯一标识符，本表主键。可跨表关联其他事实表与维度表。 |
| `user_id` | bigint | 店铺所属用户 ID，来源于 `mp_user.dim_shop__reg_s0_live`。 |
| `seller_name` | string | 店铺名称（即 `shop_name`），来源于 `mp_user.dim_shop__reg_s0_live`。 |
| `account_create_datetime` | string | 广告主账户创建时间，格式为 `'YYYY-MM-DD HH:MM:SS'`，表示店铺在广告系统中的注册时间。来源于 `mp_paidads.dim_advertiser__reg_s0_live`。⚠️ 该字段为 string 类型存储，时间比较或计算需先做类型转换。 |

---

### 维度：店铺类型与卖家属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_type` | string | 卖家类型，按优先级派生：`Official Store`（官方店） > `Cross Border`（跨境） > `Managed Seller`（托管卖家） > `Preferred Seller`（优选卖家） > `Preferred Plus Seller`（优选Plus卖家） > `Others`（其他）。⚠️ 为派生枚举字段，优先级固定，不可直接用于加法聚合。 |
| `seller_type_1p` | string | 针对 CB 店铺的 1P 卖家类型分类，枚举值：`Lovito`、`SCS`、`Local SCS`、`Others`、`Unknown`。来源于 `mp_cb.dim_shop__reg_live`、`mp_cb.dim_shop_ext__reg_live` 及 `mp_paidads.dim_local_scs_shop_list`。非 CB 店铺默认为 `Unknown`。 |
| `cb_seller_type` | string | 跨境卖家细分类型，来源于 `mp_cb.dim_shop_ext__reg_live` 的 `seller_type` 字段，如 `CNCB` 等。非跨境卖家为 NULL。 |
| `is_official_shop` | tinyint | 是否官方店铺，1 表示官方店，0 表示非官方店。 |
| `is_preferred_shop` | tinyint | 是否优选店铺（Preferred Shop），1 表示是，0 表示否。 |
| `is_managed_seller` | tinyint | 是否托管卖家（Managed Seller），1 表示是，0 表示否。 |
| `is_cb_seller` | tinyint | 是否跨境卖家，1 表示跨境，0 表示本土。 |
| `is_principal` | tinyint | 是否主营店铺（principal shop）。当前 ETL 中固定写入 `1`，即参与广告分析的店铺均标记为主营。⚠️ 该字段当前为常量 1，不可用于筛选区分不同类型店铺。 |
| `principal_type` | string | 主营类型，派生逻辑：若为跨境卖家且 `principal_type` 为 NULL 则填 `'Cross Border'`，否则取 `regma_general.shop_attributes` 中的原始值，仍为 NULL 时默认 `'Local Brand'`。 |
| `is_cb_sip_affiliated` | tinyint | 是否关联跨境 SIP（Strategic Important Partners），来源于 `mp_seller.dim_shop_ext__reg_s0_live`。 |
| `is_local_sip_affiliated` | tinyint | 是否关联本土 SIP，来源于 `mp_seller.dim_shop_ext__reg_s0_live`。 |
| `is_sip_primary` | tinyint | 是否为 SIP 主店铺，来源于 `mp_seller.dim_shop_ext__reg_s0_live`。 |

---

### 维度：店铺品类与聚类

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_level1_global_be_category` | string | 店铺一级全球后端品类（Global BE Category），如 `Mobile & Gadgets`、`Beauty` 等。来源于 `mp_item.dws_shop_listing_td__reg_s0_live`，取 `first()` 值。 |
| `shop_level2_global_be_category` | string | 店铺二级全球后端品类，提供比一级品类更细粒度的商品分类描述。来源同上。 |
| `shop_level1_fe_display_category_id` | bigint | 店铺一级前端展示品类 ID，用于前端页面分类展示。来源同上，若无记录则填充 `0`。⚠️ 默认值为 0 而非 NULL，过滤"有品类"时需排除 `shop_level1_fe_display_category_id = 0`。 |
| `cluster` | string | 品类大类聚合标签，由 `shop_level1_global_be_category` 派生：`EL`（电子）、`Fashion`（时尚）、`FMCG`（快消）、`Lifestyle`（生活方式）。不在映射范围内的品类为 NULL。⚠️ 为派生字段，NULL 表示品类未被任一 cluster 覆盖，过滤时需注意 NULL 值处理。 |

---

### 维度：卖家与广告主状态

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_status` | string | 卖家当月经营状态，基于近三个月平台 GMV 变化计算：`new`（新卖家）、`existing`（活跃）、`churn`（本月流失）、`reactivated`（重新激活）、`churned_before`（历史流失）、`others`。无记录时默认 `'churned_before'`。⚠️ 基于月末 GMV 快照计算，时效性受 `grass_date` 影响，应取当月最后一天分区数据以获得完整月度状态。 |
| `advertiser_status` | string | 广告主当月投放状态，基于近三个月广告消耗变化计算：`new`、`existing`、`churn`、`reactivated`、`churned_before`、`never_activated`、`others`。无记录时默认 `'never_activated'`。⚠️ 同 `seller_status`，基于月末消耗快照，应取当月最后一天分区数据。 |
| `seller_tier` | string | 卖家分层，基于当月增量平台 GMV（USD）划分：`large_seller`、`medium_seller`、`small_seller`、`micro_seller`。无记录时默认 `'micro_seller'`。⚠️ 阈值来自 `mp_paidads.dim_seller_tier_threshold__reg_s0_live`，各地区阈值不同，跨地区对比需注意口径差异。 |
| `advertiser_tier` | string | 广告主分层，基于当月增量广告消耗（USD）划分：`large_advertiser`、`medium_advertiser`、`small_advertiser`、`micro_advertiser`。无记录时默认 `'micro_advertiser'`。⚠️ 阈值同上，各地区阈值不同。 |

---

### 维度：广告投放行为

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_placement_type` | string | 卖家广告投放组合类型，基于当日各广告位（搜索/发现/店铺/商品加速/自动加速）是否有活跃广告派生，枚举如 `full_ads`、`search_only`、`search_discovery`、`no_related_ads` 等。无记录时默认 `'no_related_ads'`。⚠️ 为复合派生枚举字段，不可直接聚合，如需拆解各广告位明细请关联 `mp_paidads.ads_advertise_mkt_1d__reg_s0_live`。 |
| `seller_active_ads_placement_type` | array\<string\> | 卖家当日有效投放的广告产品类型列表（含有效消耗且状态为活跃的广告位，取 `product_type` 去重集合）。⚠️ 为 Array 类型，SQL 查询中需使用 `ARRAY_CONTAINS` 或 `LATERAL VIEW EXPLODE` 展开后再过滤，不可直接用等值比较。 |

---

### 维度：关键卖家标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `key_seller_90` | tinyint | 是否为品类头部卖家（Top 10%），基于当日平台 GMV 在同一 `shop_level1_global_be_category` 内排名，百分位 ≥ 90% 则为 1。无记录时默认 `0`。 |
| `key_seller_95` | tinyint | 是否为品类头部卖家（Top 5%），百分位 ≥ 95% 则为 1。无记录时默认 `0`。 |

---

### 指标：卖家平台 GMV

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_platform_gmv_for_tier_usd` | double | 卖家当日平台 GMV（USD），来源于 `mp_order.dws_seller_gmv_1d__reg_s0_live`，用于计算 `key_seller_90` / `key_seller_95` 百分位排名。⚠️ 该字段为当日（1d）GMV，不代表月度累计；月度分层计算（`seller_tier`）使用的是另一路月末 td 数据，两者口径不同，不可混用。 |
| `seller_revenue_for_tier_usd` | double | 卖家当日广告消耗总额（USD），来源于 `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` 的 `ads_expenditure_amt_usd` 汇总，用于参考广告收入规模。⚠️ 为当日消耗，与 `advertiser_tier` 分层所用的月度增量消耗（td 快照差值）口径不同，不可直接用于月度分层还原计算。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区条件，否则将触发全表扫描，造成严重的计算资源浪费和查询超时：

```sql
WHERE tz_type      = 'local'          -- 当前 ETL 仅写入 local 分区，缺失将扫描空分区或产生重复
  AND grass_region = 'MY'             -- 替换为目标地区大写代码，如 TH / VN / PH / SG 等
  AND grass_date   = '2025-01-31'     -- 替换为目标日期
```

- `tz_type`：当前 ETL 固定写入 `'local'`，必须过滤，遗漏时不会返回正确数据。
- `grass_region`：必须使用**大写**地区代码（ETL 以 `upper('${region}')` 写入）。
- `grass_date`：必须指定具体日期，避免跨分区全量扫描。

---

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确处理方式 |
|------|------|-------------|
| `seller_status` / `advertiser_status` | 枚举状态字段，无法直接聚合 | 使用 `COUNT(DISTINCT shop_id)` 配合 `WHERE seller_status = 'xxx'` 统计各状态店铺数 |
| `seller_tier` / `advertiser_tier` | 枚举分层字段，已基于月度阈值预计算 | 不可 SUM；如需还原月度消耗/GMV，需回溯 `dws_seller_gmv_td__reg_s0_live` 或 `dws_advertiser_placement_performance_td__reg_s0_live` 原始数据 |
| `ads_placement_type` | 多条件组合派生枚举 | 不可 SUM；如需分析各广告位明细，需关联 `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` |
| `seller_active_ads_placement_type` | Array 类型 | 不可直接等值比较或 SUM；需使用 `ARRAY_CONTAINS(seller_active_ads_placement_type, 'xxx')` 或 `LATERAL VIEW EXPLODE` 展开 |
| `key_seller_90` / `key_seller_95` | 基于品类内百分位的 0/1 标记 | 可 SUM 统计头部卖家数，但**不可跨品类直接 SUM 后再算比例**，需按 `shop_level1_global_be_category` 分组 |
| `seller_platform_gmv_for_tier_usd` | 当日 1d GMV，非月度累计 | 如需月度 GMV 请使用 `mp_order.dws_seller_gmv_td__reg_s0_live` 的月末快照 |
| `seller_revenue_for_tier_usd` | 当日广告消耗，非月度增量 | 如需月度广告消耗分层依据，请使用 `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` |
| `shop_level1_fe_display_category_id` | 无品类时填充为 `0`（非 NULL） | 过滤"有品类"的店铺时应使用 `WHERE shop_level1_fe_display_category_id != 0` |

---

### 时效性说明

- **`seller_status` / `advertiser_status` / `seller_tier` / `advertiser_tier`**：这四个字段基于"上月末 td 快照"与"上上月末 td 快照"的差值计算，反映的是**上月**的经营/投放状态与分层。因此：
  - 若 `grass_date` = 当月某日（非月末），上述字段仍基于**上月末**数据，数值不会随日内变化而更新。
  - 建议取**当月最后一天**分区获取最新月度状态；若需实时日粒度分析，应直接查询 `dws_seller_gmv_td__reg_s0_live` 和 `dws_advertiser_placement_performance_td__reg_s0_live`。
- **`seller_platform_gmv_for_tier_usd` / `key_seller_90` / `key_seller_95`**：基于当日（`grass_date`）1d GMV 计算，与分区日期对应，无月度滞后问题。
- **`ads_placement_type` / `seller_active_ads_placement_type` / `seller_revenue_for_tier_usd`**：基于当日广告数据，与分区日期对应。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_user.dim_shop__reg_s0_live` | 店铺基础信息（名称、跨境/官方/优选/托管标记、user_id） |
| `mp_item.dws_shop_listing_td__reg_s0_live` | 店铺一级/二级品类及前端展示品类 ID |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主账户创建时间 |
| `mp_paidads.dim_advertiser_tier_threshold__reg_s0_live` | 广告主分层阈值（各地区 large/medium/small 消耗门槛） |
| `mp_paidads.dim_seller_tier_threshold__reg_s0_live` | 卖家分层阈值（各地区 large/medium/small GMV 门槛） |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 当日广告投放明细（广告位类型、消耗、活跃状态） |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` | 近三个月各月末广告消耗 td 快照（用于计算 advertiser_status/tier） |
| `mp_order.dws_seller_gmv_td__reg_s0_live` | 近三个月各月末平台 GMV td 快照（用于计算 seller_status/tier） |
| `mp_order.dws_seller_gmv_1d__reg_s0_live` | 当日平台 GMV（用于品类内 GMV 百分位排名） |
| `mp_seller.dim_shop_ext__reg_s0_live` | 店铺 SIP 关联信息（is_cb_sip_affiliated / is_local_sip_affiliated / is_sip_primary） |
| `regma_general.shop_attributes` | 店铺主营类型（principal_type） |
| `mp_cb.dim_shop__reg_live` | CB 店铺基础信息（用于 seller_type_1p 派生） |
| `mp_cb.dim_shop_ext__reg_live` | CB 店铺扩展信息（cb_seller_type / seller_type_1p 派生） |
| `mp_paidads.dim_local_scs_shop_list` | 本地 SCS 店铺白名单（用于 seller_type_1p = 'Local SCS' 判断） |

---

## ETL 逻辑摘要

### 数据流

```
mp_user.dim_shop__reg_s0_live          ──────────────────────────┐
mp_item.dws_shop_listing_td__reg_s0_live ──── [shop_listing] ───┤
mp_paidads.dim_advertiser__reg_s0_live  ──── [dim_advertiser] ──┤
regma_general.shop_attributes           ──── [msbenchmark] ─────┤
                                                                  ▼
                                                           [seller_info]
                                                          （店铺基础宽表）
                                                                  │
mp_order.dws_seller_gmv_td__reg_s0_live                          │
  (本月末 / 上月末 / 上上月末)          ──── [seller_status] ───┤
mp_paidads.dim_seller_tier_threshold    ──── [seller_tier_threshold]┤
                                                                  │
mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live  │
  (本月末 / 上月末 / 上上月末)          ──── [advertiser_status]─┤
mp_paidads.dim_advertiser_tier_threshold──── [advertiser_tier_threshold]┤
                                                                  │
mp_paidads.ads_advertise_mkt_1d__reg_s0_live                     │
                                         ──── [seller_ads_placement_type]┤
                                                                  │
mp_order.dws_seller_gmv_1d__reg_s0_live                          │
  + [shop_listing]                       ──── [platform_order] ──┤
                                                                  │
mp_seller.dim_shop_ext__reg_s0_live      ──── [shop_ext] ────────┤
                                                                  │
mp_cb.dim_shop__reg_live                 ──┐                     │
mp_cb.dim_shop_ext__reg_live             ──┤── [seller_1p] ──────┤
mp_paidads.dim_local_scs_shop_list       ──┘                     │
                                                                  ▼
                                          INSERT OVERWRITE
                                    mp_paidads.dim_shop_info__reg_s0_live
                                        (partition: tz_type=local /
                                         grass_region / grass_date)
```

> 调度引擎：Spark SQL（Studio 任务 `data_paidadsmart.studio_4438974`），以 `${region}` / `${grass_date}` 参数化覆盖所有地区，按日调度，写入 Parquet 格式外部表。

---

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `shop` | `mp_user.dim_shop__reg_s0_live` | 提取店铺基础属性（名称、跨境/官方/优选/托管/user_id 标记） |
| `msbenchmark` | `regma_general.shop_attributes` | 提取店铺主营类型 `principal_type` |
| `shop_listing` | `mp_item.dws_shop_listing_td__reg_s0_live` | 提取店铺主品类（一/二级 BE Category 及前端品类 ID），CACHE 提升复用性能 |
| `dim_advertiser` | `mp_paidads.dim_advertiser__reg_s0_live` | 提取广告主账户创建时间 |
| `seller_info` | shop + dim_advertiser + msbenchmark + shop_listing | 整合基础信息，派生 `seller_type`、`cluster`、`principal_type` |
| `advertiser_tier_threshold` | `mp_paidads.dim_advertiser_tier_threshold__reg_s0_live` | 获取广告主分层 USD 门槛值 |
| `seller_tier_threshold` | `mp_paidads.dim_seller_tier_threshold__reg_s0_live` | 获取卖家分层 USD 门槛值 |
| `seller_status` | `mp_order.dws_seller_gmv_td__reg_s0_live`（三个月末快照） + seller_tier_threshold | 基于 GMV 月度变化计算卖家状态与分层 |
| `advertiser_status` | `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live`（三个月末快照） + advertiser_tier_threshold | 基于广告消耗月度变化计算广告主状态与分层 |
| `seller_ads_placement_type` | `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 统计当日各广告位活跃广告数，派生 `ads_placement_type` 组合枚举及 `seller_active_ads_placement_type` 集合 |
| `platform_order` | `mp_order.dws_seller_gmv_1d__reg_s0_live` + shop_listing | 计算品类内 GMV 百分位（key_seller_90 / key_seller_95）及当日平台 GMV |
| `shop_ext` | `mp_seller.dim_shop_ext__reg_s0_live` | 提取店铺 SIP 关联属性 |
| `seller_1p` | `mp_cb.dim_shop__reg_live` + `mp_cb.dim_shop_ext__reg_live` + `mp_paidads.dim_local_scs_shop_list` | 派生 CB 店铺 1P 分类（seller_type_1p）及 cb_seller_type |

---

### 注意事项

1. **`seller_status` / `advertiser_status` / `seller_tier` / `advertiser_tier` 的时间口径**：四个字段均基于"上月末"与"上上月末"的 td 累计快照差值（即月度增量）计算。`grass_date` 为月中时，这些字段反映的仍是已过去的完整月度，并非当月实时状态。建议**月末日期**分区作为月度分析标准快照。

2. **`is_principal` 恒为 1**：ETL 中直接硬编码 `1 as is_principal`，当前版本所有店铺均标记为 principal，该字段暂无区分意义，过滤时请勿依赖此字段做业务筛选。

3. **`seller_type` 优先级规则**：派生优先级为 Official Store > Cross Border > Managed Seller > Preferred Seller > Preferred Plus Seller > Others，同时满足多条件的店铺只取最高优先级类型，分析时需注意各类型之间存在互斥覆盖关系。

4. **NULL 值填充默认值**：多个字段在左连接后使用 `COALESCE` 填充默认值（`seller_status` → `'churned_before'`、`advertiser_status` → `'never_activated'`、`seller_tier` → `'micro_seller'`、`advertiser_tier` → `'micro_advertiser'`、`ads_placement_type` → `'no_related_ads'`、`key_seller_90/95` → `0`、`seller_type_1p` → `'Unknown'`、`shop_level1_fe_display_category_id` → `0`），业务过滤时须注意这些默认值的含义，避免将"无数据"误判为真实低值。

5. **`cluster` 字段品类覆盖不完整**：仅映射了特定品类到 EL / Fashion / FMCG / Lifestyle，其余品类 `cluster` 为 NULL。统计各 cluster 店铺数时，建议增加 `WHERE cluster IS NOT NULL` 或单独统计 NULL 行以避免遗漏。

6. **地区参数化调度**：ETL SQL 中出现的 `upper('${region}')`、`${grass_date}`、`${timezone}` 均为调度模板参数，非固定值。本表覆盖所有已上线地区，各地区分区独立，不存在跨地区数据混合。

7. **`shop_listing` 使用 CACHE**：ETL 中对 `shop_listing` 临时视图使用了 `MEMORY_AND_DISK` 缓存，原因是该视图被 `seller_info` 与 `platform_order` 两路复用，生产环境中缓存可显著降低重复扫描开销。

---

*文档生成时间：2026-05-20*