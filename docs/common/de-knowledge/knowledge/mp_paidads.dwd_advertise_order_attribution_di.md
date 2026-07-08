<!-- ads-workspace-gdoc-sync: gdoc_id=1UQ0hUuXOWU1w9P9GWdpyJf8JriAe7isv5UTo3dLISQ8 gdoc_url=https://docs.google.com/document/d/1UQ0hUuXOWU1w9P9GWdpyJf8JriAe7isv5UTo3dLISQ8/edit -->

# mp_paidads.dwd_advertise_order_attribution_di

**分层**：DWD（数据明细层）
**主键**：`order_id`、`ads_id`、`item_id`、`shop_id`、`grass_date`、`grass_region`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆写（INSERT OVERWRITE）
**引用频次**：29 次（候选表范围内下游引用）

---

## 业务描述

本表为广告订单归因明细表，记录广告点击与订单之间的关联关系，是 Paid Ads 业务最核心的订单归因 DWD 明细层。表中每行对应一次广告交互（点击/曝光）所归因的订单事件，包含直接订单（Direct Order）与宽泛订单（Broad Order）两类归因口径，完整保留了点击时间戳、事件时间戳、付款时间戳、确认时间戳等多个时间维度，支持多种订单状态的分析需求。

本表广泛用于广告投放效果评估、ROAS（广告支出回报率）计算、买家行为路径分析以及广告平台大盘报表的生产。下游报表和数据集市层（DWS/ADS）可直接基于本表进行广告 GMV、订单数、商品售出量等核心指标的汇总计算，同时支持按广告位（placement）、入口（entrance）、关键词（keyword）、匹配类型（match\_type）、买家人群标签（matched\_premium\_segment\_value\_id）等多维度下钻分析。

各地区按本地时区参数化调度，覆盖所有 Shopee 运营地区。`tz_type = 'local'` 分区为当前唯一写入分区，查询时须明确指定以避免全表扫描。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区键。当前写入值为 `'local'`，表示按各地区本地时区对齐日期。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 地区分区键，如 `'BR'`、`'TW'` 等，大写国家/地区代码。各地区独立调度写入 |
| `grass_date` | date | 日期分区键，格式 `YYYY-MM-DD`，对应事件发生的本地日期。⚠️ 每次查询必须指定，避免全表扫描 |

---

### 维度：主键与订单标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_id` | bigint | 订单 ID，广告归因订单的唯一标识 |
| `request_id` | string | 广告请求 ID，用于标识一次广告请求，可与广告日志关联 |
| `ads_id` | bigint | 广告 ID |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |

---

### 维度：广告属性与投放信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `placement` | bigint | 广告位编码，标识广告展示的版位位置。枚举值参见 [beeshop\_ads.proto](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L148) |
| `entrance` | bigint | 广告入口编码，标识买家点击或曝光的具体入口位置，反映广告流量来源 |
| `pricing_type` | int | 广告定价类型编码，描述该广告所使用的竞价/定价方式 |
| `match_type` | bigint | 关键词匹配类型，区分关键字与用户查询的匹配程度（如精确匹配、广泛匹配等） |
| `query` | string | 买家搜索查询词，促成广告曝光/点击的用户输入内容 |
| `keywords` | string | 广告关键词，广告主设置的用于匹配用户查询的关键词 |
| `matched_premium_segment_value_id` | string | 命中的买家人群标签 segment\_value\_id，用于定向投放效果分析 |

---

### 维度：时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `click_timestamp` | bigint | 产生订单的广告点击时间戳，Unix epoch 格式（秒）。⚠️ 存储为整型 Unix 时间戳，不可直接用于日期过滤，需转换后使用 |
| `click_datetime` | string | 产生订单的广告点击日期时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `event_timestamp` | bigint | 对应行事件（下单/付款/确认）的时间戳，Unix epoch 格式。⚠️ 存储为整型 Unix 时间戳，需注意与 `grass_date` 分区的对齐关系 |
| `event_datetime` | string | 对应行事件（下单/付款/确认）的日期时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `paid_timestamp` | bigint | 订单付款时间戳，Unix epoch 格式 |
| `paid_datetime` | string | 订单付款日期时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `confirmed_timestamp` | bigint | 发货确认时间戳，Unix epoch 格式。COD 订单为下单时间，非 COD 订单为付款时间 |
| `confirmed_datetime` | string | 发货确认日期时间，格式 `YYYY-MM-DD HH:MM:SS`。COD 订单为下单时间，非 COD 订单为付款时间 |

