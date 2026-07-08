<!-- ads-workspace-gdoc-sync: gdoc_id=16GZMOnileqPTaBg1wXCQWmN6jFoei6oq3E5UwcIa7CM gdoc_url=https://docs.google.com/document/d/16GZMOnileqPTaBg1wXCQWmN6jFoei6oq3E5UwcIa7CM/edit -->

# mp_paidads.ads_sc_potential_product_ads_item_rcmd_daily

**分层**：ADS（应用数据层）
**主键**：`item_id`（业务主键）；`key` 字段为复合字符串主键（`item_{region}_{item_id}:potential_product`）
**分区**：`grass_region`（地区）、`grass_date`（业务日期）
**更新频率**：每日调度，覆盖 `BIZ_YESTERDAY` 分区
**引用频次**：1 次（候选表范围内下游引用）

---

## 业务描述

本表是付费广告潜力商品推荐的核心输出表，每日产出各地区满足潜力评分条件的商品推荐列表，供广告智能推荐系统消费。表中每行代表一个候选推荐商品，携带其在近7日的广告绩效指标（曝光、点击转化率、GMV、订单数、增长率）以及类目分位基准值，用于判断商品是否具备"高潜力"或"低价潜力"两类推荐资质。

本表主要服务于两类场景：**好潜力商品（good_potential）** 推荐——基于 CTR×CR、GMV、订单增长率在同类目内的分位排名筛选出表现优异且有增长趋势的商品；**低价潜力商品（low_price_potential）** 推荐——来自价格竞争力模型，筛选当前未投放广告的低价竞争力商品。两类商品通过 FULL JOIN 合并后统一写入本表，下游广告推荐服务通过 `key` 字段拉取并解析 `value` 序列化字段使用。

本表的核心价值在于：将平台销售漏斗数据、类目分位基准、刷单异常过滤、大促日历修正等多路信号融合成一张可直接供广告推荐系统消费的商品候选集，同时通过 `good_potential_score` 和 `low_price_score` 两个评分字段明确标注商品的推荐类型，实现广告流量的精准导流。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码（大写），如 `ID`、`MY`、`TH` 等；各地区按本地时区参数化调度独立写入分区 |
| `grass_date` | date | 业务日期分区，对应 `BIZ_YESTERDAY`（调度日前一天），即指标统计基准日 |

---

### 维度：主键与广告推荐属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `key` | string | 推荐记录的复合字符串主键，格式为 `item_{grass_region}_{item_id}:potential_product`，由调度参数拼接生成，供下游 KV 存储或推荐服务按 key 检索 |
| `value` | string | 由自定义 UDF `marshal_item` 序列化生成的字段，编码内容包含 `item_id`、`good_potential_score`、`low_price_score`，下游需调用对应反序列化方法解析，不可直接文本解析 ⚠️ 为 UDF 序列化字节串，不可直接当字符串读取，需通过配套反序列化工具解码 |
| `item_id` | bigint | 商品 ID，业务主键，与 `grass_region`、`grass_date` 联合唯一 |
| `shop_id` | bigint | 店铺 ID，商品归属店铺 |
| `good_potential_score` | int | 好潜力评分标记：`1` 表示该商品通过好潜力筛选规则，`0` 表示未通过（仅来自低价潜力路径的商品默认为 `0`）⚠️ 非连续评分，仅为 0/1 标记，不可参与数值聚合计算均值 |
| `low_price_score` | int | 低价潜力评分标记：`1` 表示该商品来自低价竞争力模型且当前未投放广告，`0` 表示非此路径⚠️ 非连续评分，仅为 0/1 标记，不可参与数值聚合计算均值 |

---

### 维度：类目层级

| 字段 | 类型 | 说明 |
|------|------|------|
| `l1_cat` | bigint | 商品一级类目 ID；来自 `rcmd_score_stats` 维表，`0` 表示缺失 |
| `l2_cat` | bigint | 商品二级类目 ID；`0` 表示缺失 |
| `l3_cat` | bigint | 商品三级类目 ID；`0` 表示缺失；ETL 中以 `final_cat` 优先取 l3 > l2 > l1 用于分位基准匹配 |

---

### 指标：商品近7日广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_7d` | bigint | 近7日（剔除大促日后有效天）商品自然流量曝光总数，来源于 `dws_user_item_feature_sales_funnel_metrics_1d` |
| `ctrcr_7d` | double | 近7日点击转化率（CTRCR），计算口径为 `order_cnt_7d / impression_7d`（即曝光到订单的综合转化率），保留5位小数 ⚠️ 为预计算比率，不可直接 SUM，跨商品汇总需用 `order_cnt_7d / impression_7d` 重新计算 |
| `gmv_usd_7d` | double | 近7日 GMV（美元），来源于平台 omni 销售漏斗数据，保留5位小数 |
| `order_cnt_7d` | double | 近7日有效天订单数（剔除大促日后的实际订单总量），保留5位小数 |
| `order_growth_rate` | double | 近7日 vs 近14日（对比周期）日均订单数增长率，计算口径为 `avg_order_7d / avg_order_cnt_14d - 1`；仅当 `avg_order_cnt_14d > 0` 且近期日均高于历史日均时有值，否则为 `NULL` ⚠️ 为派生比率字段，不可直接 SUM，跨商品聚合需回溯分子分母；NULL 表示无可比基准期数据 |

