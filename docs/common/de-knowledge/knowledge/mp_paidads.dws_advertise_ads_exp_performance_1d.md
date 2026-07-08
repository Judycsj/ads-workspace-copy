<!-- ads-workspace-gdoc-sync: gdoc_id=1rETgutvMSDstkVRr9KsCjMIq1LlQgqyC_HcPKtmhXI0 gdoc_url=https://docs.google.com/document/d/1rETgutvMSDstkVRr9KsCjMIq1LlQgqyC_HcPKtmhXI0/edit -->

# mp_paidads.dws_advertise_ads_exp_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`user_id` + `entrance` + `exp_id` + `placement` + `platform` + `outlier_label` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1 调度，覆盖前一自然日数据）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表面向 **广告 A/B 实验分析**场景，记录各地区每日广告曝光、点击、转化、消耗等核心绩效指标，按用户（`user_id`）× 实验分组（`exp_id`）× 广告入口/位置（`entrance` / `placement`）× 平台（`platform`）粒度进行汇总。其核心价值在于将来自不同广告形态（搜索广告、发现广告、视频广告、橱窗广告、直播广告等）的 A/B 实验信号统一解析、拼接，供实验效果评估平台或分析师在同一口径下对比各实验组的广告表现。

本表同时关联了平台大盘 GMV 分层标签（`outlier_label`）及各广告形态维度的异常卖家标签（`shop_ads_outlier_label` 等），使下游分析可在剔除头部异常用户后进行更稳健的实验效果评估，有效应对广告实验中因超级买家/大卖家带来的数据噪声问题。

本表仅写入 `tz_type = 'local'` 分区，各地区按本地时区参数化调度，覆盖全量运营地区。适用场景包括：广告实验日报、实验指标汇总看板、异常用户过滤后的 A/B 实验效果分析等。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。本表仅写入 `'local'`（各地区本地时区），查询时**必须指定 `tz_type = 'local'`** |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'`、`'ID'` 等，覆盖全量运营地区 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD` |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 广告主（卖家）用户 ID |
| `entrance` | int | 广告流量入口编码。搜索广告/展示广告入口值为 `1,5,6,23,24,27,28`；发现广告/视频广告为其余值；橱窗广告（Shop Ads）按 `placement` 区分 |
| `exp_id` | string | A/B 实验分组标识，由 ETL 从原始 `ab_sign` 字段按不同广告类型的解析规则拆分提取。⚠️ 同一用户同一天可能对应多条不同 `exp_id`，勿在未 GROUP BY `exp_id` 的情况下直接聚合，否则会重复计算 |
| `placement` | int | 广告位编码。`3` 或 `2003` 为橱窗广告；`2030` 为游戏广告；`0,4,1000,1200` 为搜索广告；`3327,3328,3337,3338,3339,3342` 为直播广告；其余为发现/视频广告 |
| `platform` | int | 广告投放平台编码（如 Android / iOS / PC 等） |

---

### 维度：异常用户分层标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `outlier_label` | string | 基于平台大盘当日 GMV 的买家分层标签，取值：`'top_05_percent'`（前 0.5%）、`'top_1_percent'`（前 1%）、`'bottom_99_percent'`（其余）。未能匹配大盘数据的用户默认填充 `'bottom_99_percent'`。⚠️ 该标签按用户当日 GMV 全量分桶（ntile(200)）计算，仅反映当日排名，不具跨天可比性 |
| `shop_ads_outlier_label` | string | 基于橱窗广告（placement in (3,2003)）broad GMV 的卖家异常分层，取值同 `outlier_label`。若该卖家当日橱窗广告 broad GMV 为 0 则为 NULL |
| `game_ads_outlier_label` | string | 基于游戏广告（placement = 2030）broad GMV 的卖家异常分层，取值同 `outlier_label`。若无正向 GMV 则为 NULL |
| `search_ads_outlier_label` | string | 基于搜索广告（placement in (0,4,1000,1200)）broad GMV 的卖家异常分层，取值同 `outlier_label`。若无正向 GMV 则为 NULL |
| `live_ads_outlier_label` | string | 基于直播广告（placement in (3327,3328,3337,3338,3339,3342)）broad GMV 的卖家异常分层，取值同 `outlier_label`。若无正向 GMV 则为 NULL |