---

### 指标：直接订单（Direct Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt` | bigint | 直接订单数。直接订单定义：用户点击广告商品后在 7 天内完成购买。详见 [归因说明文档](https://confluence.shopee.io/x/XjJ0CQ) |
| `daily_order_cnt` | bigint | 与广告点击时间戳同日下单的直接广告订单数 |
| `paid_order_cnt` | bigint | 30 天窗口内已付款的广告直接订单数 |
| `confirmed_order_cnt` | bigint | 30 天窗口内已付款或已确认的广告直接订单数 |
| `ads_gmv_amt_local` | double | 直接广告订单 GMV（本地货币）。⚠️ GMV 口径为 `order_price × 商品数量`，仅含商品折扣/捆绑促销，不含运费、运费返还、买家手续费、平台返利、卖家券、银行卡返现及金币返利，与 order\_mart GMV（含全类型折扣）存在差异，使用时注意口径对齐 |
| `ads_gmv_amt_usd` | double | 直接广告订单 GMV（美元）。⚠️ 由 `ads_gmv_amt_local / exchange_rate` 派生计算而来，跨地区汇总时需注意汇率时效性，不建议直接 SUM 后与其他来源美元 GMV 比较 |
| `ads_items_sold_cnt` | bigint | 直接订单中售出的商品数量 |

---

### 指标：宽泛订单（Broad Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 宽泛广告订单数。宽泛归因逻辑：买家所购商品所属店铺在 7 天内有广告点击，且该商品最新点击非关键词/定向广告时归因为宽泛订单 |
| `broad_order_gmv_amt_local` | double | 宽泛广告订单 GMV（本地货币） |
| `broad_order_gmv_amt_usd` | double | 宽泛广告订单 GMV（美元）。⚠️ 由本地货币除以汇率派生计算而来，跨地区汇总时注意汇率口径 |
| `broad_order_item_cnt` | bigint | 宽泛广告订单中售出的商品数量 |
| `broad_shopitem_click_cnt` | bigint | 宽泛归因口径下的广告点击数。归因规则：商品（所在店铺）在 7 天内有广告点击；若商品最新点击来自关键词/定向广告则归入对应广告，若来自店铺广告直接商品点击则归入店铺广告宽泛 |
| `broad_shopitem_impression_cnt` | bigint | 宽泛归因口径下的广告曝光数。归因规则同 `broad_shopitem_click_cnt`，基于曝光维度统计 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全分区扫描，导致严重的计算资源浪费和查询超时：

```sql
WHERE tz_type      = 'local'          -- 当前唯一写入分区，必须指定
  AND grass_region = 'BR'             -- 替换为目标地区代码（大写）
  AND grass_date   = '2024-01-01'     -- 或指定日期范围，如 BETWEEN ... AND ...
```

- **`tz_type`**：必须指定 `'local'`，当前为唯一有效分区值；遗漏将扫描所有 tz\_type 分区
- **`grass_region`**：必须指定目标地区大写代码；遗漏将跨地区全量扫描，产生重复计数风险
- **`grass_date`**：必须指定日期或日期范围；遗漏将触发全历史数据扫描

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确做法 |
|------|------|----------|
| `ads_gmv_amt_usd` | 由 `ads_gmv_amt_local / exchange_rate` 派生，汇率按地区+日期匹配，跨地区/日期直接 SUM 会混淆汇率口径 | 先对本地货币 `ads_gmv_amt_local` 进行 SUM，再统一转换汇率；或确保只在相同 grass\_region + grass\_date 下 SUM |
| `broad_order_gmv_amt_usd` | 同上，为派生美元字段 | 同 `ads_gmv_amt_usd` 处理方式 |
| `broad_shopitem_click_cnt` / `broad_shopitem_impression_cnt` | 宽泛归因逻辑为窗口期内店铺维度聚合，行级别直接 SUM 可能产生重复计数 | 确认聚合维度与归因窗口对齐，建议在 `order_id` + `ads_id` 维度去重后再汇总 |
| `confirmed_order_cnt` / `paid_order_cnt` | 统计口径为 30 天滚动窗口，跨多日汇总时存在重复计数风险 | 明确业务口径选取单一事件类型（placed/paid/confirmed），避免多日累加 |

