<!-- ads-workspace-gdoc-sync: gdoc_id=17VfP4uEvauDt0WGrq84eAGQgsXOQxM3MPfTaMuAKFrw gdoc_url=https://docs.google.com/document/d/17VfP4uEvauDt0WGrq84eAGQgsXOQxM3MPfTaMuAKFrw/edit -->

# mp_paidads.dim_shop_info_monthly

**分层**：DIM（维度层 / ADS 层）
**主键**：`shop_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每月（按自然月末或指定 grass_date 调度，各地区按本地时区参数化调度）
**引用频次**：0（末端 ADS 层维表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告域的**店铺月度宽表维度表**，以店铺（shop）为粒度，整合了店铺基础属性、卖家分层、广告主分层、广告投放类型、平台 GMV 关键卖家标识、广告预算月度趋势及广告采用率标签等多维信息。每个自然月末（或指定业务日期）产出一份快照，记录该月截止到 `grass_date` 时点各店铺的综合画像。

本表是付费广告运营分析的核心维表，常见使用场景包括：广告主分层运营（Advertiser Tier）、卖家活跃状态追踪（new / existing / churn / reactivated）、广告产品组合分析（Ads Placement Type）、预算健康度和采用率趋势分析（Adoption Tag）、以及与事实表 JOIN 后进行多维度下钻分析。

本表覆盖所有启用付费广告的地区市场，各地区通过 `${region}` 和 `${timezone}` 参数化调度写入，查询时须通过 `grass_region` 和 `grass_date` 分区字段锁定目标地区和月份，避免全表扫描。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `'local'`（本地时区）。查询时**必须指定**此字段以避免全表扫描 |
| `grass_region` | string | 地区代码（大写），如 `'MY'`、`'TH'`、`'PH'` 等。查询时**必须指定** |
| `grass_date` | date | 数据快照日期，通常为当月最后一个自然日或业务调度日期。查询时**必须指定** |

---

### 维度：店铺基础信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺唯一标识，跨表关联的主键字段 |
| `seller_name` | string | 店铺名称（来源于 `mp_user.dim_shop__reg_s0_live` 的 `shop_name`） |
| `account_create_datetime` | string | 账户创建时间，格式为 `'YYYY-MM-DD HH:MM:SS'`，表示店铺在系统中的注册时间 ⚠️ 以字符串格式存储，日期比较需先转换类型 |
| `shop_level1_global_be_category` | string | 店铺所属全球商业一级类目（如 `'Mobile & Gadgets'`、`'Beauty'` 等） |
| `shop_level2_global_be_category` | string | 店铺所属全球商业二级类目，为一级类目的细分 |
| `cluster` | string | 基于一级类目派生的业务簇，取值：`'EL'`（电子）、`'Fashion'`（时尚）、`'FMCG'`（快消）、`'Lifestyle'`（生活）；不在映射范围内的类目为 NULL ⚠️ 为派生字段，不可直接聚合，仅用于分组过滤 |
| `seller_type` | string | 卖家类型，按优先级派生，取值：`'Official Store'`、`'Cross Border'`、`'Managed Seller'`、`'Preferred Seller'`、`'Preferred Plus Seller'`、`'Others'` ⚠️ 为多条件优先级判断的派生字段，同一店铺在不同月份可能变化 |
| `principal_type` | string | 主体类型，来源于 `regma_general.shop_attributes`；跨境卖家且 principal_type 为 NULL 时强制赋值为 `'Cross Border'`，其余 NULL 赋值为 `'Local Brand'` |
| `is_principal` | tinyint | 是否为主体店铺，ETL 中固定赋值为 `1`（所有写入记录均为 1）⚠️ 当前版本恒为 1，不反映实际主体状态，请谨慎用于过滤 |
| `is_cb_seller` | tinyint | 是否跨境卖家，`1` = 是，`0` = 否 |
| `is_official_shop` | tinyint | 是否官方旗舰店，`1` = 是，`0` = 否 |
| `is_preferred_shop` | tinyint | 是否优选店铺（Preferred Shop），`1` = 是，`0` = 否 |
| `is_managed_seller` | tinyint | 是否托管卖家（Managed Seller），`1` = 是，`0` = 否 |

---

### 维度：卖家与广告主状态分层

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_status` | string | 卖家本月活跃状态，基于平台 GMV td 环比三个月计算，取值：`'new'`（新卖家）、`'existing'`（活跃）、`'churn'`（本月流失）、`'reactivated'`（重新激活）、`'churned_before'`（持续非活跃）、`'others'`；NULL 时默认赋值 `'churned_before'` ⚠️ 为快照时点状态，不同月份 grass_date 结果不同，纵向对比需固定分区 |
| `seller_tier` | string | 卖家分层，基于当月增量平台 GMV（USD）与阈值表对比计算，取值：`'large_seller'`、`'medium_seller'`、`'small_seller'`、`'micro_seller'`；NULL 时默认赋值 `'micro_seller'` ⚠️ 阈值由 `dim_seller_tier_threshold` 动态读取，各地区阈值不同 |
| `advertiser_status` | string | 广告主本月活跃状态，基于广告消耗额 td 环比三个月计算，取值：`'new'`、`'existing'`、`'churn'`、`'reactivated'`、`'churned_before'`、`'never_activated'`、`'others'`；NULL 时默认赋值 `'never_activated'` ⚠️ 为快照时点状态，不同月份 grass_date 结果不同，纵向对比需固定分区 |
| `advertiser_tier` | string | 广告主分层，基于当月增量广告消耗额（USD）与阈值表对比计算，取值：`'large_advertiser'`、`'medium_advertiser'`、`'small_advertiser'`、`'micro_advertiser'`；NULL 时默认赋值 `'micro_advertiser'` ⚠️ 阈值由 `dim_advertiser_tier_threshold` 动态读取，各地区阈值不同 |
| `ads_placement_type` | string | 本月广告投放产品组合类型，枚举值为 search/discovery/shop/item/auto 五类产品的组合字符串（如 `'search_only'`、`'search_discovery'`、`'full_ads'` 等共 30+ 种），NULL 时默认赋值 `'no_related_ads'` ⚠️ 为派生枚举标签，仅用于分组/过滤，不可聚合 |