---

### 指标：广告点击与曝光

| 字段 | 类型 | 说明 |
|------|------|------|
| `impressions` | bigint | 广告曝光次数（来源字段 `impression_cnt`） |
| `deduct_impression` | bigint | 计费曝光次数（与扣费逻辑相关的曝光量） |
| `ads_click_cnt` | bigint | 成功扣费的有效点击数（来源字段 `click_cnt`） |
| `raw_clicks` | bigint | 总点击数（含扣费失败的点击，来源字段 `raw_click_cnt`）。⚠️ `raw_clicks` ≥ `ads_click_cnt`，两者差值为扣费失败点击；不可用 `raw_clicks` 替代 `ads_click_cnt` 计算 CTR |
| `deduplicated_click_cnt_1d` | bigint | 1 日内去重点击数（来源字段 `deduplicated_click`）。⚠️ 已在 ETL 中按 1 日窗口去重，含义不同于 `ads_click_cnt`，不可与后者直接叠加 |
| `product_click` | bigint | 商品点击次数（广告展示中用户点击商品的次数） |

---

### 指标：视频互动

| 字段 | 类型 | 说明 |
|------|------|------|
| `video_view` | bigint | 视频播放次数（启动即计） |
| `video_play_3s_cnt` | bigint | 视频播放超过 3 秒的次数 |
| `video_play_5s_cnt` | bigint | 视频播放超过 5 秒的次数 |
| `video_play_complete` | bigint | 视频完整播放次数 |
| `view_duration` | bigint | 视频累计播放时长（单位：毫秒或秒，具体单位以上游 `dwd_advertise_performance_di` 字段定义为准）。⚠️ 为累计时长之和，计算平均播放时长需除以 `video_view`，不可直接与其他粒度数据相加后比较 |

---

### 指标：转化与 GMV（7 日直接归因）

| 字段 | 类型 | 说明 |
|------|------|------|
| `add_to_cart` | bigint | 加购次数（24 小时归因窗口，来源字段 `add_to_cart_cnt`） |
| `ads_order_cnt` | bigint | 广告直接带来的订单数（7 日直接归因，来源字段 `order_cnt`） |
| `ads_gmv_usd` | decimal(25,10) | 广告直接归因 GMV（USD，7 日直接归因），来源字段 `ads_order_gmv_usd`。⚠️ 已折算为 USD，折算汇率来自 `dim_exchange_rate`，汇率为当日汇率，不适合跨日直接累加后与其他汇率口径对比 |
| `broad_order_cnt` | bigint | 广义归因订单数（7 日宽泛归因，来源字段 `broad_order_cnt`） |
| `broad_gmv_usd` | decimal(25,10) | 广义归因 GMV（USD，7 日宽泛归因）。⚠️ 由 `broad_gmv_amt_local`（本地货币）除以当日汇率转换而来，跨地区/跨日汇总时需注意汇率一致性 |

---

### 指标：广告消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_revenue_usd` | decimal(25,10) | 广告消耗金额（USD），即广告主的广告花费，来源字段 `expenditure_amt_usd` |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐值 / 说明 | 遗漏后果 |
|----------|--------------|---------|
| `tz_type` | 必须指定 `tz_type = 'local'` | 本表仅写入 `local` 分区，若不过滤将触发全分区扫描，在分区不完整时可能返回 0 行或引发性能问题 |
| `grass_region` | 按需指定目标地区，如 `grass_region = 'TH'` | 不过滤将跨全量地区扫描，数据量成倍膨胀，极大影响查询性能 |
| `grass_date` | 指定具体日期或日期范围，如 `grass_date = '2026-04-21'` | 不过滤将触发全量历史分区扫描，严重影响性能且易导致资源超限 |