### 时效性说明

- 本表每日全量覆写（INSERT OVERWRITE），数据对应 `grass_date` 当日的最新快照
- `confirmed_order_cnt` / `paid_order_cnt` 反映的是以 **30 天为窗口**的回溯统计，即某一 `grass_date` 分区的值包含了该日期前 30 天内发生的付款/确认事件，**不代表当日新增**
- `daily_order_cnt` 仅统计与广告点击同日下单的订单，与 `order_cnt`（7 天窗口）存在口径差异，选取指标时需明确业务需求

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 主数据源，提供广告曝光、点击与订单归因的完整明细记录，包含 GMV 本地货币金额 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对美元的汇率，用于将本地货币 GMV 转换为美元 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  (主表：广告绩效明细，含订单归因、GMV本地货币)
          |
          | LEFT OUTER JOIN ON grass_region
          |
mp_order.dim_exchange_rate__reg_s0_live
  (汇率维表：当日地区汇率，过滤条件: grass_region + grass_date)
          |
          ▼
  过滤：order_id IS NOT NULL
     OR paid_datetime IS NOT NULL
     OR confirmed_datetime IS NOT NULL
  （排除无订单关联的纯曝光/点击行）
          |
          ▼
  字段映射 + 美元金额派生计算
  ads_gmv_amt_usd      = ads_order_gmv_local / exchange_rate
  broad_order_gmv_amt_usd = broad_gmv_amt_local / exchange_rate
          |
          ▼
dwd_advertise_order_attribution_di__reg_s0_live
  PARTITION (tz_type='local', grass_region='${region}', grass_date)
  REPARTITION(100)
```

### 关键 CTE 说明

本 ETL 无显式 CTE，汇率维表以内联子查询方式关联：

| 子查询别名 | 来源表 | 作用 |
|-----------|--------|------|
| `ex_rate` | `mp_order.dim_exchange_rate__reg_s0_live` | 按 `grass_region` + `grass_date` 过滤，获取当日地区汇率，用于本地货币转美元 |

### 注意事项

1. **订单过滤逻辑**：ETL 通过 `order_id IS NOT NULL OR paid_datetime IS NOT NULL OR confirmed_datetime IS NOT NULL` 过滤，确保本表只保留有实际订单事件的行，纯广告曝光/点击行不写入本表。

2. **汇率关联方式为 LEFT JOIN**：若当日汇率维表缺失对应地区数据，`exchange_rate` 将为 NULL，导致所有美元字段（`ads_gmv_amt_usd`、`broad_order_gmv_amt_usd`）为 NULL。使用美元字段前建议检查数据完整性。

3. **参数化调度**：ETL 中出现的 `'BR'`、`upper('${region}')` 等为调度模板的参数化实例，实际调度时由 `${region}`、`${grass_date}` 变量替换，覆盖所有 Shopee 运营地区，各地区按本地时区独立调度。

4. **GMV 口径差异**：`ads_gmv_amt_local` 使用 `order_price`（仅含商品折扣/捆绑促销），与 order\_mart 的 `total_price`（含运费、平台返利、卖家券等全类型优惠）存在系统性差异，跨系统对比 GMV 时需特别注意口径对齐。

5. **写入分区**：当前 ETL 固定写入 `tz_type='local'` 分区，如未来新增其他时区类型分区，查询侧过滤条件需相应调整。

6. **REPARTITION(100)**：ETL 强制指定 100 个输出文件分区，适配大数据量地区；小地区可能产生较多小文件，读取时注意 Spark/Hive 的文件合并配置。

---

*文档生成时间：2026-04-22*