---

### 维度：关键卖家标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `key_seller_90` | tinyint | 是否为本类目内平台 GMV 排名前 10% 的关键卖家（百分位 ≥ 90%），`1` = 是，`0` = 否；NULL 时赋值 `0` ⚠️ 百分位基于当月截止 grass_date 的类目内排名，月中数据不代表月末最终结果 |
| `key_seller_95` | tinyint | 是否为本类目内平台 GMV 排名前 5% 的关键卖家（百分位 ≥ 95%），`1` = 是，`0` = 否；NULL 时赋值 `0` ⚠️ 同 key_seller_90，月中结果存在偏差 |

---

### 维度：广告采用率标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_adoption_tag_m1` | string | 全品类广告：当月均值预算 vs. 上月均值预算的变化标签，取值：`'uplift'`（持平或增长）、`'drop'`（下降幅度 < 70%）、`'churn'`（下降幅度 ≥ 70%）；NULL 时赋值 `'uplift'` ⚠️ 由两期月均预算相除派生，不可直接 SUM，需用原始预算字段重新计算 |
| `seller_adoption_tag_m2` | string | 全品类广告：当月均值预算 vs. 上上月均值预算的变化标签，取值同 m1；NULL 时赋值 `'uplift'` ⚠️ 同上 |
| `seller_target2_adoption_tag_m1` | string | Target2.0（ROI 2.0）广告：当月 vs. 上月预算变化标签，取值同 m1；NULL 时赋值 `'uplift'` |
| `seller_target2_adoption_tag_m2` | string | Target2.0（ROI 2.0）广告：当月 vs. 上上月预算变化标签；NULL 时赋值 `'uplift'` |
| `seller_simple2_adoption_tag_m1` | string | Simple2.0（ROI 2.0 简单模式）广告：当月 vs. 上月预算变化标签；NULL 时赋值 `'uplift'` |
| `seller_simple2_adoption_tag_m2` | string | Simple2.0 广告：当月 vs. 上上月预算变化标签；NULL 时赋值 `'uplift'` |
| `seller_auto_adoption_tag_m1` | string | 自动广告（Item Boost / Simple Mode / Auto Boost）：当月 vs. 上月预算变化标签；NULL 时赋值 `'uplift'` |
| `seller_auto_adoption_tag_m2` | string | 自动广告：当月 vs. 上上月预算变化标签；NULL 时赋值 `'uplift'` |
| `seller_manual_adoption_tag_m1` | string | 手动广告（Manual Mode）：当月 vs. 上月预算变化标签；NULL 时赋值 `'uplift'` |
| `seller_manual_adoption_tag_m2` | string | 手动广告：当月 vs. 上上月预算变化标签；NULL 时赋值 `'uplift'` |