**最小安全查询模板：**
```sql
SELECT ...
FROM mp_paidads.dws_advertise_ads_exp_performance_1d__reg_s0_live
WHERE tz_type      = 'local'
  AND grass_region = '<目标地区>'
  AND grass_date   = '<目标日期>'
  AND exp_id       = '<目标实验ID>'  -- 推荐：进一步限制扫描范围
```

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|---------|------------|
| `broad_gmv_usd` | 由本地货币 GMV 除以当日汇率得到，不同地区汇率不同，多地区跨日直接 SUM 存在汇率口径不一致 | 单地区单日直接 SUM 安全；多地区汇总应确保各自汇率一致性或回溯至本地货币口径 |
| `ads_gmv_usd` | 同上，已按当日汇率折算 | 同上 |
| `view_duration` | 为各行播放时长之和，计算人均/次均时长需搭配 `video_view` 作分母 | 平均播放时长 = `SUM(view_duration) / NULLIF(SUM(video_view), 0)` |
| `deduplicated_click_cnt_1d` | 已在 ETL 中执行 1 日去重，与 `ads_click_cnt` 口径不同，两者不可叠加 | 根据分析目的选择一个口径，不可 `ads_click_cnt + deduplicated_click_cnt_1d` |
| `outlier_label` / `*_outlier_label` | 为分桶派生字段，不具备数值聚合意义 | 用于 `WHERE` / `GROUP BY` 过滤或分组，不可 SUM |
| `exp_id` | 同一用户同日可能有多条 `exp_id` 记录，未 GROUP BY `exp_id` 直接聚合将导致重复计数 | 必须在 `GROUP BY` 中包含 `exp_id` 字段，或明确指定 `WHERE exp_id = '...'` |

---

### 时效性说明

- 本表写入分区固定为 `tz_type = 'local'`，数据为各地区本地时区的自然日粒度，**无 UTL/UTC 双时区分区**，查询时无需额外区分时区版本。
- 本表为 T+1 调度，查询最新数据应使用 `grass_date = CURRENT_DATE - 1`（或调度完成后的最新分区日期），**避免查询当天分区（数据可能尚未写入或写入不完整）**。
- `outlier_label` 及各 `*_outlier_label` 标签基于当日快照计算，**仅反映该日期的分桶结果，不可跨日直接比较分层变化**。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 核心来源表，提供广告曝光、点击、转化、消耗等行级明细数据，以及 A/B 实验标识 `ab_sign` |
| `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 提供平台大盘买家 GMV，用于计算平台级 `outlier_label` 异常分层 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 提供当日地区汇率，用于将本地货币 GMV（`broad_gmv_amt_local`）折算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  │
  ├──[entrance 过滤 & ab_sign 按 \|r\| 拆分]──────────────────────────┐
  │   搜索广告 / 展示广告                                               │
  │                                                                    │
  ├──[entrance 排除 & ab_sign 按 \|p\| + # 解析]────────────────────── ├──► ads_exp_base_info
  │   发现广告 / 视频广告 (discovery_ads_ab cache)                      │    (UNION ALL 合并4类广告)
  │                                                                    │
  ├──[发现广告 Cross-traffic ab_sign 按 \|bkt\| 拆分]─────────────────┤
  │                                                                    │
  └──[placement in (3,2003) & ab_sign 按 \|m\| 拆分]─────────────────┘
      橱窗广告 (Shop Ads)

ads_exp_base_info
  │
  ├── LEFT JOIN platfrom_base_info ◄── dwd_order_item_place_pay_complete_di (ntile GMV 分桶)
  │   → 获取平台大盘 outlier_label
  │
  └──► [GROUP BY user_id, entrance, placement, platform, exp_id, outlier_label]
        → ads_base (聚合层)
              │
              ├── LEFT JOIN dim_exchange_rate → broad_gmv_local / rate = broad_gmv_usd
              ├── LEFT JOIN shop_ads_rank_info  ◄── dwd_advertise_performance_di (placement 3,2003)
              ├── LEFT JOIN game_ads_rank_info  ◄── dwd_advertise_performance_di (placement 2030)
              ├── LEFT JOIN search_ads_rank_info◄── dwd_advertise_performance_di (placement 0,4,1000,1200)
              └── LEFT JOIN live_ads_rank_info  ◄── dwd_advertise_performance_di (placement 3327-3342)
                        │
                        ▼
          ads_exp_info (最终视图)
                        │
                        ▼
  dws_advertise_ads_exp_performance_1d__reg_s0_live
  (INSERT OVERWRITE partition tz_type='local')
```