---

### 指标：类目分位基准

| 字段 | 类型 | 说明 |
|------|------|------|
| `ctrcr_p50` | double | 商品所属类目（final_cat 对应层级）在当日所有候选商品中 CTRCR 的 P50 分位数；仅统计 `impression_7d >= 100` 且 `click_7d > 0` 的商品 ⚠️ 为类目级预聚合分位值，不代表单商品指标，不可 SUM/AVG |
| `gmv_p60` | double | 商品所属类目 GMV（美元）的 P60 分位数，用于好潜力筛选下界 ⚠️ 为类目级预聚合分位值，不可 SUM/AVG |
| `gmv_p90` | double | 商品所属类目 GMV（美元）的 P90 分位数，用于好潜力筛选上界（排除头部异常高GMV商品）⚠️ 为类目级预聚合分位值，不可 SUM/AVG |
| `order_growth_p60` | double | 商品所属类目订单增长率的 P60 分位数，仅统计 `order_growth_rate > 0` 的商品 ⚠️ 为类目级预聚合分位值，不可 SUM/AVG |
| `order_p80` | double | 商品所属类目近7日订单数的 P80 分位数，用于无历史对比期时的订单门槛替代指标 ⚠️ 为类目级预聚合分位值，不可 SUM/AVG |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询 **必须同时指定** 以下分区条件，否则将触发全表全分区扫描，导致查询超时或产生高昂计算费用：

```sql
WHERE grass_region = '<REGION>'   -- 必填，如 'ID'、'MY'、'TH'，大写
  AND grass_date = DATE '<YYYY-MM-DD>'  -- 必填，指定具体业务日期
```

- `grass_region`：必须使用大写地区编码，与写入时 `upper('${region}')` 一致。
- `grass_date`：本表每日覆盖写入，通常取最新分区（`BIZ_YESTERDAY`）。遗漏任一分区条件将导致读取所有历史分区数据，严重影响查询性能。

---

### 不可直接 SUM 的字段

| 字段 | 错误用法 | 正确处理方式 |
|------|----------|-------------|
| `ctrcr_7d` | `SUM(ctrcr_7d)` / `AVG(ctrcr_7d)` | 跨商品汇总需用 `SUM(order_cnt_7d) / SUM(impression_7d)` 重新计算 |
| `order_growth_rate` | `SUM(order_growth_rate)` | 派生比率，需回溯分子分母（`avg_order_7d`、`avg_order_cnt_14d`）重新计算；本表未存储原始分母，如需跨商品聚合请关联中间表 `ads_sc_potential_product_ads_item_temp__reg` |
| `ctrcr_p50` / `gmv_p60` / `gmv_p90` / `order_growth_p60` / `order_p80` | 任何聚合操作 | 均为类目级预计算分位基准值，仅供单行筛选逻辑参考，不具备跨行 SUM/AVG 意义 |
| `good_potential_score` / `low_price_score` | `SUM` 后做均值 | 仅为 0/1 标记位；`COUNT(*) WHERE good_potential_score = 1` 可用于统计好潜力商品数量 |
| `value` | 直接字符串解析 | 需调用配套反序列化 UDF（`marshal_item` 逆向工具）解码，不可直接 `LIKE` 或文本截取 |

---

### 时效性说明

- 本表写入的 `grass_date` 分区为调度日的 `BIZ_YESTERDAY`，即每日 T+1 产出前一天的数据。
- 查询最新数据时应取 `MAX(grass_date)` 对应分区，或明确指定最近已完成调度的日期。
- `order_growth_rate` 字段在以下情况下为 `NULL`：商品近14日无有效订单（`avg_order_cnt_14d = 0`）或近7日日均不高于历史日均，查询时注意 NULL 处理（用 `COALESCE` 或 `IS NOT NULL` 过滤）。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live` | 提供商品维度的近7日、近14日曝光数、点击数、GMV（美元）、订单数等核心销售漏斗指标 |
| `mp_paidads.dim_campaign_day__reg_s0_live` | 大促日历维表，用于识别并剔除大促日，修正有效统计天数（`campaign_days_7d`/`campaign_days_14d`） |
| `mkplpaidads_data.rcmd_score_stats` | 商品属性维表，提供商品的 `shop_id`、三级类目（`l1/l2/l3_cat`）、价格、SKU 状态等维度信息 |
| `mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live` | 当前已投放广告的商品黑名单，用于排除已在投广告的商品（好潜力路径与低价潜力路径均需过滤） |
| `szci_antifraud.brushing_detection_abnormal_item_online_di` | 刷单异常商品名单，用于在好潜力候选商品中过滤刷单异常商品 |
| `srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf` | 低价竞争力模型输出，提供具有低价潜力的商品列表，构成 `low_price_potential = 1` 的商品来源 |
| `mp_paidads.ads_sc_potential_product_ads_item_temp__reg` | ETL 中间临时表，存储商品原始绩效指标及类目信息，作为类目分位计算和好潜力筛选的基础 |

---

## ETL 逻辑摘要

### 数据流

```
traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live
        │  (近7日 + 近14日曝光/点击/GMV/订单，剔除大促日)
        │