---

### 指标：广告预算月均值（USD）

> 所有预算字段均为**月内有效广告日的平均日预算**（`AVG`，仅统计预算 > 0 的日期），非累计求和值。

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_valid_budget_usd` | double | 全品类广告：当月（月初至 grass_date）日均有效预算（USD）⚠️ 为月均值，不可直接 SUM 跨店铺求总月预算 |
| `campaign_valid_budget_usd_last_1m` | double | 全品类广告：上月完整月日均有效预算（USD）⚠️ 同上 |
| `campaign_valid_budget_usd_last_2m` | double | 全品类广告：上上月完整月日均有效预算（USD）⚠️ 同上 |
| `target2_campaign_valid_budget_usd` | double | Target2.0（ROI 2.0）广告：当月日均有效预算（USD）⚠️ 仅统计预算 > 0 的日期均值 |
| `target2_campaign_valid_budget_usd_last_1m` | double | Target2.0 广告：上月日均有效预算（USD） |
| `target2_campaign_valid_budget_usd_last_2m` | double | Target2.0 广告：上上月日均有效预算（USD） |
| `simple2_campaign_valid_budget_usd` | double | Simple2.0（ROI 2.0 简单模式）广告：当月日均有效预算（USD） |
| `simple2_campaign_valid_budget_usd_last_1m` | double | Simple2.0 广告：上月日均有效预算（USD） |
| `simple2_campaign_valid_budget_usd_last_2m` | double | Simple2.0 广告：上上月日均有效预算（USD） |
| `auto_campaign_valid_budget_usd` | double | 自动广告（Item Boost / Simple Mode / Auto Boost）：当月日均有效预算（USD） |
| `auto_campaign_valid_budget_usd_last_1m` | double | 自动广告：上月日均有效预算（USD） |
| `auto_campaign_valid_budget_usd_last_2m` | double | 自动广告：上上月日均有效预算（USD） |
| `manual_campaign_valid_budget_usd` | double | 手动广告（Manual Mode）：当月日均有效预算（USD） |
| `manual_campaign_valid_budget_usd_last_1m` | double | 手动广告：上月日均有效预算（USD） |
| `manual_campaign_valid_budget_usd_last_2m` | double | 手动广告：上上月日均有效预算（USD） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表多分区扫描，严重影响性能并产生重复数据：

```sql
WHERE tz_type      = 'local'               -- 固定值，本表仅写入 local 分区
  AND grass_region = 'MY'                  -- 替换为目标地区大写代码
  AND grass_date   = '2024-11-30'          -- 替换为目标月份的快照日期（通常为月末）