---

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|--------------|--------|------|
| `discovery_ads_ab` | `dwd_advertise_performance_di` | 缓存发现广告 & 视频广告明细（`entrance not in (1,5,6,23,24,27,28)`），拆分 `ab_sign` 为数组，供后续两个 UNION 分支复用 |
| `ads_exp_base_info` | `dwd_advertise_performance_di`（3 路）+ `discovery_ads_ab`（2 路） | 将 4 类广告（搜索/展示、发现、发现跨流量、橱窗）各自按对应的分隔符规则解析 `ab_sign`，UNION ALL 输出行级 `exp_id` 展开明细 |
| `platfrom_base_info` | `dwd_order_item_place_pay_complete_di` | 计算平台大盘买家当日 GMV，使用 `ntile(200)` 分桶生成 `outlier_label` |
| `shop_ads_rank_info` | `dwd_advertise_performance_di`（placement 3,2003）| 按橱窗广告 broad GMV 对卖家分桶，生成 `shop_ads_outlier_label` |
| `game_ads_rank_info` | `dwd_advertise_performance_di`（placement 2030）| 按游戏广告 broad GMV 对卖家分桶，生成 `game_ads_outlier_label` |
| `search_ads_rank_info` | `dwd_advertise_performance_di`（placement 0,4,1000,1200）| 按搜索广告 broad GMV 对卖家分桶，生成 `search_ads_outlier_label` |
| `live_ads_rank_info` | `dwd_advertise_performance_di`（placement 3327/3328/3337/3338/3339/3342）| 按直播广告 broad GMV 对卖家分桶，生成 `live_ads_outlier_label` |
| `ads_exp_info` | `ads_exp_base_info` + `platfrom_base_info` + 4 类 rank_info + `dim_exchange_rate` | 汇总聚合 + 关联异常标签 + 汇率转换，输出最终写入字段集 |

---

### 注意事项

1. **ab_sign 解析逻辑各广告类型不同**：搜索/展示广告使用 `\|r\|` 分隔符拆分实验 ID；发现/视频广告使用 `\|p\|` 后结合 `#` 和 `@` 进行多层解析；橱窗广告使用 `\|m\|`；发现广告跨流量实验使用 `\|bkt\|`。下游若需反查某 `exp_id` 来源，需对应广告类型的解析规则。

2. **搜索广告仅取 `tz_type = 'local'` 分区数据**：在 `ads_exp_base_info` 的搜索/展示广告分支中，查询 `dwd_advertise_performance_di` 时已明确过滤 `tz_type = 'local'`，而发现广告 `discovery_ads_ab` 分支未添加该过滤。最终写入本表均为 `local` 分区，此差异在上游 DWD 层已通过 `grass_date` 对齐。

3. **`outlier_label` 缺失值填充**：当广告明细中的 `user_id` 无法匹配 `platfrom_base_info`（如该买家当日无平台订单），ETL 使用 `COALESCE(outlier_label, 'bottom_99_percent')` 填充，即默认归入普通用户。过滤分析时注意此类用户并非真正具有 bottom 99 分布特征，只是无法分层。

4. **`broad_gmv_usd` 汇率依赖**：`broad_gmv_usd` 由本地货币除以当日汇率得到，若 `dim_exchange_rate` 数据缺失，对应行的 `broad_gmv_usd` 将为 NULL，而非 0。使用前需确认汇率数据完整性。

5. **各 `*_outlier_label` 可能为 NULL**：各广告类型的异常标签来自 LEFT JOIN，仅当该卖家在对应广告类型有正向 broad GMV 时才会有分层结果，否则为 NULL。下游过滤时建议使用 `COALESCE(shop_ads_outlier_label, 'bottom_99_percent')` 处理。

6. **本表为末端 ADS 层表**：当前无其他候选表引用本表，通常直接由 BI 报表、实验效果平台或数据科学团队查询使用。

---

*文档生成时间：2026-04-22*