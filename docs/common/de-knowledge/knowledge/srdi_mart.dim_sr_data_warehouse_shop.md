<!-- ads-workspace-gdoc-sync: gdoc_id=1_rLeDRh91lryKlqpWfqx6yzGq_Fdipp4mP-W9OdZsxM gdoc_url=https://docs.google.com/document/d/1_rLeDRh91lryKlqpWfqx6yzGq_Fdipp4mP-W9OdZsxM/edit -->

# srdi_mart.dim_sr_data_warehouse_shop

**分层：** DIM（维度层）
**主键：** `shop_id`（在 `grass_region` + `local_date` 分区内唯一）
**分区：** `grass_region`（站点/区域）、`local_date`（本地日期）
**更新频率：** 每日全量覆写（`INSERT OVERWRITE`，按分区）
**引用频次 / 访问频次：** 929 次

---

## 业务描述

本表是搜推数仓（SRDI）面向店铺维度的宽表，整合了店铺基础属性、经营状态、商品上架、互动行为、卖家等级及竞对标记等多维信息，为搜索、推荐、数据分析等下游场景提供统一的店铺快照。

**核心业务场景：**

- 搜索/推荐特征工程：通过店铺类型、评分、评级、活跃商品数等指标构建店铺侧特征。
- 卖家运营分析：分析店铺状态、粉丝数、评价分布、最近登录时间等运营健康度指标。
- 跨境/B2C/托管店铺专项分析：结合 `shop_is_cb_shop`、`shop_is_b2c`、`shop_is_ccb_shop`、`shop_cb_shop_origin_country` 等字段做专项统计。
- 竞对识别：通过 `shop_is_competitor` 快速过滤竞争对手店铺。
- 区域/城市分布分析：基于 `shop_state`、`shop_city`、`shop_district` 做地理维度下钻。

**适合回答的问题示例：**

- 某区域某日活跃在售商品数最多的 TopN 店铺是哪些？
- 本地某区域 preferred 类型店铺的平均卖家评分是多少？
- 托管店铺与普通店铺的粉丝数分布有何差异？
- 哪些店铺被标记为竞对？其评分情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识（如 `ID`、`TH`、`MY` 等），所有查询必须携带此过滤条件 |
| `local_date` | date | 本地日期，数据快照日期，所有查询必须携带此过滤条件 |

### 维度：店铺基础信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺唯一标识，主键 |
| `shop_user_id` | bigint | 店铺对应的用户（卖家）ID |
| `shop_name` | string | 店铺名称 |
| `shop_type` | string | 店铺类型，枚举值：`official`（官方店）、`preferred`（优质店）、`preferred_plus`（超级优质店）、`long_tail`（长尾店）；依据 `is_official_shop`、`is_preferred_shop`、`is_preferred_plus_shop` 标志位派生 |
| `shop_tier` | string | 店铺等级（来自托管店铺维度表） |
| `shop_status` | bigint | 店铺状态码 |
| `shop_seller_status` | bigint | 卖家账号状态码 |
| `shop_create_datetime` | string | 店铺创建时间 |
| `shop_is_holiday_mode` | tinyint | 是否处于假期模式，1=是，0=否 |

### 维度：店铺类型标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_is_b2c` | int | 是否为 B2C 店铺，1=是，0=否 |
| `shop_is_cb_shop` | tinyint | 是否为跨境店铺，1=是，0=否 |
| `shop_is_ccb_shop` | int | 是否为 CCB（综合跨境）店铺，1=是，0=否 |
| `shop_is_fbs` | int | 是否为 FBS（Fulfilled by Shopee）店铺，1=是，0=否 |
| `shop_is_fss_shop` | int | 是否为 FSS 店铺，1=是，0=否 |
| `shop_is_supermarket_shop` | int | 是否为超市店铺，1=是，0=否 |
| `shop_is_bi_excluded` | int | 是否被 BI 分析排除，1=排除，0=不排除 |
| `shop_is_competitor` | boolean | 是否为竞对店铺；由 BD 竞对链接表与店铺配对表 UNION 后 LEFT JOIN 派生，有匹配记录则为 `true`，否则为 `false` |
| `shop_cb_shop_origin_country` | string | 跨境店铺的来源国家/地区（仅跨境店铺有值） |

### 维度：托管与类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_primary_managed_kpi_category` | string | 店铺主要托管 KPI 类目（来自托管店铺维度表，非托管店铺为 NULL） |