```

- **`tz_type`**：本表 ETL 固定以 `tz_type = 'local'` 写入，查询时必须加此过滤，否则分区裁剪失效。
- **`grass_region`**：各地区数据独立写入，不指定将读取所有地区数据，导致 `shop_id` 重复且跨地区混算。
- **`grass_date`**：本表为月度快照，每月末产出一个分区；不指定将扫描所有历史月份，导致数据重复且查询极慢。

---

### 不可直接 SUM 的字段

以下字段为**预计算均值或派生标签**，不能对多行直接求和：

| 字段 | 错误用法 | 正确用法 |
|------|----------|----------|
| `campaign_valid_budget_usd` 及所有 `*_valid_budget_usd*` 系列（共 15 个） | `SUM(campaign_valid_budget_usd)` 求总预算 | 此字段为店铺月内日均有效预算，跨店铺求和无业务意义；如需总量，应回溯 `mp_paidads.ads_campaign_valid_budget_1d` 原始日粒度数据 |
| `seller_adoption_tag_m1/m2` 及所有 Adoption Tag 系列（共 10 个） | 对标签字段 COUNT 后直接作为增长率 | 仅用于分组过滤，增长率需用分子/分母预算字段重新计算：`(campaign_valid_budget_usd / campaign_valid_budget_usd_last_1m) - 1` |
| `cluster`、`seller_type`、`ads_placement_type` | 聚合计算 | 仅用于 GROUP BY 或 WHERE 过滤 |
| `key_seller_90`、`key_seller_95` | `SUM` 求关键卖家总数时需注意同一店铺在不同类目中可能为 NULL | 使用 `SUM(COALESCE(key_seller_90, 0))` 统计数量 |

---

### 时效性说明

- 本表为**月度快照**，`grass_date` 通常为当月最后一天（如 `2024-11-30`）。
- **`seller_status` / `advertiser_status`**：当月状态基于 td（截止日期累计）口径计算，在月中调度时结果为不完整月的快照，**只有月末 grass_date 的数据才代表完整当月状态**，月中值仅供参考。
- **`key_seller_90` / `key_seller_95`**：百分位基于当月截止 grass_date 的累计 GMV 排名，月中数据排名可能与月末最终结果有较大偏差，建议仅使用月末分区值。
- **`*_valid_budget_usd`（当月字段）**：统计区间为月初至 grass_date，月末值为完整月均值，月中值为部分月均值，两者口径不同，纵向对比时须使用相同 grass_date 逻辑的分区。
- 查询历史趋势时，推荐固定使用**每月最后一天**的 `grass_date` 分区，以保证各月数据口径一致。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_user.dim_shop__reg_s0_live` | 获取店铺基础信息：`shop_name`、`is_preferred_plus_shop` |
| `regma_general.shop_attributes` | 获取店铺主体类型 `principal_type` |
| `mp_paidads.dim_advertiser__reg_s0_live` | 获取广告主维度属性：类目、账户创建时间、店铺类型标志位等 |
| `mp_paidads.dim_advertiser_tier_threshold__reg_s0_live` | 获取广告主分层阈值（各地区 large/medium/small 最低消耗门槛） |
| `mp_paidads.dim_seller_tier_threshold__reg_s0_live` | 获取卖家分层阈值（各地区 large/medium/small 最低 GMV 门槛） |
| `mp_order.dws_seller_gmv_td__reg_s0_live` | 计算卖家月度平台 GMV（td 口径），用于派生 `seller_status` 和 `seller_tier` |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live` | 计算广告主月度广告消耗额（td 口径），用于派生 `advertiser_status` 和 `advertiser_tier` |
| `mp_paidads.dim_advertise__reg_s0_live` | 统计本月各广告位类型的有效广告数，用于派生 `ads_placement_type` |
| `mp_order.dws_item_gmv_1d__reg_s0_live` | 计算店铺当月 GMV，用于派生 `key_seller_90` / `key_seller_95` 类目内百分位排名 |
| `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | 获取各广告产品类型的日粒度有效预算，用于计算当月及过去两月的日均预算字段和 Adoption Tag |

---

## ETL 逻辑摘要

### 数据流