mp_paidads.dim_campaign_day__reg_s0_live ──► [campaign_days CACHE]
        │  (大促日历，修正有效统计天数)
        │
        ▼
   ┌─────────────────────────────────┐
   │  Step 1: 计算商品绩效基础指标    │
   │  ctrcr_7d / gmv_usd_7d /        │
   │  order_cnt_7d / order_growth_rate│
   └──────────────┬──────────────────┘
                  │
mkplpaidads_data.rcmd_score_stats ─────► JOIN (item_id → shop_id, 类目)
                  │
ads_simple_roi2_npb_item_hi ───────────► LEFT JOIN → 过滤已投广告商品
                  │
szci_antifraud.brushing_detection ─────► LEFT JOIN → 过滤刷单异常商品
                  │
                  ▼
   ads_sc_potential_product_ads_item_temp__reg（中间表，INSERT OVERWRITE）
                  │
                  ├──────────────────────────────────────────────────────┐
                  │  Step 2: 按类目计算分位基准                          │
                  │  (l1/l2/l3_cat 分别计算 P50/P60/P80/P90)            │
                  │  → category_data (TEMP VIEW)                         │
                  │                                                       │
                  ▼                                                       │
   ┌─────────────────────────────────┐                                   │
   │  好潜力路径 (good_potential=1)   │◄──────────────────────────────────┘
   │  筛选规则：                      │
   │  impression>=100, click>0,       │
   │  avg_order_7d > avg_14d,         │
   │  ctrcr>=p50, gmv in [p60,p90],   │
   │  growth>=p60 or order>=p80       │
   └──────────────┬──────────────────┘
                  │  FULL JOIN
   ┌──────────────▼──────────────────┐
   │  低价潜力路径 (low_price=1)      │◄─── srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf
   │  来自价格竞争力模型              │◄─── (排除已投广告: ads_simple_roi2_npb_item_hi)
   └──────────────┬──────────────────┘
                  │
                  ▼
   marshal_item UDF 生成 value 字段
   CONCAT 生成 key 字段
                  │
                  ▼
ads_sc_potential_product_ads_item_rcmd_daily__reg_s0_live（INSERT OVERWRITE）
```

---

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `campaign_days`（CACHE TABLE） | `mp_paidads.dim_campaign_day__reg_s0_live` | 统计近7日、近14日、近21日内大促天数，动态确定有效统计窗口的日期序列（`grass_date_7D`、`grass_date_14D`）及有效天数（`campaign_days_7d`、`campaign_days_14d`），用于修正日均订单分母 |
| `category_data`（TEMP VIEW） | `ads_sc_potential_product_ads_item_temp__reg` | 按 l1/l2/l3 三级类目分别计算 CTRCR P50、GMV P60/P90、订单增长率 P60、订单数 P80 共5个分位基准值，UNION ALL 合并后供好潜力筛选规则使用 |

---

### 注意事项

1. **大促日修正机制**：ETL 通过 `campaign_days` 动态判断近7日内实际大促天数。若大促天数 < 7，则使用近7日作为当期窗口、近14日作为对比窗口；否则向前顺移一个窗口（近14日/近21日），以确保统计的有效性不受大促日异常数据干扰。查询 `order_growth_rate` 时应注意其分子分母的有效天数并非固定7天。

2. **刷单过滤逻辑**：仅在好潜力路径（Step 1 → 中间表写入阶段）对商品做刷单过滤；低价潜力路径不经过刷单过滤，可能包含行为异常商品，使用时需注意。

3. **good_potential_score / low_price_score 并集关系**：两个字段通过 FULL JOIN 合并，同一商品可能同时为 `good_potential_score=1` 且 `low_price_score=1`。筛选时应注意是否需要 OR / AND 语义。

4. **中间表依赖**：`category_data` 临时视图依赖 `ads_sc_potential_product_ads_item_temp__reg` 当日分区，该中间表在同一任务内先于最终表写入。若需复现类目分位值，应查询此中间表而非本表（本表已存储分位基准字段，但无法还原中间计算过程）。

5. **`value` 字段序列化**：`marshal_item` 为自定义 UDF（`com.shopee.deepdata.warehouse.hive.udf.MarshalItemPotential`），其输出为 Java/Scala 序列化的字节编码字符串，下游 Flink/Spark 消费端需加载同一 UDF 或配套解码库方可正确解析，不可直接用 SQL 字符串函数处理。

6. **类目分位值继承层级**：`ctrcr_p50` 等分位字段的计算类目为 `final_cat`（优先 l3 > l2 > l1），但本表写入时 `category_data` 包含三个层级的 UNION ALL，JOIN 时以 `final_cat` 匹配，若 l3_cat 有值则优先用 l3 分位，否则回落至 l2、l1，确保每个商品都能获得分位基准。

---

*文档生成时间：2026-04-22*