### 维度：地理位置

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_state` | string | 店铺取货地址省/州级行政区 |
| `shop_city` | string | 店铺取货地址市级行政区 |
| `shop_district` | string | 店铺取货地址区/县级行政区 |

### 指标：评价与评分

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_seller_rating` | string | 卖家评级原始 JSON 字符串，含各星级评价数量（`$.rating_count[0..5]`） |
| `shop_score` | double | 卖家加权综合评分，由 `seller_rating` JSON 中各星级评价数量加权平均计算得出（1\~5星加权，0星权重为0）；**不可直接 SUM/AVG** |
| `shop_response_rate` | double | 店铺消息回复率（0~1 或百分比，视上游定义），**不可直接 SUM** |
| `shop_rating_bad` | bigint | 差评总数（累计） |
| `shop_rating_normal` | bigint | 中评总数（累计） |
| `shop_rating_good` | bigint | 好评总数（累计） |
| `shop_sold_total` | bigint | 店铺历史累计销量 |

### 指标：互动与粉丝（截至当日，_td 后缀）

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_follower_cnt_td` | bigint | 截至当日的店铺粉丝数（累计至今，`_td` = to-date） |
| `shop_like_cnt_td` | bigint | 截至当日的店铺点赞数（累计至今） |

### 指标：商品上架

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_active_item_with_stock_cnt` | bigint | 当前有库存的活跃在售商品数 |
| `shop_first_listing_datetime` | string | 店铺首次上架商品的时间 |
| `shop_last_listing_datetime` | string | 店铺最近一次上架商品的时间 |

### 指标：登录行为（截至当日，_td 后缀）

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_last_login_datetime_td` | string | 截至当日卖家最近一次登录时间 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：表按站点分区存储，查询时必须明确指定，避免全表扫描。
- **`local_date`**：表按日期分区，每次查询需指定具体日期或日期范围，未指定将导致多分区全扫。

```sql
-- 示例
SELECT *
FROM srdi_mart.dim_sr_data_warehouse_shop
WHERE grass_region = 'ID'
  AND local_date = '2026-05-16';
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `shop_score` | 加权平均值，直接 SUM 无业务意义；需用评价数量字段重新加权计算 |
| `shop_response_rate` | 比率字段，跨店 SUM 无意义；如需汇总需用分子/分母分别聚合 |
| `shop_seller_rating` | 原始 JSON 字符串，需先解析再聚合 |
| `shop_follower_cnt_td` | `_td` 后缀表示截至当日的累计值，跨日期 SUM 会造成重复计数 |
| `shop_like_cnt_td` | 同上，截至当日累计值 |
| `shop_last_login_datetime_td` | 时间戳字段，不可求和 |

### 时效性说明

- 本表为**日快照维度表**，每日覆写对应分区，反映当日 `local_date` 的店铺状态。
- `_td` 后缀字段（`shop_follower_cnt_td`、`shop_like_cnt_td`、`shop_last_login_datetime_td`）均为**截至当日的累计/最新值**，跨日期对比时请使用不同 `local_date` 分区的值做差值计算，而非直接相减行数据。
- `shop_rating_bad`、`shop_rating_normal`、`shop_rating_good`、`shop_sold_total` 为历史**累计总量**，同样不适合跨分区直接相减计算增量（除非上游有明确标注为增量字段）。

### 其他注意事项