```
mp_user.dim_shop__reg_s0_live          ──────────────────────────────────┐
regma_general.shop_attributes           ──────────────────────────────────┤
mp_paidads.dim_advertiser__reg_s0_live ──────────────────────────────────┤
                                                                          ▼
                                                              [CTE: seller_info]
                                                         (店铺基础维度宽表拼接)
                                                                          │
mp_order.dws_seller_gmv_td__reg_s0_live ─────────────────────────────────┤
mp_paidads.dim_seller_tier_threshold__reg_s0_live ────────────────────────┤
                                                    ▼                     │
                                          [CTE: seller_status]            │
                                       (卖家状态 & 分层计算)              │
                                                                          │
mp_paidads.dws_advertiser_placement_performance_td──────────────────────── ┤
mp_paidads.dim_advertiser_tier_threshold__reg_s0_live ───────────────────  ┤
                                                    ▼                     │
                                         [CTE: advertiser_status]         │
                                      (广告主状态 & 分层计算)             │
                                                                          │
mp_paidads.dim_advertise__reg_s0_live ───────────────────────────────────  ┤
                                                    ▼                     │
                                      [CTE: seller_ads_placement_type]    │
                                          (广告产品组合枚举)              │
                                                                          │
mp_order.dws_item_gmv_1d__reg_s0_live ──────────────────────────────────  ┤
                                                    ▼                     │
                                          [CTE: platform_order]           │
                                        (类目内 GMV 百分位排名)           │
                                                                          │
mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live ────────────────────  ┤
                                                    ▼                     │
                                          [CTE: adoption_tag]             │
                                       (月均预算 & 采用率标签计算)        │
                                                                          │
                          ┌───────────────────────────────────────────────┘
                          │  LEFT JOIN 所有 CTE（以 shop_id 为键）
                          ▼
            dim_shop_info_monthly__reg_s0_live
             (INSERT OVERWRITE, PARQUET 格式写入)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `shop` | `mp_user.dim_shop__reg_s0_live` | 获取当日快照的店铺名称和 preferred_plus 标志 |
| `msbenchmark` | `regma_general.shop_attributes` | 获取店铺 principal_type（按 shop_id 去重聚合） |
| `dim_advertiser` | `mp_paidads.dim_advertiser__reg_s0_live` | 获取广告主类目、账户信息、店铺类型标志，并计算 `cluster` 派生字段 |
| `seller_info` | shop + dim_advertiser + msbenchmark | 三表 LEFT JOIN 拼接店铺完整基础维度，派生 `seller_type`、`principal_type` |
| `advertiser_tier_threshold` | `mp_paidads.dim_advertiser_tier_threshold__reg_s0_live` | 读取广告主分层阈值（large/medium/small 门槛值） |
| `seller_tier_threshold` | `mp_paidads.dim_seller_tier_threshold__reg_s0_live` | 读取卖家分层阈值（large/medium/small 门槛值） |
| `seller_status` | `mp_order.dws_seller_gmv_td__reg_s0_live`（三个时间窗口）+ seller_tier_threshold | FULL JOIN 三期 GMV 快照，计算卖家活跃状态和 GMV 分层 |
| `advertiser_status` | `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live`（三个时间窗口）+ advertiser_tier_threshold | FULL JOIN 三期广告消耗快照，计算广告主活跃状态和消耗分层 |
| `seller_ads_placement_type` | `mp_paidads.dim_advertise__reg_s0_live` | 统计当月各广告位类型的广告数量，通过多分支 CASE WHEN 枚举产品组合类型 |
| `platform_order` | `mp_order.dws_item_gmv_1d__reg_s0_live` + dim_advertiser | 计算店铺当月 GMV，通过 PERCENT_RANK 计算类目内百分位，派生 key_seller_90/95 |
| `adoption_tag` | `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | 分三个月窗口计算各广告产品类型的日均有效预算，并派生月度 Adoption Tag 标签 |

### 注意事项

1. **预算字段为月均值而非累计值**：`campaign_valid_budget_usd` 系列字段通过 `AVG` 聚合日粒度预算得到，仅对预算 > 0 的日期取均值（NULL 日期不参与计算），反映的是"有投放日的平均日预算"，而非月度总消耗。对多个店铺直接 `SUM` 无法还原总体预算规模，如需月总预算，应回溯 `ads_campaign_valid_budget_1d` 日粒度数据。

2. **状态字段的三期比较口径**：`seller_status` 和 `advertiser_status` 均通过 FULL JOIN 三期快照（当月末、上月末、上上月末）的累计 td 值进行差值比较，当月增量 = 当月末 td - 上月末 td。若某期数据缺失（无记录），COALESCE 为 0，可能导致部分状态判断偏差，需关注数据上游的完整性。

3. **Adoption Tag 的 NULL 处理**：当分母（last_1m 或 last_2m 预算）为 0 时，除法结果为 NULL/无穷大，导致 CASE WHEN 所有分支均不命中，最终输出 NULL；INSERT 时通过 `COALESCE(..., 'uplift')` 将 NULL 统一赋值为 `'uplift'`。使用时需注意 `'uplift'` 标签包含"上期无预算"和"真实增长"两种情况，不能仅凭标签判断增长。

4. **`is_principal` 恒为 1**：ETL 中对所有写入记录固定赋值 `1 as is_principal`，该字段当前版本无实际区分意义，请勿将其用于过滤真实主体店铺。

5. **`ads_placement_type` 覆盖范围**：统计区间为当月月初至 `grass_date`，基于 `dim_advertise` 表中有效广告记录判断；未在平台投放任何广告的店铺默认为 `'no_related_ads'`。

6. **地区参数化调度**：ETL SQL 中出现的具体地区代码（如 `upper('mx')`）和时区为调度模板的参数化实例，本表通过 `${region}`、`${timezone}` 参数覆盖所有启用地区，查询时应通过 `grass_region` 动态指定目标地区。

---

*文档生成时间：2026-05-20*