- `shop_primary_managed_kpi_category` 和 `shop_tier` 仅对托管店铺有值，非托管店铺为 `NULL`，使用时注意过滤。
- `shop_is_competitor` 为 boolean 类型，过滤时直接用 `WHERE shop_is_competitor = true`。
- `shop_cb_shop_origin_country` 仅跨境店铺（`shop_is_cb_shop = 1`）有实际值。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_user.dim_shop__reg_s0_live` | 店铺核心属性：状态、类型、评分、地址、卖家信息等基础维度（主驱动表） |
| `mp_seller.dim_managed_shop__reg_s0_live` | 店铺托管信息：主要托管 KPI 类目、店铺等级（`shop_tier`） |
| `mp_user.dws_shop_interaction_td__reg_s0_live` | 店铺互动累计指标：粉丝数、点赞数（截至当日） |
| `mp_item.dws_shop_listing_td__reg_s0_live` | 商品上架信息：首次/最近上架时间、有库存活跃商品数 |
| `mp_user.dws_user_login_td_account_info__reg_s0_live` | 卖家登录行为：最近登录时间（截至当日） |
| `mkpldp_bd_center.salesforce_metrics_reg_continuous_tab` | BD 竞对识别：通过竞对链接或竞对名称标记竞对店铺 |
| `marketplace.shopee_pcenter_db__shop_pairs_tab__reg_daily_s0_live` | 竞对店铺配对表：通过店铺配对关系补充竞对标记 |
| `mp_seller.dim_shop_ext__reg_s0_live` | 店铺扩展信息：跨境店铺来源国（`shop_cb_shop_origin_country`） |

---

## ETL 逻辑摘要

### 数据流

```
mp_user.dim_shop__reg_s0_live                     ──┐
mp_seller.dim_managed_shop__reg_s0_live            ──┤
mp_user.dws_shop_interaction_td__reg_s0_live       ──┤
mp_item.dws_shop_listing_td__reg_s0_live           ──┤  LEFT JOIN on shop_id
mp_user.dws_user_login_td_account_info__reg_s0_live──┤
mkpldp_bd_center.salesforce_metrics_reg_...        ──┤  UNION → 竞对集合
marketplace.shopee_pcenter_db__shop_pairs_tab...   ──┤
mp_seller.dim_shop_ext__reg_s0_live                ──┘
                                                     ↓
                              srdi_mart.dim_sr_data_warehouse_shop
                              (INSERT OVERWRITE PARTITION)
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Statement 1 | `dim_shop_${grass_region_without_quote}` | 从 `mp_user.dim_shop__reg_s0_live` 提取店铺基础属性，派生 `shop_type`（官方/preferred/preferred_plus/长尾）、`shop_score`（加权评分）、地址三级字段，过滤 `tz_type='local'` 及当日当区数据 |
| Statement 2 | `dim_managed_shop_${grass_region_without_quote}` | 从 `mp_seller.dim_managed_shop__reg_s0_live` 提取托管店铺的 KPI 类目和等级 |
| Statement 3 | `dws_shop_interaction_${grass_region_without_quote}` | 从 `mp_user.dws_shop_interaction_td__reg_s0_live` 提取截至当日的粉丝数和点赞数 |
| Statement 4 | `dws_shop_listing_${grass_region_without_quote}` | 从 `mp_item.dws_shop_listing_td__reg_s0_live` 提取首次/最近上架时间及有库存活跃商品数 |
| Statement 5 | `dws_shop_login_${grass_region_without_quote}` | 从 `mp_user.dws_user_login_td_account_info__reg_s0_live` 提取卖家最近登录时间 |
| Statement 6 | `shop_bd_competitor_${grass_region_without_quote}` | 对 BD Salesforce 竞对表与店铺配对表取 `UNION`（自动去重），生成竞对 `shop_id` 集合；注意此步骤**无区域/日期过滤**，竞对数据为全量 |
| Statement 7 | `dim_shop_ext_${grass_region_without_quote}` | 从 `mp_seller.dim_shop_ext__reg_s0_live` 提取跨境店铺来源国 |
| Statement 8 | `INSERT OVERWRITE` | 以 `dim_shop` 为主表，对其余 6 个 Temporary View 执行 `LEFT JOIN`，拼装最终宽表，写入目标分区（`grass_region`、`local_date`） |

### 注意事项

1. **单一写入源**：本表仅有 1 个 ETL 文件，不存在多文件并发写入同一分区的风险。
2. **分区写入方式**：使用 `INSERT OVERWRITE PARTITION`，每次执行会完整覆盖对应 `grass_region` + `local_date` 分区，重跑幂等。
3. **竞对表无时间/区域过滤**：`shop_bd_competitor` 临时视图的两个来源表均未按 `grass_region` 或日期过滤，可能存在跨区域数据混入，使用 `shop_is_competitor` 字段时需结合业务背景判断准确性。
4. **`shop_score` 计算风险**：当 `seller_rating` JSON 中所有星级评价数总和为 0 时，分母为 0，`shop_score` 将产生 `NaN` 或 `NULL`，下游使用时需做空值保护。
5. **参数化执行**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}`、`${schema}` 均为运行时参数，ETL 按站点分别调度执行。
6. **`tz_type = 'local'` 过滤**：所有上游表均按本地时区（`local`）过滤，确保日期对齐为站点本地日期，与分区字段 `local_date` 语义一致。

---

*文档生成时间：2026-05-17*